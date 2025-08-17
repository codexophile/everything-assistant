#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ..\#lib\WebViewToo\WebViewToo.ahk
; Local modules
#Include ./src/ahk/WindowHelpers.ahk
#Include ./src/ahk/QueryActions.ahk
#Include ./src/ahk/Chapters.ahk
#Include ./src/ahk/FileActions.ahk

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
SelectedFileDuration := ""  ; Duration in seconds or formatted string

; GUI setup
AssistantGui := WebViewGui("Resize AlwaysOnTop")
AssistantGui.Title := AssistantWindowTitle
AssistantGui.Navigate "index.html"
AssistantGui.Debug()

; Poll Everything/Assistant focus & selection
SetTimer(CheckEverythingActive, 100)

; Query manipulation functions moved to lib/QueryActions.ahk

CheckEverythingActive() {
  global AssistantGui
  global SelectedFilePath, SelectedFileName, LastSelectedPath, LastSelectedName
  global SelectedNames, SelectedCount, SelectedFolderPaths, SelectedChaptersJson, SelectedFileDuration
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

        ; Update chapter metadata (Everything context) - helper will handle conditions
        UpdateChaptersMetadata(false)

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
      SelectedChaptersJson := ""
      SelectedFileDuration := ""
      LastSelectedPath := ""
      LastSelectedName := ""
      AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
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

      ; Update chapter metadata (Explorer context)
      UpdateChaptersMetadata(true)
      AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
    }

    AssistantGui.Show("w600 h600 NoActivate")
  } else {
    if (LastSelectedPath != "" || LastSelectedName != "") {
      ; Clear selection state and notify
      SelectedFilePath := ""
      SelectedFileName := ""
      SelectedNames := ""
      SelectedCount := 0
      SelectedFolderPaths := ""
      LastSelectedPath := ""
      LastSelectedName := ""
      SelectedChaptersJson := ""
      SelectedFileDuration := ""
      AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
    }
    AssistantGui.Hide()
  }
}
