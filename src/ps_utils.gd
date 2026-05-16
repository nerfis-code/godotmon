class_name Utils
extends RefCounted

static func to_id(text) -> String:
  if text != null:
    if typeof(text) == TYPE_DICTIONARY:
      if text.has("id"):
        text = text.id
      elif text.has("userid"):
        text = text.userid

  if typeof(text) != TYPE_STRING and typeof(text) != TYPE_INT and typeof(text) != TYPE_FLOAT:
    return ""

  var s: String = str(text).to_lower()

  var result := ""
  for i in range(s.length()):
    var c := s[i]
    var code := c.unicode_at(0)

    # keep only a-z and 0-9
    if (code >= 97 and code <= 122) or (code >= 48 and code <= 57):
      result += c

  return result