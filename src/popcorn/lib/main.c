#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

char *ext = ".asm", *prog, *infile = "<<stdin>>", *outfile = 0;
int errors, opt, tree, trace, yyparse(void);

extern int yylineno;
extern char *yytext;
extern int real_flag, yynerrs;

int yyerror (char *s){

	fprintf(stdout,"\b%s : %s @ line %d\n", infile, s, yylineno);
	errors++;
	return 0;
}


char *dupstr (const char *s){	 /* duplicate strings */

	char *result;
	if (s == 0)
		return 0;

	result = malloc (sizeof(char)*strlen(s)+1);
	if (result == 0)
		return 0;

	strncpy (result, s, strlen(s));
	result[strlen(s)] = 0;

	return result;
}


int main(int argc, char *argv[]){
	#ifdef YYDEBUG
	extern int yydebug;
	yydebug = getenv("YYDEBUG") ? 1 : 0;
	#endif

	printf("Popcorn Compiler - dsrb\n");

	prog = argv[0];

	if (argc > 1){
		if (strcmp(argv[1], "-O") == 0) { opt = 1; argc--; argv++; }
		if (strcmp(argv[1], "-tree") == 0) { tree = 1; argc--; argv++; }
		if (strcmp(argv[1], "-trace") == 0) { trace = 1; argc--; argv++; }
		if (strcmp(argv[1], "-debug") == 0) { trace = 2; ext = ".stk"; argc--; argv++; }

		if (argc > 3){
			fprintf(stderr, "USAGE: %s [-O] [-tree] [-trace] [-debug] [infile]\n", argv[0]);
			exit(1);
		}

		extern FILE *yyin;
		if ((yyin = fopen(infile = argv[1], "r")) == NULL){
			perror(argv[1]);
			return 1;
		}
	}

	if (argc == 2){
		char *str = dupstr(argv[1]);
		int len = strlen(str);
		if (len > 4 && str[len-4] == '.')
			strcpy((outfile = str)+len-4, ext);
	}
	if (argc > 2) outfile = argv[2];

	if (yyparse() != 0 || errors > 0 || yynerrs > 0 || real_flag){
		fprintf(stderr, "Popcorn Compiler : %d errors in \"%s\"\nPlease, review the code and don't waste my time.\n", errors, infile);
		return 1;
	}
	else{
		printf("Popcorn Compiler : Success.\n");
	}
		
	return 0;
}
