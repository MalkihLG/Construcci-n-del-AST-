
%{
#include <stdio.h>
#include <stdlib.h>

typedef struct ASTNode {
    int id;
    char label[32];
    struct ASTNode *left;
    struct ASTNode *right;
} ASTNode;

int yylex(void);
void yyerror(const char *s);

int next_id = 0;

ASTNode *create_node(const char *label, ASTNode *left, ASTNode *right) {
    ASTNode *node = malloc(sizeof(ASTNode));

    if (node == NULL) {
        fprintf(stderr, "Error de memoria\n");
        exit(EXIT_FAILURE);
    }

    node->id = next_id++;
    snprintf(node->label, sizeof(node->label), "%s", label);
    node->left = left;
    node->right = right;

    return node;
}

ASTNode *create_number(int value) {
    char text[32];
    snprintf(text, sizeof(text), "%d", value);
    return create_node(text, NULL, NULL);
}

void write_tree(FILE *file, ASTNode *node) {
    if (node == NULL) return;

    fprintf(file, "  n%d [label=\"%s\"];\n",
            node->id, node->label);

    if (node->left != NULL) {
        fprintf(file, "  n%d -> n%d;\n",
                node->id, node->left->id);
        write_tree(file, node->left);
    }

    if (node->right != NULL) {
        fprintf(file, "  n%d -> n%d;\n",
                node->id, node->right->id);
        write_tree(file, node->right);
    }
}

void generate_dot(ASTNode *root) {
    FILE *file = fopen("ast.dot", "w");

    if (file == NULL) {
        perror("No se pudo crear ast.dot");
        return;
    }

    fprintf(file, "digraph AST {\n");
    fprintf(file, "  node [shape=circle];\n");

    write_tree(file, root);

    fprintf(file, "}\n");
    fclose(file);

    printf("Archivo ast.dot generado correctamente.\n");
}

void free_tree(ASTNode *node) {
    if (node == NULL) return;

    free_tree(node->left);
    free_tree(node->right);
    free(node);
}
%}

%union {
    int number;
    struct ASTNode *node;
}

%token <number> NUMBER
%type <node> expression

%left '+' '-'
%left '*' '/'

%%

program:
    expression '\n'
    {
        printf("Sintaxis correcta.\n");
        printf("AST construido correctamente.\n");
        generate_dot($1);
        free_tree($1);
    }
    ;

expression:
    NUMBER
    {
        $$ = create_number($1);
    }
    | expression '+' expression
    {
        $$ = create_node("+", $1, $3);
    }
    | expression '-' expression
    {
        $$ = create_node("-", $1, $3);
    }
    | expression '*' expression
    {
        $$ = create_node("*", $1, $3);
    }
    | expression '/' expression
    {
        $$ = create_node("/", $1, $3);
    }
    | '(' expression ')'
    {
        $$ = $2;
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error sintactico: %s\n", s);
}

int main(void) {
    printf("Ingresa una expresion matematica:\n");
    return yyparse();
}
