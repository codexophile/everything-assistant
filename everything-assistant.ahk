#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\#lib\WebViewToo\WebViewToo.ahk

; Constants
EverythingWindowTitle := "ahk_class EVERYTHING_(1.5a)"
AssistantWindowTitle := "Everything Assistant"
MainWidth := 300
FileTaggerPath := "c:\mega\IDEs\Electron\file-tagger\"
AvidemuxPath := "C:\Program Files\Avidemux\avidemux.exe"

; Hotkeys
; Alt+Shift+C -> Clean the current Everything query (remove &, commas, square brackets, tidy spaces)
!+c:: CleanQuery()

; Globals exposed to the WebView for current selection
SelectedFilePath := ""
SelectedFileName := ""
LastSelectedPath := ""
LastSelectedName := ""
SelectedNames := ""        ; newline-delimited names from Everything list view
SelectedCount := 0
SelectedFolderPaths := ""   ; folder chain (parent -> root) for current single selection
SelectedChaptersJson := ""  ; JSON array of chapter objects parsed from .ffmetadata (if any)

; GUI setup
AssistantGui := WebViewGui("Resize AlwaysOnTop")
AssistantGui.Title := AssistantWindowTitle
AssistantGui.Navigate "index.html"
AssistantGui.Debug()

; Poll Everything/Assistant focus & selection
SetTimer(CheckEverythingActive, 100)

; =========================
; Helpers / Reuse Utilities
; =========================

; Ensure Everything window exists. Returns true if present else false (and optionally shows a message).
EnsureEverythingWindow(showMsg := true) {
  global EverythingWindowTitle
  if WinExist(EverythingWindowTitle)
    return true
  if showMsg
    MsgBox "Everything window not found."
  return false
}

GetEverythingQuery() {
  global EverythingWindowTitle
  if !WinExist(EverythingWindowTitle)
    return ""
  return ControlGetText("Edit1", EverythingWindowTitle)
}

SetEverythingQuery(text) {
  global EverythingWindowTitle
  if !WinExist(EverythingWindowTitle)
    return
  ControlSetText(text, "Edit1", EverythingWindowTitle)
}

; Append token to existing query ensuring a separating space when needed.
AppendToken(curr, token) {
  return RegExMatch(curr, "\s$") ? curr . token : curr . " " . token
}

; Reset selection-related globals & notify webview.
ResetSelection() {
  global SelectedFilePath, SelectedFileName, SelectedNames, SelectedCount, SelectedFolderPaths
  global LastSelectedPath, LastSelectedName, SelectedChaptersJson, AssistantGui
  SelectedFilePath := ""
  SelectedFileName := ""
  SelectedNames := ""
  SelectedCount := 0
  SelectedFolderPaths := ""
  SelectedChaptersJson := ""
  LastSelectedPath := ""
  LastSelectedName := ""
  AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
}

; Populate SelectedFolderPaths when a single selection exists.
SetSelectedFolderChainIfSingle() {
  global SelectedFolderPaths, SelectedCount, SelectedFilePath
  SelectedFolderPaths := ""
  if (SelectedCount = 1 && SelectedFilePath != "") {
    folders := GetFolderChain(SelectedFilePath)
    SelectedFolderPaths := JoinWithNewlines(folders)
  }
}

; Update chapter metadata depending on context.
UpdateChaptersMetadata(isExplorer := false) {
  global SelectedCount, SelectedFilePath, SelectedFileName, SelectedChaptersJson
  if (SelectedCount = 1 && SelectedFilePath != "" && SelectedFileName != "") {
    if isExplorer {
      SplitPath(SelectedFilePath, &fName, , , &dir)
      SelectedChaptersJson := GetChaptersForSelected(dir, fName)
    } else {
      SelectedChaptersJson := GetChaptersForSelected(SelectedFilePath, SelectedFileName)
    }
  } else {
    SelectedChaptersJson := ""
  }
}

;  MARK: Essential

;  MARK: Query related

; Add "!folder:" to the Everything search box (Edit1) to exclude folders from results
ExcludeFolders() {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  if InStr(curr, "!folder:") {
    newText := StrReplace(curr, "!folder:")
  } else {
    newText := (Trim(curr) = "") ? "!folder:" : AppendToken(curr, "!folder:")
  }
  SetEverythingQuery(newText)
}

; Toggle exclusion of a specific folder path in the Everything search box
ToggleExcludeFolder(folderPath) {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  ; Normalize path for exclusion syntax (remove trailing backslash)
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  excl := '!"' . folder . '"'
  if InStr(curr, excl) {
    ; Remove exclusion
    newText := StrReplace(curr, excl)
  } else {
    newText := (Trim(curr) = "") ? excl : AppendToken(curr, excl)
  }
  SetEverythingQuery(newText)
}

; Restrict search to only a specific folder by appending |folder:"path" to the Everything search box
SetSearchOnlyFolder(folderPath) {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  ; Normalize path for Everything folder search syntax (remove trailing backslash)
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  only := ' "' . folder . '"'
  if InStr(curr, only) {
    ; Already present, do nothing
    return
  }
  currTrim := Trim(curr)
  if (currTrim = "") {
    newText := only
  } else {
    newText := curr . only
  }
  SetEverythingQuery(newText)
}

; Remove the |folder:"path" filter for the given folder from the Everything search box
ClearSearchOnlyFolder(folderPath) {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  only := ' |folder:"' . folder . '"'
  newText := StrReplace(curr, only)
  SetEverythingQuery(newText)
}

CleanQuery() {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  if (curr = "") {
    return
  }
  ; Remove ampersands, commas, and square brackets then normalize whitespace
  cleaned := RegExReplace(curr, "[&,\[\]]", "")
  ; Collapse multiple spaces/tabs/newlines into a single space
  cleaned := RegExReplace(cleaned, "\s+", " ")
  cleaned := Trim(cleaned)
  if (cleaned != curr) {
    SetEverythingQuery(cleaned)
  }
}

CheckEverythingActive() {
  global AssistantGui
  global SelectedFilePath, SelectedFileName, LastSelectedPath, LastSelectedName
  global SelectedNames, SelectedCount, SelectedFolderPaths, SelectedChaptersJson
  global EverythingWindowTitle, AssistantWindowTitle

  if WinActive(EverythingWindowTitle) OR WinActive(AssistantWindowTitle) OR WinActive("DevTools") {
    try {
      status := StatusBarGetText(, EverythingWindowTitle)
    } catch {
      return
    }
    fileSelected := RegExMatch(status, "   \|   Path: (.+)", &Path)
    try names := ListViewGetContent("Selected Col1", "SysListView321", EverythingWindowTitle)
    catch {
      return
    }
    currCount := (names && names != "") ? StrSplit(names, "`n").Length : 0

    if (fileSelected || currCount > 0) {
      currPath := fileSelected ? Path[1] : ""
      currName := names
      if (currPath != LastSelectedPath || currName != LastSelectedName) {
        SelectedFilePath := currPath
        SelectedFileName := currName
        SelectedNames := names
        SelectedCount := currCount

        ; Update folder chain only for single-selection with a valid path
        SelectedFolderPaths := ""
        if ((SelectedCount = 1) && (SelectedFilePath != "")) {
          folders := GetFolderChain(SelectedFilePath)
          SelectedFolderPaths := JoinWithNewlines(folders)
        }

        LastSelectedPath := currPath
        LastSelectedName := currName

        ; Update chapter metadata (only for single selection w/ video file)
        if (SelectedCount = 1 && SelectedFilePath != "" && SelectedFileName != "") {
          ; In Everything context SelectedFilePath is folder path
          SelectedChaptersJson := GetChaptersForSelected(SelectedFilePath, SelectedFileName)
        } else {
          SelectedChaptersJson := ""
        }

        ; Notify webview to update its UI from ahk.global variables
        AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
      }
    } else if (LastSelectedPath != "" || LastSelectedName != "") {
      ResetSelection()
    }

    AssistantGui.Show("w600 h600 NoActivate")
  } else if WinActive("ahk_class CabinetWClass") { ; Windows Explorer
    selectedPaths := Explorer_GetSelected()

    if (selectedPaths != LastSelectedPath) {
      currCount := (selectedPaths != "") ? StrSplit(selectedPaths, "`n").Length : 0
      currPath := ""
      currName := ""
      names := ""

      if (currCount = 1) {
        currPath := selectedPaths
        SplitPath(currPath, &currName)
        names := currName
      } else if (currCount > 1) {
        pathsList := StrSplit(selectedPaths, "`n")
        namesList := []
        for path in pathsList {
          SplitPath(path, &name)
          namesList.Push(name)
        }
        names := JoinWithNewlines(namesList)
      }

      SelectedFilePath := currPath
      SelectedFileName := currName
      SelectedNames := names
      SelectedCount := currCount

      SetSelectedFolderChainIfSingle()

      LastSelectedPath := selectedPaths
      LastSelectedName := "" ; Reset this to ensure change detection works across apps

      ; Update chapter metadata (only for single selection w/ video file)
      UpdateChaptersMetadata(true)

      AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
    }

    AssistantGui.Show("w600 h600 NoActivate")
  } else {
    if (LastSelectedPath != "" || LastSelectedName != "")
      ResetSelection()
    AssistantGui.Hide()
  }
}

GetSingleSelectedFilePath() {
  FileName := ListViewGetContent("Selected Col1", "SysListView321", EverythingWindowTitle)
  status := StatusBarGetText(, EverythingWindowTitle)
  fileSelected := RegExMatch(status, "   \|   Path: (.+)", &Path)
  currPath := fileSelected ? Path[1] "\" FileName : ""
  return currPath
}

GetMultipleSelectedFilePaths() {
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

; Open PowerShell (pwsh) in the given folder as working directory
OpenPwsh(folderPath, selectedFileName) {
  try {
    if (folderPath = "")
      return
    ; Ensure path exists
    if !FileExist(folderPath) {
      MsgBox "Folder not found: " . folderPath
      return
    }
    ; Prefer pwsh (PowerShell Core), fallback to Windows PowerShell
    pwshPath := "pwsh.exe"
    powershellPath := "powershell.exe"
    ; Use UseErrorLevel so we can detect failures
    ; Quote the path properly and set working directory
    ; Run <exe> -NoExit -Command Set-Location -LiteralPath '<folder>'
    cmd := pwshPath " -NoExit -Command Set-Location -LiteralPath " "'" folderPath "'"
    Run cmd, folderPath, , &OutPid
    WinWait "ahk_pid " OutPid
    WinActivate
    A_Clipboard := '"' selectedFileName '"'
    Send("^v{Home}")
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

; Open a folder in Explorer
OpenFolder(folderPath) {
  try {
    if (folderPath = "")
      return
    if !FileExist(folderPath) {
      MsgBox "Folder not found: " . folderPath
      return
    }
    cmd := "explorer.exe " . Chr(34) . folderPath . Chr(34)
    Run(cmd)
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

; Open parent folder and select the provided folder (or file)
OpenExplorerSelect(pathToSelect) {
  try {
    if (pathToSelect = "")
      return
    if !FileExist(pathToSelect) {
      MsgBox "Path not found: " . pathToSelect
      return
    }
    ; Use explorer /select,"path"
    cmd := "explorer.exe /select," . Chr(34) . pathToSelect . Chr(34)
    Run(cmd)
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
    ; Optional: launch external tagger (kept from existing implementation)
    ; Run with the selected list passed along; if you only want MsgBox, comment the next line.
    Run FileTaggerPath "node_modules\electron\dist\electron.exe " FileTaggerPath " --files-list " '"' s '"',
      FileTaggerPath
  } catch as e {
    try MsgBox "(error) " . e.Message
  }
}

; Delete currently selected files in Everything by simulating Delete key.
; Safety: ensures Everything window is active before sending Delete.
DeleteSelected() {
  global EverythingWindowTitle, SelectedCount
  if !WinExist(EverythingWindowTitle) {
    MsgBox "Everything window not found."
    return
  }
  WinActivate EverythingWindowTitle
  WinWaitActive EverythingWindowTitle, , 1
  if !WinActive(EverythingWindowTitle) {
    MsgBox "Couldn't activate Everything."
    return
  }
  ; Optional: Confirm if nothing selected
  status := StatusBarGetText(, EverythingWindowTitle)
  fileSelected := RegExMatch(status, "   \|   Path: (.+)", &Path)
  if (!fileSelected && SelectedCount <= 0) {
    MsgBox "No items selected to delete."
    return
  }
  ; Send Delete to Everything; Everything will handle multi-select deletion
  Send "{Delete}"
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

; =========================
; Chapter (.ffmetadata) support
; =========================

IsVideoFile(ext) {
  extLower := StrLower(ext)
  for , v in ["mp4", "mkv", "mov", "avi", "webm", "m4v"] {
    if (extLower = v)
      return true
  }
  return false
}

; Convert image file to base64 data URL (COM-based, avoids Crypt32 quirks)
FileToBase64(filePath) {
  try {
    if (!filePath || !FileExist(filePath))
      return ""
    ; Use ADODB.Stream to read binary
    stream := ComObject("ADODB.Stream")
    stream.Type := 1  ; binary
    stream.Open()
    stream.LoadFromFile(filePath)
    ; Read bytes into a safe variant then encode via XML DOM Base64
    bytes := stream.Read()
    stream.Close()
    xml := ComObject("MSXML2.DOMDocument.6.0")
    node := xml.createElement("b64")
    node.dataType := "bin.base64"
    node.nodeTypedValue := bytes
    base64 := RegExReplace(node.text, "[\r\n]")
    SplitPath(filePath, , , &ext)
    mime := "image/jpeg"
    if ext {
      e := StrLower(ext)
      if (e = "png")
        mime := "image/png"
      else if (e = "gif")
        mime := "image/gif"
      else if (e = "webp")
        mime := "image/webp"
      else if (e = "bmp")
        mime := "image/bmp"
      else if (e = "svg")
        mime := "image/svg+xml"
    }
    return base64 ? ("data:" mime ";base64," base64) : ""
  } catch as err {
    OutputDebug "[EverythingAssistant] FileToBase64 COM error: " err.Message
    return ""
  }
}

GetChaptersForSelected(folderPath, fileName) {
  try {
    if (folderPath = "" || fileName = "")
      return ""
    SplitPath(fileName, , , &ext, &nameNoExt)
    if !IsVideoFile(ext)
      return ""
    metaFile := folderPath "\" nameNoExt "." ext ".ffmetadata"
    if !FileExist(metaFile)
      return ""
    return ParseFFMetadata(metaFile)
  } catch {
    return ""
  }
}

JsonEscape(str) {
  if (str = "")
    return ""
  ; Escape backslash and quotes, and control chars
  str := StrReplace(str, "\", "\\")
  str := StrReplace(str, '"', '\"')
  str := StrReplace(str, "`r", "")
  str := StrReplace(str, "`n", "\\n")
  str := StrReplace(str, "`t", "\\t")
  return str
}

FormatTimecode(seconds) {
  if (seconds = "" || seconds < 0)
    return "00:00:00.000"
  totalMs := Round(seconds * 1000)
  ms := Mod(totalMs, 1000)
  totalSec := (totalMs - ms) / 1000
  s := Mod(totalSec, 60)
  totalMin := (totalSec - s) / 60
  m := Mod(totalMin, 60)
  h := (totalMin - m) / 60
  return Format("{:02}:{:02}:{:02}.{:03}", h, m, s, ms)
}

ParseFFMetadata(filePath) {
  chapters := []
  current := Map()
  try {
    for line in StrSplit(FileRead(filePath, "UTF-8"), "`n") {
      line := Trim(line)
      if (line = "" || SubStr(line, 1, 1) = ";")
        continue
      if (line = "[CHAPTER]") {
        if (current.Count) {
          chapters.Push(current)
          current := Map()
        }
        continue
      }
      if RegExMatch(line, "^([^=]+)=(.*)$", &m) {
        key := StrLower(Trim(m[1]))
        val := Trim(m[2])
        current[key] := val
      }
    }
    if (current.Count)
      chapters.Push(current)
  } catch {
    return ""
  }
  if (chapters.Length = 0)
    return ""
  ; Build JSON
  json := "["
  for idx, ch in chapters {
    startRaw := ch.Has("start") ? ch["start"] : "0"
    endRaw := ch.Has("end") ? ch["end"] : "0"
    startNum := startRaw + 0
    endNum := endRaw + 0
    ; Assume nanoseconds -> seconds
    startSec := startNum / 1000000000
    endSec := endNum / 1000000000

    ; Convert thumbnail file path to base64 data URL
    thumbnailBase64 := ""
    if (ch.Has("thumbnail") && ch["thumbnail"] != "") {
      thumbnailPath := ch["thumbnail"]
      if (!InStr(thumbnailPath, ":") && !SubStr(thumbnailPath, 1, 1) = "\") {
        SplitPath(filePath, , &metaDir)
        thumbnailPath := metaDir "\" thumbnailPath
      }
      thumbnailBase64 := FileToBase64(thumbnailPath)
      if (thumbnailBase64 = "")
        OutputDebug "[EverythingAssistant] Thumbnail conversion failed: " thumbnailPath
    }

    obj := '{' .
      '"start":"' JsonEscape(startRaw) '",' .
      '"end":"' JsonEscape(endRaw) '",' .
      '"startSeconds":' startSec ',' .
      '"endSeconds":' endSec ',' .
      '"startTimecode":"' JsonEscape(FormatTimecode(startSec)) '",' .
      '"endTimecode":"' JsonEscape(FormatTimecode(endSec)) '",' .
      '"title":"' JsonEscape(ch.Has("title") ? ch["title"] : "") '",' .
      '"thumbnail":"' JsonEscape(thumbnailBase64) '"' .
      '}'
    json .= obj . (idx < chapters.Length ? "," : "")
  }
  json .= "]"
  ; A_Clipboard := json
  return json
}
