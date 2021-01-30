SUBDIRS := boot bios cpmfs

clean all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
	
.PHONY: clean all $(SUBDIRS)