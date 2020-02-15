org 1000h
bits 16
cpu 486

jmp short Start

struc column
	.posX: resb 1
	.lowY: resb 1
	.highY: resb 1
endstruc

%define COLUMN_WIDTH 4
%define COLUMN_INTERVAL 25
%define MAX_VISIBLE_COLUMNS 10 ;(80 - 1 + COLUMN_WIDTH) / COLUMN_INTERVAL
%define FIRST_COLUMN_POS_X 70
%define GROUND_HEIGHT 4
%define COLUMN_TOP_MIN_Y 2
%define COLUMN_TOP_MAX_Y 16 - GROUND_HEIGHT

;=================================================================================
;=================================== Main code ===================================
;=================================================================================

Start:
	xor ax, ax
	mov bx, ax
	mov cx, ax
	mov [diskNum], dl
	mov dx, ax
	mov si, ax
	mov di, ax
	
	xor ah, ah ; set video mode to text 80x25
	mov al, 3
	int 10h
	
	mov ah, 00h ; seed rng
	int 1Ah
	mov [lastRandNum], dx	
	
	xor bh, bh
	call ClearScreen	
StartMenu:
	xor bh, bh
	call ClearScreen

	mov ax, szWelcomeToTheGame ; print welcome
	mov bl, 0Ch
	xor bh, bh
	mov dl, 28
	mov dh, 12
	call printString
	mov ax, szPressToPlay ; print press to play
	mov bl, 0Eh
	xor bh, bh
	mov dl, 28
	mov dh, 13
	call printString
	
	xor ah, ah ; wait for any key
	int 16h
	jmp StartGame
StartGame:
	mov eax, [playerStartY] ; set player pos and speed
	mov [playerY], eax
	mov eax, [playerStartYVel]
	mov [playerYVel], eax
	mov word [score], 0
	mov byte [collCnt], 0
	mov bl, FIRST_COLUMN_POS_X
	call SpawnColumn
	
	mov cx, 80 ; draw ground
	mov ah, 1
	mov al, '#'
	mov bl, 0Ah
	xor bh, bh
	xor dl, dl
	mov dh, 25 - GROUND_HEIGHT
	call FillRect
	mov bl, 06h
	mov ah, GROUND_HEIGHT - 1
	mov dh, 25 - GROUND_HEIGHT + 1
	call FillRect

.GameLoop:
	mov ah, 01h
	int 16h
	jz .noJump
	xor ah, ah
	int 16h ;TODO: check if this is the jump key
	mov eax, [jumpSpeed]
	mov [playerYVel], eax	
	.noJump:	
	fld dword [playerYVel] ; update velocity and y position
	fadd dword [gravityAcc]
	fld dword [playerVelFactor]
	fmulp st1
	fld dword [playerY]
	fadd st0, st1
	fstp dword [playerY]
	fstp dword [playerYVel]
	fld dword [playerY]
	frndint
	fistp word [playerYInt]
	
	cmp byte [playerYInt], 1 ; check if player is too high
	jns .yPositive
	mov dword [playerY], 0
	mov byte [playerYInt], 0
	.yPositive:
	
	mov ah, 06h ; clear screen
	xor al, al
	xor cx, cx
	mov dh, 24 - GROUND_HEIGHT
	mov dl, 79
	int 10h	
	
	xor dl, dl ; draw collumns. move colluns
	mov si, colls
	xor bh, bh
	mov al, 'X'
	.columnLoop:
		push dx
		xor dh, dh
		.printRowLoop:
			movzx cx, [columnWidth]
			mov dl, [si+column.posX]
			test dl, dl
			jns .xNotNeg
			add cl, dl 
			xor dl, dl
			.xNotNeg:
			mov bl, dl
			add bl, [columnWidth]
			sub bl, 80
			jng .widthOk
			sub cl, bl
			.widthOk:
			mov ah, 02h
			int 10h		
			mov ah, 09h
			mov bl, 0Dh
			int 10h
			inc dh
			cmp dh, [si+column.highY]
			je .lower
			cmp dh, 25 - GROUND_HEIGHT
			je .end
			jmp .printRowLoop
		.lower:
			mov dh, [si+column.lowY]
			jmp .printRowLoop
		.end:	
		pop dx
		dec byte [si+column.posX]
		add si, column_size
		inc dl
		cmp dl, [collCnt]
		jne .columnLoop
	
	mov al, column_size ; spawn new column if necessary
	mov ah, [collCnt]
	dec ah
	mul ah
	movzx di, al
	add di, colls
	mov al, 80
	sub al, [di+column.posX]
	cmp al, COLUMN_INTERVAL
	jne .noSpawn
	mov bl, 79 ; (79 - COLUMN_WIDTH)
	call SpawnColumn
	.noSpawn:
	
	mov al, 'B' ; draw player
	mov bl, 0fh
	xor bh, bh
	mov dl, [playerX]
	mov dh, [playerYInt]
	call printChar
	
	xor bh, bh ; draw score
	mov dl, 36
	xor dh, dh
	mov ax, szScore 
	mov bl, 0Eh
	call printString
	mov ax, [score] 
	mov bl, 0Eh
	xor bh, bh
	mov dl, 43
	xor dh, dh
	call printNumDec
	
	cmp byte [playerYInt], 25 - GROUND_HEIGHT ; check ground collision
	js .noGroundCollision
	jmp GameOver
	.noGroundCollision:
	
	cmp word [collCnt], 0 ; remove first column if off view. add score. check column collision
	je .noRemove
	mov al, [colls+column.posX]
	inc al
	cmp [playerX], al
	jl .noCollision
	add al, [columnWidth]	
	cmp [playerX], al
	jg .noCollision
	mov ah, [playerYInt]
	mov al, [colls+column.lowY]
	cmp ah, al
	jnl .collision
	mov al, [colls+column.highY]
	cmp ah, al
	jl .collision
	jmp .noCollision
	.collision:
	jmp GameOver
	.noCollision:
	mov al, [colls+column.posX]
	add al, [columnWidth]
	cmp al, [playerX]
	jne .noScore
	inc word [score]
	.noScore:
	test al, al
	jnz .noRemove
	dec byte [collCnt]
	cld
	mov si, colls
	add si, column_size
	mov di, colls	
	mov al, [collCnt]
	mov ah, column_size
	mul ah
	movzx cx, al
	rep movsb
	.noRemove:
	
	mov ah, 02h ; set cursor to bottom right
	xor bh, bh
	mov dl, 79
	mov dh, 24
	int 10h
	
	mov ah, 86h ; wait for next frame
	mov word dx, [updateInterval]
	mov word cx, [updateInterval+2]
	int 15h
	jmp .GameLoop
GameOver:
	mov cx, 11
	mov ah, 3
	mov al, ' '
	mov bl, 40h
	xor bh, bh
	mov dl, 35
	mov dh, 11
	call FillRect
	
	mov ax, szGameOver
	mov bl, 40h
	mov dl, 36
	mov dh, 12
	call printString
	
	mov ah, 86h ; FIXME: actually delay waiting for key press
	mov word dx, [restartDelay]
	mov word cx, [restartDelay+2]
	int 15h
	
	xor ah, ah ; wait for any key
	int 16h
	jmp StartGame
	
DeadLoop:
hlt
jmp DeadLoop


;=================================================================================
;================================== Subroutines ==================================
;=================================================================================

; args: bh = color
ClearScreen:
	mov ah, 06h
	xor al, al
	xor cx, cx
	mov dh, 24
	mov dl, 79
	int 10h
	ret	

; args: bl = x	
; invalidates: ax, bx, dx, di
SpawnColumn:
	mov al, column_size
	mov ah, [collCnt]
	mul ah
	movzx di, al
	add di, colls
	mov [di+column.posX], bl
	call NextRandomNum
	xor dx, dx
	mov bx, COLUMN_TOP_MAX_Y - COLUMN_TOP_MIN_Y
	div bx
	add dx, COLUMN_TOP_MIN_Y
	mov byte [di+column.highY], dl
	add dl, [columnSpaceHeight]
	mov byte [di+column.lowY], dl
	inc byte [collCnt]
	ret

; ret: ax = random number
NextRandomNum:
	mov ax, 25173          
    mul word [lastRandNum]
    add ax, 13849
    mov [lastRandNum], ax
    ret

; args: cx = width, ah = height, al = char, bl = color, bh = page, dl = x, dh = y
; invalidates: ah, dh, si
FillRect:
	push cx
	mov cl, dh
	add cl, ah
	mov si, sp
	.loop:
		mov ah, 02h
		int 10h
		mov ah, 09h
		xchg cx, [si]
		int 10h
		xchg cx, [si]
		inc dh
		cmp dh, cl
		jne .loop
	pop cx
	ret

;=================================================================================
;================================== Global data ==================================
;=================================================================================
	
szWelcomeToTheGame db "Welcome to Floppy Bird",0
szPressToPlay db "Press any key to play", 0
szScore db "Score: ",0
szGameOver db "GAME OVER", 0

diskNum db 0
consoleCoords dw 0
consoleAttr dw 0
lastRandNum dw 0

playerX db 15 ; const
playerY dd 0.0
playerYInt db 0
playerYVel dd 0.0
colls resb column_size * MAX_VISIBLE_COLUMNS
collCnt db 0
score dw 0

playerStartY dd 6.0
playerStartYVel dd -1.5
gravityAcc dd 0.38
jumpSpeed dd -2.4
playerVelFactor dd 0.975
columnWidth db COLUMN_WIDTH
columnSpaceHeight db 8
groundHeight db GROUND_HEIGHT

; VirtualBox sometimes appears to have messed up clock. If so, multiply values below by 4.
updateInterval dd 1_000_000 / 20
restartDelay dd 250_000

%include "commonSubroutines.nasm"
times 1200h - ($ - $$) db 0 ; take up 3 segments