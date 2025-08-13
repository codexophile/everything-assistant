#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\#lib\WebViewToo\WebViewToo.ahk

; Constants
EverythingWindowTitle := "ahk_class EVERYTHING_(1.5a)"
AssistantWindowTitle := "Everything Assistant"
MainWidth := 300
FileTaggerPath := "c:\mega\IDEs\Electron\file-tagger\"
AvidemuxPath := "C:\Program Files\Avidemux\avidemux.exe"

; Globals exposed to the WebView for current selection
SelectedFilePath := ""
SelectedFileName := ""
LastSelectedPath := ""
LastSelectedName := ""
SelectedNames := ""        ; newline-delimited names from Everything list view
SelectedCount := 0
SelectedFolderPaths := ""   ; folder chain (parent -> root) for current single selection

; GUI setup
AssistantGui := WebViewGui("Resize AlwaysOnTop")
AssistantGui.Title := AssistantWindowTitle
AssistantGui.Navigate "index.html"
; AssistantGui.Debug()

; Poll Everything/Assistant focus & selection
SetTimer(CheckEverythingActive, 100)

CheckEverythingActive() {
  global AssistantGui
  global SelectedFilePath, SelectedFileName, LastSelectedPath, LastSelectedName
  global SelectedNames, SelectedCount, SelectedFolderPaths
  global EverythingWindowTitle, AssistantWindowTitle

  if WinActive(EverythingWindowTitle) OR WinActive(AssistantWindowTitle) OR WinActive("DevTools") {
    status := StatusBarGetText(, EverythingWindowTitle)
    fileSelected := RegExMatch(status, "   \|   Path: (.+)", &Path)
    names := ListViewGetContent("Selected Col1", "SysListView321", EverythingWindowTitle)
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
        ; Notify webview to update its UI from ahk.global variables
        AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
      }
    } else if (LastSelectedPath != "" || LastSelectedName != "") {
      ; Clear selection state and notify
      SelectedFilePath := ""
      SelectedFileName := ""
      SelectedNames := ""
      SelectedCount := 0
      SelectedFolderPaths := ""
      LastSelectedPath := ""
      LastSelectedName := ""
      AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
    }

    AssistantGui.Show("w600 h600 NoActivate")
  } else {
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

JoinWithNewlines(arr) {
  out := ""
  for _, v in arr
    out .= (out = "" ? "" : "`n") . v
  return out
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

; Add "!folder:" to the Everything search box (Edit1) to exclude folders from results
ExcludeFolders() {
  global EverythingWindowTitle
  if !WinExist(EverythingWindowTitle) {
    MsgBox "Everything window not found."
    return
  }
  curr := ControlGetText("Edit1", EverythingWindowTitle)
  if InStr(curr, "!folder:") {
    ; Remove '!folder:' if present
    newText := StrReplace(curr, "!folder:")
  } else {
    currTrim := Trim(curr)
    if (currTrim = "") {
      newText := "!folder:"
    } else {
      ; ensure a space before appending if needed
      newText := RegExMatch(curr, "\s$") ? curr . "!folder:" : curr . " !folder:"
    }
  }
  ControlSetText(newText, "Edit1", EverythingWindowTitle)
}

; Toggle exclusion of a specific folder path in the Everything search box
ToggleExcludeFolder(folderPath) {
  global EverythingWindowTitle
  if !WinExist(EverythingWindowTitle) {
    MsgBox "Everything window not found."
    return
  }
  curr := ControlGetText("Edit1", EverythingWindowTitle)
  ; Normalize path for exclusion syntax (remove trailing backslash)
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  excl := '!"' . folder . '"'
  if InStr(curr, excl) {
    ; Remove exclusion
    newText := StrReplace(curr, excl)
  } else {
    currTrim := Trim(curr)
    if (currTrim = "") {
      newText := excl
    } else {
      newText := RegExMatch(curr, "\s$") ? curr . excl : curr . " " . excl
    }
  }
  ControlSetText(newText, "Edit1", EverythingWindowTitle)
}

; Restrict search to only a specific folder by appending |folder:"path" to the Everything search box
SetSearchOnlyFolder(folderPath) {
  global EverythingWindowTitle
  if !WinExist(EverythingWindowTitle) {
    MsgBox "Everything window not found."
    return
  }
  curr := ControlGetText("Edit1", EverythingWindowTitle)
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
  ControlSetText(newText, "Edit1", EverythingWindowTitle)
}

; Remove the |folder:"path" filter for the given folder from the Everything search box
ClearSearchOnlyFolder(folderPath) {
  global EverythingWindowTitle
  if !WinExist(EverythingWindowTitle) {
    MsgBox "Everything window not found."
    return
  }
  curr := ControlGetText("Edit1", EverythingWindowTitle)
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  only := ' |folder:"' . folder . '"'
  newText := StrReplace(curr, only)
  ControlSetText(newText, "Edit1", EverythingWindowTitle)
}
