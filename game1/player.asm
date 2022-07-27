PLAYER: {
    .var DIR_LEFT = 0
    .var DIR_RIGHT = 1

    .label tmp1 = $77
    .label tmp2 = $bb

    .var JOY2 = $dc00
    .var JOY_UP =    %00000001
    .var JOY_DOWN =  %00000010
    .var JOY_LEFT =  %00000100
    .var JOY_RIGHT = %00001000
    .var JOY_FIRE =  %00010000

    XPos:                .byte $28
    YPos:                .byte $8e
    YPosIncJump:         .byte $8e
    Direction:           .byte DIR_RIGHT
    CurrentFrame:        .byte 0
    CurrentSprite:       .byte 0

    .var JumpFrameCount = 20
    JumpPattern:         .fill 20,round(32*sin(toRadians(i*360/40)))
    JumpFrame:           .byte 0

    ScreenRowLSB:        .fill 25, <[$0400 + i * 40]
    ScreenRowMSB:        .fill 25, >[$0400 + i * 40]

    ScreenLocation:      .word $0000
    ColourLocation:      .word $0000
  
    Init: {
        lda #$80
        sta $07f8

        lda #$01
        sta $d015
        sta $d01c

        lda #7
        sta $d025

        lda #9
        sta $d026

        lda #5
        sta $d027

        rts
    }

    Render: {
        lda XPos
        asl
        sta $d000
        bcc !+
        lda VIC.SPRITE_MSB
        ora #%00000001
        jmp !++

    !:  lda VIC.SPRITE_MSB
        and #%11111110

    !:  sta VIC.SPRITE_MSB

        lda YPos

        ldx JumpFrame
        cpx #0
        beq !++

        sec
        sbc JumpPattern, x
      
        pha

        inc JumpFrame
        lda JumpFrame
        cmp #JumpFrameCount
        bne !+

        lda #0
        sta JumpFrame

     !: pla

     !: sta $d001

        lda CurrentFrame
        sta CurrentSprite
        lsr CurrentSprite
        lsr CurrentSprite

        lda #$80 
 
        ldx Direction
        cpx #DIR_RIGHT
        beq !+

        lda #$88

     !: clc
        adc CurrentSprite
        sta $07f8

        jsr UpdateScreenLocation

        rts
    }

    UpdateScreenLocation: {
lda #4
sta $0400
        lda #<SCREEN_RAM
        sta ScreenLocation
        lda #>SCREEN_RAM
        sta ScreenLocation+1

        lda XPos
        lsr
        lsr
        clc
        adc ScreenLocation
        sta ScreenLocation
        lda ScreenLocation+1
        adc #0
        sta ScreenLocation+1
 
        lda ScreenLocation
        sta tmp1
        lda ScreenLocation+1
        sta tmp1+1

        ldy #0

.break
        sta (tmp1), x

        lda #<COLOUR_RAM
        sta ColourLocation
        lda #>COLOUR_RAM
        sta ColourLocation+1

        lda XPos
        lsr
        lsr
        clc
        adc ColourLocation
        sta ColourLocation
        lda ColourLocation+1
        adc #0
        sta ColourLocation+1
 
        lda ColourLocation
        sta tmp2
        lda ColourLocation+1
        sta tmp2+1

        lda #06
        ldy #00
        sta (tmp2), y

        rts
    }

    CheckJoystick: {
        check_joystick_right:
          lda JOY2
          and #JOY_RIGHT
          bne check_joystick_left
          lda #DIR_RIGHT
          sta Direction
          inc XPos
          inc CurrentFrame
          lda CurrentFrame
          cmp #$20
          bne check_joystick_fire
          lda #$00
          sta CurrentFrame
          jmp check_joystick_fire

        check_joystick_left:
          lda JOY2
          and #JOY_LEFT
          bne check_joystick_fire
          lda #DIR_LEFT
          sta Direction
          dec XPos
          inc CurrentFrame
          lda CurrentFrame
          cmp #$20
          bne check_joystick_fire
          lda #$00
          sta CurrentFrame

        check_joystick_up:
          lda JOY2
          and #JOY_UP
          bne check_joystick_down
          dec YPos

        check_joystick_down:
          lda JOY2
          and #JOY_DOWN
          bne check_joystick_fire
          inc YPos

        check_joystick_fire:
          lda JOY2
          and #JOY_FIRE
          bne !+

.break
          
          lda JumpFrame
          bne !+

          lda #1
          sta JumpFrame
 
        !:
        rts
    }
  
}
