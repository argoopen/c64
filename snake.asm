.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(start)

* = $1000

.var sid =  $d400
.var joy2 = $dc00

.var joy_up =    %00000001;
.var joy_down =  %00000010;
.var joy_left =  %00000100;
.var joy_right = %00001000;

.var start_pos = $05f4
.var start_speed = $ff
.var start_tail_length = $08

.var char_player = $57
.var char_border = $66
.var char_space = $20

.var dir_up = 1
.var dir_right = 2
.var dir_down = 3
.var dir_left = 4

.var sram_ptr = $bb
.var head_history_ptr = $fb
.var tail_history_ptr = $fd
.var temp_ptr = $39

start: jsr init
       jsr drawborder

loop:  jsr check_joystick
       jsr move_player
       jsr update_head_history
       jsr update_tail_history
       jsr check_collision
       jsr beep
       jsr draw_player

       ldx speed
       jsr delay

       sec
       lda speed
       sbc #$04
       sta speed
       cmp #$20
       bcs skip_reset_speed
       lda #$20
       sta speed
  skip_reset_speed:
       jsr $ffe1
       bne loop

init:  jsr $e544

       lda #$00
       sta sram_ptr
       ldx $0288
       stx sram_ptr+1

       lda #0
       sta $d020
       sta $d021

       lda #<start_pos
       ldx #>start_pos
       sta head_pos
       stx head_pos+1
       sta tail_pos
       stx tail_pos+1

       sta player_history_head
       stx player_history_head+1
       lda #dir_right
       sta player_dir
       lda #start_speed
       sta speed
       lda #start_tail_length
       sta tail_growth

       lda #<history
       sta head_history_ptr
       sta tail_history_ptr
       lda #>history
       sta head_history_ptr+1
       sta tail_history_ptr+1

       jsr update_head_history

       rts

initsid:
       lda #$00
       ldx #$00
  initsidloop:
       sta sid, y
       iny
       cpy 28
       bne initsidloop
       rts

check_collision:
       ldy #$00
       lda (sram_ptr),y
       cmp #$20
       bne game_over
       rts

game_over:
       inc $d020
       dec $d021
       jsr $ffe4
       beq game_over
       jmp start

check_joystick:
  check_joystick_right:
       lda joy2
       and #joy_right
       bne check_joystick_left
       ldx #dir_right
       stx player_dir
  check_joystick_left:
       lda joy2
       and #joy_left
       bne check_joystick_up
       ldx #dir_left
       stx player_dir
  check_joystick_up:
       lda joy2
       and #joy_up
       bne check_joystick_down
       ldx #dir_up
       stx player_dir
  check_joystick_down:
       lda joy2
       and #joy_down
       bne check_joystick_end
       ldx #dir_down
       stx player_dir
  check_joystick_end:
       rts

move_player: 
  move_player_right:
       lda player_dir
       cmp #dir_right
       bne move_player_left

       clc
       lda head_pos
       adc #$01
       sta head_pos
       lda head_pos+1
       adc #$00
       sta head_pos+1
  move_player_left:
       lda player_dir
       cmp #dir_left
       bne move_player_up

       sec
       lda head_pos
       sbc #$01
       sta head_pos
       lda head_pos+1
       sbc #$00
       sta head_pos+1
  move_player_up:
       lda player_dir
       cmp #dir_up
       bne move_player_down

       sec
       lda head_pos
       sbc #40
       sta head_pos
       lda head_pos+1
       sbc #$00
       sta head_pos+1
  move_player_down:
       lda player_dir
       cmp #dir_down
       bne move_player_update_pos

       clc
       lda head_pos
       adc #40
       sta head_pos
       lda head_pos+1
       adc #$00
       sta head_pos+1
  move_player_update_pos:
       ldx #$00
  
       lda head_pos
       sta sram_ptr
       lda head_pos+1
       sta sram_ptr+1

       rts

update_head_history:
       ldy #0
       lda head_pos
       sta (head_history_ptr), y

       clc
       lda head_history_ptr
       adc #1
       sta head_history_ptr

       lda head_history_ptr+1
       adc #0
       sta head_history_ptr+1

       lda head_pos+1
       sta (head_history_ptr), y

       clc
       lda head_history_ptr
       adc #1
       sta head_history_ptr

       lda head_history_ptr+1
       adc #0
       sta head_history_ptr+1
 
       lda head_history_ptr+1
       cmp #$40
       bne !+

       lda head_history_ptr
       bne !+

       lda #<history
       sta head_history_ptr
       lda #>history
       sta head_history_ptr+1
     
!:     rts

update_tail_history:
       lda tail_growth

       cmp #$00
       beq !++

       sec
       sbc #$01
       sta tail_growth

       bcs !+

       lda #$00
       sta tail_growth

!:     rts

!:     jsr clear_tail

       clc
       lda tail_history_ptr
       adc #2
       sta tail_history_ptr

       lda tail_history_ptr+1
       adc #0
       sta tail_history_ptr+1
 
       lda tail_history_ptr+1
       cmp #$40
       bne !+

       lda tail_history_ptr
       bne !+

       lda #<history
       sta tail_history_ptr
       lda #>history
       sta tail_history_ptr+1
     
!:     rts

clear_tail:
       ldy #0
       lda (tail_history_ptr),y
       sta temp_ptr

       iny
       lda (tail_history_ptr),y
       sta temp_ptr+1

       ldy #0
       lda #char_space
       sta (temp_ptr),y

       rts

draw_player: 
       lda #char_player
       ldy #$00
       sta (sram_ptr),y
      
       rts

beep:   jsr initsid
        lda #15
        sta sid+24
        lda #90
        sta sid+1
        lda #8*16+8
        sta sid+5
        lda #8*16+4
        sta sid+6
        lda #1+16
        sta sid+4
        lda #16
        sta sid+4
        rts

drawborder:
       jsr drawtop
       jsr drawedges
       jsr drawbottom
  drawtop:
       ldx #$00
       ldy #$00
       lda #char_border
  extendtop:
       sta (sram_ptr),y
       iny
       cpy #40
       bne extendtop
       sta (sram_ptr),y
       ldx #$00
       rts
  drawedges:
       clc
       lda sram_ptr
       adc #39
       sta sram_ptr
       lda sram_ptr+1
       adc #$00
       sta sram_ptr+1
       lda #char_border
       sta (sram_ptr),y
       clc
       lda sram_ptr 
       adc #01
       sta sram_ptr
       lda sram_ptr+1
       adc #$00
       sta sram_ptr+1
       lda #char_border
       sta (sram_ptr),y
       inx
       cpx #23
       bcc drawedges
       ldx #$00
       rts
  drawbottom:
       clc
       lda sram_ptr
       adc #01
       sta sram_ptr
       lda sram_ptr+1
       adc #$00
       sta sram_ptr+1
       lda #char_border
       sta (sram_ptr),y
       inx
       cpx #39
       bcc drawbottom
       rts

delay:
       ldy #0
  delayyloop:
       dey
       bne delayyloop
       dex
       bne delay
       rts
       
head_pos:            .word start_pos
tail_pos:            .word start_pos
player_history_head: .word start_pos
player_dir:          .byte dir_right
speed:               .byte start_speed
tail_growth:         .byte start_tail_length

history:     .fill 2048, 0

