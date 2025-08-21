; FileActions.ahk - misc file / explorer / external tool helpers
#Requires AutoHotkey v2.0

SendToAvidemux(path) {
  global AvidemuxPath
  try {
    if (!FileExist(AvidemuxPath)) {
      MsgBox "Avidemux executable not found: " . AvidemuxPath
      return
    }
    if (!FileExist(path)) {
      MsgBox "File not found: " . path
      return
    }
    Run '"' . AvidemuxPath . '" "' . path . '"', , "UseErrorLevel"
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

OpenPwsh(folderPath, selectedFileName) {
  try {
    if (folderPath = "")
      return
    if !FileExist(folderPath) {
      MsgBox "Folder not found: " . folderPath
      return
    }
    pwshPath := "pwsh.exe"
    cmd := pwshPath " -NoExit -Command Set-Location -LiteralPath '" folderPath "'"
    Run cmd, folderPath, , &OutPid
    WinWait "ahk_pid " OutPid
    WinActivate
    A_Clipboard := '"' selectedFileName '"'
    Send("^v{Home}")
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

OpenFolder(folderPath) {
  try {
    if (folderPath = "")
      return
    if !FileExist(folderPath) {
      MsgBox "Folder not found: " . folderPath
      return
    }
    Run("explorer.exe " . Chr(34) . folderPath . Chr(34))
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

OpenExplorerSelect(pathToSelect) {
  try {
    if (pathToSelect = "")
      return
    if !FileExist(pathToSelect) {
      MsgBox "Path not found: " . pathToSelect
      return
    }
    Run("explorer.exe /select," . Chr(34) . pathToSelect . Chr(34))
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

SendToFileTagger(data) {
  try {
    s := ""
    if IsObject(data) {
      if data.HasProp("toSend")
        s := data.toSend
    } else {
      s := data
    }
    ; Run FileTaggerPath ElectronSubPath " " FileTaggerPath " --files-list " '"' s '"',
    ;   FileTaggerPath
    Run("tagger-launcher.ahk" ' "' s '"')
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

DeleteSelected() {
  global SelectedCount, SelectedFilePath, selectedFileName
  if (SelectedCount == 1) {
    FileRecycle(SelectedFilePath "\" selectedFileName)
  }
  else if (SelectedCount > 1) {
    Paths := GetMultipleSelectedFilePaths()
    loop parse Paths, "`n`r" {
      if (A_LoopField == "")
        continue
      try FileRecycle A_LoopField
      catch as error {
        MsgBox "Failed to recycle: " . A_LoopField . "`nError: " . error.Message
      }
    }
  }
}

GetVideoDuration(filePath) {
  global FfprobePath
  ; if (!FileExist(FfprobePath)) {
  ;   MsgBox("ffprobe.exe not found at: " . FfprobePath)
  ;   return ""
  ; }

  ; -v error: show only errors
  ; -show_entries format=duration: get only the duration value
  ; -of default=...: print the value raw, without the "duration=" key
  cmd := '"' FfprobePath '" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "' filePath '"'

  ; Run the command hidden and capture its stdout
  shell := ComObject("WScript.Shell")
  exec := shell.Exec(cmd)

  ; Wait for the process to finish and read the output
  output := ""
  while !exec.StdOut.AtEndOfStream
    output .= exec.StdOut.ReadAll()

  ; Trim whitespace and return the duration (in seconds)
  return Trim(output)
}

Explorer_GetSelected() {
  ID := WinGetID("A")
  shell := ComObject("Shell.Application")
  for window in shell.Windows {
    if (window.HWND = ID) {
      selectedItems := window.Document.SelectedItems
      paths := ""
      for item in selectedItems {
        paths .= item.Path . "`n"
      }
      return Trim(paths, "`n")
    }
  }
  return ""
}

JoinWithNewlines(arr) {
  result := ""
  for i, item in arr {
    result .= item . (i < arr.Length ? "`n" : "")
  }
  return result
}

GetSingleSelectedFilePath() {
  SelectedFileFullPath := SelectedFilePath "\" selectedFileName
  return SelectedFileFullPath
}

GetMultipleSelectedFilePaths() {
  global LastFileContext, LastSelectedPath, EverythingWindowTitle
  if (LastFileContext = "explorer" || (WinExist("ahk_class CabinetWClass") && LastSelectedPath != "" && !WinActive(
    EverythingWindowTitle))) {
    return LastSelectedPath  ; newline-delimited list already cached
  }
  WinActivate(EverythingWindowTitle)
  A_Clipboard := ""
  Send "^+c"
  ClipWait(1)
  return A_Clipboard
}

GetFolderChain(originalPath, folderPaths := []) {
  folderPaths.Push(originalPath)
  SplitPath(originalPath, , &parent)
  if (originalPath = parent || parent = "")
    return folderPaths
  return GetFolderChain(parent, folderPaths)
}
