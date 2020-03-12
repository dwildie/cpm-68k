AS       = m68k-elf-as
ASFLAGS += -m68000
ASFLAGS += -alms

CC       = m68k-elf-gcc
CCFLAGS += -Wall
CCFLAGS += -m68000
#CCFLAGS += -ggdb
CCFLAGS += -nostdlib
CCFLAGS += -nodefaultlibs
CCFLAGS += -I../baselibc/include
CCFLAGS += -I../fat/include

LD       = m68k-elf-ld
LDFLAGS  += -L../fat/target
LDFLAGS  += -L../baselibc/target
LDFLAGS  += -L/usr/local/lib/gcc/m68k-elf/9.2.0/m68000

LIBS     += -lfat
LIBS     += -lc
LIBS     += -lgcc
 
CMD_AS_SRC = $(wildcard commands/*.s)
CMD_AS_OBJ = $(patsubst commands/%.s, obj/commands/%.o, $(CMD_AS_SRC))

BIOS_AS_SRC = $(wildcard bios/*.s)
BIOS_AS_OBJ = $(patsubst bios/%.s, obj/bios/%.o, $(BIOS_AS_SRC))

IDE_AS_SRC = $(wildcard ide/*.s)
IDE_AS_OBJ = $(patsubst ide/%.s, obj/ide/%.o, $(IDE_AS_SRC))

LIB_AS_SRC = $(wildcard lib/*.s)
LIB_AS_OBJ = $(patsubst lib/%.s, obj/lib/%.o, $(LIB_AS_SRC))

IO_AS_SRC = $(wildcard io/*.s)
IO_AS_OBJ = $(patsubst io/%.s, obj/io/%.o, $(IO_AS_SRC))

IO_C_SRC = $(wildcard io/*.c)
IO_C_OBJ = $(patsubst io/%.c, obj/io/%.o, $(IO_C_SRC))

DSK_AS_SRC = $(wildcard disk/*.s)
DSK_AS_OBJ = $(patsubst disk/%.s, obj/disk/%.o, $(DSK_AS_SRC))

DSK_C_SRC = $(wildcard disk/*.c)
DSK_C_OBJ = $(patsubst disk/%.c, obj/disk/%.o, $(DSK_C_SRC))

SREC_AS_SRC = $(wildcard s-record/*.s)
SREC_AS_OBJ = $(patsubst s-record/%.s, obj/s-record/%.o, $(SREC_AS_SRC))

OBS = $(CMD_AS_OBJ) $(BIOS_AS_OBJ) $(IDE_AS_OBJ) $(LIB_AS_OBJ) $(IO_AS_OBJ) $(IO_C_OBJ) $(DSK_AS_OBJ) $(DSK_C_OBJ) $(SREC_AS_OBJ) 

all: target/boot.srec 

obj/io/%.o:	io/%.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<
	
obj/io/%.o:	io/%.c
	$(CC) $(CCFLAGS) -S -o $(@:.o=.s) $<
	$(CC) $(CCFLAGS) -c -o $@ $<

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

obj/disk/%.o:	disk/%.c
	$(CC) $(CCFLAGS) -S -o $(@:.o=.s) $<
	$(CC) $(CCFLAGS) -c -o $@ $<

# --------------------------------------------------------------------------------
# M68K CPM Boot Loader
# --------------------------------------------------------------------------------
obj/main.o: main.s
	$(AS) -m68010 -alms -a=$(@:.o=.lst) -o $@ $<

obj/boot.srec: obj/main.o $(OBS)
	$(LD) $(LDFLAGS) -T boot.rom.lnk obj/main.o $(OBS) $(LIBS) -Map $(@:.srec=.map) -o $@

target/boot.srec: obj/boot.srec
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K Boot Loader" -o $@
	srec_info $@

clean:
	rm -rf obj/* target/*
	mkdir -p obj/io obj/disk obj/lib obj/s-record obj/bios target


