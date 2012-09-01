/* POPCORN COMPILER - code.c dsrb@Skywalker IST-TP LEIC n.º 65893  - 2010 */
#include <stdio.h>
#include <stdlib.h>
#include "lib/node.h"			//	OVERLOADING, ELIF, ALLOCA, CONTINUE, BREAK, +=..., var!, src das restantes func, frontend gcc, REAIS,
#include "y.tab.h"
#include "lib/tabid.h"
#include "lib/postfix.h"

#define SUB(x)  value.sub.n[x]

#define mais attrib!='+'
#define menos attrib!='-'
#define mult attrib!='*'
#define div attrib!='/'
#define mod attrib!='%'
#define exp attrib!=EXP
#define inteiro attrib!=INT_NUMBER


#define verif(p) (p->inteiro && p->mais && p->menos && p->mult && p->div && p->mod && p->exp)


static int lbl;
static void eval(Node *p);
static FILE *out;
static char *mklbl(int);
int args, print;

int pow_flag = 0, printer_flag = 0, offset = 0;

void evaluate(Node *p){
	extern char *outfile, **yynames;
	extern int errors, tree, real_flag;

	if(real_flag){
		printf("No floating point support @ line %d\n", real_flag);
		exit(1);
	}
	
	if (tree > 0) {
		printNode(p, stdout, yynames);
		return;
	}
	if (outfile == 0)
		outfile = "out.asm";
	if (!(out = fopen(outfile, "w"))) {
		perror(outfile);
		exit(2);
	}

	eval(p);
	/* import library functions */
	fprintf(out, pfEXTRN, "readi");
	fprintf(out, pfEXTRN, "printi");
	fprintf(out, pfEXTRN, "prints");
	fprintf(out, pfEXTRN, "println");
	
	if(pow_flag)
		fprintf(out, pfEXTRN, "power");
	if(printer_flag)
		fprintf(out, pfEXTRN, "printer");
	
	fclose(out);
	if (errors > 0) unlink(outfile);
}


static void eval(Node *p){

	int i, lbl1, lbl2, size, temp = 0, attrib = 1;
	char *name;

	if (p == 0) return;
	switch(p->attrib){

		case CONTINUE:
		/* JMP cond*/
			break;		
		case BREAK:
		/* JMP fim */
			break;		
		case ELIF:
		
			break;

		case FOR:
			eval(p->SUB(0));
			fprintf(out, pfLABEL, mklbl(lbl1 = ++lbl));
			eval(p->SUB(1));
			fprintf(out, pfJZ, mklbl(lbl2 = ++lbl));
			IDpush();
			eval(p->SUB(3));
			eval(p->SUB(2));
			IDpop();
			fprintf(out, pfJMP, mklbl(lbl1));
			fprintf(out, pfLABEL, mklbl(lbl2));
			break;

		case ALLOCA:
			eval(p->SUB(1));
			fprintf(out, pfALLOC);
			fprintf(out, pfSP);
			eval(p->SUB(0));
			fprintf(out, pfSTORE);
			break;

		case EXTERN:						/* extern declarations        */
			for (i = 0; i < p->value.sub.num; i++){
				name = p->SUB(i)->SUB(0)->value.s;
				IDnew(EXTERN, name, p->SUB(i)->value.sub.num);
				fprintf(out, pfEXTRN, name);
			}
			break;
		case INIT:
			name = p->SUB(0)->SUB(0)->value.s;
			IDnew(INIT, name, p->SUB(1)->value.sub.num);
			fprintf(out, pfDATA);
			fprintf(out, pfALIGN);				/* make sure we are aligned   */
			
			fprintf(out, pfGLOBL, name, pfOBJ);
			fprintf(out, pfLABEL, name);
			for(i = 0; i < p->SUB(1)->value.sub.num; i++){
				fprintf(out, pfCONST, p->SUB(1)->SUB(i)->value.i);
			}
			fprintf(out, pfTEXT);
			fprintf(out, pfALIGN);				/* make sure we are aligned   */
			break;
		case CONST:
			fprintf(out, pfRODATA);
			fprintf(out, pfALIGN);

			name = p->SUB(0)->SUB(0)->value.s;
			IDnew(CONST, name, p->SUB(1)->value.sub.num);				
			fprintf(out, pfLABEL, name);			/* name variable location     */
			for (temp = 0; temp < p->SUB(1)->value.sub.num; temp++)
				fprintf(out, pfCONST, p->SUB(1)->SUB(temp)->value.i);
			fprintf(out, pfTEXT);
			fprintf(out, pfALIGN);
			break;
			
		case LVALUE2:
			for (i = 0; i < p->value.sub.num; i++)
				eval(p->SUB(i));
			break;
		case LVALUE:
  			name = p->SUB(0)->SUB(0)->value.s;

			if(p->SUB(0)->SUB(0)->attrib == IDLVALUE)
				IDnew(INT_NUMBER, name, offset);
			else if (p->SUB(0)->SUB(0)->attrib == IDARRAY)
				IDnew(ARRAY, name, offset);
			else{
				name = p->SUB(0)->SUB(0)->SUB(0)->value.s;
				offset -= 4 * p->SUB(0)->SUB(1)->value.i;
				IDnew(ARRAYINDEX, name, offset);
				break;
			}
			offset -= 4;
			break;
		case VAR:
			for (i = 0; i < p->value.sub.num; i++){
				eval(p->SUB(i));
			}
			break;

		case ARRAYINDEX:
			eval(p->SUB(1));
			if (p->SUB(1)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfINT, 4);				/* push an integer	      */
			fprintf(out, pfMUL);
			eval(p->SUB(0));
			fprintf(out, pfADD);

			break;
		case ARRAY:
			eval(p->SUB(0));	
			break;

		case FNNAME:
			name = p->SUB(0)->SUB(0)->value.s;
			if(p->value.sub.num == 2)
				temp = p->SUB(1)->value.sub.num;
			IDnew(FNNAME, name, temp);
			IDpush();
			IDnew(INT_NUMBER, name, -4);
			
			offset = -8;
			fprintf(out, pfTEXT);
			fprintf(out, pfALIGN);
			fprintf(out, pfGLOBL, name, pfFUNC);
			fprintf(out, pfLABEL, name);
			fprintf(out, pfENTER, args + 4);
			break;
		case FUNCTION:
			args = count_args(p);
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			fprintf(out, pfLOCAL, -4);
			fprintf(out, pfLOAD);
			fprintf(out, pfPOP);
			fprintf(out, pfLEAVE);
			fprintf(out, pfRET);
			IDpop();
			break;

		case INT_NUMBER:
			fprintf(out, pfINT, p->value.i);		/* push an integer	      */
			break;
		case ID:						/* */
			name = p->SUB(0)->value.s;
			switch(p->SUB(0)->attrib){
				case IDLVALUE:
				case IDARRAY:
				case IDARRAYINDEX:
					temp = IDfind(name, &attrib);
					fprintf(out, pfLOCAL, attrib);
					break;
				default:
					fprintf(out, pfADDR, name);
					break;
			}
			break;	
		case DO:
			fprintf(out, pfLABEL, mklbl(lbl1 = ++lbl));
			IDpush();
			eval(p->SUB(0));
			IDpop();
			fprintf(out, pfLABEL, mklbl(lbl2 = ++lbl));
			eval(p->SUB(1));
			fprintf(out, pfJNZ, mklbl(lbl1));
			if (p->value.sub.num > 2){			/* do else 			*/
				IDpush();
				eval(p->SUB(2));
				IDpop();
			}
			break;		
		case WHILE:
			fprintf(out, pfLABEL, mklbl(lbl1 = ++lbl));
			eval(p->SUB(0));
			fprintf(out, pfJZ, mklbl(lbl2 = ++lbl));
			IDpush();
			eval(p->SUB(1));
			IDpop();
			fprintf(out, pfJMP, mklbl(lbl1));
			fprintf(out, pfLABEL, mklbl(lbl2));
			if (p->value.sub.num > 2){			/* while else 			*/
				IDpush();
				eval(p->SUB(2));
				IDpop();
			}
			break;
		case CALL:
			name = p->SUB(0)->value.s;
			if(p->value.sub.num == 2) {	
				for(i = p->SUB(1)->value.sub.num; i > 0; i--){
					eval(p->SUB(i));		/* evaluate argument	      */
					if (p->SUB(i)->attrib != INT_NUMBER)
						fprintf(out, pfLOAD);
				}
			}
			fprintf(out, pfCALL, name);
			fprintf(out, pfTRASH, i);			/* remove the return value    */
			fprintf(out, pfPUSH);
			break;	

		case STR:						/* generate the string	      */			 
			fprintf(out, pfRODATA);				/* strings are DATA readonly  */
			fprintf(out, pfALIGN);				/* make sure we are aligned   */
			fprintf(out, pfLABEL, mklbl(lbl1 = ++lbl));	/* give the string a name     */
			fprintf(out, pfSTR, p->value.s); 		/* output string characters   */
				/* make the call */
			fprintf(out, pfTEXT);				/* return to the TEXT segment */
			fprintf(out, pfALIGN);				/* make sure we are aligned   */
			fprintf(out, pfADDR, mklbl(lbl1));
			break;

		case PRINTSTUFF:
			eval(p->SUB(0));
			if(p->SUB(0)->attrib == ID){
				fprintf(out, pfLOAD);
				fprintf(out, pfCALL, "printi");		/* call the print function    */
			}
			else if(p->SUB(0)->attrib == STR){
				fprintf(out, pfCALL, "prints");		/* call the print function    */
			}
			else if(p->SUB(0)->attrib == INT_NUMBER){
				fprintf(out, pfCALL, "printi");		/* call the print function    */
			}
			print = 0;
			break;
		case '!':
			print = 1;
			eval(p->SUB(0));				/* determine the value        */
			fprintf(out, pfTRASH, 4);			/* delete the printed value   */
			break;		
		case OUT:
			print = 1;
			eval(p->SUB(0));				/* determine the value        */
			fprintf(out, pfCALL, "println");		/* print a newline	      */
			fprintf(out, pfTRASH, 4);			/* delete the printed value   */
			break;
		case IF:
			eval(p->SUB(0));
			if (p->SUB(0)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfJZ, mklbl(lbl1 = ++lbl));
			IDpush();
			eval(p->SUB(1));
			IDpop();
			if (p->value.sub.num > 2){			/* if else 			*/
				fprintf(out, pfJMP, mklbl(lbl2 = ++lbl));
				fprintf(out, pfLABEL, mklbl(lbl1));
				IDpush();
				eval(p->SUB(2));
				IDpop();
				lbl1 = lbl2;
			}
			fprintf(out, pfLABEL, mklbl(lbl1));
			break;

		case BONUS:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;	
		case COMPOUND_STAT:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;
		case CONST_LIST:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;	
		case DECL_VAR_LIST:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;	
		case EXPRESSION_LIST:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;
		case EXTRA_STAT_LIST:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;
		case NUM_LIST:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;	
		case PROGRAM:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;
		case STATEMENT:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;
		case STATEMENT_LIST:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;
		case ULTRA:
			for (i = 0; i < p->value.sub.num; i++)
	  			eval(p->SUB(i));
			break;		

		case AND_OP:
			eval(p->SUB(0));				/* evaluate first argument    */
			if (p->SUB(0)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfDUP);
			fprintf(out, pfJZ, mklbl(lbl1 = ++lbl));
			fprintf(out, pfTRASH, 4);
			eval(p->SUB(1));				/* evaluate second argument   */
			if (p->SUB(0)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfLABEL, mklbl(lbl1));
			break;
		case OR_OP:
			eval(p->SUB(0));				/* evaluate first argument    */
			if (p->SUB(0)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfDUP);
			fprintf(out, pfJNZ, mklbl(lbl1 = ++lbl));
			fprintf(out, pfTRASH, 4);
			eval(p->SUB(1));				/* evaluate second argument   */
			if (p->SUB(0)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfLABEL, mklbl(lbl1));
			break;
		case NOT:
			eval(p->SUB(0));				/* evaluate argument	      */
			if (p->SUB(0)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfINT, 0);
			fprintf(out, pfEQ);
			break;
		case '?':
			fprintf(out, pfCALL, "readi");
			fprintf(out, pfPUSH);
			eval(p->SUB(0));
			fprintf(out, pfSTORE);
			break;
		case '=':
			eval(p->SUB(1));				/* determine the new value    */
			if(p->SUB(1)->attrib == '='){
				eval(p->SUB(1)->SUB(0));
				fprintf(out, pfLOAD);
			}
			eval(p->SUB(0));	 			/* determine the new address  */
			fprintf(out, pfSTORE);				/* store the value at address */
			break;
		case '@':
			eval(p->SUB(0));				/* evaluate argument	      */
			break;
		case SIMETRIC:
			eval(p->SUB(0));				/* evaluate argument	      */
			if (p->SUB(0)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfNEG);				/* make the 2-compliment      */
			break;
		case INC:
			eval(p->SUB(0));				/* evaluate argument	      */
			fprintf(out, pfINCR, 1);
			break;		
		case DEC:
			eval(p->SUB(0));				/* evaluate argument	      */
			fprintf(out, pfDECR, 1);
			break;
		case ADDEDATTRIB:
			eval(p->SUB(0));
			fprintf(out, pfLOAD);
			eval(p->SUB(1));
			if (p->SUB(1)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfADD);

			eval(p->SUB(0));				/* determine the new address  */
			fprintf(out, pfSTORE);				/* store the value at address */			
			break;

/*		case MINUSATTRIB:
			eval(p->SUB(0));
			fprintf(out, pfLOAD);
			eval(p->SUB(1));
			if (p->SUB(1)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfSUB);

			eval(p->SUB(0));	 			
			fprintf(out, pfSTORE);							
			break;

		case MULATTRIB:
			eval(p->SUB(0));
			fprintf(out, pfLOAD);
			eval(p->SUB(1));
			if (p->SUB(1)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfMUL);

			eval(p->SUB(0));	 			
			fprintf(out, pfSTORE);							
			break;

		case DIVATTRIB:
			eval(p->SUB(0));
			fprintf(out, pfLOAD);
			eval(p->SUB(1));
			if (p->SUB(1)->attrib != INT_NUMBER)
				fprintf(out, pfDIV);
			fprintf(out, pfADD);

			eval(p->SUB(0));	 			
			fprintf(out, pfSTORE);							
			break;

		case MODATTRIB:
			eval(p->SUB(0));
			fprintf(out, pfLOAD);
			eval(p->SUB(1));
			if (p->SUB(1)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			fprintf(out, pfMOD);

			eval(p->SUB(0));	 			
			fprintf(out, pfSTORE);							
			break;

		case EXPATTRIB:
			eval(p->SUB(0));
			fprintf(out, pfLOAD);
			eval(p->SUB(1));
			if (p->SUB(1)->attrib != INT_NUMBER)
				fprintf(out, pfLOAD);
			pow_flag = 1;
			fprintf(out, pfCALL, "power");
			fprintf(out, pfTRASH, 8);
			fprintf(out, pfPUSH);

			eval(p->SUB(0));	 			
			fprintf(out, pfSTORE);							
			break;
*/
		default:	
			if(print){
				if(p->attrib == '+'){
					for (i = 0; i < p->value.sub.num; i++){
	  					eval(p->SUB(i));

						if(p->SUB(i)->attrib == ID){
							fprintf(out, pfLOAD);
							fprintf(out, pfCALL, "printi");		/* call the print function    */
						}
						else if(p->SUB(i)->attrib == INT_NUMBER){
							fprintf(out, pfCALL, "printi");		/* call the print function    */
						}
	  					else if (p->SUB(i)->attrib == STR){
							fprintf(out, pfCALL, "prints");			/* call the print function    */
						}
						else if(p->SUB(i)->attrib == '*'){
							eval(p->SUB(i)->SUB(1));				/* determine the value        */
							if (p->SUB(i)->SUB(1)->attrib != INT_NUMBER)
								fprintf(out, pfLOAD);

							eval(p->SUB(i)->SUB(0));				/* determine the value        */

							printer_flag = 1;
							fprintf(out, pfCALL, "printer");		/* print a newline	      */
							fprintf(out, pfTRASH, 4);			/* remove the return value    */	
						}
					}
				}
				else{
					eval(p->SUB(1));				/* determine the value        */
					if (p->SUB(1)->attrib != INT_NUMBER)
						fprintf(out, pfLOAD);

					eval(p->SUB(0));				/* determine the value        */

					printer_flag = 1;
					fprintf(out, pfCALL, "printer");		/* print a newline	      */
					fprintf(out, pfTRASH, 4);			/* remove the return value    */	
				}
			}
			else{

				eval(p->SUB(1));				/* evaluate first argument    */
				if (p->SUB(1)->attrib != INT_NUMBER)
					fprintf(out, pfLOAD);

				switch(p->attrib){	 			/* make the operation ...     */
					case '+':
						eval(p->SUB(0));				/* determine the new value    */
						if (verif(p->SUB(0)))
							fprintf(out, pfLOAD);				
			
						fprintf(out, pfADD);
						break;
					case '-':	
						eval(p->SUB(0));				/* determine the new value    */
						if (p->SUB(0)->attrib != INT_NUMBER && p->SUB(0)->attrib != '-')
							fprintf(out, pfLOAD);	

						fprintf(out, pfSUB); 
						break;
					case '*':
						eval(p->SUB(0));				/* determine the new value    */
						if (p->SUB(0)->attrib != INT_NUMBER && p->SUB(0)->attrib != '*')
							fprintf(out, pfLOAD);		

						fprintf(out, pfMUL);
						break;
					case '/':
						eval(p->SUB(0));				/* determine the new value    */
						if (p->SUB(0)->attrib != INT_NUMBER && p->SUB(0)->attrib != '/')
							fprintf(out, pfLOAD);	

						fprintf(out, pfDIV);
						break;
					case '%':
						eval(p->SUB(0));				/* determine the new value    */
						if (p->SUB(0)->attrib != INT_NUMBER && p->SUB(0)->attrib != '%')
							fprintf(out, pfLOAD);	

						fprintf(out, pfMOD);
						break;
					case EXP:
						eval(p->SUB(0));				/* determine the new value    */
						if (p->SUB(0)->attrib != INT_NUMBER && p->SUB(0)->attrib != EXP)
							fprintf(out, pfLOAD);	

						pow_flag = 1;
						fprintf(out, pfCALL, "power");
						fprintf(out, pfTRASH, 8);
						fprintf(out, pfPUSH);
						break;
					case '<':
						fprintf(out, pfLT); break;
					case '>':
						fprintf(out, pfGT); break;
					case GE_OP:
						fprintf(out, pfGE); break;
					case LE_OP:
						fprintf(out, pfLE); break;
					case NE_OP:
						fprintf(out, pfNE); break;
					case EQ_OP:
						fprintf(out, pfEQ); break;
					case IMPLICA:
						eval(p->SUB(0));
						fprintf(out, pfNOT);
						eval(p->SUB(1));
						fprintf(out, pfOR);
						break;

					default:
						printf("WTF? Unknown %d ('%c') !\n", p->attrib, p->attrib);
				}
			}
	}
}



static char *mklbl(int n){

	static char str[20];
	if (n < 0)
		sprintf(str, ".L%d", -n);
	else
		sprintf(str, "_L%d", n);
	return str;
}

int count_args(Node *p){

	int tmp = 0, i = 0;

	if(p->attrib == DECL_VAR_LIST)
		for(; i < p->SUB(0)->SUB(0)->value.sub.num; i++)
			tmp += 4;
	else
		for (i = 0; i < p->value.sub.num && p->SUB(i) != NULL; i++){
			tmp += count_args(p->SUB(i));
		}

	return tmp;
}


