bits	64
;	res=((a*b*c)-(c*d*e))/((a/b)+(c/d))
section	.data
EXIT_SUCCESS equ 0
SYS_exit equ 60

null: 
	dq 	0

res:
	dw	0
a:
	dw	4000
b:
	dw	20
c:
	dw	20
d:
	dw	20
e:
	dw	30
section	.text
global	_start
_start:
	xor rax, rax
	xor rbx, rbx
	xor rcx, rcx
	xor rdx, rdx

	mov  ax,  word[a]
	mov  bx,  word[b]
	imul bx 	;ax = ax * bx
	
	; expand	
	xor rbx, rbx
	mov bx, dx
	shl ebx, 16
	mov bx, ax
	xor eax, eax
	mov eax, ebx
	xor ebx, ebx
		
			; rax = a*b
	xor ebx, ebx
	mov bx, word[c]
	imul rbx	
			; rax = a*b*c
	mov rsi, rax
	xor rax, rax  
	xor rbx, rbx

	mov ax, word[c]
	mov bx, word[d]
	imul ebx	; rax = c*d

	xor bx, bx
	mov bx, word[e]
	imul rbx  	; rax = c*d*e
	
	xor rbx, rbx
	mov rbx, rsi
	sub rbx, rax	; rbx = (a*b*c) - (c*d*e)
	jo error

	xor rax, rax
	mov rsi, rbx
	xor rbx, rbx
	
	mov cx, word[b]
	cmp cx, 0
	je error 	; catch flag ZF = 1 that mean b = 0

	mov ax, word[a]
	idiv ecx 	; rax = rax/rcx :: rax = a/b
	jo error
			; quotient - rax, reminder - rdx

	xor rbx, rbx
	mov ebx, eax
	mov cx, word[d]
	cmp cx, 0
	je error
	
	xor rdx, rdx
	xor rax, rax
	mov ax, word[c]
	idiv ecx		; rax = c/d
	jo error

	add eax, ebx 	; rax = a/b + c/d
	jo error
	
	xor rbx, rbx
	mov rbx, rsi	; rbx = (a*b*c) - (c*d*e)
	idiv rbx	
	jo error

	mov [res], rax
	xor rax, rax
	xor rbx, rbx
	xor rdx, rdx
	xor rcx, rcx

last:
	mov rax, SYS_exit
	mov rdi, EXIT_SUCCESS
	syscall
error:
	mov rax, SYS_exit
	mov rdi, 1
	syscall
