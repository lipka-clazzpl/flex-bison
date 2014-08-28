ch2-4: ch2-4.l
	flex ch2-4.l
	cc -o $@ lex.yy.c 

ch2-3: ch2-3.l
	flex ch2-3.l
	cc -o $@ lex.yy.c 

ch2-1: ch2-1.l
	flex ch2-1.l
	cc -o $@ lex.yy.c

ex1-3a: ex1-3a.l ex1-3a.y
	bison -d ex1-3a.y
	flex ex1-3a.l
	cc -o $@ ex1-3a.tab.c lex.yy.c -lfl

ex1-3: ex1-3.l ex1-3.y
	bison -d ex1-3.y
	flex ex1-3.l
	cc -o $@ ex1-3.tab.c lex.yy.c -lfl

ex1-2: ex1-2.l ex1-2.y
	bison -d ex1-2.y
	flex ex1-2.l
	cc -o $@ ex1-2.tab.c lex.yy.c -lfl

ch1-5: ch1-5.l ch1-5.y
	bison -d ch1-5.y
	flex ch1-5.l
	cc -o $@ ch1-5.tab.c lex.yy.c -lfl

ch1-4: ch1-4.l 
	flex ch1-4.l
	cc -o $@ lex.yy.c -lfl

clean:
	rm -f kolek.o dolek.o
