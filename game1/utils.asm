UTILS: {
    ClearScreen: {
        ldx #250
    !:  
        dex
        sta SCREEN_RAM, x
        sta SCREEN_RAM + 250, x
        sta SCREEN_RAM + 500, x
        sta SCREEN_RAM + 750, x
        bne !-
        rts
    }
}
