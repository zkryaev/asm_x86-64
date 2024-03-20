SRCS = lab.s
OBJS = $(SRCS:.s=.o)
EXE = lab

all: 
	echo "first or second mode?"

clean:
	rm -rf $(EXE) $(OBJS)

ascending: 
	nasm -g -f elf64 lab.s -o lab.o -D ascending
	ld -g -static lab.o -o lab
descending:
	nasm -g -f elf64 lab.s -o lab.o -D descending
	ld -static lab.o -o lab
 