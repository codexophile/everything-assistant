#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\#lib\WebViewToo\WebViewToo.ahk

EverythingWindowTitle := "ahk_class EVERYTHING_(1.5a)"
AssistantWindowTitle := "Everything Assistant"
MainWidth := 300

; Globals exposed to the WebView for current selection
SelectedFilePath := ""
SelectedFileName := ""
LastSelectedPath := ""
LastSelectedName := ""
; Multi-select support
SelectedNames := "" ; Newline-delimited names from Everything list view
SelectedCount := 0
; Folder chain (parent -> root) for the current single selection
SelectedFolderPaths := ""

AssistantGui := WebViewGui("Resize AlwaysOnTop")
AssistantGui.Title := AssistantWindowTitle
AssistantGui.Navigate "index.html"

SetTimer(CheckEverythingActive, 100)

CheckEverythingActive() {
  global AssistantGui, SelectedFilePath, SelectedFileName, LastSelectedPath, LastSelectedName
  global SelectedNames, SelectedCount, SelectedFolderPaths

  if WinActive(EverythingWindowTitle) OR WinActive(AssistantWindowTitle) {

    StatusText := StatusBarGetText(, EverythingWindowTitle)
    FileSelected := RegExMatch(StatusText, "   \|   Path: (.+)", &Path)
    ; Get all selected item names (column 1), newline-delimited if multiple
    SelectedName := ListViewGetContent("Selected Col1", "SysListView321", "ahk_class EVERYTHING_(1.5a)")
    currCount := (SelectedName && SelectedName != "") ? StrSplit(SelectedName, "`n").Length : 0

    if (FileSelected || currCount > 0) {
      currPath := FileSelected ? Path[1] : ""
      currName := SelectedName
      if (currPath != LastSelectedPath || currName != LastSelectedName) {
        SelectedFilePath := currPath
        SelectedFileName := currName
        SelectedNames := SelectedName
        SelectedCount := currCount
        ; Update folder chain only for single-selection with a valid path
        SelectedFolderPaths := ""
        if ((SelectedCount = 1) && (SelectedFilePath != "")) {
          folders := GetFoldersFullPaths(SelectedFilePath)
          chain := ""
          for _, fPath in folders {
            chain .= (chain = "" ? "" : "`n") . fPath
          }
          SelectedFolderPaths := chain
        }
        LastSelectedPath := currPath
        LastSelectedName := currName
        ; Notify webview to update its UI from ahk.global variables
        AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
      }
    } else {
      if (LastSelectedPath != "" || LastSelectedName != "") {
        SelectedFilePath := ""
        SelectedFileName := ""
        SelectedNames := ""
        SelectedCount := 0
        SelectedFolderPaths := ""
        LastSelectedPath := ""
        LastSelectedName := ""
        AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
      }
    }

    AssistantGui.Show("w300 h300 NoActivate")

  } else {
    AssistantGui.Hide()
  }
}

GetFoldersFullPaths(OriginalPath, FolderPaths := []) {
  FolderPaths.Push(OriginalPath)
  SplitPath(OriginalPath, , &ParentFolder)
  if (OriginalPath = ParentFolder || ParentFolder = "")
    return FolderPaths
  return GetFoldersFullPaths(ParentFolder, FolderPaths)
}

; Text := ControlGetText("Edit1", "ahk_class EVERYTHING_(1.5a)")
; MsgBox(Text)
; ControlSetText("Test", "Edit1", "ahk_class EVERYTHING_(1.5a)")

SubmitForm(data) {
  MsgBox data.toSend
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
  StatusText := StatusBarGetText(, EverythingWindowTitle)
  FileSelected := RegExMatch(StatusText, "   \|   Path: (.+)", &Path)
  if (!FileSelected && SelectedCount <= 0) {
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
