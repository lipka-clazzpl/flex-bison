/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int string_offset = 0;
bool discard_string = false;
int comment_nestness = 0;
%}

%x COMMENT
%x STRING_CONSTANT

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN	        <-
LE 		<=
INT_CONST       [0-9]+

%%

 /*
  *  Nested comments
  */
"(*"	{ BEGIN (COMMENT); comment_nestness = 1; }
<COMMENT>"(*" { ++comment_nestness; }
<COMMENT>"*)" { if(--comment_nestness <= 0) { BEGIN (INITIAL); } }
<COMMENT><<EOF>>	{ BEGIN (INITIAL); cool_yylval.error_msg = "EOF in comment"; return ERROR; }
<COMMENT>\n   { ++curr_lineno; }
<COMMENT>.    { }

"*)"	{ cool_yylval.error_msg = "Unmatched *)"; return ERROR; }

"--".* {  }

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return (ASSIGN); }
{LE}			{ return (LE); }

 /*
  *  The single-character operators.
  */ 
";" |
"(" |
")" |
"{" |
"}" |
":" |
"+" |
"-" |
"*" |
"/" |
"@" |
"=" |
"<" |
"'" |
"," |
"~" |
"." 	{ return yytext[0]; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:"class")			{ return (CLASS); }

(?i:"else")			{ return (ELSE); }

"f"(?i:"alse")			{ cool_yylval.boolean = false; return (BOOL_CONST); }

"t"(?i:"rue")			{ cool_yylval.boolean = true; return (BOOL_CONST); }

(?i:"fi")			{ return (FI); }

(?i:"if")			{ return (IF); }

(?i:"in")			{ return (IN); }

(?i:"inherits")			{ return (INHERITS); }

(?i:"isvoid")			{ return (ISVOID); }

(?i:"let")			{ return (LET); }

(?i:"loop")			{ return (LOOP); }

(?i:"pool")			{ return (POOL); }

(?i:"then")			{ return (THEN); }

(?i:"while")			{ return (WHILE); }

(?i:"case")			{ return (CASE); }

(?i:"esac")			{ return (ESAC); }

(?i:"of")			{ return (OF); }

(?i:"new")			{ return (NEW); }

(?i:"not")			{ return (NOT); }

 /*
  * Integer constants
  */

{INT_CONST}			{ cool_yylval.symbol = inttable.add_string(yytext); return (INT_CONST); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"				{ string_buf_ptr = string_buf; string_offset = 0; discard_string = false; BEGIN (STRING_CONSTANT); }

<STRING_CONSTANT>\"		{ BEGIN (INITIAL); if(!discard_string) {*(string_buf_ptr + string_offset) = '\0'; cool_yylval.symbol = stringtable.add_string(string_buf); return (STR_CONST);} }

<STRING_CONSTANT>\\n		{ *(string_buf_ptr + string_offset) = '\n'; 
					if(++string_offset > MAX_STR_CONST - 1) { discard_string = true; cool_yylval.error_msg = "String constant too long"; return ERROR; } 
				}

<STRING_CONSTANT>\\t		{ *(string_buf_ptr + string_offset) = '\t'; 
					if(++string_offset > MAX_STR_CONST - 1) { discard_string = true; cool_yylval.error_msg = "String constant too long"; return ERROR; } 
				}

<STRING_CONSTANT>\\b		{ *(string_buf_ptr + string_offset) = '\b'; 
					if(++string_offset > MAX_STR_CONST - 1) { discard_string = true; cool_yylval.error_msg = "String constant too long"; return ERROR; } 
				}

<STRING_CONSTANT>\\f		{ *(string_buf_ptr + string_offset) = '\f'; 
					if(++string_offset > MAX_STR_CONST - 1) { discard_string = true; cool_yylval.error_msg = "String constant too long"; return ERROR; } 
				}

<STRING_CONSTANT>\\\0		{ 
					discard_string = true; cool_yylval.error_msg = "String contains escaped null character."; return ERROR;
				}

<STRING_CONSTANT>\\(.|\n)	{ *(string_buf_ptr + string_offset) = yytext[1]; 
					if(++string_offset > MAX_STR_CONST - 1) { discard_string = true; cool_yylval.error_msg = "String constant too long"; return ERROR; } 
					if(yytext[1] == '\n') ++curr_lineno;
				}

<STRING_CONSTANT>[^\0\\\n\"]+	{       char *yyptr = yytext;
					while(*yyptr) {
						*(string_buf_ptr + string_offset) = *yyptr++; 
						if(++string_offset > MAX_STR_CONST - 1) { discard_string = true; cool_yylval.error_msg = "String constant too long"; return ERROR; } 
					}
				}

<STRING_CONSTANT>\n		{ BEGIN (INITIAL); ++curr_lineno; if(!discard_string) {cool_yylval.error_msg = "Unterminated string constant"; return ERROR; } }

<STRING_CONSTANT>\0		{ discard_string = true; cool_yylval.error_msg = "String contains null character."; return ERROR; }

<STRING_CONSTANT><<EOF>>	{ BEGIN (INITIAL); cool_yylval.error_msg = "EOF in string constant"; return ERROR; }

\n				{ ++curr_lineno; }

 /*
  * Identifiers
  */

"self"				{ cool_yylval.symbol = idtable.add_string("self"); return OBJECTID; }
"SELF_TYPE"			{ cool_yylval.symbol = idtable.add_string("SELF_TYPE"); return TYPEID; }
[A-Z][a-zA-Z0-9_]*		{ cool_yylval.symbol = idtable.add_string(strdup(yytext)); return TYPEID; }

[a-z][a-zA-Z0-9_]*              { cool_yylval.symbol = idtable.add_string(strdup(yytext)); return OBJECTID; }

 /*
  * Whitespace
  */
[ \r\f\t\v]			{	}

.				{ cool_yylval.error_msg = yytext; return ERROR; }
%%
