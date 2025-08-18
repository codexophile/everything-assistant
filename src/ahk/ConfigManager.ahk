; ConfigManager.ahk - Handle reading and writing configuration values
#Requires AutoHotkey v2.0
#Include ..\..\..\#lib\_JXON.ahk

; Update a configuration value in memory and in the config.ini file
UpdateConfig(key, value) {
  global

  ; Skip if empty key
  if (!key)
    return false

  ; Check if it's a valid config key we manage
  allowedKeys := ["FileTaggerPath", "ElectronSubPath", "AvidemuxPath"] ; Add more as needed
  if (!HasValue(allowedKeys, key)) {
    MsgBox("Attempted to update unknown config key: " key)
    return false
  }

  ; Update the global variable
  try {
    %key% := value
  } catch {
    MsgBox("Failed to update " key)
    return false
  }

  ; Determine which section this belongs to
  section := GetConfigSection(key)
  if (!section)
    section := "General" ; Default section

  ; Write to the ini file
  IniWrite(value, "config.ini", section, key)
  return true
}

; Update multiple configuration values at once (from JSON string)
UpdateConfigBulk(jsonStr) {
  if (!jsonStr)
    return false

  try {
    ; Parse the JSON string
    changes := Jxon_Load(jsonStr)

    ; Apply each change
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
  pathKeys := ["FileTaggerPath", "ElectronSubPath", "AvidemuxPath"]
  if (HasValue(pathKeys, key))
    return "Paths"

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
