; ConfigManager.ahk - Handle reading and writing configuration values
; Replaced dependency on _JXON.ahk with a minimal internal JSON parser
; supporting only the constructs we need: a top-level object with
; string keys and primitive (string/number/boolean/null) values.
; If future needs expand, consider adding a full JSON library again.
#Requires AutoHotkey v2.0
; Include minimal JSON parser extracted to its own file
#Include "MinimalJson.ahk"

; Default config values (ensure they exist as plain globals for JS access)
; JS reads window.ahk.global.OpenDevToolsAtStartup
if (!IsSet(OpenDevToolsAtStartup)) {
  OpenDevToolsAtStartup := false
}

; Load persisted values from config.ini (if present). This must happen early so
; the web UI (which reads window.ahk.global.*) sees the stored value instead of
; the default. Safe to call multiple times.
LoadInitialConfig() {
  global OpenDevToolsAtStartup
  iniFile := A_ScriptDir "\config.ini"
  if !FileExist(iniFile)
    return
  try {
    val := IniRead(iniFile, "General", "OpenDevToolsAtStartup", "")
    if (val != "") {
      ; Accept 1/0/true/false (case-insensitive)
      low := StrLower(val)
      if (val = 1 || val = "1" || low = "true")
        OpenDevToolsAtStartup := true
      else if (val = 0 || val = "0" || low = "false")
        OpenDevToolsAtStartup := false
      ; else leave default if unexpected
    }
  } catch {
    ; Ignore read errors; defaults remain.
  }
}

; Perform the initial load immediately when this file is included.
LoadInitialConfig()

; Getter exposed to JS (function bridging works even if raw variable bridging does not)
GetOpenDevToolsAtStartup() {
  global OpenDevToolsAtStartup
  return OpenDevToolsAtStartup ? 1 : 0
}

; JSON parser functions now live in MinimalJson.ahk

; Update a configuration value in memory and in the config.ini file
UpdateConfig(key, value) {
  global

  ; Skip if empty key
  if (!key)
    return false

  ; Check if it's a valid config key we manage
  allowedKeys := ["OpenDevToolsAtStartup"] ; Updated allowed keys list
  if (!HasValue(allowedKeys, key)) {
    MsgBox("Attempted to update unknown config key: " key)
    return false
  }

  ; Normalize boolean-like input for our only key
  if (key = "OpenDevToolsAtStartup") {
    ; Accept true/false/"true"/"false"/1/0
    if (value = true || value = 1 || value = "1" || value = "true")
      OpenDevToolsAtStartup := true
    else
      OpenDevToolsAtStartup := false
    valueToStore := OpenDevToolsAtStartup ? 1 : 0
  } else {
    return false ; should not happen with current allowedKeys
  }

  ; Determine which section this belongs to
  section := GetConfigSection(key)
  if (!section)
    section := "General" ; Default section

  ; Write to the ini file
  IniWrite(valueToStore, "config.ini", section, key)
  return true
}

; Update multiple configuration values at once (from JSON string)
UpdateConfigBulk(jsonStr) {
  if (!jsonStr)
    return false
  try {
    ; Allow passing either a JSON string or an already-materialized object
    if (Type(jsonStr) != "String") {
      changes := jsonStr
    } else {
      changes := Json_Parse(jsonStr)
    }

    if !(IsObject(changes))
      throw Error("Changes payload is not an object")

    success := true
    for key, value in changes {
      if (!UpdateConfig(key, value))
        success := false
    }
    return success
  } catch Error as e {
    MsgBox("Error processing bulk config update: " e.Message)
    return false
  }
}

; Browse for a file and return the selected path
BrowseForFile(startDir := "", fileTypes := "All Files (*.*)", title := "Select File") {
  try {
    selectedFile := FileSelect(3, , title, fileTypes)
    return selectedFile
  }
  catch {
    return ""
  }
}

; Browse for a folder and return the selected path
BrowseForFolder(startDir := "", title := "Select Folder") {
  try {
    selectedFolder := DirSelect(startDir, 3, title)
    return selectedFolder
  }
  catch {
    return ""
  }
}

; Helper to determine which section a config key belongs to
GetConfigSection(key) {
  ; Map known keys to their sections
  if (key = "OpenDevToolsAtStartup")
    return "General"

  ; Default to General for unknown keys
  return "General"
}

; Internal helper function for array containment check
HasValue(haystack, needle) {
  for value in haystack
    if (value = needle)
      return true
  return false
}

; Read and return the entire config.ini as an object of the form:
; {
;   SectionName: { Key: Value, ... },
;   ...
; }
; Primitive value coercion rules:
;   - "true"/"false" (case-insensitive) -> boolean true/false
;   - Numeric (integer or float) -> number
;   - Otherwise -> raw (trimmed) string
; If the ini file does not exist or can't be read, returns an empty object.
ReadFullConfig() {
  iniPath := A_ScriptDir "\config.ini"
  config := Map() ; Use Map for dynamic keyed access
  if !FileExist(iniPath)
    return config

  ; Read file content
  content := ""
  try content := FileRead(iniPath, "UTF-8")
  catch {
    return config
  }

  currentSection := "General" ; Assume implicit General if keys appear before any section header
  config[currentSection] := Map()

  for line in StrSplit(content, "`n", "`r") {
    if (line = "")
      continue
    ; Trim whitespace
    line := Trim(line)
    if (line = "")
      continue
    ; Skip comments starting with ; or #
    if (SubStr(line, 1, 1) = ";" || SubStr(line, 1, 1) = "#")
      continue
    ; Section header
    if (RegExMatch(line, "^\[(.+)\]$", &m)) {
      currentSection := m[1]
      if !config.Has(currentSection)
        config[currentSection] := Map()
      continue
    }
    ; Key=Value line
    eqPos := InStr(line, "=")
    if (eqPos) {
      key := Trim(SubStr(line, 1, eqPos - 1))
      value := Trim(SubStr(line, eqPos + 1))
      if (key = "")
        continue
      ; Coerce value type
      low := StrLower(value)
      if (low = "true") {
        coerced := true
      } else if (low = "false") {
        coerced := false
      } else if RegExMatch(value, "^[+-]?\d+$") { ; integer
        coerced := Integer(value)
      } else if RegExMatch(value, "^[+-]?\d+\.\d+([eE][+-]?\d+)?$") { ; float
        try {
          coerced := value + 0.0
        } catch {
          coerced := value
        }
      } else {
        coerced := value
      }
      ; Ensure section map exists (defensive)
      if !config.Has(currentSection)
        config[currentSection] := Map()
      config[currentSection][key] := coerced
    }
  }
  return config
}
