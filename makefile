# tools

ASM=as61860
ASMFLAGS=-los

LNK=aslink
LNKFLAGS=-imwu

DEPLOYTOOL=ihx2emu

BASLDRTOOL=ihx2bas.py
#BASLDRFLAGS=-fast -p 28417
BASLDRFLAGS=-fast -p

RM=rm -f


# files

OBJS=chip8.rel keyboard.rel display.rel memcard.rel c8font.rel stub.rel
OUTPUT=chip8.ihx
DEPLOYDIR=../emulators/Sharptool/ROM/

DEPLOYFILE=emu_out.bin
BASLDRFILE=chip8.bas
BASLDREMU=chip8e.bas
BASLDREXT=basldr/basldr_ext.bas
#BASLDREXT=basldr/eof.bas

TARGETHEADER=target.h

# targets

all: $(OUTPUT)


# This target builds a BASIC ML program loader

basldr: $(BASLDRFILE)
basldremu:: $(BASLDREMU)

$(BASLDRFILE): $(OUTPUT)
	$(BASLDRTOOL) $(BASLDRFLAGS) `tail -n 1 target.h | tr ';' ' '` $(OUTPUT)|tr '\n' '\r' > $(BASLDRFILE) && cat $(BASLDREXT)|tr '\n' '\r' >> $(BASLDRFILE)
$(BASLDREMU): $(OUTPUT)
	$(BASLDRTOOL) $(BASLDRFLAGS) `tail -n 1 target.h | tr ';' ' '` $(OUTPUT) > $(BASLDREMU) && cat $(BASLDREXT) >> $(BASLDREMU)

# This target copies a memory image to lolos sharptool (emulator)

deploy: $(DEPLOYDIR)$(DEPLOYFILE)

$(DEPLOYDIR)$(DEPLOYFILE): $(OUTPUT)
	$(DEPLOYTOOL) -o $(DEPLOYDIR)$(DEPLOYFILE) $(OUTPUT)

$(OUTPUT): $(OBJS)
	$(LNK) $(LNKFLAGS) $(OUTPUT) $(OBJS)

%.rel: %.asm
	$(ASM) $(ASMFLAGS) $<

keyboard.rel: regs.h basic.h keyboard.h $(TARGETHEADER)
display.rel: regs.h basic.h display.h $(TARGETHEADER)
memcard.rel: regs.h basic.h memcard.h $(TARGETHEADER)
chip8.rel: regs.h basic.h keyboard.h sound.h display.h c8font.h stub.h $(TARGETHEADER)
c8font.rel: c8font.h $(TARGETHEADER)
stub.rel: stub.h $(TARGETHEADER)

clean:
	$(RM) *.rel *.sym *.lst *.map *.rst $(OUTPUT) $(BASLDRFILE)

.PHONY: all clean
