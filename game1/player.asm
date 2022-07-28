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
//    YPos:              .byte $8e
    YPos:                .byte $4e
    YPosIncJump:         .byte $8e
    Direction:           .byte DIR_RIGHT
    CurrentFrame:        .byte 0
    CurrentSprite:       .byte 0

    JumpPattern:         .fill 20,round(40*sin(toRadians(i*360/40)))
    __JumpPattern:

    JumpFrame:           .byte 0

    ScreenRowLSB:        .fill 25, <[SCREEN_RAM + i * 40]
    ScreenRowMSB:        .fill 25, >[SCREEN_RAM + i * 40]
    .var ScreenRowOffsetX = 0
    .var ScreenRowOffsetY = 8

    ColourRowLSB:        .fill 25, <[COLOUR_RAM + i * 40]
    ColourRowMSB:        .fill 25, >[COLOUR_RAM + i * 40]

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
        cmp #[__JumpPattern - JumpPattern - 1]
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

        rts
    }

    CurrentCollisions:    .byte %00000000
    CollisionTemp:        .byte %00000000
    .var COLLISION_FLOOR =      %00000001

    CheckCollisions: {
        // Check foot 1
        ldx #$08
        ldy #$14
        jsr CheckCollision
        sta CollisionTemp
sta $0400

        // Check foot 2
        ldx #$01
        ldy #$14
        jsr CheckCollision
sta $0401

        ora CollisionTemp

        cmp #1

        beq !+

        // Clear foot collision
        lda CurrentCollisions
        and #[255-COLLISION_FLOOR]
        sta CurrentCollisions

        rts

     !: // Set foot collision
        lda CurrentCollisions
        ora #COLLISION_FLOOR
        sta CurrentCollisions
        
        rts
    }

    CheckCollision: {
        // X has X sprite pixel offset
        // Y has Y sprite pixel offset
        stx tmp2
        sty tmp1

        lda YPos 

        clc
        sbc tmp1
        
        sec
        sbc #ScreenRowOffsetY

        lsr
        lsr
        lsr
        tay
        lda ScreenRowLSB, y 
        sta ScreenLocation

        lda ScreenRowMSB, y 
        sta ScreenLocation+1

        lda XPos

        clc
        sbc tmp2
        
        sec
        sbc #ScreenRowOffsetX
        
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
        lda (tmp1), y
        cmp #0

        beq !+

        lda #1
        rts

     !: 
        lda #0
        rts

//      lda #16
//      ldy #0
//      sta (tmp1), y

rts

        lda YPos
        sec
        sbc #ScreenRowOffsetY
        lsr
        lsr
        lsr
        tay
        lda ColourRowLSB, y
        sta ColourLocation

        lda ColourRowMSB, y
        sta ColourLocation+1

        lda XPos
        sec
        sbc #ScreenRowOffsetX
        lsr
        lsr
        clc
        adc ColourLocation
        sta ColourLocation
        lda ColourLocation+1
        adc #0
        sta ColourLocation+1
 
        lda ColourLocation
        sta tmp1
        lda ColourLocation+1
        sta tmp1+1

        lda #06
        ldy #00
        sta (tmp1), y

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
          bne check_joystick_up
          lda #$00
          sta CurrentFrame
          jmp check_joystick_up

        check_joystick_left:
          lda JOY2
          and #JOY_LEFT
          bne check_joystick_up
          lda #DIR_LEFT
          sta Direction
          dec XPos
          inc CurrentFrame
          lda CurrentFrame
          cmp #$20
          bne check_joystick_up
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

          lda JumpFrame
          bne !+

          lda #1
          sta JumpFrame
 
        !: rts
    }
  
}
