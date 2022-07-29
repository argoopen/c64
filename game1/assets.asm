/*
    $0400 - $07ff Screen
    $3800 - $3fff 1 charset
    $2000 - $23ff 16 sprites
*/

.label SCREEN_RAM = $0400
.label COLOUR_RAM = $d800

* = $3800 "Charset"
.import binary "assets/maps - Chars.bin"

* = $2000 "Sprites"
.import binary "assets/sprites.bin"

* = $8000 "Map data"
MAP_TILES:
    .import binary "assets/maps - Tiles.bin"

CHAR_COLORS:
    .import binary "assets/maps - CharAttribs.bin"

* = * "LEVEL DATA"
MAP_1:
    .import binary "assets/maps - Map (20x12).bin"
