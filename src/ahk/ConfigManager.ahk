; ConfigManager.ahk - Handle reading and writing configuration values
; Replaced dependency on _JXON.ahk with a minimal internal JSON parser
; supporting only the constructs we need: a top-level object with
; string keys and primitive (string/number/boolean/null) values.
; If future needs expand, consider adding a full JSON library again.
#Requires AutoHotkey v2.0

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

; ---------------- Minimal JSON Parser (object + primitives) -----------------
Json_Parse(json) {
  idx := 1
  return Json_ParseValue(json, &idx)
}

Json_SkipWS(str, &i) {
  while (i <= StrLen(str)) {
    ch := SubStr(str, i, 1)
    if (ch != " " && ch != "`t" && ch != "`r" && ch != "`n")
      break
    i++
  }
}

Json_ParseValue(str, &i) {
  Json_SkipWS(str, &i)
  if (i > StrLen(str))
    throw Error("Unexpected end of JSON")
  ch := SubStr(str, i, 1)
  if (ch = '"')
    return Json_ParseString(str, &i)
  if (ch = '{')
    return Json_ParseObject(str, &i)
  if RegExMatch(ch, "[-0-9]")
    return Json_ParseNumber(str, &i)
  if (SubStr(str, i, 4) = "true") {
    i += 4
    return true
  }
  if (SubStr(str, i, 5) = "false") {
    i += 5
    return false
  }
  if (SubStr(str, i, 4) = "null") {
    i += 4
    return "" ; represent null as empty string
  }
  throw Error("Unexpected token at position " i)
}

Json_ParseString(str, &i) {
  if (SubStr(str, i, 1) != '"')
    throw Error("Expected '" . '"' . "' at position " i)
  i++ ; skip opening quote
  out := ""
  while (i <= StrLen(str)) {
    ch := SubStr(str, i, 1)
    if (ch = '"') {
      i++
      return out
    }
    if (ch = "\\") { ; escape
      i++
      if (i > StrLen(str))
        throw Error("Bad escape at end")
      esc := SubStr(str, i, 1)
      switch esc {
        case '"', '\\', '/':
          out .= esc
        case 'b':
          out .= Chr(8)
        case 'f':
          out .= Chr(12)
        case 'n':
          out .= "`n"
        case 'r':
          out .= "`r"
        case 't':
          out .= "`t"
        case 'u': ; read next 4 hex (no surrogate pair handling)
          hex := SubStr(str, i + 1, 4)
          if !RegExMatch(hex, "^[0-9A-Fa-f]{4}$")
            throw Error("Invalid unicode escape")
          code := "0x" hex
          out .= Chr(code)
          i += 4
        default:
          throw Error("Invalid escape character '" esc "'")
      }
    } else {
      out .= ch
    }
    i++
  }
  throw Error("Unterminated string")
}

Json_ParseNumber(str, &i) {
  start := i
  len := StrLen(str)
  if (SubStr(str, i, 1) = '-')
    i++
  while (i <= len && RegExMatch(SubStr(str, i, 1), "[0-9]"))
    i++
  if (i <= len && SubStr(str, i, 1) = '.') {
    i++
    while (i <= len && RegExMatch(SubStr(str, i, 1), "[0-9]"))
      i++
  }
  if (i <= len && (SubStr(str, i, 1) = 'e' || SubStr(str, i, 1) = 'E')) {
    i++
    if (SubStr(str, i, 1) = '+' || SubStr(str, i, 1) = '-')
      i++
    while (i <= len && RegExMatch(SubStr(str, i, 1), "[0-9]"))
      i++
  }
  numStr := SubStr(str, start, i - start)
  return numStr + 0
}

Json_ParseObject(str, &i) {
  if (SubStr(str, i, 1) != '{')
    throw Error("Expected '{' at position " i)
  i++
  obj := {}
  Json_SkipWS(str, &i)
  if (SubStr(str, i, 1) = '}') {
    i++
    return obj
  }
  loop {
    Json_SkipWS(str, &i)
    key := Json_ParseString(str, &i)
    Json_SkipWS(str, &i)
    if (SubStr(str, i, 1) != ':')
      throw Error("Expected ':' after key at position " i)
    i++
    value := Json_ParseValue(str, &i)
    obj[key] := value
    Json_SkipWS(str, &i)
    ch := SubStr(str, i, 1)
    if (ch = ',') {
      i++
      continue
    } else if (ch = '}') {
      i++
      break
    } else {
      throw Error("Expected ',' or '}' at position " i)
    }
  }
  return obj
}
; ---------------------------------------------------------------------------

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
