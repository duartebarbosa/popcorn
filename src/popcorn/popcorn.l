/* POPCORN COMPILER - FLEX dsrb@Skywalker IST-TP LEIC n.º 65893  - 2010 */
%{

#include <stdio.h>
#include <stdlib.h>
#include "lib/node.h"
#include "y.tab.h" 

#define SIZE 80

int n = 0, last = 0, i = 0, tmp = 0, backslash_flag = 0, real_flag = 0, stack[SIZE] = {0};

int *top = stack;		/* top points to the top of stack */
int *p1 = stack;		/* initialize p1 */

void push(int i);
void pop(void);
int clearStack();
int updateLast();
char *dupstr (const char *s);


%}
DIG [0-9]
INT {DIG}+
EXP [Ee][+-]?{INT}
REAL ({INT}?"."{INT})|({INT}"."{INT}?)|{INT}({EXP})?

OCT [0-7]
HEX [0-7a-fA-F]
NL "\n"|"\n\r"|"\r"

%option yylineno
%x COM STRING
%%
			/*** Rules section ***/
"not"						{return(NOT); }				/* RESERVED KEYWORDS */
"and"						{return(AND_OP); }
"or"						{return(OR_OP); }
"if"						{return(IF); }
"then"						{return(THEN); }
"else"						{return(ELSE); }
"endif"						{return(ENDIF); }
"while"						{return(WHILE); }
"do"						{return(DO); }
"for"						{return(FOR); }
"done"						{return(DONE); }
"until"						{return(UNTIL); }
"break"						{return(BREAK); }
"continue"					{return(CONTINUE); }
"goto"						{yyerror("The Goto keyword is reserved but has no use in PopCorn language");}/* RESERVED BUT NOT USED */
"real"						{if(!real_flag) {real_flag = yylineno;} return(REAL); }
"integer"					{return(INTEGER); }
"const"						{return(CONST); }
"var"						{return(VAR); }
"elif"						{return(ELIF); }
^"init"						{return(INIT); }
^"extern"					{return(EXTERN); }
^"end"						{pop(); clearStack(); return(END); }

"+"						{return('+'); }				/* OPERATORS */
"+="						{return(ADDEDATTRIB); }
"-"						{return('-'); }
"-="						{return(MINUSATTRIB); }
"*"						{return('*'); }
"*="						{return(MULATTRIB); }
"/"						{return('/'); }
"/="						{return(DIVATTRIB); }
"%"						{return('%'); }
"%="						{return(MODATTRIB); }
"**"						{return(EXP); }
"**="						{return(EXPATTRIB); }
"<"						{return('<'); }
">"						{return('>'); }
"="						{return(EQ_OP); }
">="						{return(GE_OP); }
"<="						{return(LE_OP); }
"<>"						{return(NE_OP); }
":="						{return('='); }
"=>"						{return(IMPLICA); }
"?"						{return('?'); }
"!"						{return('!'); }
"!!"						{return(OUT); }
"@"						{return('@'); }
"++"						{return(INC); }
"--"						{return(DEC); }

"["						{return('['); }				/* DELIMITATORS */
"]"						{return(']'); }
","						{return(','); }
";"						{return(';'); }
"("						{return('('); }
")"						{return(')'); }

<STRING>[^\']*					{yylval.c = dupstr( yytext ); return (STR); }		/* special tokens */
<STRING>"\newline"				;
<STRING>\'					BEGIN INITIAL;
\'						BEGIN STRING;

\'\'						{ yylval.c = ""; return (STR); }
[A-Za-z][A-Za-z0-9_]*				{ yylval.c = dupstr( yytext ); return (ID); }

"0"{OCT}					{ char *endptr; yylval.i = strtol(yytext, &endptr, 8);
						  if(errno == ERANGE)
							  yyerror("Integer Overflow");
						  return(INT_NUMBER); 
						}
"0x"{HEX}					{ char *endptr; yylval.i = strtol(yytext, &endptr, 16);
						  if(errno == ERANGE)
							  yyerror("Integer Overflow");
						  return(INT_NUMBER);
						}
{INT} 						{ char *endptr; yylval.i = strtol(yytext, &endptr, 10);
						  if(errno == ERANGE)
							  yyerror("Integer Overflow");
						  return(INT_NUMBER);
						}
{REAL} 						{real_flag = yylineno; return(REAL_NUMBER); }

^[ \t]+						{
						 for(i = 0, tmp = 0; i != yyleng; i++){			/* count tabs and spaces */
							if(yytext[i] == ' '){
								tmp++;
							}
							else{
								tmp += 8;
							}
						 }
						 updateLast();
						 if( tmp == *p1) {/* do nothing */;}			/* work out indents */
						 else if( tmp > *p1){
							if(backslash_flag == 0){
						 		push(tmp);
						 		return(NEWBLOCK);
						 	}
						 }
						 else if(tmp < *p1 && tmp == last){
							if(backslash_flag == 0){
						 		pop();
						 		return(OLDBLOCK);
						 	}
						 }
						 else {yyerror("Indentation Error");}
						}


<COM>\}|\}{NL}					{if(n == 1) {n--; BEGIN INITIAL; } else {n--;} }
<COM>[^\{\}]*					;							/* discard comments */
<COM>\{						n++;
\{						{n++; BEGIN COM;}
[.]*\#[^\n]*{NL}				;							/* discard comments */



^[ \t]*{NL}					{;	/* discard white lines */}

\\[ \t]*{NL}					{backslash_flag = 1;/* continuacao de linha logica */}

{NL}						{backslash_flag = 0; return(NEWLINE);}
[ \t]						;
.						{yyerror("Unknown Keyword");}



%%

			/*** C Code section ***/

int yywrap(void){

	/* verificar se a pilha esta vazia, erro se nao */
	if(p1 != top){
		yyerror("Stack not empty on exit; check blocks indentation");
	}
	
	return 1;
}

void push(int i){
	last = *p1;
	p1++;

	if(p1 == (top + SIZE)) {
		printf("Indentation Stack Overflow.\n");
	}
	*p1 = i;
}

void pop(void){
	*p1 = 0;
	if(p1 == top) {
		printf("Indentation Stack Underflow.\n");
	}
	p1--;
}

int updateLast(){
	int * p2 = p1;
	p2--;
	last = *p2;

	return 0;
}

int clearStack(){
	for(i = 0; i < SIZE; i++){
		stack[i] = 0;
	}
	return 0;
}
