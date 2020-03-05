SUBDIRS := boot bios cpmfs

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
	
.PHONY: all $(SUBDIRS)