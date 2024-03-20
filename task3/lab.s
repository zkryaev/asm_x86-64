bits	64
;	Delete words from the string whose first and last characters are different.

section	.data
; ▶ Standard constants:
	SYS_exit  equ   60 ; terminate
	EXIT_SUCCESS equ 0 ; success code

	LF    equ 10 ; line feed
	NULL  equ 0  ; end of string

	STDIN equ  0 ; standard input
	STDOUT equ 1 ; standard output

	SYS_read  equ 0 ; read
	SYS_write equ 1 ; write
	SYS_open  equ 2 ; file open
	SYS_close equ 3 ; file close
	O_RDONLY equ 000000q ; file mode: read only

; ▶ My constants:
	l_str equ 1024
	l_filename equ 10
;//////////////////////////////////////////////////

; ▶ Dialog msg's:

msg2:
	db "	[ Lentgh < 10 ]", LF, NULL
msg4:
	db "	Repeat!", LF, NULL
errMsgLength:
	db "	Error!: LEN", LF, NULL
errMsgOpen:
	db "	Error!: OPEN", LF, NULL 

;tab_characters:
;	db " ,.?!:;", NULL

filename:
	times l_filename db 0

fileDescriptor:
	dd 0	

fileOffset:
	dd 0

counterSymbols:
	dd 0

was_it_long_str:
	dd 0

skip_symbols:
	dd 0

chr:
	db 0


oldstr:
	times l_str	db	NULL
newstr:
	times l_str	db	NULL

section	.text
global	_start
_start:
	call dialog
	mov rdi, [fileDescriptor]
	mov rsi, l_str
	call mainFunc
	xor rdi, rdi
	mov edi, [fileDescriptor]
	call closeFile
	jmp last

last:
	mov rax, SYS_exit
	mov rdi, EXIT_SUCCESS
	syscall

; void printString(&string)
global printString
printString:
	push rbx
	mov rbx, rdi
	mov rdx, 0 			; drop counter
						; Count characters in string (exclude NULL)
	strCountLoop:
		cmp byte [rbx], NULL
		je strCountDone
		inc rdx 	; count symbols
		inc rbx		; make an offset
		jmp strCountLoop

	strCountDone:
		cmp rdx, 0
		je printDone
	
		mov rax, SYS_write  ; system code for write()
		mov rsi, rdi 		; address of chars to write
		mov rdi, STDOUT 	; standard out
							; RDX = counter to write, set above
		syscall

	printDone:
		pop rbx
		ret

; void dialog()
global dialog
dialog:
	read_filename:
		mov rdi, msg2
		call printString

		mov rdi, filename
		mov rsi, l_filename
		call readConsoleString
		cmp eax, -1		  ; if entered wrong string
		je read_filename ; enter correct string

	open_file:
		mov rdi, filename
		call openFile
		cmp eax, -1
		je read_filename

	dialog_end:
		ret

; int openFile(&string)
global openFile
openFile:
	findCurrentFile:
		mov rax, SYS_open ; open file
						  ; rdi - filename
		mov rsi, O_RDONLY ; mode: only read
		syscall

		cmp rax, 0
		jl openFail
		mov [fileDescriptor], eax ; if file was founded -> eax contain descriptor
	openDone:
		ret
	openFail:
		mov rdi, errMsgOpen
		call printString
		mov rax, -1
		ret

; void closeFile(int FileDescriptor)
global closeFile
closeFile:
	push rbx
	mov rbx, rdi
	closeProcess:
		mov rax, SYS_close
		mov rdi, rbx
		syscall
	closeDone:
		pop rbx
		ret

; int readConsoleString(&string, size_buff) : return -1 if entered string bigger than given buffer
global readConsoleString
readConsoleString:
	push rbx
	push r12
	push r15
	mov r15, rsi ; length_str
	mov rbx, rdi
	mov r12, 0  ; char counter
	readCharacters:
		mov rax, SYS_read  ; system code for read
		mov rdi, STDIN     ; standard in
		lea rsi, byte[chr] ; address of chr, result: [rsi+1], [rsi+1 + 1] e.c
		mov rdx, 1         ; count (how many to read)
		syscall

		mov al, byte [chr] ; get character just read
		cmp al, LF 		   ; if \n, input done
		je readStrDone

		inc r12 		   ; count++
		cmp r12, r15 	   ; if chars >= length_str
		jae errLength ; stop placing in buffer

		mov byte [rbx], al ; filename[i] = chr
		inc rbx ;  offset
		jmp readCharacters

	readStrDone:
		mov byte[rbx], NULL ; add NULL termination
		pop r15
		pop r12
		pop rbx
		ret

	errLength:
		pop r15
		pop r12
		pop rbx

		mov rdi, errMsgLength
		call printString
		mov rdi, msg4
		call printString
		mov eax, -1
		
		ret
		
; void MainFunc(int FileDescriptor, int size_buff)
global mainFunc
mainFunc:
	push rbx
	push r15
	push r14
	push r13
	mov rbx, oldstr
	mov r15, rdi
	mov r14, rsi
	mov r13, 0 ; counter of characters
	jmp readProcess
	decfileOffset:
		dec dword[skip_symbols]
		jmp readProcess
	readProcess:
		mov rax, SYS_read  ; mode: read
		mov rdi, r15	   ; fileDescriptor
		lea rsi, byte[chr] ; Adress of string
		mov rdx, 1	   ; Number of chr's
		syscall


		cmp dword[was_it_long_str], 0
		je pre_capture

		cmp dword[skip_symbols], 0
		jg decfileOffset

		mov dword[was_it_long_str], 0

		pre_capture:
			cmp rax, 0	   	; EOF?
			je obtainString

			inc r13
			cmp r13, r14   	; number of characters != 1024
			je obtainString
			jmp saveCharacter
			
	saveCharacter:
		mov al, byte[chr]
		mov byte[rbx], al
		inc dword[counterSymbols]

		mov rdi, rbx
		inc rbx
		call is_tab_character
		cmp rax, 1
		jne readProcess

		mov edi, [counterSymbols]
		add dword[fileOffset], edi
		mov dword[counterSymbols], 0

		jmp readProcess

	obtainString:
		mov byte[rbx], NULL
		mov rdi, oldstr
		mov rsi, newstr
		call stringProcessing

		;mov rdi, newstr
		;call printString

		cmp r13, r14 	; if number of symbols was too high, so we have to check is there any other symbols left
		jl readDone
		is_longerString:
			mov rbx, oldstr
			xor r13, r13	  ; drop off counter character

			movsx rdi, dword[fileDescriptor]
			call closeFile

			mov rdi, filename
			call openFile

			mov dword[was_it_long_str], 1
			mov ecx, [fileOffset]
			mov [skip_symbols], ecx
			mov dword[counterSymbols], 0
			jmp readProcess

	readDone:
		pop r13
		pop r14
		pop r15
		pop rbx
		ret

	readError:
		pop r13
		pop r14
		pop r15
		pop rbx
		ret

;void stringProcessing(oldstr, newstr)
global stringProcessing
stringProcessing: ; rdi, rsi, rdx - oldstring
		push rbx
		push rax
		push rcx
	characterProcessing:
		xor rax, rax
		xor rcx, rcx
		mov rbx, newstr
		find_StringBegin:
			cmp byte[rdi], NULL
			je processDone

			call is_tab_character
			cmp rax, 1
			je offset_rdi

			mov rsi, rdi
			mov rdx, rdi
			jmp find_wordEND

		find_wordBEGIN:
			cmp byte[rdi], NULL
			je processDone

			inc rdi

			cmp byte[rdi], NULL
			je processDone

			call is_tab_character
			cmp rax, 1
			je find_wordBEGIN

			mov rsi, rdi
			mov rdx, rdi
			jmp find_wordEND

		find_wordEND:
			inc rdi

			call is_tab_character
			cmp rax, 1
			je cmpLetter

			cmp byte[rdi], NULL
			je cmpLetter

			inc rsi
			jmp find_wordEND

		cmpLetter:
			cmp rsi, rdx 		; is it the same position? When they point on 1 letter
			je wordSAVE

			mov al, byte[rsi]
			mov cl, byte[rdx]
			cmp al, cl		; if letters equal so word have to be deleted
			je wordSAVE
			jmp find_wordBEGIN

		wordSAVE:
			mov al, byte[rdx]
			mov byte[rbx], al ; newstr[i] = oldstr[i]
			inc rbx
			inc rdx
			cmp rdx, rsi
			jle wordSAVE

			call is_tab_character
			cmp rax, 1
			jne find_wordBEGIN
			xor rax, rax
			
			; add tab char after word
			mov al, byte[rdi]
			mov byte[rbx], al
			inc rbx
			jmp find_wordBEGIN

	offset_rdi:
		xor rax, rax
		inc rdi
		jmp find_StringBegin ; continue

	processDone:
		mov rsi, rdi
		dec rbx
		mov rdi, rbx

		call is_tab_character
		cmp rax, 1
		jne return
		
		mov al, byte[rdi]
		mov byte[rbx], al

		return:
			inc rbx
			mov al, byte[rsi]
			mov byte[rbx], al
			pop rcx
			pop rax
			pop rbx
			ret

; int is_tab_character(rdi, rsi)
global is_tab_character
is_tab_character:
		cmp byte[rdi], 32 ; is " "
		je make_an_offset
		cmp byte[rdi], 33 ; is "!"
		je make_an_offset
		cmp byte[rdi], 44 ; is ","
		je make_an_offset
		cmp byte[rdi], 46 ; is "."
		je make_an_offset
		cmp byte[rdi], 58 ; is ":"
		je make_an_offset
		cmp byte[rdi], 59 ; is ";"
		je make_an_offset
		cmp byte[rdi], 63 ; is "?"
		je make_an_offset
		xor rax, rax
		ret

		make_an_offset:
			mov rax, 1
			ret