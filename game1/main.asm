.var brkFile = createFile("breakpoints.txt")
.macro break() {
  .eval brkFile.writeln("break " + toHexString(*))
}

BasicUpstart2(start_game)

* = $1000

start_game:
    inc $d020
    dec $d021
    jmp start_game
