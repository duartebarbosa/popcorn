BUFsiz	equ	32

section .data
	global _env
	$nl	db	10, 0
	$sp	db	32, 0
	$bufsiz	db	BUFsiz
	$_env	dd	0

section .bss
	$buffer	resb	BUFsiz

section .text
	global println, printsp, printi, readln, readi, debug
	global strlen, atoi, itoa, argc, argv, envp
	extern prints, readb

argc:	mov	eax, [_env]
	mov	eax, [eax]
	ret

argv:	mov	eax, [_env]
	add	eax, 4
	mov	ebx, [esp+4]
	lea	eax, [eax+ebx*4]
	mov	eax, [eax]
	ret

envp:	mov	ebx, [_env]
	mov	edx, [ebx]
	lea	eax, [ebx+edx*4]
	add	eax, 8	; argc+argv
	mov	ebx, [esp+4]
	lea	eax, [eax+ebx*4]
	mov	eax, [eax]
	ret

strlen:
	mov	edx, [esp+4]
	cmp	byte [edx], 0
	mov	eax, edx
	je	.Lend
.Lrep:	inc	eax
	cmp	byte [eax], 0
	jne	.Lrep
.Lend:	sub	eax, edx
	ret

println:
	push	dword $nl
	call	prints
	add	esp, 4
	ret

printsp:
	push	dword $sp
.Lmais:	;cmp	dword [esp+8], 0
	mov	eax, [esp+8]
	cmp	eax, 0
	jle	.Lfim
	call	prints
	dec	dword [esp+8]
	jmp	.Lmais
.Lfim:	add	esp, 4
	ret

debug:	ret

itoa:
	mov	ecx, [esp+4]	; load arg
	mov	edi, $buffer+15
	mov	esi, 0
	test	ecx, ecx
	jge	.L8
	inc	esi
	neg	ecx
.L8:	mov	[edi], byte 0	; put the NULL character and walk backwards
	dec	edi
	mov	ebx, 10
.L9:	mov	eax, ecx
	xor	edx, edx
	div	ebx
	mov	ecx, eax
	add	edx, byte '0'
	mov	[edi], dl
	dec	edi
	test	ecx, ecx
	jg	.L9
	test	esi, esi
	je	.L10
	mov	[edi], byte '-'
	dec	edi
.L10:	mov	eax, edi
	inc	eax
	ret

printi:
	push	dword [esp+4]
	call	itoa
	add	esp, 4
	push	eax
	call	prints
	add	esp, 4
	ret

atoi:
	mov	esi, [esp+4]
	mov	ecx, 1
	xor	ebx, ebx
	xor	eax, eax
	cld
	lodsb
	cmp	eax, '-'
	jne	.L1
	neg	ecx
	lodsb
.L1:	cmp	eax, '0'
	jb	.L2
	cmp	eax, '9'
	ja	.L2
	sub	eax, '0'
	xchg	ebx, eax
	mov	edx, 10
	mul	edx
	add	ebx, eax
	xor	eax, eax
	lodsb
	jmp	.L1
.L2:	mov	eax, ebx
	mul	ecx
	ret

readln:				; readln(buf, siz)
	mov	ecx, [esp+8]	;
	mov	edi, [esp+4]	;
	cld
_Lnext:	call	readb
	cmp	eax, 0
	jle	_Lerr
	cmp	eax, 10
	je	_Lend
	cmp	ecx, 1
	jle	_Lend
	stosb
	dec	ecx
	jmp	_Lnext
_Lend:	xor	eax, eax
	stosb
	mov	eax, [esp+4]
	ret
_Lerr:	xor	eax, eax
	ret

readi:
	push	dword $bufsiz
	push	dword $buffer
	call	readln
	add	esp, 8
	cmp	eax, 0
	je	.Lerr
	push	eax
	call	atoi
	add	esp,4
	ret
.Lerr:	mov	eax, 0x80000000
	ret
