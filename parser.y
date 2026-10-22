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
    expression '\n' { printf("Sintaxis correcta. Expresion evaluada con exito.\n"); }
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
    fprintf(stderr, "Error sintactico: %s\n", s);
}

int main(void) {
    return yyparse();
}