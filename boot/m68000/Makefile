AS       = m68k-elf-as
ASFLAGS += -m68000
ASFLAGS += -alms
ASFLAGS += -I../ 
ASFLAGS += --defsym IS_68000=1

CC       = m68k-elf-gcc
CCFLAGS += -Wall
CCFLAGS += -m68000
#CCFLAGS += -ggdb
CCFLAGS += -nostdlib
CCFLAGS += -nodefaultlibs
CCFLAGS += -I../include
CCFLAGS += -I../../baselibc/include
CCFLAGS += -I../../fat/include

LD       = m68k-elf-ld
LDFLAGS  += -L../../fat/target
LDFLAGS  += -L../../baselibc/target
LDFLAGS  += -L/usr/local/lib/gcc/m68k-elf/9.2.0/m68000

#LIBS     += -lfat
LIBS     += -lc
LIBS     += -lgcc
 
BIOS_AS_SRC = $(wildcard ../bios/*.s)
BIOS_AS_OBJ = $(patsubst ../bios/%.s, obj/bios/%.o, $(BIOS_AS_SRC))

DSK_AS_SRC = $(wildcard ../disk/*.s)
DSK_AS_OBJ = $(patsubst ../disk/%.s, obj/disk/%.o, $(DSK_AS_SRC))

DSK_C_SRC = $(wildcard ../disk/*.c)
DSK_C_OBJ = $(patsubst ../disk/%.c, obj/disk/%.o, $(DSK_C_SRC))

IO_AS_SRC = $(wildcard ../io/*.s)
IO_AS_OBJ = $(patsubst ../io/%.s, obj/io/%.o, $(IO_AS_SRC))

IO_C_SRC = $(wildcard ../io/*.c)
IO_C_OBJ = $(patsubst ../io/%.c, obj/io/%.o, $(IO_C_SRC))

LIB_AS_SRC = $(wildcard ../lib/*.s)
LIB_AS_OBJ = $(patsubst ../lib/%.s, obj/lib/%.o, $(LIB_AS_SRC))

SREC_AS_SRC = $(wildcard ../s-record/*.s)
SREC_AS_OBJ = $(patsubst ../s-record/%.s, obj/s-record/%.o, $(SREC_AS_SRC))

OBS = $(CMD_AS_OBJ) $(BIOS_AS_OBJ) $(IDE_AS_OBJ) $(LIB_AS_OBJ) $(IO_AS_OBJ) $(IO_C_OBJ) $(DSK_AS_OBJ) $(DSK_C_OBJ) $(SREC_AS_OBJ) 

all: target/boot.srec

obj/bios/%.o:	../bios/%.s | obj/bios
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/disk/%.o:	../disk/%.s | obj/disk
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<
	
obj/disk/%.o:	../disk/%.c | obj/disk
	$(CC) $(CCFLAGS) -S -o $(@:.o=.s) $<
	$(CC) $(CCFLAGS) -c -o $@ $<

obj/io/%.o:	../io/%.s | obj/io
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<
	
obj/io/%.o:	../io/%.c | obj/io
	$(CC) $(CCFLAGS) -S -o $(@:.o=.s) $<
	$(CC) $(CCFLAGS) -c -o $@ $<

obj/lib/%.o:	../lib/%.s | obj/lib
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/s-record/%.o:	../s-record/%.s | obj/s-record
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

# --------------------------------------------------------------------------------
# M68000 CPM Boot Loader
# --------------------------------------------------------------------------------
obj/main.o: ../main.s | obj
	cat $< | sed "s/__BUILD-DATE__/$$(date '+%Y-%m-%d %H:%M:%S')/" > $(@:.o=.as)
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $(@:.o=.as)

obj/boot.srec: obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS)) | obj
	$(LD) $(LDFLAGS) -T boot.lnk obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS)) $(LIBS) -Map $(@:.srec=.map) -o $@

target/boot.srec: obj/boot.srec | target
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K 68000 Boot Loader" -o $@
	srec_info $@

clean:
	rm -rf obj/* target/*

obj:
	mkdir -p $@

obj/io: obj
	mkdir -p $@

obj/disk: obj
	mkdir -p $@

obj/lib: obj
	mkdir -p $@

obj/s-record: obj
	mkdir -p $@

obj/bios: obj
	mkdir -p $@

target:
	mkdir -p $@



