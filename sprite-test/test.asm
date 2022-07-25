.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(start_game)

* = $1000

.var ptr1 = $fb
.var ptr2 = $bb
.var ptr3 = $77

start_game:
    jsr do_all_platforms
    rts

do_all_platforms:
    lda #<platform_data
    sta ptr2
    lda #>platform_data
    sta ptr2+1

    jsr do_platform

!:  nop
    jmp !-

do_platform:
    lda (ptr2), y
    tay

    lda #119

!:  dey 

    ldx platform_data+1
    stx ptr1
    ldx platform_data+2
    stx ptr1+1

    sta (ptr1), y

    cpy #0
    beq !+
    jmp !-

!:  
    rts

platform_data: .byte 10
               .word 1024

               .byte 0
               .word 0

platform_ptr:   .byte 0
