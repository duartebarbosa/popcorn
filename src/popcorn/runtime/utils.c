

int power(int a, int b){

	register int tmp = a;

	if(b == 0) return 1;
	if(b == 1) return a;
	for(; b != 1; b--){
		a *= tmp;
	}

	return a;
}

int printer(char * string, int num){

	unsigned int i = 0;

	for(; i < num; i++)
		prints(string);

	return 0;
}


