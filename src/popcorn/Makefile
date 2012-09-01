ID = popcorn
EXT = .pip
VER = alpha

ALUNO = 65893

CC = gcc
LEX = flex
YACC = byacc
NASM = nasm

CFLAGS = -g -DYYDEBUG -I$(LIB)
#CFLAGS = -O3 -I$(LIB)
YFLAGS = -dv
LFLAGS = -l
NASMFLAGS = -felf


.SUFFIXES: $(EXT) .asm
LOADLIBS = -L$(LIB) -lcomp # -lfl

OBJECTS = lex.yy.o y.tab.o popcorn.yy.o teste.o teste teste.asm implies.asm implies implies.o
FILES = popcorn.yy.c
FILES1 = y.tab.c
FILES2 = y.tab.h y.output y.dot
FFILE = popcorn.l

BID = $(ID)-$(VER)
LIB = ./lib/
BIN = $(ID)
RUN = runtime/lib$(ID).a
BASE = y.tab.o lex.yy.o

full:	clean all

all:	backup $(BIN) $(RUN) release

%:%.asm
	$(NASM) $(NASMFLAGS) $*.asm
	$(LD) $*.o -L runtime/ -l$(ID) -o $@

$(EXT).asm:
	./$(ID) $<

$(ID): $(BASE) code.o lib/libcomp.a
	$(LINK.c) -o $@ $^ $(LOADLIBS)

lib/libcomp.a: lib/node.o lib/tabid.o lib/main.o
	ar crs	$@ $?

$(RUN): runtime/lib.o runtime/linux.o runtime/sys.o
	ar crs	$@ $?

runtime/%.o:runtime/%.asm
	$(NASM) $(NASMFLAGS) $<

lex.yy.c: $(ID).l y.tab.c
	$(LEX) $(LFLAGS) $<

y.tab.c: $(ID).y
	$(YACC) $(YFLAGS) $<

release:
	cd ..; cd ..; cp src/popcorn/popcorn release/;

ver:
	@echo $(VER)

backup:	clean zip

clean:
	@-rm -f $(OBJECTS) $(FILES) $(FILES1) $(FILES2) popcorn *.tgz *.*~

zip:
	@-tar -czf $(ID)-$(ALUNO)-$(VER).tgz * 

.PHONY: clean zip backup

