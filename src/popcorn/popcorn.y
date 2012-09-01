/* POPCORN COMPILER - BYACC dsrb@Skywalker IST-TP LEIC n.º 65893  - 2010 */
%{
#include <stdio.h>
#include "lib/node.h"
#include "lib/tabid.h"
#include "lib/postfix.h"

extern FILE *yyin;
extern int yylineno, real_flag;

%}

%union{
	int i;
	char* c;
	Node* n;
}

%type<i> INTEGER CONST INT_NUMBER
%type<c> ID STR 
%type<n> expression program statement statement_list number_list const multi_atrib function compound_statement const_list decl_var_list if_statement
%type<n> while_statement do_while_statement extra_statement ultra_statement bonus_statement extra_statement_list expression_list decl_var array_id_list
%type<n> function_call lvalue '!' OUT '?' number function_definition declaration value id_list id_fn_list elif_statement elif_def for_statement iter for_start cond 

%token IF ELSE ELIF THEN DO WHILE UNTIL ENDIF DONE BREAK CONTINUE EXTERN END NEWLINE NEWBLOCK OLDBLOCK INTEGER REAL CONST VAR INIT REAL_NUMBER STATEMENT

%nonassoc '!' OUT
%right '=' ADDEDATTRIB
%left OR_OP
%left AND_OP
%nonassoc EQ_OP NE_OP
%left IMPLICA
%nonassoc '<' '>' GE_OP LE_OP
%left '+' '-'
%left '*' '/' '%'
%nonassoc INC DEC '?'
%right identity simetric NOT
%nonassoc '@'
%right EXP
%left ID STR INT_NUMBER REAL_NUMBER function_priority parentesis array_priority


%token PROGRAM FUNCTION FNNAME ALLOCA COMPOUND_STAT STATEMENT ULTRA BONUS IDENTITY SIMETRIC ARRAY CALL LVALUE2 ARRAYINDEX IDINIT IDFUNC IDCALL IDLVALUE
%token NUM_LIST EXPRESSION_LIST DECL_VAR_LIST CONST_LIST EXTRA_STAT_LIST STATEMENT_LIST NEG LVALUE PRINTSTUFF OTHERPRINT IDCONST IDARRAYINDEX
%token IDARRAY LVALUEOUT LVALUEOUTLN FOR ADDEDATTRIB EXPATTRIB MODATTRIB DIVATTRIB MULATTRIB MINUSATTRIB

%start start

%%

start			:	program									{ evaluate($1); freeNode($1); }
			;

program			:	function_definition							{ $$ = $1; }
			|	declaration NEWLINE							{ $$ = $1; }
			|	program function_definition						{ $$ = subNode(PROGRAM, 2, $1, $2); }
			|	program declaration NEWLINE						{ $$ = subNode(PROGRAM, 2, $1, $2); }
			|	error NEWLINE								{ $$ = 0; }
			;

declaration 		:	const									{ $$ = $1; }
			|	EXTERN id_fn_list							{ $$ = subNode(EXTERN, 1, $2); }
			|	EXTERN INTEGER id_fn_list						{ $$ = subNode(EXTERN, 1, $3); }
			|	EXTERN REAL id_fn_list							{ $$ = subNode(EXTERN, 1, $3); }
			|	INIT ID '=' '[' number_list ']'						{ $$ = subNode(INIT, 2, subNode(ID, 1, strNode(IDINIT, $2), $5)); }
			|	INIT INTEGER ID '=' '[' number_list ']'					{ $$ = subNode(INIT, 2, subNode(ID, 1, strNode(IDINIT, $3), $6)); }
			|	INIT REAL ID '=' '[' number_list ']'					{ $$ = 0; }
			;

const	 		:	CONST multi_atrib							{ $$ = $2; }
			|	CONST ID '=' '[' number_list ']'					{ $$ = subNode(CONST, 3, subNode(ID, 1, strNode(IDCONST, $2), $5), 0); }
			;

multi_atrib		:	ID '=' value								{ $$ = subNode(CONST, 3, subNode(ID, 1, strNode(IDCONST, $1), $3), 0); }
			|	ID ',' multi_atrib ',' value						{ $$ = subNode(CONST, 3, subNode(ID, 1, strNode(IDCONST, $1), $3, $5)); }
			;

function_definition	:	INTEGER function NEWLINE NEWBLOCK compound_statement END NEWLINE	{ $$ = subNode(FUNCTION, 2, $2, $5); }
			|	REAL function NEWLINE NEWBLOCK compound_statement END NEWLINE	 	{ $$ = 0; }
			|	function NEWLINE NEWBLOCK compound_statement END NEWLINE		{ $$ = subNode(FUNCTION, 2, $1, $4); }
			|	error END NEWLINE							{ $$ = 0; }
			;

function		:	ID '(' id_list ')'							{ $$ = subNode(FNNAME, 2, subNode(ID, 1, strNode(IDFUNC, $1), $3)); }
			|	ID '(' ')'								{ $$ = subNode(FNNAME, 1, subNode(ID, 1, strNode(IDFUNC, $1))); }
			|	ID '(' error ')'							{ $$ = 0; }
			;

compound_statement	:	const_list NEWLINE decl_var_list statement_list				{ $$ = subNode(COMPOUND_STAT, 3, $1, $3, $4); }
			|	const_list NEWLINE statement_list					{ $$ = subNode(COMPOUND_STAT, 3, $1, $3, 0); }
			|	decl_var_list statement_list						{ $$ = subNode(COMPOUND_STAT, 3, $1, $2, 0); }
			|	statement_list								{ $$ = $1; }
			;

statement		:	OLDBLOCK								{ $$ = 0; }	
			|	NEWBLOCK								{ $$ = 0; }
			|	NEWLINE									{ $$ = 0; }
			|	if_statement NEWLINE							{ $$ = $1; }
			|	while_statement NEWLINE							{ $$ = $1; }
			|	do_while_statement NEWLINE						{ $$ = $1; }
			|	for_statement NEWLINE							{ $$ = $1; }
			|	expression NEWLINE							{ $$ = $1; }
			|	'[' ID ']' EQ_OP expression NEWLINE					{ $$ = subNode(ALLOCA, 2, strNode(ID, $2), $5);}
			;

extra_statement		:	statement								{ $$ = subNode(STATEMENT, 1, $1); }
			|	CONTINUE NEWLINE							{ $$ = nilNode(CONTINUE); }
			|	CONTINUE INT_NUMBER NEWLINE						{ $$ = intNode(CONTINUE, $2); }
			|	BREAK NEWLINE								{ $$ = nilNode(BREAK); }
			|	BREAK INT_NUMBER NEWLINE						{ $$ = intNode(BREAK, $2); }
			;

ultra_statement		:	NEWLINE NEWBLOCK decl_var_list extra_statement_list			{ $$ = subNode(ULTRA, 2, $3, $4); }
			|	NEWLINE NEWBLOCK extra_statement_list					{ $$ = $3; }
			;

bonus_statement		: 	NEWLINE NEWBLOCK decl_var_list statement_list				{ $$ = subNode(BONUS, 2, $3, $4); }
			|	NEWLINE NEWBLOCK statement_list						{ $$ = $3; }
			;

while_statement		: 	WHILE expression DO ultra_statement DONE				{ $$ = subNode(WHILE, 3, $2, $4, 0); }
			|	WHILE expression DO ultra_statement ELSE bonus_statement DONE		{ $$ = subNode(WHILE, 3, $2, $4, $6); }
			|	WHILE error DONE							{ $$ = 0; }
			;

do_while_statement	:	DO ultra_statement UNTIL expression DONE 				{ $$ = subNode(DO, 3, $2, $4, 0); }
			|	DO ultra_statement UNTIL expression ELSE bonus_statement DONE		{ $$ = subNode(DO, 3, $2, $4, $6); }
			|	DO error DONE								{ $$ = 0; }
			;

for_statement		:	FOR for_start cond iter DO ultra_statement DONE 			{ $$ = subNode(FOR, 4, $2, $3, $4, $6); }
			|	FOR for_start cond iter DO NEWLINE DONE					{ $$ = subNode(FOR, 4, $2, $3, $4, 0); }
			|	FOR error DONE								{ $$ = 0; }
			;

for_start		:	expression_list ';'							{ $$ = $1; }
			|	';'									{ $$ = 0; }
			;

cond			:	expression ';'								{ $$ = $1; }
			|	';'									{ $$ = 0; }
			;

iter			:	expression_list								{ $$ = $1; }
			|										{ $$ = 0; }
			;

if_statement		:	IF expression THEN ultra_statement ENDIF				{ $$ = subNode(IF, 4, $2, $4, 0, 0); }
			|	IF expression THEN ultra_statement elif_statement ENDIF			{ $$ = subNode(IF, 4, $2, $4, $5, 0);}
			|	IF expression THEN ultra_statement ELSE bonus_statement ENDIF		{ $$ = subNode(IF, 4, $2, $4, $6, 0); }
			|	IF expression THEN ultra_statement elif_statement ELSE bonus_statement ENDIF		{ $$ = subNode(IF, 4, $2, $4, $5, $7); }
			|	error ENDIF								{ $$ = 0; }
			;

elif_def		:	ELIF expression THEN ultra_statement					{ $$ = subNode(ELIF, 2, $2, $4); }
			;

elif_statement		:	elif_def								{ $$ = $1; }
			|	elif_statement elif_def							{ $$ = addNode($1, $2, $1->value.sub.num); }
			;

decl_var		:	VAR array_id_list NEWLINE						{ $$ = subNode(VAR, 1, $2); }
			|	VAR INTEGER array_id_list NEWLINE					{ $$ = subNode(VAR, 1, $3); }
			|	VAR REAL array_id_list NEWLINE						{ $$ = 0; }
			|	VAR error NEWLINE							{ $$ = 0; }
			;

expression		:	function_call			%prec function_priority			{ $$ = $1; }
			|	'(' expression ')'		%prec parentesis			{ $$ = $2; }
			|	INC lvalue								{ $$ = subNode(INC, 1, $2); }
			|	DEC lvalue								{ $$ = subNode(DEC, 1, $2); }
			|	lvalue INC								{ $$ = subNode(INC, 1, $1); }
			|	lvalue DEC								{ $$ = subNode(DEC, 1, $1); }
			|	expression '+' expression						{ $$ = subNode('+', 2, $1, $3); }
			|	expression '-' expression						{ $$ = subNode('-', 2, $1, $3); }
			|	expression '*' expression						{ $$ = subNode('*', 2, $1, $3); }
			|	expression '/' expression						{ $$ = subNode('/', 2, $1, $3); }
			|	expression EXP expression						{ $$ = subNode(EXP, 2, $1, $3); }
			|	expression '%' expression						{ $$ = subNode('%', 2, $1, $3); }
			|	lvalue '=' expression							{ $$ = subNode('=', 2, $1, $3); }
			|	lvalue ADDEDATTRIB expression						{ $$ = subNode(ADDEDATTRIB, 2, $1, $3); }
/*			|	lvalue MINUSATTRIB expression						{ $$ = subNode(MINUSATTRIB, 2, $1, $3); }
			|	lvalue MULATTRIB expression						{ $$ = subNode(MULATTRIB, 2, $1, $3); }
			|	lvalue DIVATTRIB expression						{ $$ = subNode(DIVATTRIB, 2, $1, $3); }
			|	lvalue MODATTRIB expression						{ $$ = subNode(MODATTRIB, 2, $1, $3); }
			|	lvalue EXPATTRIB expression						{ $$ = subNode(EXPATTRIB, 2, $1, $3); }
*/			|	expression AND_OP expression						{ $$ = subNode(AND_OP, 2, $1, $3); }
			|	expression OR_OP expression						{ $$ = subNode(OR_OP, 2, $1, $3); }
			|	expression EQ_OP expression						{ $$ = subNode(EQ_OP, 2, $1, $3); }
			|	expression NE_OP expression						{ $$ = subNode(NE_OP, 2, $1, $3); }
			|	expression GE_OP expression						{ $$ = subNode(GE_OP, 2, $1, $3); }
			|	expression LE_OP expression						{ $$ = subNode(LE_OP, 2, $1, $3); }
			|	expression '<' expression						{ $$ = subNode('<', 2, $1, $3); }
			|	expression '>' expression						{ $$ = subNode('>', 2, $1, $3); }
			|	expression IMPLICA expression						{ $$ = subNode(IMPLICA, 2, $1, $3); }
			|	'+' expression			%prec identity				{ $$ = $2; }
			|	'-' expression			%prec simetric				{ $$ = subNode(SIMETRIC, 1, $2); }
			|	'@' lvalue								{ $$ = subNode('@', 1, $2); }
			|	NOT expression								{ $$ = subNode(NOT, 1, $2); }
			|	expression '!'								{ $$ = subNode('!', 1, subNode(PRINTSTUFF, 1, $1)); }
			|	expression OUT								{ $$ = subNode(OUT, 1,subNode(PRINTSTUFF, 1, $1)); }
			|	lvalue '?'								{ $$ = subNode('?', 1, $1); }
			|	STR 									{ $$ = strNode(STR, $1); }
			|	lvalue									{ $$ = $1; }
			|	number									{ $$ = $1; }
			;


lvalue			:	ID									{ $$ = subNode(ID, 1, strNode(IDLVALUE, $1)); }
			|	ID '[' expression ']'		%prec array_priority			{ $$ = subNode(ARRAYINDEX, 2, subNode(ID, 1, strNode(IDARRAYINDEX, $1), $3)); }
			;

function_call		:	ID '(' expression_list ')'						{ $$ = subNode(CALL, 2, strNode(IDCALL, $1), $3); }
			|	ID '(' ')'								{ $$ = subNode(CALL, 1, strNode(IDCALL, $1)); }
			;

number			: 	INT_NUMBER								{ $$ = intNode(INT_NUMBER, $1); }
			|	REAL_NUMBER								{ $$ = 0; }
			;

value			:	number									{ $$ = $1; }
			|	STR									{ $$ = strNode(STR, $1); }
			;
			
number_list		:	number									{ $$ = subNode(NUM_LIST, 1, $1); }
			|	'-' number								{ $$ = subNode(NUM_LIST, 1, subNode(NEG, 1, $2)); }
			|	number_list ',' number							{ $$ = addNode($1, $3, $1->value.sub.num); }
			|	number_list ',' '-' number						{ $$ = addNode($1, $4, $1->value.sub.num); }
			;

id_list			:	ID									{ $$ = strNode(ID, $1); }
			|	id_list ',' ID								{ $$ = addNode($1, strNode(ID, $3), $1->value.sub.num);}
			;

id_fn_list		:	ID									{ $$ = subNode(ID, 1, strNode(ID, $1)); }
			|	function								{ $$ = $1; }
			|	id_fn_list ',' ID							{ $$ = addNode($1, subNode(ID, 1, strNode(ID, $3)), $1->value.sub.num); }
			|	id_fn_list ',' function							{ $$ = addNode($1, $3, $1->value.sub.num); }
			;

array_id_list		:	lvalue									{ $$ = subNode(LVALUE2, 1 ,subNode(LVALUE, 1, $1)); }
			|	ID '[' ']'								{ $$ = subNode(ID, 1, strNode(IDARRAY, $1)); }
			|	array_id_list ',' ID '[' ']'						{ $$ = addNode($1, strNode(ID, $3), $1->value.sub.num); }
			|	array_id_list ',' lvalue						{ $$ = addNode($1, subNode(LVALUE, 1, $3), $1->value.sub.num); }
			;

expression_list		:	expression								{ $$ = subNode(EXPRESSION_LIST, 1, $1); }
			|	expression_list ',' expression						{ $$ = addNode($1, $3, $1->value.sub.num); }
			;

decl_var_list		:	decl_var								{ $$ = subNode(DECL_VAR_LIST, 1, $1); }
			|	decl_var_list decl_var							{ $$ = addNode($1, $2, $1->value.sub.num); }
			;

const_list		:	const									{ $$ = subNode(CONST_LIST, 1, $1); }
			|	const_list NEWLINE const						{ $$ = addNode($1, $3, $1->value.sub.num); }
			;

extra_statement_list	:	extra_statement								{ $$ = subNode(EXTRA_STAT_LIST, 1, $1); }
			|	extra_statement_list extra_statement					{ $$ = addNode($1, $2, $1->value.sub.num); }
			;

statement_list		:	statement								{ $$ = subNode(STATEMENT_LIST, 1, $1); }
			|	statement_list statement						{ $$ = addNode($1, $2, $1->value.sub.num); }
			;

%%

char **yynames = (char **) yyname;

