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

GetVideoDuration(filePath, fmt := "hms", roundSeconds := false) {
  ; Silently obtain video duration using ffprobe with no visible window.
  ; fmt (previously named 'format' but renamed to avoid shadowing built-in Format()):
  ;   "raw"    -> original ffprobe float seconds string (default)
  ;   "seconds"-> numeric seconds (optionally rounded)
  ;   "hms"    -> HH:MM:SS (rounded to nearest second unless roundSeconds=false, in which case truncates)
  ; Returns "" on failure.
  global FfprobePath
  if (!filePath || !FileExist(filePath))
    return ""
  FoundFfprobe := ProgramExistsFromPath(FfprobePath)
  if (!IsSet(FfprobePath) || FfprobePath = "" || !ProgramExistsFromPath(FfprobePath))
    return ""

  tempFile := A_Temp "\\ffdur_" A_TickCount ".txt"
  ffCmd := '"' FfprobePath '" -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "' filePath '"'
  cmdLine := 'cmd.exe /c "' ffCmd ' > "' tempFile '" 2>nul"'
  RunWait cmdLine, , "Hide"
  if !FileExist(tempFile)
    return ""
  dur := Trim(FileRead(tempFile))
  FileDelete(tempFile)
  if (dur = "")
    return ""

  durTrimmed := Trim(dur)
  durTrimmed := RegExReplace(durTrimmed, "[\r\n]")
  secFloat := durTrimmed + 0.0

  if (fmt = "raw") {
    if (roundSeconds)
      return Round(secFloat)
    return dur
  }

  ; Seconds numeric
  if (fmt = "seconds") {
    return roundSeconds ? Round(secFloat) : secFloat
  }

  if (fmt = "hms") {
    ; Choose integer seconds (rounded vs truncated)
    total := roundSeconds ? Round(secFloat) : Floor(secFloat)
    hrs := Floor(total / 3600)
    mins := Floor(Mod(total, 3600) / 60)
    secs := Mod(total, 60)
    Result := Format("{:02}:{:02}:{:02}", hrs, mins, secs)
    return Result
  }

  ; Unknown format -> fallback raw
  return dur
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
