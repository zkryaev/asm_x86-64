section .data
half:
        dd 0.5
section .text
; void asm_NearNeighbour(int w1, int h1, int w2, int h2, unsigned char* src, unsigned char* dst);
; arguments:              rdi,    rsi,    rdx,    rcx,         r8,                  r9
global asm_NearNeighbour
asm_NearNeighbour:
        mov rax, r9
        mov r9, r8
        mov r8, 3

        xor r10, r10
        xor r11, r11
        xor r12, r12
        xor r13, r13
        xor r14, r14
        xor r15, r15

        ; double scaleX, scaleY        
        cvtsi2ss  xmm0, rdi     ; w1
        cvtsi2ss  xmm1, rsi     ; h1
        cvtsi2ss  xmm2, rdx     ; w2
        cvtsi2ss  xmm3, rcx     ; h2

        divss    xmm0, xmm2     ; scaleX = (double)w1/w2;
        divss    xmm1, xmm3     ; scaleY = (double)h1/h2;
        xor r15,r15
        height: 
                cmp r15, rcx ; y < h2
                jge resizeDone
                xor r14, r14
                width:  
                        cmp r14, rdx ; x < w2
                        jge incY
                        cvtsi2ss xmm2, r14
                        cvtsi2ss xmm3, r15
                        mulss xmm2, xmm0
                        mulss xmm3, xmm1
                        
                        movss xmm4, dword[half]
                        subss xmm2, xmm4
                        subss xmm3, xmm4

                        cvtss2si r13, xmm2 ; sourceX =  (int)(x * scaleX);
                        cvtss2si r12, xmm3 ; sourceY = (int)(y * scaleY);
                        
                        ;sourceIndex
                        mov r11, r12
                        imul r11, rdi
                        add r11, r13
                        imul r11, r8 ; sourceIndex = (sourceY * w1 + sourceX) * n;

                        ;targetIndex
                        mov r10, r15
                        imul r10, rdx
                        add r10, r14
                        imul r10, r8 ; targetIndex = (y * w2 + x) * n;

                        ; r9 = src, rax = dst
                        push r9
                        push rax

                        add rax, r10 ; dst[targetIndex]
                        add r9, r11  ; src[sourceIndex]
                        ; dst[targetIndex] = src[sourceIndex];
                        mov r11b, [r9]
                        mov [rax], r11b
                        
                        add rax, 1
                        add r9, 1 
                        ; dst[targetIndex + 1] = src[sourceIndex + 1];
                        mov r11b, [r9]
                        mov [rax], r11b

                        add rax, 1
                        add r9, 1
                        ; dst[targetIndex + 2] = src[sourceIndex + 2];
                        mov r11b, [r9]
                        mov [rax], r11b

                        pop rax
                        pop r9
                        xor r11, r11
                        xor r10, r10
                        inc r14 ; x++
                        jmp width
                        incY:
                                inc r15
                                jmp height
        resizeDone:
        ret