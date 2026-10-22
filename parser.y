%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex(void);
%}

%token NUMBER
%left '+' '-'
%left '*' '/'

%%

program:
    expression '\n' { printf("Sintaxis correcta. Expresión evaluada con éxito.\n"); }
    ;

expression:
    NUMBER
  | expression '+' expression
  | expression '-' expression
  | expression '*' expression
  | expression '/' expression
  ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error sintáctico: %s\n", s);
}

int main(void) {
    return yyparse();
}