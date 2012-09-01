section .bss
	$buf2	resb	2
	$bt	resb	4

section .text
	global _exit, _mainCRTStartup, prints, readb
	extern _GetStdHandle@4, _WriteFile@20, _ReadFile@20, _ExitProcess@4
	extern _GetCommandLineA@0, strlen, _env, _main

prints:
	push	dword 0
	push	dword $bt
	push	dword [esp+12]		; pushd 'prints' first argument
	call	strlen
	pop	edx	; save string
	push	eax	; push length
	push	edx	; push the string back in correct order
	push	dword -11
	call	_GetStdHandle@4	; do not pop args: stdcall
	push	eax
	call	_WriteFile@20	; stdcall
	ret

readb:
	push	ebx
	push	ecx
	push	edx
	push	dword -10
	call	_GetStdHandle@4	; do not pop args: stdcall
	push	dword 0
	push	dword $bt
	push	dword 1
	push	dword $buf2
	push	eax
	call	_ReadFile@20	; stdcall
	xor	eax, eax
	mov	al, [$buf2]
	pop	edx
	pop	ecx
	pop	ebx
	ret

_exit:
	push	dword [esp+4]
	call	_ExitProcess@4
	jmp	_exit

_mainCRTStartup:	
	call	_GetCommandLineA@0
	mov	esi, eax	; str
	mov	edx, esi	; s
	xor	ecx, ecx	; argc
	push	dword 0		; NULL pointer for envp
	mov	edi, esp
	push	dword 0		; NULL pointer for argv[argc]
.args0:	mov	al, [edx]	; while (*s != 0) s++;
	test	al, al
	je	.args1
	inc	edx
	jmp	.args0
.args1:	cmp	edx, esi	; while (s >= str & *s != ' ') s--;
	jl	.args2
	mov	al, [edx]
	cmp	al, 0x20
	je	.args2
	dec	edx
	jmp	.args1
.args2:	mov	eax, 1		; *sp-- = s+1;
	add	eax, edx
	push	eax
	inc	ecx		; argc++;
	mov	al, [edx]	; if (*s == ' ') *s = 0;
	cmp	al, 0x20
	jne	.args3
	mov	[edx], byte 0
.args3:	dec	edx		; while (--s >= str && *s == ' ') ;
	cmp	edx, esi
	jl	.args4
	mov	al, [edx]
	cmp	al, 0x20
	je	.args3
.args4:	cmp	edx, esi	; } while (s >= str);
	jge	.args1
	inc	edx
	mov	ebx, esp
	push	ecx		; argc
	mov	[_env], esp
	push	edi		; envp
	push	ebx		; argv
	push	ecx		; argc
; _start:
	call	_main
	push	eax
	call	_exit
