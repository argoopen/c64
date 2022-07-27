.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(Entry)

Entry:
  lda #$00
  sta $fb
  lda #$04
  sta $fc

  ldx #0
  lda #1
  sta ($fb), x

  sta $0401

  !:
  jmp !-

