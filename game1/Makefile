JAVA=java
KICKASS=$(JAVA) -jar ../kickass/KickAss.jar
C1541=/Applications/vice-x86-64-gtk3-3.6.1/bin/c1541
VICE=/Applications/vice-x86-64-gtk3-3.6.1/bin/x64sc
DEBUGGER=/Applications/C64\ Debugger.app/Contents/MacOS/C64\ Debugger
NAME=game1

vice: $(NAME).prg
	$(VICE) $<

debug: $(NAME).prg
	$(DEBUGGER) $<

$(NAME).prg: main.asm
	$(KICKASS) main.asm -o $(NAME).prg -showmem -vicesymbols

$(NAME).d64: $(NAME).prg
	$(C1541) -format $(NAME),8 d64 $(NAME).d64 -attach $(NAME).d64 -write $(NAME).prg

clean:
	rm -f $(NAME).prg
	rm -f $(NAME).vs
	rm -f $(NAME).d64
