## Coco3 Bootstrap Rom
## A Color Computer 3 rom file for booting Nitros9

This project is to create a bootstrap.rom that contains the first stage bootstrap for Nitros9.  The intended use of the rom is for booting Nitros9 in an emulator environment but there should be no reason on could not burn a physical ROM that would work if so desired.

A Nitros9 stage one bootstrap contains the modules REL, BOOT, and KRN and is often refered to as the "boottrack" because it normally resides on track 34 of a bootable Os9 disk.  Typically Nitros9 is booted by typing the "DOS" command from Disk Extended Color Basic. The 'DOS' command then reads the boottrack from the floppy disk and executes it.

Disk Extended Color Basic (DECB) is in a rom within the FD502 Floppy Disk Controller. This project would replace that rom in the emulation environment with a simple Nitros9 booter. This would eliminate the need for a boot floppy or it's emulated equivalent. It would also simplify system configuration by eliminating the need for a disk to contain the bootstrap. Floppy and hard disk access would still be available using Nitros9 drivers. As long as the second stage boot file (Os9Boot) is intact and the bootstrap can find it the boot can proceed.

# Some detail about the Nitros9 booting process

The first two bytes of the Nitros9 boottrack is the string "OS" followed by the bootstrap code. To boot Nitros9 from disk DECB needs only to copy the boottrack to $2600 and then jump to $2602.

Within the $1200 (4608) byte first stage bootstrap are the Nitros9 modules REL, KRN, and BOOT arranged as follows:

`
    REL  0000 - 012F   $130 bytes (304)
    BOOT 0130 - 02ff   $1D0 bytes (464)
    KRN  0300 - 11FF   $FOO bytes (3840)
`

REL is executed first. It moves the bootstrap modules to high ram, and prints 'NITROS9 BOOT' or 'NITROS 6309' on the screen. REL then calls KRN init.  KRN init places a 'K' on screen, sets up the system, and validates the REL, BOOT, and KRN modules, printing their names as it does.  KRN init then calls F$Boot which puts a 't' on the screen, links the BOOT module, and then calls it. BOOT locates the second stage bootstrap and loads and validates it's modules. The second stage bootstrap contains KRNp2 and all required system modules. The kernel then locates and executes sysgo to start user processes.

On disk the second stage bootstrap typically resides in the OS9boot file but it's name is not important to the booting process.  BOOT finds it by examining logical sector zero (LSN0) on the disk.  LSN0 contains two fields of importance to the boot process, DD.BT and DD.BSZ.

`
    DD.BT  locates the second stage bootstrap file.
    DD.BSZ is the size of the bootstrap file if it is contigious.
`

If DD.BSZ is non zero it is assumed that Os9Boot is contigious and DD.BT is the sector it starts on. A Nitros9 enhancement permits the use of a non-contigious OS9Boot file - If DD.BSZ is zero then DD.BT points to the sector containing the Os9Boot file's descriptor instead of the file it'self. The file descriptor contains a null terminated list of segments containing OS9Boot. The segment list contains up to 48 entries containing the size and location of each file segment.

Since the target of this project is the virtual environment a BOOT that works with virtual harddrives is desired. A early step was to improve the booter for virtual hardrives. Robert Gault wrote a vhd booter called boot_vhd to use for with the very nice RGBDOS system which allows a vhd to contain 255 virtual floppies as well as contain a complete OS9/Nitros9 system. That booter is used to boot Os9 and Nitros9 from RGBDOS virtual hard drives and works well for that purpose.  It's source is in the nitros9 third party section. However it can not boot non-contigous Os9Boot files.

The ability to boot from a non-contiguous OS9Boot greatly simplifies the process of modifying it and the Nitros9 Ease Of Use Project relies on this capability to allow use of it's swapboot utility.  So I created boot_emu, a vhd booter that can deal with non-contigous boot files.  All the hard lifting for dealing with the segment list was already done, the only part I needed to write was initializing and reading a vhd sector.  I was able to add boot_emu to the Nitros9 project and source for it is available on gitbub.

# Creating the bootstrap rom

I created a boottrack file by combining my desired REL, BOOT, and KRN from Nitros9: (My work was done on WSL and examples are linux shell commands)

`
   cat rel_80_3309 boot_emu krn_6309 > boottrack
`

Next was a proof of concept - to put the boottrack in a Coco bin file that will load and boot Nitros9. Coco bin files consist of one or more segments followed by a terminator segment. They have a 5 byte header:

`
   byte len    description
     0   1   type (0 or 255)
     1   2   length
     3   2   address  
`

If the segment type is zero the segment is data. DECB will move it to the specified address. If the type is 255 the segment is a terminatoor and the address is the execution address.  To convert the boottrack file to a coco binary all that is needed is to prepend a 5 byte header and a 5 byte trailer to it:

`
   echo 00 12 00 26 00 | xxd -r -p > emuboot.bin  # $1200 bytes at $2600
   cat boottrack >> emuboot.bin                   # boot modules go here
   echo ff 00 00 26 02 | xxd -r -p >> emuboot.bin # execute at $2602
`

This creates a emuboot.bin that VCC will load and execute using it's quickload feature.  In the process of testing I discovered that OS9Boot must contain the emudsk module to actually read from virtual hard drives.  I also had to switch clock2 with clock2_cloud9 to use the clock in harddisk.dll. I used EOU swapboot to change Os9boot. The ability to handle non-contigous OS9Boot file came in handy right off the bat!

The next step was to try to create a ROM with my proven to work bootstrap. This initially proved to be quite simple. I wrote a tiny bit of 6309 code, assembled it with lwasm and tacked the boottrack on to the result:

The code (bootstrap.asm):
`
    org $C000
    ldu #boottrk  ; where bootrack is in ROM
    ldy #$2600    ; where it goes in low RAM
    ldw #$1200    ; bytes to copy
    tfm u+,y+     ; do the copy
    jmp $2602     ; Run the booter
  boottrk         ; Boot modules go here
`

To create the ROM:

`
    lwasm --raw -o bootstrap bootstrap.asm
    cat bootstrap rel_80_3309 boot_emu krn_6309 > bootstrap.rom
`

This worked when used as a standalone rom cart on VCC and also on MAME.  I prettied up the code by adding some directives for 6809 and nice comments and I thought I was done.  But I was not.  I had wanted to use boot.rom instead of disk11.rom as the external rom for the FD502 cart so I did not burn an extra MMI slot just to boot Nitros9.  When I tried that it did not work.

This began some frustration trying to understand why. I soon realized that Extended Color Basic was ignoring my boot.rom because there was no 'DK' at it's start. When I added a 'DK' the real fun began. Nitros would sort of try to boot but would crash with various colorful patterns on the screen.

I knew the bootstrap image was being trashed somehow but I was not sure where or how so I created a dummy bootstrap containing only text and added a break (lwasm emuext opcode) to my program before it copied the modules to $2600. When I examined my dummy text in memory I discovered the bootstrap was being trashed before my program ran. I should have realized that Super Extended Basic had already moved the rom to ram and modified it. The fix was simple - set the gime to ROM mode before copying the bootstrap:

`
  lda #$CC       ; Tell GIME to
  sta $FF90      ; map 16k external
  clr $FFDE      ; Switch to ROM mode.
`


