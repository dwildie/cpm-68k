AS       = m68k-elf-as
ASFLAGS += -m68000
ASFLAGS += --defsym _GNU_=1
ASFLAGS += --defsym _CPM_=0
ASFLAGS += -alms

CC       = m68k-elf-gcc
CCFLAGS += -Wall
CCFLAGS += -m68000
#CCFLAGS += -ggdb
CCFLAGS += -nostdlib
CCFLAGS += -nodefaultlibs

LD       = m68k-elf-ld

all: target/bios.srec obj/ldr.srec target/btstrap.s target/ldbios.s target/bios.s target/buffer.s target/biosend.s

%.s:	%.c
	$(CC) $(CCFLAGS) -S $<

# --------------------------------------------------------------------------------
# M68K CPM Bios
# --------------------------------------------------------------------------------
obj/%.o: %.s
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/bios.srec: obj/bios.o obj/buffer.o obj/biosend.o
	$(LD) -T bios.lnk obj/bios.o obj/buffer.o -Map $(@:.srec=.map) -o $@

obj/ldr.srec: obj/btstrap.o obj/ldbios.o

target/bios.srec: obj/bios.srec
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K S100 V0.1.0 Bios" -o $@
	srec_info $@

target/%.s: %.s
	cat cpm_defs.s $< | sed -e 's/\.include\s*"\(.*\)"/include(`\1'"'"')/' \
	       | m4 \
	       | sed -e 's/^\*.*//' -e 's/^\(.*\)=\s*\(.*\)/\1 equ \2/' -e 's/.global/globl/' \
	       | sed -e 's/.word/DC.W/' -e 's/.byte/DC.B/' -e 's/.long/DC.L/' -e 's/\%D/D/g' \
	       | sed -e 's/\%A/A/g' -e 's/\%SP/SP/' -e 's/\%FP/FP/' -e 's/\.ascii/DC.B/' \
	       | sed -e 's/0[xX]/$$/g' -e 's/\.ifne/ifne/' -e 's/\.endif/endc/' > $@
	unix2dos $@

clean:
	rm -rf obj/* target/*
	mkdir -p obj target


