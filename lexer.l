
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"

%}

%%

[0-9]+          { yylval.number = atoi(yytext); return NUMBER; }
[ \t\r]+        { /* Ignorar espacios */ }
\n              { return '\n'; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
.               { return yytext[0]; }

%%
