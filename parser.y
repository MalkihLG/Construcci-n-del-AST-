
%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Nodo {
    int id;
    char etiqueta[128];
    struct Nodo *hijo;
    struct Nodo *hermano;
} Nodo;

int yylex(void);
void yyerror(const char *mensaje);

static int siguiente_id = 0;

Nodo *crearNodo(const char *etiqueta) {
    Nodo *nuevo = calloc(1, sizeof(Nodo));

    if (nuevo == NULL) {
        perror("Error de memoria");
        exit(EXIT_FAILURE);
    }

    nuevo->id = siguiente_id++;
    snprintf(nuevo->etiqueta, sizeof(nuevo->etiqueta),
             "%s", etiqueta);

    return nuevo;
}

void agregarHijo(Nodo *padre, Nodo *hijo) {
    if (padre == NULL || hijo == NULL) return;

    if (padre->hijo == NULL) {
        padre->hijo = hijo;
        return;
    }

    Nodo *actual = padre->hijo;

    while (actual->hermano != NULL) {
        actual = actual->hermano;
    }

    actual->hermano = hijo;
}

Nodo *crearOperacion(const char *nombre,
                     Nodo *izquierda, Nodo *derecha) {
    Nodo *nodo = crearNodo(nombre);
    agregarHijo(nodo, izquierda);
    agregarHijo(nodo, derecha);
    return nodo;
}

Nodo *crearNumero(int numero) {
    char texto[128];

    snprintf(texto, sizeof(texto),
             "Numero: %d", numero);

    return crearNodo(texto);
}

Nodo *crearIdentificador(const char *nombre) {
    char texto[128];

    snprintf(texto, sizeof(texto),
             "Identificador: %s", nombre);

    return crearNodo(texto);
}

void escribirDOT(FILE *archivo, Nodo *nodo) {
    if (nodo == NULL) return;

    const char *color =
        nodo->hijo == NULL ? "#EAF5FF" : "#DDEFFF";

    fprintf(archivo,
        "n%d [label=\"%s\", fillcolor=\"%s\"];\n",
        nodo->id, nodo->etiqueta, color);

    Nodo *hijo = nodo->hijo;

    while (hijo != NULL) {
        fprintf(archivo,
            "n%d -> n%d;\n",
            nodo->id, hijo->id);

        escribirDOT(archivo, hijo);
        hijo = hijo->hermano;
    }
}

int generarDOT(Nodo *raiz) {
    FILE *archivo = fopen("ast.dot", "w");

    if (archivo == NULL) {
        perror("No se pudo crear ast.dot");
        return 0;
    }

    fprintf(archivo, "digraph AST {\n");
    fprintf(archivo, "rankdir=TB;\n");
    fprintf(archivo, "graph [bgcolor=\"white\", ");
    fprintf(archivo, "nodesep=0.35, ranksep=0.7];\n");

    fprintf(archivo, "node [shape=box, ");
    fprintf(archivo, "style=\"rounded,filled\", ");
    fprintf(archivo, "fontname=\"Arial\", ");
    fprintf(archivo, "fontsize=11, ");
    fprintf(archivo, "color=\"#2474A6\"];\n");

    fprintf(archivo, "edge [color=\"#2474A6\"];\n");

    escribirDOT(archivo, raiz);

    fprintf(archivo, "}\n");

    if (fclose(archivo) != 0) {
        perror("Error al guardar ast.dot");
        return 0;
    }

    return 1;
}

void liberarAST(Nodo *nodo) {
    if (nodo == NULL) return;

    liberarAST(nodo->hijo);
    liberarAST(nodo->hermano);
    free(nodo);
}
%}

%union {
    int numero;
    char *texto;
    struct Nodo *nodo;
}

%token <numero> NUMBER
%token <texto> IDENTIFICADOR

%token VAR IMPRIMIR SI SINO
%token IGUAL MAYOR_IGUAL MENOR_IGUAL

%type <nodo> programa instrucciones instruccion
%type <nodo> bloque expresion condicion

%left IGUAL '>' '<' MAYOR_IGUAL MENOR_IGUAL
%left '+' '-'
%left '*' '/'

%nonassoc SIN_SINO
%nonassoc SINO

%start programa

%%

programa:
    instrucciones
    {
        Nodo *raiz = crearNodo("SISTEMA: Mini JARVIS");
        agregarHijo(raiz, $1);

        printf("Analisis sintactico correcto.\n");
        printf("AST construido correctamente.\n");

        if (generarDOT(raiz)) {
            printf("Archivo ast.dot generado.\n");
        }

        liberarAST(raiz);
    }
    ;

instrucciones:
    %empty
    {
        $$ = crearNodo("INSTRUCCIONES");
    }
    | instrucciones instruccion
    {
        agregarHijo($1, $2);
        $$ = $1;
    }
    ;

instruccion:
    VAR IDENTIFICADOR '=' expresion ';'
    {
        $$ = crearNodo("DECLARACION VARIABLE");

        agregarHijo($$, crearIdentificador($2));
        agregarHijo($$, $4);

        free($2);
    }
    | IDENTIFICADOR '=' expresion ';'
    {
        $$ = crearNodo("ASIGNACION");

        agregarHijo($$, crearIdentificador($1));
        agregarHijo($$, $3);

        free($1);
    }
    | IMPRIMIR expresion ';'
    {
        $$ = crearNodo("IMPRIMIR");
        agregarHijo($$, $2);
    }
    | SI condicion bloque %prec SIN_SINO
    {
        $$ = crearNodo("CONDICION SI");

        agregarHijo($$, $2);
        agregarHijo($$, $3);
    }
    | SI condicion bloque SINO bloque
    {
        $$ = crearNodo("CONDICION SI / SINO");

        agregarHijo($$, $2);
        agregarHijo($$, $3);
        agregarHijo($$, $5);
    }
    ;

bloque:
    '{' instrucciones '}'
    {
        $$ = crearNodo("BLOQUE");

        agregarHijo($$, $2);
    }
    ;

condicion:
    expresion '>' expresion
    {
        $$ = crearOperacion("MAYOR QUE", $1, $3);
    }
    | expresion '<' expresion
    {
        $$ = crearOperacion("MENOR QUE", $1, $3);
    }
    | expresion IGUAL expresion
    {
        $$ = crearOperacion("IGUAL QUE", $1, $3);
    }
    | expresion MAYOR_IGUAL expresion
    {
        $$ = crearOperacion("MAYOR O IGUAL", $1, $3);
    }
    | expresion MENOR_IGUAL expresion
    {
        $$ = crearOperacion("MENOR O IGUAL", $1, $3);
    }
    ;

expresion:
    NUMBER
    {
        $$ = crearNumero($1);
    }
    | IDENTIFICADOR
    {
        $$ = crearIdentificador($1);
        free($1);
    }
    | expresion '+' expresion
    {
        $$ = crearOperacion("SUMA", $1, $3);
    }
    | expresion '-' expresion
    {
        $$ = crearOperacion("RESTA", $1, $3);
    }
    | expresion '*' expresion
    {
        $$ = crearOperacion("MULTIPLICACION", $1, $3);
    }
    | expresion '/' expresion
    {
        $$ = crearOperacion("DIVISION", $1, $3);
    }
    | '(' expresion ')'
    {
        $$ = $2;
    }
    ;

%%

void yyerror(const char *mensaje) {
    fprintf(stderr,
        "Error sintactico: %s\n", mensaje);
}

int main(void) {
    printf("=================================\n");
    printf("   CONSTRUCCION DEL AST\n");
    printf("       MINI JARVIS\n");
    printf("=================================\n");

    printf("Analizando programa...\n");

    return yyparse();
}
