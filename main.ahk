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

AssistantGui := WebViewGui("Resize AlwaysOnTop")
AssistantGui.Title := AssistantWindowTitle
AssistantGui.Navigate "index.html"

SetTimer(CheckEverythingActive, 100)

CheckEverythingActive() {
  global AssistantGui, SelectedFilePath, SelectedFileName, LastSelectedPath, LastSelectedName

  if WinActive(EverythingWindowTitle) OR WinActive(AssistantWindowTitle) {

    StatusText := StatusBarGetText(, EverythingWindowTitle)
    FileSelected := RegExMatch(StatusText, "   \|   Path: (.+)", &Path)
    SelectedName := ListViewGetContent("Selected Col1", "SysListView321", "ahk_class EVERYTHING_(1.5a)")

    if (FileSelected) {
      currPath := Path[1]
      currName := SelectedName
      if (currPath != LastSelectedPath || currName != LastSelectedName) {
        SelectedFilePath := currPath
        SelectedFileName := currName
        LastSelectedPath := currPath
        LastSelectedName := currName
        ; Notify webview to update its UI from ahk.global variables
        AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
      }
    } else {
      if (LastSelectedPath != "" || LastSelectedName != "") {
        SelectedFilePath := ""
        SelectedFileName := ""
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
