/*
    $0400 - $07ff Screen
    $3800 - $3fff 1 charset
    $2000 - $23ff 16 sprites
*/

.label SCREEN_RAM = $0400
.label COLOUR_RAM = $d800

* = $3800 "Charset"
.import binary "assets/chars.bin"

* = $2000 "Sprites"
.import binary "assets/sprites.bin"

* = $8000 "Map data"
MAP_TILES:
    .import binary "assets/tiles.bin"

CHAR_COLORS:
    .import binary "assets/char-colours.bin"

* = * "LEVEL DATA"
MAP_1:
    .import binary "assets/map1.bin"
