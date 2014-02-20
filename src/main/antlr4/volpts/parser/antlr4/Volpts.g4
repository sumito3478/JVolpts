grammar Volpts;

import VolptsDef;

@members {
  ParserUtils util = new ParserUtils();
}

// lexical rules

fragment NewLineChar : '\u000D' | '\u000A' | '\u0085' | '\u2028' | '\u2029';

SINGLE_LINE_COMMENT : ('//' ~ [\u000D''\u000A''\u0085''\u2028''\u2029']*) -> channel(HIDDEN);

fragment Space : '\u0009' | '\u000B' | '\u000C' | '\u0020' | '\u1680' | '\u180E' | '\u2000'..'\u200A' | '\u202F' | '\u205F' | '\u3000';

SPACE : ('\u0009' | '\u000B' | '\u000C' | '\u0020' | '\u1680' | '\u180E' | '\u2000'..'\u200A' | '\u202F' | '\u205F' | '\u3000') -> channel(HIDDEN);

NEW_LINE : ('\u000D' | '\u000A' | '\u000D' '\u000A' | '\u0085' | '\u2028' | '\u2029') -> channel(HIDDEN);

// keywords
LET : 'let' ;
LET_QUESTION : 'let?' ;
DATA : 'data' ;
IF : 'if' ;
ELSE : 'else' ;
VAL : 'val' ;
WHERE : 'where' ;
REC : 'rec';
FUN : 'fun' ;
MATCH : 'match' ;
CASE : 'case' ;
RECORD : 'record' ;
TYPE : 'type' ;
TRUE : 'true';
FALSE : 'false' ;
IMPORT : 'import' ;
AS : 'as' ;
VARIANT : 'variant' ;
OF : 'of' ;

fragment IdentifierStart : '$' | '_' | UnicodeCategoryLl | UnicodeCategoryLu | UnicodeCategoryLt | UnicodeCategoryLo | UnicodeCategoryNl ;

fragment IdentifierPart : Digit | IdentifierStart ;

ID : IdentifierStart IdentifierPart* ;

LPAREN : '(' ;
RPAREN : ')' ;
EQUAL : '=' ;
MINUS : '-' ;
LCBRACKET : '{' ;
RCBRACKET : '}' ;
COMMA : ',' ;
DOUBLE_ARROW : '=>' ;
ARROW : '->' ;
DOT : '.' ;
COLON : ':' ;
LBRACKET : '[';
RBRACKET : ']';
LESS_THAN : '<' ;
GREATER_THAN : '>' ;
OR : '|' ;
BACK_QUOTE : '`' ;

// OP : ('!' | '#' | '$' | '%' | '&' | '*' | '+' | MINUS | '/' | '<' | EQUAL | '>' | '?' | '@' | '^' | '|' | '~' | UnicodeCategorySm)+ ;

fragment DecimalNumeral : '0' | ('1' .. '9') ('0' .. '9')* ;

fragment HexNumeral : '0x' ('0' .. '9' | 'a' .. 'f' | 'A' .. 'F')+ ;

fragment OctalNumeral : '0' ('0' .. '7')+ ;

fragment BinaryNumeral : '0b' ('0' .. '1')+ ;

INTEGER_LITERAL : (DecimalNumeral | HexNumeral | OctalNumeral | BinaryNumeral) ('L' | 'l')? ;

fragment Digit : '0' .. '9' ;

fragment ExponentPart : ('E' | 'e') ('+' | '-')? Digit+ ;

fragment FloatType : 'F' | 'f' | 'D' | 'd' ;

FLOATING_POINT_LITERAL :
  Digit+ '.' Digit* ExponentPart? FloatType?
  | '.' Digit+ ExponentPart? FloatType?
  | Digit+ ExponentPart
  | Digit+ FloatType
  | Digit+ ExponentPart FloatType
  ;

STRING_LITERAL : '"' (~ '"')* '"' ;

SEMICOLON : ';' ;

// parser rules

compilation_unit : (decl semi)+ ;

semi @init { util.promoteNEW_LINE(_input); } : SEMICOLON | EOF | NEW_LINE ;

type_generic : BACK_QUOTE ID;

type_args : LBRACKET type (COMMA type)* RBRACKET ;

type_app : qual_id type_args?;

type_simple : type_generic | type_app ;

type_fun_params : LPAREN type (COMMA type)+ RPAREN ;

type_fun_multiple : type_fun_params ARROW type;

type_fun_single : type_simple ARROW type;

type_fun : type_fun_multiple | type_fun_single ;

type : type_fun_multiple | type_fun_single | type_simple ;

type_params : LBRACKET type_generic (COMMA type_generic)* RBRACKET;

type_annot : COLON type ;

adt_part : ID OF type semi;

gadt_part : ID COLON type_fun semi;

variant_parts : adt_part+ | gadt_part+ ;

variant : VARIANT LCBRACKET variant_parts RCBRACKET ;

record_part : ID COLON type semi;

record : RECORD LCBRACKET record_part+ RCBRACKET ;

type_def : record | variant | type ;

type_decl : TYPE ID type_params? EQUAL type_def;

val_decl : VAL? ID type_annot EQUAL expr ;

import_decl : IMPORT qual_id (AS ID)?;

decl_raw : type_decl | val_decl | import_decl ;

decl : decl_raw;

integer_literal : MINUS? INTEGER_LITERAL;

floating_point_literal : MINUS? FLOATING_POINT_LITERAL;

boolean_part : TRUE | FALSE ;

boolean_literal : boolean_part;

string_literal : STRING_LITERAL;

literal : integer_literal | floating_point_literal | boolean_literal | string_literal ;

literal_expr : literal;

type_expr : type_decl semi expr;

import_expr : import_decl semi expr;

let_expr : LET ID type_annot? EQUAL expr semi expr;

let_rec_expr : LET REC ID type_annot? EQUAL expr semi expr;

lambda_expr_single : ID ARROW expr;

lambda_expr_multiple : LPAREN ID (COMMA ID)+ RPAREN ARROW expr;

qual_id : ID (DOT ID)*;

qual_expr : qual_id;

id_expr : ID; // qual_expr does not match single ID if the next 'semi' is implicit (i.e. promoted NEW_LINE)...

app_arg : (ID EQUAL)? expr;

app_expr : qual_expr LPAREN app_arg (COMMA app_arg)* RPAREN;

match_guard : IF expr ;

match_part : CASE pat match_guard? DOUBLE_ARROW expr ;

match_expr : MATCH expr LCBRACKET match_part+ RCBRACKET ;

record_expr_part : ID EQUAL expr semi;

record_expr : RECORD LCBRACKET record_expr_part+ RCBRACKET;

if_expr : IF LPAREN expr RPAREN expr ELSE expr ;

compound_expr : LCBRACKET (expr semi)+ RCBRACKET;

expr_raw : lambda_expr_multiple | lambda_expr_single | app_expr | qual_expr | id_expr | match_expr | compound_expr | let_rec_expr | let_expr | literal | if_expr | type_expr | import_expr | record_expr ;

expr : expr_raw | LPAREN expr RPAREN | expr_raw ;

ident_pat : ID type_annot?;

unapply_pat : qual_id LPAREN pat (COMMA pat)* RPAREN;

literal_pat : literal;

pat : unapply_pat | ident_pat | literal_pat ;
