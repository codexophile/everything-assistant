; MinimalJson.ahk - Lightweight JSON parser (object + primitives only)
; Extracted from ConfigManager.ahk so it can be reused elsewhere.
; Supports: top-level value (we use object), string keys, primitive values
; (string / number / true / false / null) and nested objects of the same.
; Limitations: No arrays, no unicode surrogate pair handling, no comments.
; AutoHotkey v2 compatible. Public entry: Json_Parse(jsonText)
;
; If expansion is needed (arrays, more types), extend cautiously or
; consider pulling in a full JSON library instead.
;
#Requires AutoHotkey v2.0

Json_Parse(json) {
  idx := 1
  return Json_ParseValue(json, &idx)
}

Json_SkipWS(str, &i) {
  while (i <= StrLen(str)) {
    ch := SubStr(str, i, 1)
    if (ch != " " && ch != "`t" && ch != "`r" && ch != "`n")
      break
    i++
  }
}

Json_ParseValue(str, &i) {
  Json_SkipWS(str, &i)
  if (i > StrLen(str))
    throw Error("Unexpected end of JSON")
  ch := SubStr(str, i, 1)
  if (ch = '"')
    return Json_ParseString(str, &i)
  if (ch = '{')
    return Json_ParseObject(str, &i)
  if RegExMatch(ch, "[-0-9]")
    return Json_ParseNumber(str, &i)
  if (SubStr(str, i, 4) = "true") {
    i += 4
    return true
  }
  if (SubStr(str, i, 5) = "false") {
    i += 5
    return false
  }
  if (SubStr(str, i, 4) = "null") {
    i += 4
    return "" ; represent null as empty string
  }
  throw Error("Unexpected token at position " i)
}

Json_ParseString(str, &i) {
  if (SubStr(str, i, 1) != '"')
    throw Error("Expected '" . '"' . "' at position " i)
  i++ ; skip opening quote
  out := ""
  while (i <= StrLen(str)) {
    ch := SubStr(str, i, 1)
    if (ch = '"') {
      i++
      return out
    }
    if (ch = "\\") { ; escape
      i++
      if (i > StrLen(str))
        throw Error("Bad escape at end")
      esc := SubStr(str, i, 1)
      switch esc {
        case '"', '\\', '/':
          out .= esc
        case 'b':
          out .= Chr(8)
        case 'f':
          out .= Chr(12)
        case 'n':
          out .= "`n"
        case 'r':
          out .= "`r"
        case 't':
          out .= "`t"
        case 'u': ; read next 4 hex (no surrogate pair handling)
          hex := SubStr(str, i + 1, 4)
          if !RegExMatch(hex, "^[0-9A-Fa-f]{4}$")
            throw Error("Invalid unicode escape")
          code := "0x" hex
          out .= Chr(code)
          i += 4
        default:
          throw Error("Invalid escape character '" esc "'")
      }
    } else {
      out .= ch
    }
    i++
  }
  throw Error("Unterminated string")
}

Json_ParseNumber(str, &i) {
  start := i
  len := StrLen(str)
  if (SubStr(str, i, 1) = '-')
    i++
  while (i <= len && RegExMatch(SubStr(str, i, 1), "[0-9]"))
    i++
  if (i <= len && SubStr(str, i, 1) = '.') {
    i++
    while (i <= len && RegExMatch(SubStr(str, i, 1), "[0-9]"))
      i++
  }
  if (i <= len && (SubStr(str, i, 1) = 'e' || SubStr(str, i, 1) = 'E')) {
    i++
    if (SubStr(str, i, 1) = '+' || SubStr(str, i, 1) = '-')
      i++
    while (i <= len && RegExMatch(SubStr(str, i, 1), "[0-9]"))
      i++
  }
  numStr := SubStr(str, start, i - start)
  return numStr + 0
}

Json_ParseObject(str, &i) {
  if (SubStr(str, i, 1) != '{')
    throw Error("Expected '{' at position " i)
  i++
  obj := {}
  Json_SkipWS(str, &i)
  if (SubStr(str, i, 1) = '}') {
    i++
    return obj
  }
  loop {
    Json_SkipWS(str, &i)
    key := Json_ParseString(str, &i)
    Json_SkipWS(str, &i)
    if (SubStr(str, i, 1) != ':')
      throw Error("Expected ':' after key at position " i)
    i++
    value := Json_ParseValue(str, &i)
    obj[key] := value
    Json_SkipWS(str, &i)
    ch := SubStr(str, i, 1)
    if (ch = ',') {
      i++
      continue
    } else if (ch = '}') {
      i++
      break
    } else {
      throw Error("Expected ',' or '}' at position " i)
    }
  }
  return obj
}
