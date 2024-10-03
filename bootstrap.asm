*----------------------------------------------------
* Emulator bootstrap rom for Coco3 NitrOS9.
*
* After assembly boottrack with boot_emu is appended.
*	lwasm --raw -o bootstrap bootstrap.asm
*   cat bootstrap boottrack > bootstrap.rom 
*   truncate -s 8192 bootstrap.rom
*
* E J Jaquay 2024.09.27
*----------------------------------------------------

 PRAGMA emuext

 org $C000

 fcc "DK"   	LSRA + illegal ins

* When Super Extended Basic sees a rom starting with "DK" it 
* is processed as a disk11 rom. Basic copies it to ram then 
* makes changes to it before jumping to $C002. We need to set 
* ROM mode to avoid those changes. With VCC a rom containg "DK"
* can still fail to boot if runing at less than 3 MHz when
* loaded as at standalone cart rather than an FD502 rom unless
* "AutoStart Cart" is unchecked in VCC's misc config dialog.
* Alternatly just create a ROM with no "DK" for standalone use.

start
 lda #$CC       Tell GIME to 
 sta $FF90      map 16k external
 clr $FFDE      Switch to ROM mode.

* Copy bootstrap containing REL, BOOT, and KRN to $2600.

 ldu #boottrack where the bootstrap modules are
 ldy #$2600     where they are copied to low RAM

 IFNE H6309
  ldw #$1200    bytes to copy
  tfm u+,y+
 ELSE
  ldx #$1200    bytes to copy
cpy ldd ,u++
  std ,y++
  leax -2,x
  bne cpy
 ENDC

* break

* Jump to start of REL. REL will relocate the modules to high
* memory where they will stay resident until system goes down.

 jmp $2602

boottrack

* Bootstrap modules REL, BOOT, and KRN will get appened here.

 end
