ID = base
VER = 0e
LANG = $(ID)
BASE = comp
DIR = $$HOME/lib
CFLAGS = -g
BID = $(ID)-$(VER)

NASM = nasm -felf
YACC = byacc
LEX = flex -l

all: lib$(BASE).a

lib$(BASE).a: node.o tabid.o main.o
	ar crl $@ $?

malloc.o: malloc.c
	$(COMPILE.c) -Drcheck=2 $<

install: lib$(BASE).a lib$(LANG).a
	cp $? $(DIR)
	cp postfix.h tabid.h node.h $(DIR)

depend:
	makedepend -Y node.c tabid.c

backup: clean
	PWD=`pwd`; CWD=`basename $$PWD`; cd ..; tar cf - $$CWD | gzip -9 > $@/$(BID).tgz

clean:
	rm -f lib$(BASE).a *.o a.out core
