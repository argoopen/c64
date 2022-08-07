.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(Entry)

#import "lib/zeropage.asm"
#import "lib/vic.asm"

#import "macros.asm"
#import "utils.asm"
#import "maploader.asm"
#import "player.asm"
#import "sound.asm"

Start:

Entry:
    lda #$00
    sta VIC.BACKGROUND_COLOR
    sta VIC.BORDER_COLOR

    lda #%00011110
    sta VIC.MEMORY_SETUP

    lda #0

    jsr UTILS.ClearScreen
    jsr MAPLOADER.DrawMap

    jsr PLAYER.Init

Loop:
    RasterWait(255)

    jsr PLAYER.CheckJoystick
    jsr PLAYER.Render

    jsr PLAYER.CheckCollisions
    jsr PLAYER.JumpAndFall

    jmp Loop

#import "assets.asm"
