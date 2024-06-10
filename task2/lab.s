bits 64
; Task option: sorting the side diagonal of the matrix and everything parallel to one.

section .data

EXIT_SUCCESS equ 0
SYS_exit equ 60

; number strings of matrix
n:
	dd 4

matrix: 
		dd  0, 4, 8, 12
		dd  1, 5, 6, 13
		dd  2, 9, 10,14
		dd  3, 7, 11,15


; size of mas_ptr (it is being chosen by the size of the main side diagonal)
m:
	dd 4

mas_ptr:
	dd 0, 0, 0, 0

num_down_diag: ; what number of down side diagonal it must start
	dd 2

num_up_diag:
	dd 1

index_elementa:
	dd 3

cnp:
	dd 0

t_cnp:
	dd 0

tmp: ; before start it have to be set equal to "index_elementa"
	dd 3

counter_loop:
	dd 0

largest: ;
	dd 0

left:
	dd 0
right:
	dd 0

is_heap_built:
	dd 0
build_heap_counter:
	dd 0

is_left_one:
	dd 0
left_one_counter:
	dd 0

section .text
global _start
_start: 
diagonal:
	mov ecx, [m]
	mov eax, 0		 ; counter loop
	fullment_mas_ptr:
		; reset the pointers to the initial positions
			mov esi, matrix  ; source
			mov edi, mas_ptr ; receiver

		; mas_ptr :: offset the pointer
			mov eax, [counter_loop]
			imul eax, 4  ; 4*i
			add edi, eax ; mas_ptr + offset

		; matrix :: offset the pointer
			mov eax, [index_elementa]
			imul eax, 4
			add esi, eax ; matrix + 4*index_elementa

		; data movement :: mas_ptr[i] = &(matrix[index_elementa])
			mov eax, esi ; eax = 42025xx
			mov [edi], eax ; example: [42025xx][0][0]
			
		; matrix :: calculate new offset
			mov ebx, [index_elementa]
			add ebx, dword[m]
			sub ebx, 1
			mov [index_elementa], ebx ; index_elementa = (index_elementa + m) - 1
			
		; counter++
			inc dword[counter_loop]

		; cnp++
			inc dword[cnp]

			loop fullment_mas_ptr
		;------------------------------------fullment_mas_ptr :: end

		; counter_loop :: reset
			mov dword[counter_loop], 0

			mov eax, [cnp]
			mov [t_cnp], eax

			; calculating build_heap_counter
				mov eax, dword[cnp]
				mov ebx, 2
				xor rdx, rdx
				idiv ebx ; n/2
				dec eax
				mov dword[build_heap_counter], eax ; i = n / 2 - 1
			; calculating left_one_counter
				mov eax, dword[cnp]
				dec eax
				mov dword[left_one_counter], eax ; i = arr.size() - 1
			jmp heap_sort

dec_build_heap_counter:
	dec dword[build_heap_counter]
	jmp heapify

dec_left_one_counter:
	dec dword[left_one_counter]
	jmp heapify 

	heap_sort:
		build_heap:
			cmp dword[is_heap_built], 1
			je left_one

			mov eax, dword[build_heap_counter]
			mov dword[counter_loop], eax
			
			cmp dword[build_heap_counter], 0
			jge dec_build_heap_counter

			mov dword[is_heap_built], 1

		left_one:
			cmp dword[is_left_one], 1
			je upper_diagonal

			mov eax, dword[left_one_counter]
			mov dword[counter_loop], eax

			mov eax, dword[counter_loop]
			mov edi, mas_ptr
			imul eax, 4

			add edi, eax ; [i]
			mov esi, mas_ptr ; [0]

			; swap([0], [i])
				mov eax, [edi]
				mov ebx, [esi]
				mov edx, [eax]
				mov ecx, [ebx]
				mov [eax], ecx
				mov [ebx], edx
			
			mov eax, dword[counter_loop]
			mov dword[cnp], eax ; heap_size = i
			mov dword[counter_loop], 0; i = 0

			cmp dword[left_one_counter], 1
			jg dec_left_one_counter

			mov dword[is_left_one], 1
			jmp upper_diagonal
		

	heapify:
			mov eax, dword[counter_loop]
			mov dword[largest], eax

			child_left:
			; if( (2i+1) < cnp) | i = eax
				mov eax, [counter_loop]
				imul eax, 2
				add eax, 1
				mov dword[left], eax
				cmp eax, dword[cnp]
				jg swap

			; calculate offset = [largest]
				mov edx, [largest]
				imul edx, 4 ;

			; calculate offset = [2i+1]
				mov eax, [counter_loop]
				imul eax, 2 
				imul eax, 4 ; interpret in bytes
				add eax, 4  ; left :: offset
							
			; set pointer_1 = [i]
				mov edi, mas_ptr ;
				add edi, edx;

			; set pointer_2 = [left]
				mov esi, mas_ptr
				add esi, eax
				
			; find value [i] (edi = mas_ptr[i])
				mov eax, [edi]
				mov ebx, [eax] ; ebx = *(mas_ptr[i]) = value

			; find value [2i+1] (esi = mas_ptr[2i+1])
				mov eax, [esi]
				mov edx, [eax] ; edx = *(mas_ptr[2i+1]) = value
				%ifdef ascending
				cmp ebx, edx	
				jg child_right
				%endif 

				%ifdef descending
				cmp edx, ebx
				jg child_right 
				%endif 
				; ascending :: set largest
				mov eax, dword[left]
				mov dword[largest], eax		
			;------------------------------------left :: end
			child_right:

			; if( (2i+2) < cnp) | i = eax
				mov eax, [counter_loop]
				imul eax, 2
				add eax, 2
				mov dword[right], eax
				cmp eax, dword[cnp]
				jge swap

			; calculate offset = [largest]
				mov edx, [largest]
				imul edx, 4

			; calculate offset = [2i+2]
				mov eax, [counter_loop]
				imul eax, 2 
				imul eax, 4
				add eax, 8
				
			; set pointer_1 = [i]
				mov edi, mas_ptr
				add edi, edx ;

			; set pointer_2 = [2i+2]
				mov esi, mas_ptr
				add esi, eax
				
			; find value [i] (edi = mas_ptr[i])
				mov eax, [edi]
				mov ebx, [eax] ; ebx = *(mas_ptr[i]) = value

			; find value [2i+1] (esi = mas_ptr[2i+2])
				mov eax, [esi]
				mov edx, [eax] ; edx = *(mas_ptr[2i+2]) = value

				%ifdef ascending
				cmp ebx, edx	
				jg swap
				%endif 
				%ifdef descending
				cmp edx, ebx
				jg swap
				%endif 

				; ascending :: set largest
				mov eax, dword[right]
				mov dword[largest], eax	

			swap:
				mov eax, dword[counter_loop]
				cmp dword[largest], eax ; if (largest != i)
				je heap_sort

				mov edi, mas_ptr
				imul eax, 4
				add edi, eax ;

				mov ebx, [largest]
				mov [counter_loop], ebx ; i = largest

				mov esi, mas_ptr
				mov eax, [largest]
				imul eax, 4
				add esi, eax
				mov eax, [esi]
				mov [largest], eax

				mov eax, [edi] ; ptr i
				mov ebx, [largest] ; ptr largest
				; swap:
					mov edx, [eax] ; value i
					mov esi, [ebx] ; value largest
					mov [eax], esi
					mov [ebx], edx
				jmp heapify
			;------------------------------------right :: end
		;------------------------------------heapify :: end

	upper_diagonal:
		mov dword[cnp], 0		; reset number of pointers into mas_ptr
		mov dword[counter_loop], 0
		mov dword[is_heap_built], 0
		mov dword[is_left_one], 0

		; index_elementa = tmp - 1
		mov ebx, [tmp]
		sub ebx, 1
		mov [index_elementa], ebx
		mov [tmp], ebx

		cmp dword[index_elementa], 0		; if(index_elementa == 0)
		jle down_diagonal		;	 {jump down_diagonal}

		; (m - num_up_diag)
		mov eax, [m]
		mov edx, [num_up_diag]
		sub eax, edx
		mov ecx, eax ; | set counter loop for fullment_mas_ptr

		;num_up_diag++
		inc dword[num_up_diag]
		jmp fullment_mas_ptr

	down_diagonal:
		mov dword[cnp], 0		; reset number of pointers into mas_ptr
		mov dword[counter_loop], 0
		mov dword[is_heap_built], 0
		mov dword[is_left_one], 0

		mov eax, [num_down_diag]
		mov ecx, [m]
		imul eax, ecx 
		sub eax, 1 ; num_down_diag * m - 1

		mov [index_elementa], eax ; index_elementa = num_down_diag * m - 1

		; ecx = m - num_down_diag + 1 ; set counter for fullment_mas_ptr loop
		mov edx, [num_down_diag]
		sub ecx, edx
		add ecx, 1

		; num_down_diag++
		inc dword[num_down_diag]

		; (m*n - 1)
		mov eax, [n] 
		mov edx, [m]
		imul eax
		sub eax, 1 

		cmp dword[index_elementa], eax	; if(index_elementa != (m*n - 1)){
		je last					;			 		{terminate program}
		jmp fullment_mas_ptr	; }else
								;	  		{jump to fullment_mas_ptr}

last:
	mov rax, SYS_exit
	mov rdi, EXIT_SUCCESS
	syscall
	

