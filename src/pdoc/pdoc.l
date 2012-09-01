/* POPCORN COMPILER DOCUMENTATION GENERATOR - code.c dsrb@Skywalker IST-TP LEIC n.º 65893  - 2010 */

%{

#include <stdio.h>


int n = 0, counter = 0, comments = 0, char_counter = 0;

%}

%option yylineno
%x COM COM2 STRING
%%
			/*** Rules section ***/

<COM>\}|\}"\n"					{if(n == 1) {n--; BEGIN INITIAL; } else {n--;} }
<COM>[^\{\}]*					counter += strlen(yytext);				/* discard operational comments */
<COM>\{						n++;
\{						{n++; BEGIN COM;}

<STRING>[^\']*					;							/* discard strings */
<STRING>\'					BEGIN INITIAL;
\'						BEGIN STRING;

<COM2>\n					{printf("\n"); BEGIN INITIAL;}
<COM2>[^\n]*					{printf("%s @ line %d\n", yytext, yylineno); char_counter += strlen(yytext);}

[.]*\#						{comments++; BEGIN COM2;}

.|\n						counter++;						/* discard everything else */

%%
			/*** C Code section ***/

int main(void){

	printf("\bPDOC - Popcorn Compiler Documentation Generator - dsrb\n\nComments found :\n");
	/* Call the lexer, then quit. */
	yylex();

	printf("Stats:\nTotal Comments : %d\nTotal Characters in Comments : %d\nTotal Characters in analysis : %d\n", comments, char_counter, counter + char_counter);
	
	return 0;
}

int yywrap(void){
	return 1;
}
