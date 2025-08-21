; WindowHelpers.ahk - Everything window & selection utility helpers
#Requires AutoHotkey v2.0

; Expects EverythingWindowTitle & AssistantGui globals defined by caller.

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

AppendToken(curr, token) {
  return RegExMatch(curr, "\s$") ? curr . token : curr . " " . token
}

ResetSelection() {
  global SelectedFilePath, SelectedFileName, SelectedNames, SelectedCount, SelectedFolderPaths
  global LastSelectedPath, LastSelectedName, SelectedChaptersJson, AssistantGui, SelectedFileDuration
  SelectedFilePath := ""
  SelectedFileName := ""
  SelectedNames := ""
  SelectedCount := 0
  SelectedFolderPaths := ""
  SelectedChaptersJson := ""
  SelectedFileDuration := ""
  LastSelectedPath := ""
  LastSelectedName := ""
  AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
}

SetSelectedFolderChainIfSingle() {
  global SelectedFolderPaths, SelectedCount, SelectedFilePath
  SelectedFolderPaths := ""
  if (SelectedCount = 1 && SelectedFilePath != "") {
    folders := GetFolderChain(SelectedFilePath)
    SelectedFolderPaths := JoinWithNewlines(folders)
  }
}

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
