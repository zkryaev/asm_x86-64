bits	64

SYS_exit  equ   60 ; terminate
EXIT_SUCCESS equ 0 ; success code

section .data

msg1:
	db	"%f", 0
msg2:
	db	"log(%.10g)=%.10g", 10, 0
msg3:
	db	"Mylog(%.10g)=%.10g", 10, 0
msg4:
	db	"%s", 0
msg5:
	db "%.10g", 10, 0
msg6:
	db "w,0", 0

filename:
	times 15 db 0

fileDescriptor:
	dd 0	

prev:
	dd 0.0
cur:
	dd 0.0

n:
	dd 1

val:
	dd 0.5

accuracy:
	dd 0.1

factor:
	dd 1.0
power:
	dd 1.0

res_power:
	dd 1.0

div_2n:
	dd 1
tmp:
	dd 0.0
sum:
	dd 0.0

My_logCalc:
	dd 0.0

C_logCalc:
	dd 0.0

section	.text

extern	printf
extern	scanf
extern  logf
extern fopen
extern fclose
extern  fprintf

global main
main:
	push	rbp
	mov	rbp, rsp
	; ввод значения
		mov	rdi, msg1
		mov rsi, val
		xor	eax, eax
		call	scanf
	; ввод точности
		mov	rdi, msg1
		mov rsi, accuracy
		xor	eax, eax
		call	scanf
		jmp enter_filename
	; ввод имени файла
	enter_filename:
		mov edi, msg4
		mov rsi, filename
		xor	eax, eax
		call scanf
		mov edi, filename
		mov esi, msg6 ; write
		call fopen
		cmp eax, 0
		je enter_filename
		mov [fileDescriptor], eax

	C_log:
		movss xmm0, [val]
		movss xmm1, [val]
		mulss xmm0, xmm1 ; xmm0 = x^2
		mov eax, 1
		cvtsi2ss xmm1, eax
		addss xmm0, xmm1 
		sqrtss xmm1, xmm0 ; xmm1 = sqrt(1 + x^2)	
		movss xmm0, [val]
		addss xmm0, xmm1  ; xmm0 = 1 + sqrt(1 + x^2)
		call logf
		movss [C_logCalc], xmm0

	My_log:
		; вычисление x^2
		movss xmm0, [val]
		movss xmm1, [val]
		movss dword[cur], xmm1
		mulss xmm0, xmm1
		movss dword[power], xmm0 ; power = x^2
		
		call mylog
		movss xmm1, [val]
		movss xmm0, [sum]
		addss xmm0, xmm1
		movss [My_logCalc], xmm0

	mov edi, msg2
	movss xmm2, [val]
	movss xmm3, [C_logCalc]
	cvtss2sd xmm0, xmm2
	cvtss2sd xmm1, xmm3
	mov eax, 2
	call printf

	mov edi, msg3
	movss xmm2, [val]
	movss xmm3, [My_logCalc]
	cvtss2sd xmm0, xmm2
	cvtss2sd xmm1, xmm3
	mov eax, 2
	call printf

	mov edi, [fileDescriptor]
	call fclose
	leave
	ret


global mylog
mylog:
	push rbp
	mov rbp, rsp
	begin:
	movss xmm1, dword[cur]
	movss dword[prev], xmm1
	movss xmm5, xmm1

	; вычисление множителя с факториалами
	cvtsi2ss xmm0, dword[n]
	call factorial
	mulss xmm5, xmm0	; Cn-1*(2n-1)/2n

	; (-1)
	mov eax, -1
	cvtsi2ss xmm3, eax
	mulss xmm5, xmm3	; Cn-1*(2n-1)/2n

	; вычисление множителя со степенью
	movss xmm0, dword[power]
	mulss xmm5, xmm0

	cvtsi2ss xmm0, dword[div_2n] ; восстанавливаю знаменатель
	mulss xmm5, xmm0

	mov eax, dword[div_2n]
	add eax, 2
	mov dword[div_2n], eax
	cvtsi2ss xmm0, eax
	divss xmm5, xmm0 ; xmm5 = Cn-1*(-1)(2n-1)/2n * x^2)/(2n+1)
	
	; сохранение
	movss [cur], xmm5

 	; суммирование
	movss xmm0, [sum]
	addss xmm0, xmm5
	movss [sum], xmm0

	;запись в файл член ряда
	mov edi, [fileDescriptor]
	mov esi, msg5
	movss xmm0, dword[cur]
	mov eax, 1
	call fprintf

	; n++
	inc dword[n]

	; если это только начало вычислений и An-1 просто не существует
	movss xmm2, [prev]
	movss xmm3, dword[val]
	ucomiss xmm2, xmm3
	je begin

	; проверка на конец
	; |An-1 - An| < E
	movss xmm0, [prev] ; Sn-1
	movss xmm1, [cur]  ; Sn
	subss xmm0, xmm1
	mov eax, 0
	cvtsi2ss xmm1, eax
	ucomiss xmm0, xmm1
	jnb if_absolute
	mov eax, -1
	cvtsi2ss xmm1, eax
	mulss xmm0, xmm1 ; if negative
	if_absolute:
		movss xmm1, [accuracy]
		ucomiss xmm0, xmm1
		jbe CalcSeriesDone
	jmp begin
	CalcSeriesDone:
		leave
		ret

global factorial ;
factorial:
	movss xmm1, xmm0
	; 2n-1
	mov eax, 2
	cvtsi2ss xmm2, eax
	mulss xmm0, xmm2

	mov eax, 1
	cvtsi2ss xmm2, eax
	subss xmm0, xmm2
	; 2n
	mov eax, 2
	cvtsi2ss xmm2, eax
	mulss xmm1, xmm2

	; 2n-1/2n
	divss xmm0, xmm1

	ret	
