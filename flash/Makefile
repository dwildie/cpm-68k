AS       = m68k-elf-as
ASFLAGS += -m68010
ASFLAGS += -alms
ASFLAGS += -I../
ASFLAGS += --defsym IS_68030=1

CC      = m68k-elf-gcc
CFLAGS  =  -Wall -Werror -Wpedantic -O3 -ffreestanding -nostartfiles
CFLAGS += -m68010
CFLAGS += -Wno-unused-function
CFLAGS += -Isrc/include
CFLAGS += -I../baselibc/include
#CFLAGS += -DZDEBUG=1
#CFLAGS += -DZTRACE=1

LD       =  m68k-elf-ld
LDFLAGS += -s --no-relax
LDFLAGS += -L../baselibc/target
LDFLAGS += -L/usr/local/lib/gcc/m68k-elf/12.1.0/m68000
LIBS    += -lc
LIBS    += -lgcc

OBJFILES=obj/main.o obj/console-io.o

all:	target/flash.srec target/flash

target/flash: obj/crt0.o $(OBJFILES) | target
	$(LD) $(LDFLAGS) -T flash-elf.lnk obj/crt0.o $(OBJFILES) $(LIBS) -Map $@.map -o $@

target/flash.srec: target/flash
	objcopy -O srec $< $@

obj/%.o: src/%.s | obj
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/%.o: src/%.c | obj
	$(CC) $(CFLAGS) -DZEMBEDDED -c -o $@ $<

obj:
	mkdir -p $@

target:
	mkdir -p $@

clean:
	rm -rf obj target

