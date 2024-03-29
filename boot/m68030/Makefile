AS       = m68k-elf-as
ASFLAGS += -m68010
ASFLAGS += -alms
ASFLAGS += -I../ 
ASFLAGS += --defsym IS_68030=1

AS3FLAGS += -m68030
AS3FLAGS += -alms
AS3FLAGS += -I../ 
AS3FLAGS += --defsym IS_68030=1

CC       = m68k-elf-gcc
CCFLAGS += -Wall
CCFLAGS += -m68010
#CCFLAGS += -ggdb
#CCFLAGS += -nostdlib
#CCFLAGS += -nodefaultlibs
CCFLAGS += -ffreestanding -v
CCFLAGS += -I../include
CCFLAGS += -I../../baselibc/include
CCFLAGS += -I../../fat/include

LD       = m68k-elf-ld
LDFLAGS  += -L../../fat/target
LDFLAGS  += -L../../baselibc/target
LDFLAGS  += -L/usr/local/lib/gcc/m68k-elf/9.2.0/m68000

LIBS     += -lfat
LIBS     += -lc
LIBS     += -lgcc

SRC_DIR = ..

BIOS_AS_SRC = $(wildcard ../bios/*.s)
BIOS_AS_OBJ = $(patsubst ../bios/%.s, obj/bios/%.o, $(BIOS_AS_SRC))

DSK_AS_SRC = $(wildcard ../disk/*.s)
DSK_AS_OBJ = $(patsubst ../disk/%.s, obj/disk/%.o, $(DSK_AS_SRC))

FAT_C_SRC = $(wildcard ../fat/*.c)
FAT_C_OBJ = $(patsubst ../fat/%.c, obj/fat/%.o, $(FAT_C_SRC))

DSK_C_SRC = $(wildcard ../disk/*.c)
DSK_C_OBJ = $(patsubst ../disk/%.c, obj/disk/%.o, $(DSK_C_SRC))

IO_AS_SRC = $(wildcard ../io/*.s)
IO_AS_OBJ = $(patsubst ../io/%.s, obj/io/%.o, $(IO_AS_SRC))

IO_C_SRC = $(wildcard ../io/*.c)
IO_C_OBJ = $(patsubst ../io/%.c, obj/io/%.o, $(IO_C_SRC))

LIB_AS_SRC = $(wildcard ../lib/*.s)
LIB_AS_OBJ = $(patsubst ../lib/%.s, obj/lib/%.o, $(LIB_AS_SRC))

LIB_C_SRC = $(wildcard ../lib/*.c)
LIB_C_OBJ = $(patsubst ../lib/%.c, obj/lib/%.o, $(LIB_C_SRC))

MMU_AS_SRC = $(wildcard ../mmu/*.s)
MMU_AS_OBJ = $(patsubst ../mmu/%.s, obj/mmu/%.o, $(MMU_AS_SRC))


OBS = $(CMD_AS_OBJ) $(BIOS_AS_OBJ) $(IDE_AS_OBJ) $(LIB_AS_OBJ) $(LIB_C_OBJ) $(IO_AS_OBJ) $(IO_C_OBJ) $(DSK_AS_OBJ) $(DSK_C_OBJ) $(FAT_C_OBJ) $(MMU_AS_OBJ)

# --------------------------------------------------------------------------------
# Dependencies
# --------------------------------------------------------------------------------
all: target/boot30-16mb-flash.srec target/boot30-16mb.srec target/boot30-4mb.srec target/boot30-ss1.srec

obj/bios/%.o:	../bios/%.s | obj/bios
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/fat/%.o:	../fat/%.c | obj/fat
	$(CC) $(CCFLAGS) -S -o $(@:.o=.s) $<
	$(CC) $(CCFLAGS) -c -o $@ $<

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

obj/lib/%.o:	../lib/%.c | obj/lib
	$(CC) $(CCFLAGS) -S -o $(@:.o=.s) $<
	$(CC) $(CCFLAGS) -c -o $@ $<

obj/mmu/%.o:	../mmu/%.s | obj/mmu
	$(AS) $(AS3FLAGS) -a=$(@:.o=.lst) -o $@ $<

# --------------------------------------------------------------------------------
# M68030 CPM Boot Loader
# --------------------------------------------------------------------------------
obj/main.o: ../main.s | obj
	cat $< | sed "s/__BUILD-DATE__/$$(date '+%Y-%m-%d %H:%M:%S')/" > $(@:.o=.as)
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $(@:.o=.as)

# --------------------------------------------------------------------------------
# Propellor console - 16MB + Flash
# --------------------------------------------------------------------------------
obj/boot30-16mb-flash.srec: boot-16mb-flash.lnk obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS))
	$(LD) $(LDFLAGS) -T boot-16mb-flash.lnk obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS)) $(LIBS) -Map $(@:.srec=.map) -o $@

target/boot30-16mb-flash.srec: obj/boot30-16mb-flash.srec | target
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K 68030 16MB+Flash Boot Loader" -o $@
	srec_info $@

# --------------------------------------------------------------------------------
# Propellor console - 16MB
# --------------------------------------------------------------------------------
obj/boot30-16mb.srec: boot-16mb.lnk obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS))
	$(LD) $(LDFLAGS) -T boot-16mb.lnk obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS)) $(LIBS) -Map $(@:.srec=.map) -o $@

target/boot30-16mb.srec: obj/boot30-16mb.srec | target
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K 68030 16MB Boot Loader" -o $@
	srec_info $@

# --------------------------------------------------------------------------------
# Propellor console - 4MB
# --------------------------------------------------------------------------------
obj/boot30-4mb.srec: boot-4mb.lnk obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS))
	$(LD) $(LDFLAGS) -T boot-4mb.lnk obj/main.o $(filter-out obj/io/cpro-ss1.o, $(OBS)) $(LIBS) -Map $(@:.srec=.map) -o $@

target/boot30-4mb.srec: obj/boot30-4mb.srec | target
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K 68030 4MB Boot Loader" -o $@
	srec_info $@

# --------------------------------------------------------------------------------
# SS1 console - 16MB
# --------------------------------------------------------------------------------
obj/boot30-ss1.srec: boot-16mb.lnk obj/main.o $(filter-out obj/io/propellor.o, $(OBS))
	$(LD) $(LDFLAGS) -T boot-16mb.lnk obj/main.o $(filter-out obj/io/propellor.o, $(OBS)) $(LIBS) -Map $(@:.srec=.map) -o $@

target/boot30-ss1.srec: obj/boot30-ss1.srec | target
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K 68030 16MB Boot Loader - CompuPro SS1" -o $@
	srec_info $@

# --------------------------------------------------------------------------------
# Housekeeping
# --------------------------------------------------------------------------------
clean:
	rm -rf obj/* target/*

obj:
	mkdir -p $@

obj/io: obj
	mkdir -p $@

obj/fat: obj
	mkdir -p $@

obj/disk: obj
	mkdir -p $@

obj/lib: obj
	mkdir -p $@

obj/bios: obj
	mkdir -p $@

obj/mmu: obj
	mkdir -p $@

target:
	mkdir -p $@


