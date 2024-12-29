
# ROM build options. See bootstrap.asm for their purpose
ROMOPTS = -D DISKROM=1 -D H6309=1 -D DEBUG=0

# Rom and nitros9 module paths. These can be adjusted to suit
BOOTROM = ./vccromdir/bootstrap.rom
MODDIR  = ./moduledir
REL  = $(MODDIR)/rel_80
BOOT = $(MODDIR)/boot_emu
KRN  = $(MODDIR)/krn

all: $(BOOTROM)

clean:
	rm -f bootstrap $(BOOTROM)
	make all

bootstrap: bootstrap.asm
	lwasm $(ROMOPTS) --raw -o$@ $< 

$(BOOTROM): bootstrap $(REL) $(BOOT) $(KRN)
	cat $^ > $@
	truncate -s 8192 $(BOOTROM)
