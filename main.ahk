#Requires AutoHotkey v2.0
#Include ..\#lib\WebViewToo\WebViewToo.ahk

EverythingWindowTitle := "ahk_class EVERYTHING_(1.5a)"
AssistantWindowTitle := "Everything Assistant"
MainWidth := 300

AssistantGui := WebViewGui("Resize AlwaysOnTop")
AssistantGui.Title := AssistantWindowTitle
AssistantGui.Navigate "index.html"

SetTimer(CheckEverythingActive, 100)

CheckEverythingActive() {
  if WinActive(EverythingWindowTitle) OR WinActive(AssistantWindowTitle) {
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

Button1() {
  AssistantGui.ExecuteScriptAsync("alert('hi')")
  MsgBox "You clicked button 1"
}

Button2() {
  MsgBox "You clicked button 2"
}

SubmitForm(data) {
  MsgBox data.toSend
}
