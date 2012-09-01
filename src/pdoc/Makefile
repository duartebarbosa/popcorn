ID = pdoc
VER = final

ALUNO = 65893

CC = gcc
CFLAGS1 = -lfl
CFLAGS2 = -O3
FLEX = flex
FILES = pdoc.yy.c
FFILE = pdoc.l


all: backup pdoc release

pdoc:	pdoc.yy.c
	$(CC) pdoc.yy.c -o pdoc $(CFLAGS1) $(CFLAGS2)

release:
	cd ..; cd ..; cp src/pdoc/pdoc release/;

pdoc.yy.c : pdoc.l
	$(FLEX) -o pdoc.yy.c $(FFILE)

ver:
	@echo $(VER)

backup: clean zip
	
clean:
	@-rm -f $(FILES) pdoc *.tgz *.*~

zip:
	@-tar -czf $(ID)-$(ALUNO)-$(VER).tgz * 

.PHONY: clean zip
