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

all: target/bios4MB.srec target/bios16MB.srec obj/ldr.srec target/ldbios.s target/bios4MB.s target/bios16MB.s target/buffer.s

%.s:	%.c
	$(CC) $(CCFLAGS) -S $<

# --------------------------------------------------------------------------------
# M68K CPM Bios
# --------------------------------------------------------------------------------
obj/%.o: %.s | obj
	$(AS) $(ASFLAGS) -a=$(@:.o=.lst) -o $@ $<

obj/bios4MB.srec: obj/bios.o obj/tpa4MB.o obj/diskdefs.o obj/buffer.o | obj
	$(LD) -T bios4MB.lnk $^ -Map $(@:.srec=.map) -o $@

obj/bios16MB.srec: obj/bios.o obj/tpa16MB.o obj/diskdefs.o obj/buffer.o | obj
	$(LD) -T bios16MB.lnk $^ -Map $(@:.srec=.map) -o $@

obj/ldr.srec: obj/ldbios.o | obj

target/bios4MB.srec: obj/bios4MB.srec | target
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K S100 V0.1.1.R3 4MB BIOS" -o $@
	srec_info $@

target/bios16MB.srec: obj/bios16MB.srec | target
	srec_cat $< -fill 0x00 -over $< -header="CP/M-68K S100 V0.1.1.R3 16MB BIOS" -o $@
	srec_info $@

obj/bios4MB.s: bios.s tpa4MB.s diskdefs.s | obj
	cat $^ > $@
	
obj/bios16MB.s: bios.s tpa16MB.s diskdefs.s | obj
	cat $^ > $@
	
# Convert source files from gas format to the CP/M-68k assemblers format
target/%.s: obj/%.s | target
	cat cpm_defs.s $< | sed -e 's/\.include\s*"\(.*\)"/include(`\1'"'"')/' \
	       | m4 \
	       | sed -e 's/^\*.*//' -e 's/^\(.*\)=\s*\(.*\)/\1 equ \2/' -e 's/.global/globl/' \
	       | sed -e 's/.word/DC.W/' -e 's/.byte/DC.B/' -e 's/.long/DC.L/' -e 's/\%D/D/g' \
	       | sed -e 's/\%A/A/g' -e 's/\%SP/SP/' -e 's/\%FP/FP/' -e 's/\.ascii/DC.B/' \
	       | sed -e 's/0[xX]/$$/g' -e 's/\.ifne/ifne/' -e 's/\.endif/endc/' > $@
	unix2dos $@
	
target/%.s: %.s | target
	cat cpm_defs.s $< | sed -e 's/\.include\s*"\(.*\)"/include(`\1'"'"')/' \
	       | m4 \
	       | sed -e 's/^\*.*//' -e 's/^\(.*\)=\s*\(.*\)/\1 equ \2/' -e 's/.global/globl/' \
	       | sed -e 's/.word/DC.W/' -e 's/.byte/DC.B/' -e 's/.long/DC.L/' -e 's/\%D/D/g' \
	       | sed -e 's/\%A/A/g' -e 's/\%SP/SP/' -e 's/\%FP/FP/' -e 's/\.ascii/DC.B/' \
	       | sed -e 's/0[xX]/$$/g' -e 's/\.ifne/ifne/' -e 's/\.endif/endc/' > $@
	unix2dos $@

clean:
	rm -rf obj/* target/*

obj:
	mkdir -p $@

target:
	mkdir -p $@

