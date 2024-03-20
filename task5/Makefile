all:
	gcc -c main.c -o  main.o
	nasm -f elf64 lab.s -g -o lab.o
	gcc -z noexecstack -static main.o lab.o -o lab -lm
clean:
			rm -rf main, lab *.o
			rm -rf result_C.jpg 
			rm -rf result_asm.jpg
