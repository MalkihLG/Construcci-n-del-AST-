
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
%}

%%

"VAR"           { return VAR; }
"IMPRIMIR"       { return IMPRIMIR; }
"SI"             { return SI; }
"SINO"           { return SINO; }

[0-9]+           { yylval.numero = atoi(yytext); return NUMBER; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.texto = strdup(yytext);
    return IDENTIFICADOR;
}

[ \t\r\n]+       { /* Ignorar espacios y saltos */ }

"=="             { return IGUAL; }
">="             { return MAYOR_IGUAL; }
"<="             { return MENOR_IGUAL; }

"+"              { return '+'; }
"-"              { return '-'; }
"*"              { return '*'; }
"/"              { return '/'; }
"="              { return '='; }
">"              { return '>'; }
"<"              { return '<'; }
"{"              { return '{'; }
"}"              { return '}'; }
"("              { return '('; }
")"              { return ')'; }
";"              { return ';'; }

.                { return yytext[0]; }

%%
