DIR_TARGET	    := target
CPM_SOURCE	    := cpm_1_3
CPM_ZIP         := 68kv1_3.zip
CMDS		    := ./cmds
BIOS_FILE       := ../bios/target/bios.srec
BOOT_FILE       := $(DIR_TARGET)/boot400.sr
BOOT_START_ADDR := 0x400
BOOT_HEADER     := "CP/M 68K S100 V0.0.1"

MD    := mkdir
RM    := rm
SHELL := sh

all: $(DIR_TARGET)/disk1.img $(DIR_TARGET)/disk10.img

clean:
	$(RM) -rf $(DIR_TARGET)/*

$(DIR_TARGET)/disk1.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1 $(BOOT_FILE)
	$(SHELL) $(CMDS)/formatImage.sh $@ 1
	$(SHELL) $(CMDS)/copyDisks.sh $@ 1 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)

$(DIR_TARGET)/disk10.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1 $(BOOT_FILE)
	$(SHELL) $(CMDS)/formatImage.sh $@ 10
	$(SHELL) $(CMDS)/copyDisks.sh $@ 10 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)

$(DIR_TARGET)/diskAll.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1 $(BOOT_FILE)
	$(SHELL) $(CMDS)/formatImage.sh $@ 10
	$(SHELL) $(CMDS)/copyAll.sh $@ 0 10 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)

$(BOOT_FILE): $(BIOS_FILE) $(DIR_TARGET)/cpm400.sr
	cat $(DIR_TARGET)/cpm400.sr | sed -n '/\x1a/q;p' | grep -v "^S9" | srec_cat $(BIOS_FILE) - -header $(BOOT_HEADER) -execution-start-address=$(BOOT_START_ADDR) > $@
	unix2dos $@

$(DIR_TARGET)/cpm400.sr: $(CPM_SOURCE)/DISK9/CPM400.SR
	cat $< | sed -e 's/S12304606000/S12304606200/' | sed -e 's/00010000F5/00010000F3/' > $@
	
$(CPM_SOURCE)/DISK1: $(CPM_SOURCE)/$(CPM_ZIP)
	cd $(CPM_SOURCE); unzip -q -o $(CPM_ZIP)

$(CPM_SOURCE)/$(CPM_ZIP): $(CPM_SOURCE)
	wget -P $(CPM_SOURCE) http://cpm.z80.de/download/$(CPM_ZIP) 

#$(CPM_SOURCE):
#	$(MD) -p $(CPM_SOURCE)
#
#$(DIR_TARGET):
#	$(MD) -p $(DIR_TARGET)
