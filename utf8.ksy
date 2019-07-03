meta:
  id: utf8
  title: UTF-8
  license: WTFPL

doc: |
  Data type for a single UTF-8 character, essentially a kind of variable-length
  integer encoding.
  
  This seems like a reasonably common thing to want but for some reason I
  couldn't seem to find it so I feel like an idiot for even implementing this.
  I'm sure I'll be deleting it in a few days when someone tells me how to do
  it more simply.
  
  There are many descriptions and references at Wikipedia:
  https://en.wikipedia.org/wiki/UTF-8

seq:
  - id: head
    type: u1
  - id: tail
    type: u1
    repeat: expr
    repeat-expr: length - 1

instances:
  length:
    value: |
      (head & 0xD0) != 0 ? 4 :
      (head & 0xC0) != 0 ? 3 :
      (head & 0x80) != 0 ? 2 :
                           1
  value:
    value: |
      (head & 0xD0) != 0 ? (head & 0x3F) << 18 + (tail[0] & 0x3F) << 12 + (tail[1] & 0x3F) << 6 + (tail[0] & 0x3F) :
      (head & 0xC0) != 0 ? (head & 0x3F) << 12 + (tail[0] & 0x3F) <<  6 + (tail[1] & 0x3F) :
      (head & 0x80) != 0 ? (head & 0x3F) <<  6 + (tail[0] & 0x3F) :
                           (head & 0x3F)
    doc: Resulting value as Unicode code point
