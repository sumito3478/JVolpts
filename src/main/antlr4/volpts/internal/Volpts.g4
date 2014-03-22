grammar Volpts;

@lexer::header {
import static java.lang.Character.*;
}
@parser::header {
import java.util.List;
import java.util.Vector;
}

@members {
  ParserUtils util = new ParserUtils();
}

module returns [ModuleDeclaration v]
  @init {
      List<Declaration> declarations = new Vector<Declaration>();
    }
  : nl? (declaration { declarations.add($declaration.v); } semi)* nl? {
      $v = new ModuleDeclaration(util.seq(declarations));
    };

declaration returns [Declaration v] : 'def' nl? id nl? EQUAL nl? expression{ $v = new DefDeclaration($id.v, $expression.v); };

type returns [Type v]
  @init {
      List<RecordTypePart> recordParts = new Vector<RecordTypePart>();
    }
  : qualId { $v = new IdentifierType($qualId.v); }
  | genId { $v = new GenericType($genId.v); }
  | lhs=type nl? COMMA<assoc=right> nl? rhs=type { $v = new TupleType($lhs.v, $rhs.v); }
  | lhs=type nl? ARROW<assoc=right> nl? rhs=type { $v = new FunctionType($lhs.v, $rhs.v); }
  | LCBRACKET nl? (id nl? COLON nl? ty=type) { recordParts.add(new RecordTypePart($id.v, $ty.v)); } (semi (id nl? COLON nl? ty=type) { recordParts.add(new RecordTypePart($id.v, $ty.v)); } )* semi? RCBRACKET {
      $v = new RecordType(util.seq(recordParts));
    }
  ;

id returns [Identifier v] : ID { $v = new Identifier($ID.text); };

qualId returns [QualifiedIdentifier v]
  @init {
      List<Identifier> ids = new Vector<Identifier>();
    }
  : id { ids.add($id.v); } (nl? DOT nl? id { ids.add($id.v); })* { $v = new QualifiedIdentifier(util.seq(ids)); }
  ;

genId returns [GenericIdentifier v] : GEN_ID {
    String text = $GEN_ID.text;
    $v = new GenericIdentifier(text.substring(1, text.length()));
  };

op1 : opTimes | opDiv | opPercent;
op2 : opMinus | opPlus;

matchPart returns [MatchPart v]
  @init {
      List<Identifier> params = new Vector<Identifier>();
    }
  : id nl? LPAREN (nl? id { params.add($id.v); })* nl? RPAREN (nl? 'if' nl? cond=expression)? nl? ARROW nl? expression {
      Expression c = $cond.ctx == null ? null : $cond.v;
      $v = new MatchPart($id.v, util.seq(params), util.option(c), $expression.v);
    }
  ;

matchExpression returns [MatchExpression v]
  @init {
      List<MatchPart> parts = new Vector<MatchPart>();
    }
  : 'match' nl? expression (nl? 'case' nl? matchPart { parts.add($matchPart.v); })+ {
      $v = new MatchExpression($expression.v, util.seq(parts));
    }
  ;

expression returns [Expression v]
  @init {
      // List<Partial> partials = new Vector<Partial>();
      List<RecordPart> recordParts = new Vector<RecordPart>();
      List<Expression> compoundExpressionParts = new Vector<Expression>();
      List<VariantPart> variantParts = new Vector<VariantPart>();
    }
  : LPAREN nl? exp=expression nl? RPAREN { $v = $exp.v; }
  | literal { $v = new LiteralExpression($literal.v); }
  | id { $v = new IdentifierExpression($id.v); }
  | exp=expression nl? DOT nl? id { $v = new DotExpression($exp.v, $id.v); }
  | operator nl? exp=expression { $v = new UnaryExpression(new Operator($operator.text), $exp.v); }
  | lhs=expression nl? LPAREN nl? rhs=expression nl? RPAREN { $v = new ApplicationExpression($lhs.v, $rhs.v); }
  | lhs=expression nl? op1 nl? rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op1.text), $rhs.v); }
  | lhs=expression nl? op2 nl? rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op2.text), $rhs.v); }
  | lhs=expression nl? op3=opColon<assoc=right> nl? rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op3.text), $rhs.v); }
  | lhs=expression nl? op4=operator nl? rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op4.text), $rhs.v); }
  | lhs=expression nl? op5=COMMA<assoc=right> nl? rhs=expression { $v = new OperatorExpression($lhs.v, new Operator(","), $rhs.v); }
  | 'if' nl? LPAREN nl? cond=expression nl? RPAREN nl? lhs=expression nl? 'else' nl? rhs=expression { $v = new IfExpression($cond.v, $lhs.v, $rhs.v); }
  | 'fun' nl? id nl? ARROW nl? exp=expression { $v = new LambdaExpression($id.v, $exp.v); }
  | 'let' nl? 'rec' nl? id nl? EQUAL nl? lhs=expression semi rhs=expression { $v = new LetRecExpression($id.v, $lhs.v, $rhs.v); }
  | 'let' nl? id nl? EQUAL nl? lhs=expression semi rhs=expression { $v = new LetExpression($id.v, $lhs.v, $rhs.v); }
  | 'def' nl? id nl? EQUAL nl? lhs=expression semi rhs=expression { $v = new DefExpression($id.v, $lhs.v, $rhs.v); }
  | (id nl? EQUAL nl? exp=expression) { recordParts.add(new RecordPart($id.v, $exp.v)); } (nl? COMMA nl? (id nl? EQUAL nl? exp2=expression) { recordParts.add(new RecordPart($id.v, $exp2.v)); })* {
      $v = new RecordExpression(util.seq(recordParts));
    }
  | LCBRACKET nl? exp=expression { compoundExpressionParts.add($exp.v); } (semi exp2=expression { compoundExpressionParts.add($exp2.v); } )* semi? RCBRACKET {
      $v = new CompoundExpression(util.seq(compoundExpressionParts));
    }
  | 'inline' nl? id nl? INLINE_BLOCK {
      String block = $INLINE_BLOCK.text;
      $v = new InlineExpression($id.v, block.substring(2, block.length() - 2));
    }
  | 'variant' nl? name=id nl? EQUAL nl? LCBRACKET nl? (id nl? ':' nl? type) { variantParts.add(new VariantPart($id.v, $type.v)); } (semi (id nl? ':' nl? type) { variantParts.add(new VariantPart($id.v, $type.v)); })* semi? RCBRACKET nl? exp=expression {
      $v = new VariantExpression($name.v, util.seq(variantParts), $exp.v);
    }
  | matchExpression { $v = $matchExpression.v; }
  ;

boolean_literal : 'true' | 'false';

literal returns [Literal<?> v]
  : INTEGER_LITERAL {
      String text = $INTEGER_LITERAL.text;
      char c = text.charAt(text.length() - 1);
      switch (c) {
      case 'L':
      case 'l':
        $v = new LongLiteral(Long.parseLong(text.substring(0, text.length() - 1)));
        break;
      default:
        $v = new IntegerLiteral(Integer.parseInt(text));
        break;
      }
    }
  | FLOATING_POINT_LITERAL {
      String text = $FLOATING_POINT_LITERAL.text;
      char c = text.charAt(text.length() - 1);
      switch (c) {
      case 'F':
      case 'f':
        $v = new FloatLiteral(Float.parseFloat(text.substring(0, text.length() - 1)));
        break;
      default:
        $v = new DoubleLiteral(Double.parseDouble(text.substring(0, text.length() - 1)));
        break;
      }
    }
  | boolean_literal { $v = new BooleanLiteral(Boolean.parseBoolean($boolean_literal.text)); }
  | STRING_LITERAL {
      String text = $STRING_LITERAL.text;
      $v = new StringLiteral(text.substring(1, text.length() - 1));
    }
  ;

opPlus : OP_PLUS;

opMinus : OP_MINUS;

opTimes : OP_TIMES;

opDiv : OP_DIV;

opPercent : OP_PERCENT;

opColon : OP_COLON;

opOther : OP_OTHER;

operator : OP_PLUS | OP_MINUS | OP_TIMES | OP_DIV | OP_PERCENT | OP_OTHER;

semi : (NEW_LINE* SEMICOLON NEW_LINE*) | (NEW_LINE* EOF) | NEW_LINE+ ;

// Symbols that cannot be operator

LPAREN : '(';
RPAREN : ')';
EQUAL : '=';
LCBRACKET : '{';
RCBRACKET : '}';
COMMA : ',';
ARROW : '->';
DOT : '.';
LBRACKET : '[';
RBRACKET : ']';
COLON : ':';

// operators

fragment UnicodeCategorySm
  : ~[\u0000-\u00ff\ud800-\udbff] { Character.getType(_input.LA(-1)) == MATH_SYMBOL }?
  | [\ud800-\udbff] [\udc00-\udfff] { Character.getType(toCodePoint((char)_input.LA(-2), (char)_input.LA(-1))) == MATH_SYMBOL }?
  ;

fragment OpChar : '%' | '!' | '#' | '%' | '&' | '*' | '/' | '?' | '@' | '^' | '|' | '-' | '~' | UnicodeCategorySm;

fragment OpSuffix : '_' IdentifierPart*;

OP_ALLOW : ARROW; // reserved

OP_SINGLE_COLON : COLON; // reserved

OP_PLUS : '+' OpChar* OpSuffix?;

OP_MINUS : '-' OpChar* OpSuffix?;

OP_TIMES : '*' OpChar* OpSuffix?;

OP_DIV : '/' OpChar* OpSuffix?;

OP_PERCENT : '%' OpChar* OpSuffix?;

OP_COLON : ':' OpChar* OpSuffix?;

OP_OTHER : OpChar+ OpSuffix?;

fragment NewLineChar : '\u000D' | '\u000A' | '\u0085' | '\u2028' | '\u2029';

fragment SingleLineComment : '//' ~ [\u000D''\u000A''\u0085''\u2028''\u2029']*;

SINGLE_LINE_COMMENT : SingleLineComment -> channel(HIDDEN);

fragment MultiLineComment : '/*' .*? '*/' ;

fragment Space : '\u0009' | '\u000B' | '\u000C' | '\u0020' | '\u1680' | '\u180E' | '\u2000'..'\u200A' | '\u202F' | '\u205F' | '\u3000';

SPACE : Space+ -> channel(HIDDEN);

fragment NewLine : ('\u000D' | '\u000A' | '\u000D' '\u000A' | '\u0085' | '\u2028' | '\u2029')+;

NEW_LINE : NewLine+;

nl : NEW_LINE+;

// keywords
LET : 'let' ;
//LET_QUESTION : 'let?' ;
//DATA : 'data' ;
IF : 'if' ;
ELSE : 'else' ;
VAL : 'val' ;
DEF : 'def';
//WHERE : 'where' ;
REC : 'rec';
FUN : 'fun' ;
MATCH : 'match' ;
CASE : 'case' ;
//RECORD : 'record' ;
TYPE : 'type' ;
TRUE : 'true';
FALSE : 'false' ;
IMPORT : 'import' ;
//AS : 'as' ;
VARIANT : 'variant' ;
OF : 'of' ;
INLINE : 'inline';
PARTIAL : 'partial';

fragment IdentifierStart
  : [a-zA-Z$_]
  | ~[\u0000-\u00ff\ud800-\udbff] { isUnicodeIdentifierStart(_input.LA(-1)) }?
  | [\ud800-\udbff] [\udc00-\udfff] { isUnicodeIdentifierStart(toCodePoint((char)_input.LA(-2), (char)_input.LA(-1))) }?
  ;

fragment IdentifierPart
  : [a-zA-Z0-9$_]
  | ~[\u0000-\u00ff\ud800-\udbff] { isUnicodeIdentifierPart(_input.LA(-1)) }?
  | [\ud800-\udbff] [\udc00-\udfff] { isUnicodeIdentifierPart(toCodePoint((char)_input.LA(-2), (char)_input.LA(-1))) }?
  ;

ID : IdentifierStart IdentifierPart* ;

GEN_ID : '\'' IdentifierStart IdentifierPart*;

fragment DecimalNumeral : '0' | ('1' .. '9') ('0' .. '9')* ;

fragment HexNumeral : '0x' ('0' .. '9' | 'a' .. 'f' | 'A' .. 'F')+ ;

fragment OctalNumeral : '0' ('0' .. '7')+ ;

fragment BinaryNumeral : '0b' ('0' .. '1')+ ;

INTEGER_LITERAL : (DecimalNumeral | HexNumeral | OctalNumeral | BinaryNumeral) ('L' | 'l')? ;

fragment Digit : '0' .. '9' ;

fragment ExponentPart : ('E' | 'e') ('+' | '-')? Digit+ ;

fragment FloatType : 'F' | 'f' | 'D' | 'd' ;

FLOATING_POINT_LITERAL :
  Digit+ DOT Digit* ExponentPart? FloatType?
  | DOT Digit+ ExponentPart? FloatType?
  | Digit+ ExponentPart
  | Digit+ FloatType
  | Digit+ ExponentPart FloatType
  ;

//STRING_LITERAL : '"' (~ '"')* '"' ;
STRING_LITERAL : '"' .*? '"';

SEMICOLON : ';' ;

INLINE_BLOCK : '#{' .*? '}#';