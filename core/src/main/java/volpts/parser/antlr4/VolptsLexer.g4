lexer grammar VolptsLexer;

import VolptsDef;

tokens {
  // imaginary tokens for ast
  TYPE_GENERIC,
  TYPE_APP,
  DECL,
  TYPE_FUNCTION_PARAMS,
  TYPE_FUNCTION,
  TYPE_PARAMS,
  ADT_PART,
  GADT_PART,
  VARIANT_DEF,
  RECORD_PART,
  RECORD_DEF,
  TYPE_DECL,
  IMPORT_DECL,
  INTEGER,
  FLOATING_POINT,
  BOOLEAN,
  STRING,
  LITERAL_EXPR,
  TYPE_EXPR,
  IMPORT_EXPR,
  LET_EXPR,
  LETREC_EXPR,
  LAMBDA_EXPR,
  QUAL_ID,
  ID_EXPR,
  APP_ARG,
  APP_EXPR,
  MATCH_GUARD,
  MATCH_PART,
  MATCH_EXPR,
  RECORD_EXPR_PART,
  RECORD_EXPR,
  COMPOUND_EXPR,
  IDENT_PAT,
  UNAPPLY_PAT,
  LITERAL_PAT
}

@header {
  package volpts.parser.antlr4;
}

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
