DIR_TARGET	    := target
SAMPLES_DIR     := samples
CPM_SOURCE	    := cpm_1_3
CPM_ZIP         := 68kv1_3.zip
CMDS		    := ./cmds
BIOS_DIR        := ../bios
BIOS_TARGET     := $(BIOS_DIR)/target
BIOS_SRC        := $(BIOS_TARGET)/bios.s $(BIOS_TARGET)/ldbios.s $(BIOS_TARGET)/buffer.s $(BIOS_DIR)/PUTBOOT.S
BIOS_SUB        := $(BIOS_DIR)/sub/*.sub
BIOS_FILE       := $(BIOS_DIR)/target/bios.srec
BOOT_FILE       := $(DIR_TARGET)/boot400.sr
BOOT_START_ADDR := 0x400
BOOT_HEADER     := $(shell srec_info $(BIOS_FILE) | grep "^Header:" | sed 's/^Header: "\(.*\)"/\1/')

MD    := mkdir
RM    := rm
SHELL := sh

all: $(DIR_TARGET)/disk1.img $(DIR_TARGET)/disk10.img $(DIR_TARGET)/diskBase.img $(DIR_TARGET)/diskAll.img $(DIR_TARGET)/drive_a.img $(DIR_TARGET)/drive_b.img $(DIR_TARGET)/drive_c.img $(DIR_TARGET)/drive_d.img

clean:
	$(RM) -rf $(DIR_TARGET)/*

$(DIR_TARGET)/disk1.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1 $(BOOT_FILE)
	$(SHELL) $(CMDS)/formatPartitionedImage.sh $@ 1
	$(SHELL) $(CMDS)/copyDisks.sh $@ 1 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)

$(DIR_TARGET)/disk10.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1 $(BOOT_FILE)
	$(SHELL) $(CMDS)/formatPartitionedImage.sh $@ 10
	$(SHELL) $(CMDS)/copyDisks.sh $@ 10 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)

# 10 partitions with full CP/M distribution copied to partition 0 and bios sources to partition 1
$(DIR_TARGET)/diskAll.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1 $(BOOT_FILE)
	$(SHELL) $(CMDS)/formatPartitionedImage.sh $@ 10
	$(SHELL) $(CMDS)/copyAll.sh $@ 0 10 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)
	$(SHELL) $(CMDS)/copyFiles.sh $@ 4mb-hd-1 $(BIOS_SRC) $(BIOS_SUB) $(SAMPLES_DIR)/*

# 10 partitions with curated CP/M distribution copied to partition 0 and bios sources to partition 1
$(DIR_TARGET)/diskBase.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1 $(BOOT_FILE)
	$(SHELL) $(CMDS)/formatPartitionedImage.sh $@ 10
	$(SHELL) $(CMDS)/copyBase.sh $@ 0 10 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)
	$(SHELL) $(CMDS)/copyFiles.sh $@ 4mb-hd-1 $(BIOS_SRC) $(BIOS_SUB) $(SAMPLES_DIR)/*

# 1 bootable partition with curated CP/M distribution copied to partition 0
$(DIR_TARGET)/drive_a.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1
	$(SHELL) $(CMDS)/formatImage.sh $@ 4mb-hd-0
	$(SHELL) $(CMDS)/copyBase.sh $@ 0 10 $(CPM_SOURCE)
	$(SHELL) $(CMDS)/installSystem.sh $@ $(BOOT_FILE)
	
# 1 partition with BIOS sources
$(DIR_TARGET)/drive_b.img: $(DIR_TARGET)
	$(SHELL) $(CMDS)/formatImage.sh $@ 4mb-hd
	$(SHELL) $(CMDS)/copyFiles.sh $@ 4mb-hd $(BIOS_SRC) $(BIOS_SUB)
	
# 1 empty partition
$(DIR_TARGET)/drive_c.img: $(DIR_TARGET)
	$(SHELL) $(CMDS)/formatImage.sh $@ 4mb-hd
	
# 1 partition with full CP/M distribution copied to partition 0
$(DIR_TARGET)/drive_d.img: $(DIR_TARGET) $(CPM_SOURCE)/DISK1
	$(SHELL) $(CMDS)/formatImage.sh $@ 4mb-hd
	$(SHELL) $(CMDS)/copyAll.sh $@ 0 10 $(CPM_SOURCE)
	
$(BOOT_FILE): $(BIOS_FILE) $(DIR_TARGET)/cpm400.sr
	cat $(DIR_TARGET)/cpm400.sr | sed -n '/\x1a/q;p' | grep -v "^S9" | srec_cat $(BIOS_FILE) - -header "$(BOOT_HEADER)" -execution-start-address=$(BOOT_START_ADDR) > $@
	unix2dos $@

$(DIR_TARGET)/cpm400.sr: $(CPM_SOURCE)/DISK9/CPM400.SR
	cat $< | sed -e 's/S12304606000/S12304606200/' | sed -e 's/00010000F5/00010000F3/' > $@
	
$(CPM_SOURCE)/DISK1: $(CPM_SOURCE)/$(CPM_ZIP)
	cd $(CPM_SOURCE); unzip -q -o $(CPM_ZIP)

$(CPM_SOURCE)/$(CPM_ZIP): | $(CPM_SOURCE)
	rm -rf $(CPM_SOURCE)/*
	wget -O $(CPM_SOURCE)/$(CPM_ZIP) http://cpm.z80.de/download/$(CPM_ZIP) 
	touch $(CPM_SOURCE)/$(CPM_ZIP)

$(CPM_SOURCE):
	mkdir -p $@
	
$(DIR_TARGET):
	mkdir -p $@
	
