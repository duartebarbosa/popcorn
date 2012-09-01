ID = popcorn
EXT = .c
VER = alpha

ALUNO = 65893

LIB = $$HOME/lib/


all :	pdoc popcorn release

full :	clean zip pdoc popcorn tests

pdoc:
	cd src/pdoc; $(MAKE) $(MFLAGS)

popcorn :
	cd src/popcorn; $(MAKE) $(MFLAGS)

ver:
	@echo $(VER)

tests:	
	cp /release/*.* /tests

clean:
	cd src/pdoc; $(MAKE) clean
	cd src/popcorn; $(MAKE) clean
	cd release; rm -f *.*
	cd tests; rm -f popcorn pdoc

zip:
	@-tar -czf $(ID)-$(ALUNO)-$(VER).tgz * 

.PHONY: clean zip

