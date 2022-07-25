JAVA=java
KICKASS=$(JAVA) -jar ../kick/KickAss.jar
C1541=/Applications/vice-x86-64-gtk3-3.6.1/bin/c1541
VICE=/Applications/vice-x86-64-gtk3-3.6.1/bin/x64sc
DEBUGGER=/Applications/C64\ Debugger.app/Contents/MacOS/C64\ Debugger

vice: snake.prg
	$(VICE) $<

debug: snake.prg
	$(DEBUGGER) $<

snake.prg: snake.asm
	$(KICKASS) snake.asm -o snake.prg -showmem -vicesymbols

snake.d64: snake.prg
	$(C1541) -format snake,8 d64 snake.d64 -attach snake.d64 -write snake.prg

clean:
	rm -f snake.prg
	rm -f snake.vs
	rm -f snake.d64
