# Need to know where the modules are
ifndef NITROS9DIR
NITROS9DIR  = $(HOME)/git/nitros9
endif

ROMOPTS = -D DISKROM=1 -D H6309=1 -D DEBUG=0

# Adjust boot targets here
REL  = $(NITROS9DIR)/level2/coco3_6309/modules/rel_80
BOOT = $(NITROS9DIR)/level2/coco3_6309/modules/boot_emu
KRN  = $(NITROS9DIR)/level2/coco3_6309/modules/krn

# NOTE: You may have to add boot_emu to the BOOTERS target
#       in $(NITROS9DIR)/level2/coco3/modules/makefile

all: bootstrap.rom

clean:
	@rm -f bootstrap bootstrap.rom

bootstrap: bootstrap.asm
	lwasm $(ROMOPTS) --raw -o$@ $< 

bootstrap.rom: bootstrap $(REL) $(BOOT) $(KRN)
	cat $^ > $@
	truncate -s 8192 bootstrap.rom
