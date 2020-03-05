AS       = m68k-elf-as
ASFLAGS += -m68000
ASFLAGS += -alms

CC       = m68k-elf-gcc
CCFLAGS += -Wall
CCFLAGS += -m68000
#CCFLAGS += -ggdb
CCFLAGS += -nostdlib
CCFLAGS += -nodefaultlibs

LD       = m68k-elf-ld

all: target/bios.srec 

%.s:	%.c
	$(CC) $(CCFLAGS) -S $<

# --------------------------------------------------------------------------------
# M68K CPM Bios
# --------------------------------------------------------------------------------
obj/%.o: %.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/bios.srec: obj/main.o obj/buffer.o
	$(LD) -T bios.lnk obj/main.o obj/buffer.o -Map $(@:.srec=.map) -o $@

target/bios.srec: obj/bios.srec
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K S100 Bios" -o $@
	srec_info $@

clean:
	rm -rf obj/* target/*
	mkdir -p obj target


