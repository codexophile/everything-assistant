; QueryActions.ahk - functions manipulating Everything search box
#Requires AutoHotkey v2.0

; Requires EnsureEverythingWindow(), GetEverythingQuery(), SetEverythingQuery(), AppendToken()

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

ToggleExcludeFolder(folderPath) {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  excl := '!"' . folder . '"'
  if InStr(curr, excl) {
    newText := StrReplace(curr, excl)
  } else {
    newText := (Trim(curr) = "") ? excl : AppendToken(curr, excl)
  }
  SetEverythingQuery(newText)
}

SetSearchOnlyFolder(folderPath) {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  only := ' "' . folder . '"'
  if InStr(curr, only)
    return
  newText := (Trim(curr) = "") ? only : curr . only
  SetEverythingQuery(newText)
}

ClearSearchOnlyFolder(folderPath) {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  folder := folderPath
  if (SubStr(folder, -1) = "\\")
    folder := SubStr(folder, 1, -1)
  only := ' |folder:"' . folder . '"'
  SetEverythingQuery(StrReplace(curr, only))
}

CleanQuery() {
  if !EnsureEverythingWindow()
    return
  curr := GetEverythingQuery()
  if (curr = "")
    return
  cleaned := RegExReplace(curr, "[&,\[\]]", "")
  cleaned := RegExReplace(cleaned, "\s+", " ")
  cleaned := Trim(cleaned)
  if (cleaned != curr)
    SetEverythingQuery(cleaned)
}
