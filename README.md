## Coco3 Bootstrap Rom
### A Color Computer 3 rom file for booting Nitros9

This project creates a bootstrap rom to replace disk11 rom. The bootstrap rom contains the first stage bootstrap for Nitros9, aka the boottrack.  The intended use of the rom is for booting Nitros9 in an emulator environment but there should be no reason on could not burn a physical ROM that would work if so desired.  It's use eliminates the need for a boottrack on the floppy or other media. Floppy, hard disk, or other media access is still available using Nitros9 drivers. As long as the second stage boot file (OS9Boot) is intact and the bootstrap rom can find it the boot can proceed.

### Some detail about the Nitros9 booting process

The first two bytes of the Nitros9 boottrack is the string "OS" followed by the bootstrap code. To boot Nitros9 from floppy DECB (Disk Extended Color Basic) needs only to copy the boottrack to $2600 and then jump to $2602.

Within the $1200 (4608) byte first stage bootstrap are the Nitros9 modules REL, KRN, and BOOT arranged as follows:

```
    REL  0000 - 012F   $130 bytes (304)
    BOOT 0130 - 02ff   $1D0 bytes (464)
    KRN  0300 - 11FF   $FOO bytes (3840)
```

REL is executed first. It moves the bootstrap modules to high ram, and prints 'NITROS9 BOOT' or 'NITROS 6309' on the screen. REL then calls KRN init.  KRN init places a 'K' on screen, sets up the system, and validates the REL, BOOT, and KRN modules, printing their names as it does.  KRN init then calls F$Boot which puts a 't' on the screen, links the BOOT module, and then calls it. BOOT locates the second stage bootstrap and loads and validates it's modules. The second stage bootstrap contains KRNp2 and all required system modules. The kernel then locates and executes sysgo or a third stage kernel to start user processes.

On disk the second stage bootstrap typically resides in the OS9boot file but it's name is not important to the booting process.  BOOT finds it by examining logical sector zero (LSN0) on the disk.  LSN0 contains two fields of importance to the boot process, DD.BT and DD.BSZ.

```
    DD.BT  locates the second stage bootstrap file.
    DD.BSZ is the size of the bootstrap file if it is contigious.
```

If DD.BSZ is non zero it is assumed that OS9Boot is contigious and DD.BT is the sector it starts on. A Nitros9 enhancement permits the use of a non-contigious OS9Boot file - If DD.BSZ is zero then DD.BT points to the sector containing the OS9Boot file's descriptor instead of the file it'self. The file descriptor contains a null terminated list of segments containing OS9Boot. The segment list contains up to 48 entries containing the size and location of each file segment.

Since the target of this project is the virtual environment a BOOT that works with virtual harddrives is desired. A early step was to improve the booter for virtual harddrives. Robert Gault wrote a vhd booter called boot_vhd to use for with the very nice RGBDOS system which allows a vhd to contain 255 virtual floppies as well as contain a complete OS9/Nitros9 system. That booter is used to boot Os9 and Nitros9 from RGBDOS virtual hard drives and works well for that purpose.  It's source is in the nitros9 third party section. However it can not boot non-contigous OS9Boot files.

The ability to boot from a non-contiguous OS9Boot greatly simplifies the process of modifying it and the Nitros9 Ease Of Use Project relies on this capability to allow use of it's swapboot utility.  So I created boot_emu, a vhd booter that can deal with non-contigous boot files.  All the hard lifting for dealing with the segment list was already done, the only part I needed to write was initializing and reading a vhd sector.  I was able to add boot_emu to the Nitros9 project and source for it is available on that project's github.

### Creating the bootstrap rom

I created a boottrack file by combining my desired REL, BOOT, and KRN from Nitros9: (My work was done on linux and examples are linux shell commands)

```
   cat rel_80_3309 boot_emu krn_6309 > boottrack
```

Next I created a ROM containing the bootstrap that could be loaded as a VCC cart.  I wrote a tiny bit of 6309 code, assembled it with lwasm and appended the boot modules to the result:

bootstrap.asm:
```
    org $C000
    ldu #boottrk  ; where bootrack is in ROM
    ldy #$2600    ; where it goes in low RAM
    ldw #$1200    ; bytes to copy
    tfm u+,y+     ; do the copy
    jmp $2602     ; Run the booter
  boottrk         ; Boot modules go here
    end
```

To create the ROM:

```
    lwasm --raw -o bootstrap bootstrap.asm
    cat bootstrap rel_80_3309 boot_emu krn_6309 > bootstrap.rom
```
I also created an OS9Boot file that contains the emudsk module to read virtual disks, used clock2_cloud9 for the clock2 module, and set the DD descriptor to the first hard drive.

This worked when used as a standalone rom cart on VCC and also on MAME.  I prettied up the code by adding some directives for 6809 and nice comments.   I had intended to the bootstrap.rom instead of disk11.rom as the external rom for the FD502 cart so I did not burn an extra MMI slot just to boot Nitros9.  When I tried that it did not work.

I soon realized that DECB was ignoring my boot.rom because there was no 'DK' at it's start. When I added a 'DK' the real fun began. Nitros would sort of try to boot but would crash with various colorful patterns on the screen.

I knew the bootstrap image was being trashed somehow but I was not sure where or how so I created a dummy bootstrap containing only text and added a break (lwasm emuext opcode) to my program before it copied the modules to $2600. When I examined my dummy text in memory I discovered the bootstrap was being trashed before my program ran. I should have realized that Super Extended Basic had already moved the rom to ram and modified it. The fix was simple - set the gime to ROM mode before copying the bootstrap:

```
  lda #$CC       ; Tell GIME to
  sta $FF90      ; map 16k external
  clr $FFDE      ; Switch to ROM mode.
```

The finalized source and makefile is provided here.
