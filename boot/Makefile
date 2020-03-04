AS       = m68k-elf-as
ASFLAGS += -m68010
ASFLAGS += -alms

CC       = m68k-elf-gcc
CCFLAGS += -Wall
CCFLAGS += -m68000
#CCFLAGS += -ggdb
CCFLAGS += -nostdlib
CCFLAGS += -nodefaultlibs

LD       = m68k-elf-ld

CMD_SRC = $(wildcard commands/*.s)
CMD_OBJ = $(patsubst commands/%.s, obj/commands/%.o, $(CMD_SRC))

BIOS_SRC = $(wildcard bios/*.s)
BIOS_OBJ = $(patsubst bios/%.s, obj/bios/%.o, $(BIOS_SRC))

IDE_SRC = $(wildcard ide/*.s)
IDE_OBJ = $(patsubst ide/%.s, obj/ide/%.o, $(IDE_SRC))

LIB_SRC = $(wildcard lib/*.s)
LIB_OBJ = $(patsubst lib/%.s, obj/lib/%.o, $(LIB_SRC))

IO_SRC = $(wildcard io/*.s)
IO_OBJ = $(patsubst io/%.s, obj/io/%.o, $(IO_SRC))

DSK_SRC = $(wildcard disk/*.s)
DSK_OBJ = $(patsubst disk/%.s, obj/disk/%.o, $(DSK_SRC))

SREC_SRC = $(wildcard s-record/*.s)
SREC_OBJ = $(patsubst s-record/%.s, obj/s-record/%.o, $(SREC_SRC))

all: target/boot.srec 

obj/io/%.o:	io/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<
	
obj/commands/%.o:	commands/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<
	
obj/ide/%.o:	ide/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/lib/%.o:	lib/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/console/%.o:	console/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<
	
obj/disk/%.o:	disk/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<
	
obj/s-record/%.o:	s-record/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/bios/%.o:	bios/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

%.s:	%.c
	$(CC) $(CCFLAGS) -S $<

# --------------------------------------------------------------------------------
# M68K CPM Boot Loader
# --------------------------------------------------------------------------------
obj/main.o: main.s
	$(AS) -m68010 -alms -a=$(@:.o=.lst) -o $@ $<

obj/boot.srec: obj/main.o $(IO_OBJ) $(DSK_OBJ) $(LIB_OBJ) $(SREC_OBJ) $(BIOS_OBJ)
	$(LD) -T boot.rom.lnk obj/main.o $(IO_OBJ) $(DSK_OBJ) $(LIB_OBJ) $(SREC_OBJ) $(BIOS_OBJ) -Map $(@:.srec=.map) -o $@
	cp $(@:.srec=.map) /tmp
	cp $(@:.srec=.map) /mnt/Damian/Dropbox/retroComputing/S100/68000\ CPU/gnu/Monitor/$(notdir $(@:.srec=.map))

target/boot.srec: obj/boot.srec
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K Boot Loader" -o $@
	srec_info $@

clean:
	rm -rf obj/* target/*
	mkdir -p obj/io obj/disk obj/lib obj/s-record obj/bios target


