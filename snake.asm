.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(start_game)

* = $1000

.var raster_start = 0
.var raster_end = 58

.var sid =  $d400
.var joy2 = $dc00

.var joy_up =    %00000001//
.var joy_down =  %00000010//
.var joy_left =  %00000100//
.var joy_right = %00001000//

.var start_pos = 1024+20+12*40
.var start_speed = 20
.var start_tail_length = $08
.var start_mushroom_count = 1

.var char_player = 28
.var char_player_head = 29
.var char_border = 27
.var char_mushroom = 0
.var char_space = 32

.var dir_up = 1
.var dir_right = 2
.var dir_down = 3
.var dir_left = 4

.var sram_ptr = $bb
.var cram_ptr = $77
.var head_history_ptr = $fb
.var tail_history_ptr = $fd
.var temp_ptr = $39
.var sfx1_ptr = $73
.var sfx2_ptr = $75

start_game: 
       jsr init_game
start_level:
       jsr init_level
       jsr draw_border
       jsr place_mushroom
       jsr print_score

loop:  lda #80
!:     cmp $d012
       bne !-
!:     cmp $d012
       beq !-

       jsr play_sfx
       jsr check_joystick
       
       dec counter
       bne loop
       lda speed
       sta counter

       jsr move_player
       jsr update_head_history
       jsr update_tail_history
       jsr check_collision

       jsr draw_player

       jsr check_exit

       jsr print_score
       jsr print_mushroom_count
       jsr print_level

       lda speed
       cmp #5
       beq loop
       dec speed

       jmp loop

init_game:  
       lda #$18       // relocate charset
       sta $d018

       jsr setup_interrupt

       lda #1
       sta level

       lda #0
       sta $d020
       sta $d021
       sta score
       sta score+1
       sta sfx1_ptr
       sta sfx1_ptr+1
       sta sfx2_ptr
       sta sfx2_ptr+1

       lda #$ff
       sta sid+14
       sta sid+15
       lda #$80
       sta sid+18

       rts

init_level:  
       jsr $e544

       lda #$00
       sta sram_ptr
       ldx $0288
       stx sram_ptr+1

       lda #start_mushroom_count
       sta mushroom_count

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

place_mushroom:
!:     ldy sid+27

       cpy #$b0
       bcc !+
       lda #$04
       jmp place_mushroom_v
       
!:     cpy #$80
       bcc !+
       lda #$05
       jmp place_mushroom_v
       
!:     cpy #$40
       bcc !+
       lda #$06
       jmp place_mushroom_v

!:     lda #$07
       
  place_mushroom_v:
       ldy sid+27

       cmp #$04
       bne !+
       cpy #80
       bcc place_mushroom
       
  !:   sta place_mushroom_v+19
       sta place_mushroom_v+28
       lda $0000, y
       cmp #char_space
       bne place_mushroom
       lda #char_mushroom
       sta $0000, y

       clc
       lda place_mushroom_v+19
       adc #$d4
       sta cram_ptr+1
       lda #0
       sta cram_ptr
    
       lda #%00001001
       sta (cram_ptr), y
       
       rts

check_exit:
       ldx #0

!:     lda exit_locations, x
       bne !+
       inx
       lda exit_locations, x
       dex
       cmp #0
       beq !+

       rts

!:     lda exit_locations, x
       cmp sram_ptr
       bne !+

       inx

       lda exit_locations, x
       cmp sram_ptr+1
       bne !+

       inc level

       lda #<sfx_end_level
       sta sfx1_ptr
       lda #>sfx_end_level
       sta sfx1_ptr+1

       jmp exit_anim

  !:   inx
       jmp !---

check_collision:
!:     ldy #$00
       lda (sram_ptr),y

       cmp #char_space
       bne !+
       rts

!:     cmp #char_mushroom
       bne !+
       jsr mushroom_hit
       rts

!:     jmp game_over

next_level:
       inc level
       jmp start_level

mushroom_hit:
       clc
       lda score
       adc #10
       sta score

       lda score+1
       adc #0
       sta score+1

       dec mushroom_count
       bne !+

       jsr open_exits
       jmp !++
       
!:     jsr place_mushroom

!:     lda sid+27
       clc
       ror
       clc
       ror
       clc
       ror
       clc
       ror
       clc
       ror
       sta tail_growth

       lda #<sfx_score
       sta sfx2_ptr
       lda #>sfx_score
       sta sfx2_ptr+1

!:     rts

game_over:
!:     inc $d020
       dec $d021
       jsr $ffe4
       beq !-
       jmp start_game

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
       lda #char_player
       ldy #$00
       sta (sram_ptr),y

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

       lda #<sfx_move
       sta sfx1_ptr
       lda #>sfx_move
       sta sfx1_ptr+1

!:     rts

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

exit_anim:
       ldx #32
       lda #0
       jsr sound1
       jsr sound2
exit_anim_loop:
       lda #80
!:     cmp $d012
       bne !-
!:     cmp $d012
       beq !-

       dec counter
       bne exit_anim
       lda speed
       sta counter

       jsr clear_tail

       txa
       ora #%01000000
       jsr sound1
       cpx #%00100000
       bne !+
       inx

!:     lda tail_history_ptr
       cmp head_history_ptr
       bne !+

       lda tail_history_ptr+1
       cmp head_history_ptr+1
       bne !+

       jmp next_level

!:     clc
       lda tail_history_ptr
       adc #2
       sta tail_history_ptr
       lda tail_history_ptr+1
       adc #0
       sta tail_history_ptr+1

       lda speed
       cmp #5
       beq exit_anim_loop
       dec speed

       jmp exit_anim_loop

draw_player: 
       lda #char_player_head
       ldy #$00
       sta (sram_ptr),y

       clc
       lda sram_ptr+1
       adc #$d4
       sta sram_ptr+1

       lda #%00001011
       sta (sram_ptr),y
 
       lda sram_ptr+1
       sec
       sbc #$d4
       sta sram_ptr+1
      
       rts

draw_border:
       // top
       lda #$28
       sta sram_ptr
       lda #$04
       sta sram_ptr+1
       ldx #40
       jsr draw_wall_horizontal

       // bottom
       lda #$c0
       sta sram_ptr
       lda #$07
       sta sram_ptr+1
       ldx #40
       jsr draw_wall_horizontal

       // left
       lda #$50
       sta sram_ptr
       lda #$04
       sta sram_ptr+1
       ldx #22
       jsr draw_wall_vertical

       // right
       lda #$77
       sta sram_ptr
       lda #$04
       sta sram_ptr+1
       ldx #22
       jsr draw_wall_vertical

       jsr draw_labels

       rts

draw_wall_horizontal:
       lda #char_border
       ldy #0
       sta (sram_ptr), y

       clc
       lda sram_ptr+1
       adc #$d4
       sta sram_ptr+1
       lda #%00001001
       sta (sram_ptr), y

       lda sram_ptr+1
       sec
       sbc #$d4
       sta sram_ptr+1

       clc
       lda sram_ptr
       adc #1
       sta sram_ptr
       lda sram_ptr+1
       adc #0
       sta sram_ptr+1

       dex
       bne draw_wall_horizontal
       rts
   
draw_wall_vertical:
       lda #char_border
       ldy #0
       sta (sram_ptr), y

       clc
       lda sram_ptr+1
       adc #$d4
       sta sram_ptr+1
       lda #%00001001
       sta (sram_ptr), y

       lda sram_ptr+1
       sec
       sbc #$d4
       sta sram_ptr+1

       clc
       lda sram_ptr
       adc #40
       sta sram_ptr
       lda sram_ptr+1
       adc #0
       sta sram_ptr+1

       dex
       bne draw_wall_vertical
       rts
   
draw_labels:
       ldx #0
    !: lda score_label,x
       sta $0400,x
       inx
       cpx #6
       bne !-

       ldx #0
    !: lda mushroom_label,x
       sta $040e,x
       inx
       cpx #10
       bne !-

       ldx #0
    !: lda level_label,x
       sta $0420,x
       inx
       cpx #6
       bne !-

       rts

print_score:
       clc
       ldx #0
       ldy #7
       jsr $fff0

       lda score+1
       ldx score
       jsr $bdcd
       rts

print_mushroom_count:
       clc
       ldx #0
       ldy #25
       jsr $fff0

       lda mushroom_count+1
       ldx mushroom_count
       jsr $bdcd
       rts

print_level:
       clc
       ldx #0
       ldy #39
       jsr $fff0

       lda level+1
       ldx level
       jsr $bdcd
       rts

open_exits:
       ldx #0
!:     lda exit_locations, x
       bne !+

       inx 
       lda exit_locations, x
       bne !+

       rts

       dex

!:     lda exit_locations, x
       sta temp_ptr
       inx
       lda exit_locations, x
       sta temp_ptr+1

       lda #char_space
       ldy #0
       sta (temp_ptr), y

       inx
 
       jmp !--

setup_interrupt:
           sei                  //set interrupt bit, make the CPU ignore interrupt requests
           lda #%01111111       //switch off interrupt signals from CIA-1
           sta $dc0d

           and $d011            //clear most significant bit of VIC's raster register
           sta $d011

           lda $dc0d            //acknowledge pending interrupts from CIA-1
           lda $dd0d            //acknowledge pending interrupts from CIA-2

           lda #raster_start    //set rasterline where interrupt shall occur
           sta $d012

           lda #<irq            //set interrupt vectors, pointing to interrupt service routine below
           sta $0314
           lda #>irq
           sta $0315

           lda #%00000001       //enable raster interrupt signals from VIC
           sta $D01A

           cli                  //clear interrupt flag, allowing the CPU to respond to interrupt requests
           rts

irq:
           lda $d016
           and #%11101111
           sta $d016

           lda #<irq2           //set interrupt vectors to the second interrupt service routine at Irq2
           sta $0314
           lda #>irq2
           sta $0315

           lda #raster_end
           sta $d012            //next interrupt will occur at line no. 0

           asl $d019            //acknowledge the interrupt by clearing the VIC's interrupt flag

           jmp $ea31            //jump into KERNAL's standard interrupt service routine to handle keyboard scan, cursor display etc.

irq2:
           lda $d016
           ora #%00010000
           sta $d016

           lda #<irq             //set interrupt vectors back to the first interrupt service routine at Irq
           sta $0314
           lda #>irq
           sta $0315

           lda #raster_start
           sta $d012            //next interrupt will occur at line no. 210

           asl $d019            //acknowledge the interrupt by clearing the VIC's interrupt flag

           jmp $ea31            //jump into KERNAL's standard interrupt service routine to handle keyboard scan, cursor display etc.

play_sfx: 
          // Channel 1
          lda sfx1_ptr
          bne !+
          lda sfx1_ptr+1
          bne !+
          rts

!:        ldy #0
          lda (sfx1_ptr),y

          jsr sound1

          bne !+

          ldy #$00
          sty sfx1_ptr
          sty sfx1_ptr+1
          rts

!:        
          clc
          lda sfx1_ptr
          adc #01
          sta sfx1_ptr
          lda sfx1_ptr+1
          adc #$00
          sta sfx1_ptr+1

          // Channel 2
          lda sfx2_ptr
          bne !+
          lda sfx2_ptr+1
          bne !+
          rts

!:        ldy #0
          lda (sfx2_ptr),y

          jsr sound2

          bne !+

          ldy #$00
          sty sfx2_ptr
          sty sfx2_ptr+1
          rts

!:        
          clc
          lda sfx2_ptr
          adc #01
          sta sfx2_ptr
          lda sfx2_ptr+1
          adc #$00
          sta sfx2_ptr+1

          rts

sound1:     //NVPPPPPP - N=Noise V=Volume P=Pitch
    pha
        and #%00111111  //Pitch bits
        sta $D401       //HHHHHHHH   Voice #1 frequency H (Higher values=higher pitch)
    pla
    beq sound1_off //See if sound is turned off

    pha
        and #%10000000  //Noise Bit
        bne sound1_noise_done

        lda #%01000000  //ChibiSound_NoNoise
  sound1_noise_done:
        ora #%00000001
        sta $D404       //NPST-RSG   Voice #1 control register - Noise / Pulse / Sawtooth / Triangle / - test / Ring mod / Sync /Gate

        ldx #0
        stx $D402       //LLLLLLLL   Voice #1 pulse width L
        stx $D405       //AAAADDDD   Voice #1 Attack and Decay length - Atack / Decay
        dex //255
        stx $D400       //LLLLLLLL   Voice #1 frequency L
        stx $D403       //----HHHH   Voice #1 pulse width H
        stx $D406       //SSSSRRRR   Voice #1 Sustain volume and Release length - Sustain  / Release

    pla
    and #%01000000      //Volume bit -V------
    lsr
    lsr
    lsr
    ora #%00000111      //Move to   -----V111

  sound1_off:
    sta $D418           //MHBLVVVV   Volume and filter modes - Mute3 / Highpass / Bandpass / Lowpass / Volume (0=silent)
    rts

sound2:     //NVPPPPPP - N=Noise V=Volume P=Pitch
    pha
        and #%00111111  //Pitch bits
        sta $d408       //HHHHHHHH   Voice #1 frequency H (Higher values=higher pitch)
    pla
    beq sound2_off //See if sound is turned off

    pha
        and #%10000000  //Noise Bit
        bne sound1_noise_done

        lda #%01000000  //ChibiSound_NoNoise
  sound2_noise_done:
        ora #%00000001
        sta $d40b       //NPST-RSG   Voice #1 control register - Noise / Pulse / Sawtooth / Triangle / - test / Ring mod / Sync /Gate

        ldx #0
        stx $D409       //LLLLLLLL   Voice #1 pulse width L
        stx $D40c       //AAAADDDD   Voice #1 Attack and Decay length - Atack / Decay
        dex //255
        stx $D407       //LLLLLLLL   Voice #1 frequency L
        stx $D40a       //----HHHH   Voice #1 pulse width H
        stx $D40d       //SSSSRRRR   Voice #1 Sustain volume and Release length - Sustain  / Release

    pla
    and #%01000000      //Volume bit -V------
    lsr
    lsr
    lsr
    ora #%00000111      //Move to   -----V111

  sound2_off:
    sta $D418           //MHBLVVVV   Volume and filter modes - Mute3 / Highpass / Bandpass / Lowpass / Volume (0=silent)
    rts


score:               .word 0
head_pos:            .word start_pos
tail_pos:            .word start_pos
player_history_head: .word start_pos
player_dir:          .byte dir_right
counter:             .byte $01
speed:               .byte start_speed
tail_growth:         .byte start_tail_length
score_label:         .text "score:"
level_label:         .text "level:"
mushroom_label:      .text "mushrooms:"
mushroom_count:      .word 0
level:               .word 1
current_freq:        .byte 128
sfx_move:            .fill 2, %01001000
                     .fill 2, %01010000
                     .fill 2, %01100000
                     .byte 0
sfx_score:           .fill 5, %01000001
                     .fill 5, %01000010
                     .fill 5, %01000100
                     .fill 5, %01001000
                     .fill 5, %01010000
                     .byte 0
sfx_end_level:       .fill 2, %01000000
                     .fill 2, %01000100
                     .fill 2, %01001000
                     .fill 2, %01010000
                     .fill 2, %01100000
                     .byte 0
exit_locations:      .word 1024+20+40   
                     .word 1024+12*40   
                     .word 1024+39+12*40   
                     .word 1024+24*40+20
                     .word 0

history:     .fill 2048, 0


* = $2000
.import binary "snake.64c"

