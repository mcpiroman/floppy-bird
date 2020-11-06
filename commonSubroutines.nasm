
; args: al = char, bl = attibute, bh = page, dl = cursor x, dh = cursor y
; invalidates: ah, cx
PrintChar:
	mov cx, 1
	mov ah, 2
	int 10h	
	mov ah, 9	
	int 10h	
	inc dl			
	ret

; args: ax = address to string, bl = attibute, bh = page, dl = cursor x, dh = cursor y
; invalidates: ax, cx, si
PrintString:
	push dx
	mov si, ax
	mov cx, 1
	.loop:
	mov al, [si]
	
	test al, al
	jz .end
	
	cmp al, `\n`
	jne .writableChar
	inc dh
	mov dl, [bp-4]
	inc si
	jmp .loop
	
	.writableChar:
	mov ah, 2
	int 10h	
	mov ah, 9
	int 10h	
	inc dl			
	inc si
	jmp .loop
	
	.end:
	pop dx
	ret

; args: al = number to print, bl = attibute, bh = page, dl = cursor x, dh = cursor y
; invalidates: ax, cx
PrintNumDec:	
	test al, al
	jnz .print_ax
	push ax
	mov al, '0'	
	mov ah, 2
	int 10h
	mov cx, 1
	mov ah, 9
	int 10h	
	inc dl
	pop ax
	ret
	
	.print_ax:    
	push ax
	push cx
	mov ah, 0
	cmp ax, 0
	je .pn_done
	mov cl, 10
	div cl    
	call .print_ax
	mov al, ah
	add al, 30h	
	mov ah, 2
	int 10h
	push cx
	mov cx, 1
	mov ah, 9
	int 10h
	pop cx
	inc dl
	.pn_done:
	pop cx
	pop ax
	ret
	
; args: ax = number to print, bl = attibute, bh = page, dl = cursor x, dh = cursor y
PrintNumHex:
	push cx
	push si
	mov cx, ax
	rol cx, 4
	mov si, 3
	.loop:
	mov ah, 2
	int 10h
	mov al, cl	
	and al, 0Fh
	cmp al, 10
	jns .letter
	add al, '0'	
	jmp .print
	.letter:
	add al, ('A' - 10)
	.print:
	mov ah, 9
	push cx
	mov cx, 1	
	int 10h
	pop cx
	rol cx, 4
	inc dl
	dec si
	jns .loop
	pop si
	pop cx
	ret

; args: si, di
; invalidates: ax
Copy32:
	mov ax, [si]
	mov [di], ax
	mov ax, [si + 2]
	mov [di + 2], ax
	ret

; args: bh = color
ClearScreen:
	mov ah, 06h
	xor al, al
	xor cx, cx
	mov dh, 24
	mov dl, 79
	int 10h
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