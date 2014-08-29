%option yylineno noyywrap nodefault case-sensitive

%{

	struct symbol {
		char *name;
		struct ref *reflist;
	};

	struct ref {
		struct ref *next;
		int lineno;
		char *filename;			
	};

	#define NHASH 9997
	struct symbol symtab[NHASH];
	
	/* zwraca zawsze symbol, jak jest to ten co był zdefiniowany, jeśli nie ma to go tworzy */
	/* wołane w momencie kiedy jest pewność, że to co dostanie to nie jest słowo kluczowe,itp.*/

	struct symbol* lookup(const char* );

	void addref(const char* ,const char*, int); 
%}

%%

a |
an |
of |
the {/* pomiń */ }

[a-zA-Z]+('[s|t])?	{ addref(YY_CURRENT_BUFFER->yy_ch_buf, yytext, yylineno); }
.|\n	{ /* ignoruj wszytkie pozostałe napisy */ }

%%

// czy ten static jest tutaj uzasadniony?
static unsigned symhash( const char * symbol_name) {
	unsigned int hash = 0;
	unsigned c; // na pewno? samo unsigned wystarczy?
	while(c=*symbol_name++) { hash = hash * c ^ 9; }

	return hash;
}

struct symbol symtab[NHASH];  // zaden z dzielnikow 9997 nie jest parzysty, tablica hashujaca bedzie bardziej rozrzucona

struct symbol* lookup(const char * symbol_name) {
	struct symbol *sp = &symtab[symhash(symbol_name)%NHASH];

	// to co w bloku ponizej i mozesz wykonac maksymalnie NHASH razy
	int scount = NHASH;

	while (--scount) {
 		// czy tutaj zawsze trafi mi sie wskaźnik który nie jest nullem?

		// sprawdzenie czy trafione za pierwszym razem
                if(sp->name && !strcasecmp(symbol_name, sp->name)) { return sp; }

		// nowy wpis
		// sp->name zwróci wartość NULL, która jest domyślnie równa 0
 		// if( ! 0 ) === if( ! false ) === if( true ) <-- dla wskaźnika równego NULL
		if(!sp->name) {
			sp->name = strdup(symbol_name); // blad amatora , symbol_name jest wskaznikiem na yytext
			sp->reflist = 0;

			return sp;
		}

		if(++sp >= symtab + NHASH) {
			sp = symtab;
		}	
	}
	// nie ma maiejsca na nowy symbol to gwarantuje pętla po scount
	fputs("Tablica symboli przepełniona", stderr);
	abort();
}

void addref(const char* filename, const char* symbol_name, int lineno) {
	struct ref *r;
	struct symbol *sp = lookup(symbol_name);

	printf("addref: sp=%s\n", sp->name);

	// jeżeli zgadzają się wszystkie dane dot. referecji, nie ma potrzeby dopisywać jeszcze raz
	// dlaczego to nie jest pętla?
	if(sp->reflist && sp->reflist->lineno == lineno && sp->reflist->filename == filename) {
		return;
	}

	r = malloc(sizeof(struct ref));

	return;
}

void printrefs() {
	struct symbol *sp;
	int i;
	printf("\n");
	for(sp = symtab ; sp < symtab + NHASH; sp++) {
		//if(sp->name) printf("sp->name = %s\t", sp->name);
		if(sp->name) {
			printf("sp->name = %s\t", sp->name); // nie zdarzyl tego na wyjsciu wypisac
			do {
				printf("linia %d, plik %s", sp->reflist->lineno, sp->reflist->filename);
			} while(sp->reflist->next);
		}
	}
	printf("\n");
}

int main(int argc, char** argv) {
	if(argc < 2) {
		yylineno = 1;
		yylex();	
	}
	else {
		int i;
		for(i = 1; i < argc; i++) {
			FILE *f = fopen(argv[i], "r");
			if(!f) { 
				perror(argv[i]);
				exit(1);
			}
			yyrestart(f);
			yylineno = 1;
			yylex();
			fclose(f);
		}
	}

	printrefs();
}
