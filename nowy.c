#include <stdio.h>

struct symbol {
	char *name;
	struct ref *reflist;
};


	
#define NHASH 9997
struct symbol symtab[NHASH]; // jak wyglada pamięć w tym przypadku?

void main(void) {
	struct symbol *sp = &symtab[12];

	printf("Wskaźnik %p.\n", sp); // nie jest nullem
	printf("Nazwa %s.\n", sp->name);

	if(!sp->name) { printf("galaz 1"); } else { printf("galaz 2"); }

}
