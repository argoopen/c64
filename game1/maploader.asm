MAPLOADER: {
    .var TileCountX = 20
    .var TileCountY = 12
    .var TileWidth =  2
    .var TileHeight = 2

    .label tmp1 = $77
    .label tmp2 = $bb

    TileScreenLocations: .byte 0, 1, 40, 41
    XPos:                .byte 0
    YPos:                .byte 0
    CurrentTileValue:    .byte 0
    CurrentMapIndex:     .byte 0
  
    DrawMap: {
        lda #0
        sta YPos

        sta CurrentMapIndex

        lda #<SCREEN_RAM
        sta tmp1
        lda #>SCREEN_RAM
        sta tmp1+1
        
        lda #<COLOUR_RAM
        sta tmp2
        lda #>COLOUR_RAM
        sta tmp2+1
        
      DrawRow:
        lda #0
        sta XPos
      DrawTile:
      !:
        ldx CurrentMapIndex
        lda MAP_1, x
        sta CurrentTileValue

        asl CurrentTileValue
        asl CurrentTileValue

        ldx CurrentTileValue

        // Draw the four characters of this tile
        lda MAP_TILES, x
        ldy #0
        sta (tmp1), y
        tay
        lda CHAR_COLORS, y
        ldy #0
        sta (tmp2), y
        inx

        lda MAP_TILES, x
        ldy #1
        sta (tmp1), y
        tay
        lda CHAR_COLORS, y
        ldy #1
        sta (tmp2), y
        inx

        lda MAP_TILES, x
        ldy #40
        sta (tmp1), y
        tay
        lda CHAR_COLORS, y
        ldy #40
        sta (tmp2), y
        inx

        lda MAP_TILES, x
        ldy #41
        sta (tmp1), y
        tay
        lda CHAR_COLORS, y
        ldy #41
        sta (tmp2), y

        // Add 2 to screen mem pointer
        clc
        lda tmp1
        adc #2
        sta tmp1
        lda tmp1+1
        adc #0
        sta tmp1+1

        // Add 2 to colour mem pointer
        clc
        lda tmp2
        adc #2
        sta tmp2
        lda tmp2+1
        adc #0
        sta tmp2+1

        inc CurrentMapIndex
        lda XPos
        cmp #TileCountX-1
        beq !+

        inc XPos
        jmp DrawTile

!:
        // Add 40 to screen mem pointer
        clc
        lda tmp1
        adc #40
        sta tmp1
        lda tmp1+1
        adc #0
        sta tmp1+1

        // Add 40 to colour mem pointer
        clc
        lda tmp2
        adc #40
        sta tmp2
        lda tmp2+1
        adc #0
        sta tmp2+1

        inc YPos
        lda YPos
        cmp #TileCountY
        beq !++

!:
lda #$ff
cmp $d012
bne !-
// .break
        jmp DrawRow

      !:
        rts

    }
}
