%include {
#include <assert.h>
#include <string.h>
#include "tr.h"
#include "internal.h"
}

%name           TrParser
%token_type     { OBJ }
%token_prefix   TR_TOK_
%extra_argument { TrCompiler *compiler }

%token_destructor {
  (void) compiler;
}

%syntax_error {
  printf("Syntax error:\n");
  printf("  %s unexpected at line %d\n", yyTokenName[yymajor], compiler->curline);
}

%right ASSIGN.

/* rules */
root ::= statements(A). { compiler->node = (OBJ) NODE(ROOT, A); }
root ::= statements(A) TERM. { compiler->node = (OBJ) NODE(ROOT, A); }

statements(A) ::= statements(B) TERM statement(C). { A = PUSH(B, C); }
statements(A) ::= statement(B). { A = NODES(B); }

statement(A) ::= expr_out(B). { A = B; }
statement(A) ::= flow(B). { A = B; }
statement(A) ::= def(B). { A = B; }
statement(A) ::= class(B). { A = B; }
statement(A) ::= assign(B). { A = B; }

assign(A) ::= CONST(B) ASSIGN statement(C). { A = NODE2(SETCONST, B, C); }
assign(A) ::= ID(B) ASSIGN statement(C). { A = NODE2(ASSIGN, B, C); }

flow(A) ::= IF statement(B) TERM statements(C) opt_term END. { A = NODE2(IF, B, C); }
flow(A) ::= UNLESS statement(B) TERM statements(C) opt_term END. { A = NODE2(UNLESS, B, C); }
flow(A) ::= WHILE statement(B) TERM statements(C) opt_term END. { A = NODE2(WHILE, B, C); }
flow(A) ::= UNTIL statement(B) TERM statements(C) opt_term END. { A = NODE2(UNTIL, B, C); }

literal(A) ::= SYMBOL(B). { A = NODE(VALUE, B); }
literal(A) ::= INT(B). { A = NODE(VALUE, B); }
literal(A) ::= STRING(B). { A = NODE(STRING, B); }
literal(A) ::= TRUE. { A = NODE(BOOL, 1); }
literal(A) ::= FALSE. { A = NODE(BOOL, 0); }
literal(A) ::= NIL. { A = NODE(NIL, 0); }
literal(A) ::= SELF. { A = NODE(SELF, 0); }
literal(A) ::= RETURN. { A = NODE(RETURN, 0); }
literal(A) ::= CONST(B). { A = NODE(CONST, B); }

expr(A) ::= expr(B) DOT msg(C). { A = NODE2(SEND, B, C); }
expr(A) ::= expr(B) BINOP(C) msg(D). { A = NODE2(SEND, B, NODE2(MSG, C, NODES(NODE2(SEND, TR_NIL, D)))); }
expr(A) ::= expr(B) BINOP(C) literal(D). { A = NODE2(SEND, B, NODE2(MSG, C, NODES(D))); }
expr(A) ::= msg(B). { A = NODE2(SEND, TR_NIL, B); }
expr(A) ::= literal(B). { A = B; }

expr_out(A) ::= expr(B) DOT msg_out(C). { A = NODE2(SEND, B, C); }
expr_out(A) ::= expr(B) BINOP(C) msg_out(D). { A = NODE2(SEND, B, NODE2(MSG, C, NODES(NODE2(SEND, TR_NIL, D)))); }
expr_out(A) ::= expr(B) BINOP(C) literal(D). { A = NODE2(SEND, B, NODE2(MSG, C, NODES(D))); }
expr_out(A) ::= msg_out(B). { A = NODE2(SEND, TR_NIL, B); }
expr_out(A) ::= literal(B). { A = B; }

msg(A) ::= ID(B). { A = NODE(MSG, B); }
msg(A) ::= ID(B) O_PAR C_PAR. { A = NODE(MSG, B); }
msg(A) ::= ID(B) O_PAR args(C) C_PAR. { A = NODE2(MSG, B, C); }

msg_out(A) ::= msg(B). { A = B; }
msg_out(A) ::= ID(B) args(C). { A = NODE2(MSG, B, C); }

args(A) ::= args(B) COMMA arg(C). { A = PUSH(B, C); }
args(A) ::= arg(B). { A = NODES(B); }

arg(A) ::= expr(B). { A = B; }
/*arg(A) ::= assign(B). { A = B; }*/

def(A) ::= DEF ID(B) TERM statements(C) opt_term END. { A = NODE2(DEF, B, C); }

class(A) ::= CLASS CONST(B) TERM statements(C) opt_term END. { A = NODE2(CLASS, B, C); }

opt_term ::= TERM.
opt_term ::= .
