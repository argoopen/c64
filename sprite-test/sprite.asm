.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(start_game)

* = $1000

.var clear = $e544
.var sprite1_data =  $2000
.var sprite2_data =  $2040
.var joy2 = $dc00
.var sp0x	= $d000
.var sp0y	= $d001
.var msbx	= $d010

.var joy_up =    %00000001
.var joy_down =  %00000010
.var joy_left =  %00000100
.var joy_right = %00001000
.var dir_up = 1
.var dir_right = 2
.var dir_down = 3
.var dir_left = 4

.var ptr1 = $fb

player_dir:          .byte dir_right
counter:             .byte $01
speed:               .byte $01

start_game: 
    jsr clear

    lda #$81
    sta $07f8
    lda #$00
    sta $d020
    sta $d021

    lda #$01
    sta $d015

    lda #$80
    sta $d000
    sta $d001

    jsr draw_platforms

loop:  lda #80
!:     cmp $d012
       bne !-
!:     cmp $d012
       beq !-

       dec counter
       bne loop
       lda speed
       sta counter

       jsr  check_joystick

       jmp loop

check_joystick:
  check_joystick_right:
       lda joy2
       and #joy_right
       bne check_joystick_left

       ldx sp0x
       cpx #60
       bne move_right
       ldx msbx
       cpx #1
       beq check_joystick_up

  move_right:
       ldx #dir_right
       stx player_dir
       lda #$80
       sta $07f8

       ldx sp0x
       inx
       stx sp0x
       cpx #255
       bne check_joystick_left
       lda #1
       sta msbx
       lda #0
       sta sp0x

  check_joystick_left:
       lda joy2
       and #joy_left
       bne check_joystick_up

       ldx sp0x
       cpx #24
       bne move_left
       ldx msbx
       cpx #0
       beq check_joystick_up

  move_left:
       ldx #dir_left
       stx player_dir

       lda #$81
       sta $07f8
       ldx sp0x
       dex
       stx sp0x
       cpx #255
       bne check_joystick_up
       lda #0
       sta msbx
       jmp check_joystick_up

  check_joystick_up:
       lda joy2
       and #joy_up
       bne check_joystick_down
       ldx #dir_up
       stx player_dir   
       dec $d001
  check_joystick_down:
       lda joy2
       and #joy_down
       bne check_joystick_end
       ldx #dir_down
       stx player_dir
       inc $d001
  check_joystick_end:
       rts

draw_platforms:
       ldy #0
  !:
       beq end_draw_platforms

       lda (platform_data), y
       sta $0400
       iny
 
       lda platform_data, y
       sta <ptr1
       iny
    
       lda platform_data, y
       sta >ptr1
       iny

       txa
       sta (ptr1),y
   
       inc 53280
       
       jmp !-

  end_draw_platforms:
       rts

* = sprite1_data
.byte %00000111,%00011100,%00000000
.byte %00000001,%10000110,%00000000
.byte %00000000,%11111111,%00000000
.byte %00000000,%01100000,%11000000
.byte %00000111,%11000010,%01000000
.byte %00001000,%10000000,%01000000
.byte %00000000,%10011000,%01000000
.byte %00000011,%10001111,%11000000
.byte %00000100,%10000000,%01000000
.byte %00001000,%11000000,%11000000
.byte %00000011,%01111111,%10000000
.byte %00000010,%00001000,%00000000
.byte %00000110,%00001000,%00000000
.byte %00000000,%01111111,%00000000
.byte %00000000,%00001000,%00000000
.byte %00000000,%00011000,%00000000
.byte %00000000,%00111100,%00000000
.byte %00000000,%01100110,%00000000
.byte %00000000,%11000011,%00000000
.byte %00000000,%10000001,%10000000
.byte %00000000,%00000000,%00000000
.byte %00000000

* = sprite2_data
.byte %00000000,%00111000,%11100000
.byte %00000000,%01100001,%10000000
.byte %00000000,%11111111,%00000000
.byte %00000011,%00000110,%00000000
.byte %00000010,%01000011,%11100000
.byte %00000010,%00000001,%00010000
.byte %00000010,%00011001,%00000000
.byte %00000011,%11110001,%11000000
.byte %00000010,%00000001,%00100000
.byte %00000011,%00000011,%00010000
.byte %00000001,%11111110,%11000000
.byte %00000000,%00010000,%01000000
.byte %00000000,%00010000,%01100000
.byte %00000000,%11111110,%00000000
.byte %00000000,%00010000,%00000000
.byte %00000000,%00011000,%00000000
.byte %00000000,%00111100,%00000000
.byte %00000000,%01100110,%00000000
.byte %00000000,%11000011,%00000000
.byte %00000001,%10000001,%00000000
.byte %00000000,%00000000,%00000000
.byte %00000000

platform_data: .byte 120
               .word 1034
    
               .byte 0, 0, 0


