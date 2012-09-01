ID = popcorn
VER = 0e
LANG = $(ID)
DIR = $$HOME/lib
CFLAGS = -g
BID = $(ID) -$(VER)

OS = linux.o sys.o

NASM = nasm -felf
YACC = byacc
LEX = flex -l

all: lib$(LANG).a

lib$(LANG).a: lib.o dbl.o utils.o $(OS)
	ar crl $@ $?

install: lib$(LANG).a
	cp $? $(DIR)

.SUFFIXES: .asm
.asm.o:
	$(NASM) $<

backup: clean
	PWD=`pwd`; CWD=`basename $$PWD`; cd ..; tar cf - $$CWD | gzip -9 > $@/$(BID).tgz


clean:
	rm -f lib$(LANG).a *.o a.out core
