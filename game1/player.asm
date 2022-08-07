PLAYER: {
    .var DIR_LEFT = 0
    .var DIR_RIGHT = 1

    .label tmp1 = $77
    .label tmp2 = $bb

    .var JOY2      = $dc00
    .var JOY_UP    = %00000001
    .var JOY_DOWN  = %00000010
    .var JOY_LEFT  = %00000100
    .var JOY_RIGHT = %00001000
    .var JOY_FIRE  = %00010000

    .var XMIN      = $09
    .var XMAX      = $a8

    .var STATE_NORMAL  = $00
    .var STATE_FALLING = $07
    .var STATE_JUMPING = $05

    XPos:                .byte $28
    YPos:                .byte $50
    Direction:           .byte DIR_RIGHT
    CurrentFrame:        .byte 0
    CurrentSprite:       .byte 0

    JumpPatternX:         .fill 12,round(8*sin(toRadians(i*90/8)))
    JumpPattern:         .fill 10, 2
    __JumpPattern:

    FallPatternX:         .fill 12,8-round(8*cos(toRadians(i*90/8)))
    FallPattern:         .fill 10, 2
    __FallPattern:

    CurrentState:        .byte STATE_NORMAL
    JumpFrame:           .byte 0
    FallFrame:           .byte 0

    CurrentCollisions:    .byte %00000000
    CollisionTemp:        .byte %00000000
    .var COLLISION_FLOOR =     %00000001
    .var COLLISION_LEFT =      %00000010
    .var COLLISION_RIGHT =     %00000100

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
        sta $d001

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

    CheckCollisions: {
        // Clear all collisions
        lda #0
        sta CurrentCollisions

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

        bne !+


        // Set foot collision
        lda CurrentCollisions
        ora #COLLISION_FLOOR
        sta CurrentCollisions

     !: // Check left

        ldx #$0b
        ldy #$1e
        jsr CheckCollision
        sta $0428

        beq !+

        lda CurrentCollisions
        ora #COLLISION_LEFT
        sta CurrentCollisions

        // Check right
     !: ldx #$ff
        ldy #$1e
        jsr CheckCollision
        sta $0429

        beq !+

        lda CurrentCollisions
        ora #COLLISION_RIGHT
        sta CurrentCollisions

        
     !: rts
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

//      lda #$08
//      ldy #0
//      sta (tmp1), y


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

          lda CurrentCollisions
          and #COLLISION_RIGHT
          bne check_joystick_left

          lda #DIR_RIGHT
          sta Direction

          lda XPos
          cmp #XMAX
          bcs check_joystick_up

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

          lda CurrentCollisions
          and #COLLISION_LEFT
          bne check_joystick_up

          lda XPos
          cmp #XMIN
          bcc check_joystick_up

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
          lda CurrentState
          cmp #STATE_NORMAL
          bne !+
 
          lda JOY2
          and #JOY_FIRE
          bne !+

          lda #STATE_JUMPING
          sta CurrentState

          lda #0
          sta JumpFrame

        !: rts
    }

    JumpAndFall: {
        lda CurrentState
        cmp #STATE_JUMPING
        beq ApplyFall

        nop

      StartFallingCheck:
        lda CurrentCollisions
        and #COLLISION_FLOOR
        bne EndOfFall                  // if just landed on floor
 
      Falling:
        lda CurrentState
        cmp #STATE_FALLING
        beq ApplyFall

        lda #STATE_FALLING
        sta CurrentState

        lda #0
        sta FallFrame

        jmp ApplyFall

      EndOfFall:
        lda CurrentState
        cmp #STATE_FALLING
        bne !+

        lda YPos
        sec
        sbc #$06
        and #$f8
        ora #$06
        sta YPos           // round to top of line

      !:  
        lda #STATE_NORMAL
        sta CurrentState

      ApplyFall:
            lda CurrentState
            cmp #STATE_FALLING
            bne StartJumpingCheck

            ldx FallFrame
            lda FallPattern, x
            clc
            adc YPos
            sta YPos        // move player Y
            inx             // move to next index

            cpx #[__FallPattern - FallPattern]
            bne !+
            ldx #[__FallPattern - FallPattern - 1]


        !:  
            stx FallFrame
        !Skip:

      StartJumpingCheck:
        lda CurrentState
        cmp #STATE_JUMPING
        bne EndJumpingCheck

        ldx JumpFrame
        lda YPos
        
        sec
        sbc JumpPattern, x
        sta YPos
      
        inx

        cpx #[__JumpPattern - JumpPattern]
        bne !+

        lda #STATE_FALLING
        sta CurrentState
        
      !:
        stx JumpFrame
        

      EndJumpingCheck:
        rts
        
    }
}
