; Chapters.ahk - video chapter & ffmetadata utilities
#Requires AutoHotkey v2.0

IsVideoFile(ext) {
  extLower := StrLower(ext)
  for , v in ["mp4", "mkv", "mov", "avi", "webm", "m4v"] {
    if (extLower = v)
      return true
  }
  return false
}

FileToBase64(filePath) {
  try {
    if (!filePath || !FileExist(filePath))
      return ""
    stream := ComObject("ADODB.Stream")
    stream.Type := 1
    stream.Open()
    stream.LoadFromFile(filePath)
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
  str := StrReplace(str, "\\", "\\\\")
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
  json := "["
  for idx, ch in chapters {
    startRaw := ch.Has("start") ? ch["start"] : "0"
    endRaw := ch.Has("end") ? ch["end"] : "0"
    startNum := startRaw + 0
    endNum := endRaw + 0
    startSec := startNum / 1000000000
    endSec := endNum / 1000000000
    thumbnailBase64 := ""
    if (ch.Has("thumbnail") && ch["thumbnail"] != "") {
      thumbnailPath := ch["thumbnail"]
      if (!InStr(thumbnailPath, ":") && !SubStr(thumbnailPath, 1, 1) = "\\") {
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
  return json
}
