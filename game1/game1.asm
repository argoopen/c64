.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(Entry)

// #import "lib/zeropage.asm"
#import "lib/vic.asm"

Start:

Entry:
    lda #$00
    sta VIC.BACKGROUND_COLOR
    sta VIC.BORDER_COLOR

    lda #$7f    //Disable CIA IRQ's to prevent crash because
    sta $dc0d
    sta $dd0d

    //Bank out BASIC and Kernal ROM
    lda $01
    and #%11111000
    ora #%00000101
    sta $01

    //Set VIC BANK 3
    lda $dd00
    and #%11111100
    sta $dd00

    //Set screen and characther memory: screen at $c000 + 000; char at $c000 + %110 * 1024 = $f000 = 61440
    lda #%00001100
    sta VIC.MEMORY_SETUP

    lda #2
    sta SCREEN_RAM
    lda #3
    sta SCREEN_RAM+1
    lda #4
    sta SCREEN_RAM+2
    lda #5
    sta SCREEN_RAM+3
    lda #6
    sta SCREEN_RAM+4
    lda #7
    sta SCREEN_RAM+5

//    lda #128
//    jsr ClearScreen

Loop:
    inc $c000

//    jsr ClearScreen

    jmp Loop

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

#import "assets.asm"
