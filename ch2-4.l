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
	struct symbol lookup(const char* );

	void addref(const char* ,const char*, int); 
%}

%%
a |
an |
of |
the	{/* pomiń */ }

[a-zA-Z]+('[s|t])?	{	addref(YY_CURRENT_BUFFER->, yytext, yylineno);//TODO }

%%
