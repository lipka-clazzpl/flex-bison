%option yylineno noyywrap nodefault case-sensitive

%{

	char *currfname;

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

[a-zA-Z]+('[s|t])?	{ addref(currfname, yytext, yylineno); }
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
	r->filename = filename;
	r->lineno   = lineno;
	r->next     = sp->reflist; // zamiana pierwszego elementu
	sp->reflist = r;

	return;
}

// qsort sortuje w rosnacej kolejnosci
int symcompare(const void *s1, const void *s2) {
	const struct symbol *sp1 = s1;
	const struct symbol *sp2 = s2;

	if(!sp1->name) {
		if(!sp2->name) {
		  return 0;
		}
		return 1; // 1 = s1 > s2, puste elementy zostana wypchniete na koniec 
	}
	if(!sp2->name) return -1; // ostatnia mozliwosc, wypycham puste sp2 na koniec
                                  // -1 = s1 < s2 , s2 wedruje na koniec jako ze 
				  // kolejnosc jest rosnaca

	return strcmp(sp1->name, sp2->name);
}

void printrefs() {
	struct symbol *sp;

	qsort(symtab, NHASH, sizeof(struct symbol), *symcompare);

	for(sp = symtab ; sp->name && sp < symtab + NHASH; sp++) {
		// odwrocenie listy referencji do symbolu
		struct ref *rpp = 0;
		struct ref *rp  = sp->reflist;
		struct ref *rpn;

		do {
			// niezmienniki
			rpn = rp->next;

			// ustawienie dla pary aktualny poprzedni
			rp->next = rpp;

			// ustawienia dla pary aktualny nastepny
			rpp = rp;
			rp = rpn;
		} while (rp);

		char *prevfilename;
		printf("%10s", sp->name);
		for(rp = rpp; rp; rp = rp->next) {
			if(rp->filename != prevfilename) { 
				printf(" %s :", rp->filename); 
				prevfilename = rp->filename;
			}
			printf(" %d", rp->lineno);
		}

		printf("\n");
	}
}

int main(int argc, char** argv) {
	if(argc < 2) {
		currfname = "(stdin)";
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
			currfname = argv[i];
			yyrestart(f);
			yylineno = 1;
			yylex();
			fclose(f);
		}
	}

	printrefs();
}
