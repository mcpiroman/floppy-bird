org 7C00h
bits 16
cpu 186

jmp short Start

db "FlopBird"    ; OEM String
dw  0x200        ; bytes per sector
db  1            ; sectors per cluster
dw  1            ; ;of reserved sectors
db  2            ; ;of FAT copies
dw  224          ; size of root directory
dw  2880         ; total # of sectors if over 32 MB
db  0xF0         ; media Descriptor
dw  9            ; size of each FAT
dw  9            ; sectors per track
dw  2            ; number of read-write heads
dd  0            ; number of hidden sectors
dd  0            ; ; sectors for over 32 MB
db  0            ; holds drive that the boot sector came from
db  0            ; reserved, empty
db  0x29         ; extended boot sector signature
db "seri"        ; disk serial
db "Floppy Bird" ; volume label
db "FAT16   "    ; file system type

%define STACK_BASE_ADDR 1000h
%define PROGRAM_LOAD_ADDR 1000h
%define SEGMENTS_TO_LOAD 4

startMsg db "Starting loader", 0
jumpingToProgramMsg db "Jumping to program..", 0
programLoadFailedMsg db "Program load failed", 0
currentDrive db 0

Start:
	jmp 0000:Start2
Start2:
	cli
	xor ax, ax
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	sti
	cld
	mov [currentDrive], dl
	mov bp, STACK_BASE_ADDR
	mov sp, STACK_BASE_ADDR
	
	mov bh, al		; page 0
	mov bl, 0Fh		; color 15 (white)
	mov dl, al		; DL - cursor x
	mov dh, al      ; DH - cursor y
	
	mov ax, startMsg
	call printString
	
	push bx
	push dx		
	mov ah, 2
	mov al, SEGMENTS_TO_LOAD
	xor ch, ch
	mov cl, 2
	xor dh, dh
	mov dl, [currentDrive]
	mov bx, PROGRAM_LOAD_ADDR
	int 0x13
	pop dx
	pop bx	
	jc short LoadFailature

	inc dh
	xor dl, dl
	mov ax, jumpingToProgramMsg
	call printString
	inc dh
	
	mov dl, [currentDrive]
	; dh - cursor y
	jmp PROGRAM_LOAD_ADDR
	
LoadFailature:	
	inc dh
	xor dl, dl
	mov ax, programLoadFailedMsg
	call printString
	
	IdleLoop:
	hlt
	jmp IdleLoop
	
%include "commonSubroutines.nasm"
 
times 200h - 2 - ($ - $$) db 0 ; zerofill up to 510 bytes
dw 0AA55h ; Boot Sector signature