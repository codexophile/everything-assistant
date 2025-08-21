#Requires AutoHotkey v2.0
#SingleInstance Force
; Include necessary libraries
#Include ..\#lib\WebViewToo\WebViewToo.ahk
#Include ..\#lib\Functions.ahk
; Local modules
#Include ./src/ahk/WindowHelpers.ahk
#Include ./src/ahk/QueryActions.ahk
#Include ./src/ahk/Chapters.ahk
#Include ./src/ahk/FileActions.ahk
#Include ./src/ahk/ConfigManager.ahk

; Ensure working directory is script folder so relative paths (config.ini) resolve
SetWorkingDir(A_ScriptDir)

; Constants
EverythingWindowTitle := "ahk_class EVERYTHING_(1.5a)"
AssistantWindowTitle := "Everything Assistant"
MainWidth := 300
FileTaggerPath := "c:\mega\IDEs\Electron\file-tagger\"
ElectronSubPath := "node_modules\electron\dist\electron.exe"
AvidemuxPath := "C:\Program Files\Avidemux\avidemux.exe"
FfprobePath := "ffprobe"  ; Path to ffprobe.exe
; Tracks which file browser (Everything / Explorer) was last active so that
; when the Assistant window itself is focused we still reflect the correct context
LastFileContext := "everything"  ; default

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
VideoDurationCache := Map()  ; key: fullPath, value: {duration:"HH:MM:SS", mtime: <int>, size: <int>}

; GUI setup
AssistantGui := WebViewGui("Resize")
AssistantGui.Title := AssistantWindowTitle
AssistantGui.Navigate "index.html"

Config := ReadFullConfig()
OpenDevTools := Config['General']['OpenDevToolsAtStartup']
if (OpenDevTools == "1") {
  AssistantGui.Debug()
}

; Poll Everything/Assistant focus & selection
SetTimer(CheckEverythingActive, 100)

; Query manipulation functions moved to lib/QueryActions.ahk

CheckEverythingActive() {
  global AssistantGui
  global SelectedFilePath, SelectedFileName, LastSelectedPath, LastSelectedName
  global SelectedNames, SelectedCount, SelectedFolderPaths, SelectedChaptersJson, SelectedFileDuration
  global EverythingWindowTitle, AssistantWindowTitle, LastFileContext
  ; Do NOT reset LastFileContext each tick; we need it when Assistant is focused.

  ; Track which underlying window (Everything or Explorer) was last active
  if WinActive(EverythingWindowTitle) {
    LastFileContext := "everything"
  } else if WinActive("ahk_class CabinetWClass") {
    LastFileContext := "explorer"
  }

  usingEverything := false
  usingExplorer := false

  if WinActive(EverythingWindowTitle) {
    usingEverything := true
  } else if WinActive("ahk_class CabinetWClass") {
    usingExplorer := true
  } else if WinActive(AssistantWindowTitle) OR WinActive("DevTools") {
    ; Assistant (or its DevTools) is active – defer to last active context
    if (LastFileContext = "everything")
      usingEverything := true
    else if (LastFileContext = "explorer")
      usingExplorer := true
  }

  if (usingEverything) {
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
        LastFileContext := "everything" ; reinforce context when updating

        ; Update chapter metadata (Everything context) - helper will handle conditions
        ; Reset / set video duration and kick off async fetch if video file
        SelectedFileDuration := ""
        if (SelectedCount = 1 && SelectedFilePath != "" && SelectedFileName != "") {
          SplitPath(SelectedFileName, , , &ext)
          ext := StrLower(ext)
          ; Common video extensions
          IsAVideo := IsVideoFile(ext)
          if IsAVideo {
            fullPath := SelectedFilePath "\\" SelectedFileName
            ; Try cache first
            cached := GetCachedVideoDuration(fullPath)
            if (cached != "") {
              SelectedFileDuration := cached
            } else {
              SelectedFileDuration := "__PENDING__" ; sentinel for spinner
              selKey := SelectedFilePath "|" SelectedFileName
              SetTimer((*) => FetchAndSetVideoDuration(fullPath, selKey), -50)
            }
          }
        }

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

    AssistantGui.Show("NoActivate")
  } else if (usingExplorer) { ; Windows Explorer context (may or may not be active now)
    explorerActive := WinActive("ahk_class CabinetWClass")
    if (explorerActive) {
      ; Only attempt to read selection while Explorer is active; otherwise keep cached values.
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
          ; When multiple files are selected in Explorer, previously we left
          ; SelectedFilePath blank causing downstream actions (expecting a
          ; primary file) to think nothing was selected. Use the first item
          ; as the primary selection while still exposing all names via
          ; SelectedNames.
          pathsList := StrSplit(selectedPaths, "`n")
          primaryPath := pathsList[1]
          currPath := primaryPath
          SplitPath(primaryPath, &currName)
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
        LastFileContext := "explorer" ; reinforce context when updating

        ; Video duration handling (Explorer context) analogous to Everything branch
        SelectedFileDuration := ""
        if (SelectedCount = 1 && SelectedFilePath != "") {
          ; In Explorer, SelectedFilePath is the full path
          fullPath := SelectedFilePath
          SplitPath(fullPath, , , &ext)
          ext := StrLower(ext)
          if IsVideoFile(ext) {
            cached := GetCachedVideoDuration(fullPath)
            if (cached != "") {
              SelectedFileDuration := cached
            } else {
              SelectedFileDuration := "__PENDING__"
              selKey := SelectedFilePath "|" SelectedFileName
              SetTimer((*) => FetchAndSetVideoDuration(fullPath, selKey), -50)
            }
          }
        }

        ; Update chapter metadata (Explorer context)
        UpdateChaptersMetadata(true)
        AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
      }
    }

    AssistantGui.Show(" NoActivate")
  } else {
    ; No recognized context window active (Everything/Explorer). If Assistant itself
    ; has focus we keep showing it with the last known selection. Otherwise we can
    ; choose to hide without clearing selection (preserving state for when Assistant
    ; is re-activated). Comment/uncomment behavior as desired.
    if WinActive(AssistantWindowTitle) OR WinActive("DevTools") {
      AssistantGui.Show("") ; Keep visible while focused
    } else {
      ; Optionally hide but keep selection data so it reappears intact
      AssistantGui.Hide()
    }
  }
}

; Async helper to compute video duration without blocking UI loop.
FetchAndSetVideoDuration(fullPath, selKey) {
  global SelectedFilePath, SelectedFileName, SelectedFileDuration, AssistantGui
  ; Ensure selection still matches initial key (avoid race if user changed selection)
  currKey := SelectedFilePath "|" SelectedFileName
  if (currKey != selKey) {
    return
  }
  dur := GetVideoDuration(fullPath, "hms", true)
  if (dur = "") {
    ; Leave empty (will hide UI). Only update if still same selection.
    if (currKey = selKey) {
      SelectedFileDuration := ""
      AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
    }
    return
  }
  if (currKey = selKey) {
    SelectedFileDuration := dur
    SetVideoDurationCache(fullPath, dur)
    AssistantGui.ExecuteScriptAsync("window.updateSelectedFromAhk && window.updateSelectedFromAhk()")
  }
}

GetCachedVideoDuration(fullPath) {
  global VideoDurationCache
  if !FileExist(fullPath)
    return ""
  mtime := FileGetTime(fullPath, "M") ; modification time
  size := FileGetSize(fullPath)
  if (VideoDurationCache.Has(fullPath)) {
    entry := VideoDurationCache[fullPath]
    if (entry.mtime = mtime && entry.size = size) {
      return entry.duration
    }
  }
  return ""
}

SetVideoDurationCache(fullPath, duration) {
  global VideoDurationCache
  if (duration = "")
    return
  if !FileExist(fullPath)
    return
  mtime := FileGetTime(fullPath, "M")
  size := FileGetSize(fullPath)
  ; Simple capacity guard (optional): limit to 500 entries
  if (VideoDurationCache.Count >= 500) {
    ; Remove an arbitrary (first) entry to keep memory bounded
    for k, _ in VideoDurationCache {
      VideoDurationCache.Delete(k)
      break
    }
  }
  VideoDurationCache[fullPath] := { duration: duration, mtime: mtime, size: size }
}
