grammar Volpts;

@lexer::header {
import static java.lang.Character.*;
import lombok.val;
import volpts.ast.AST;
import static volpts.ast.AST.*;
}
@parser::header {
import lombok.val;
import volpts.ast.AST;
import static volpts.ast.AST.*;
import java.util.List;
import java.util.Vector;
}

@members {
  ParserUtils util = new ParserUtils();
}

compilationUnit : expression;

type returns [Type v]
  @init {
      val recordParts = new Vector<RecordTypePart>();
    }
  : qualId { $v = new IdentifierType($qualId.v); }
  | genId { $v = new GenericType($genId.v); }
  | lhs=type ','<assoc=right> rhs=type { $v = new TupleType($lhs.v, $rhs.v); }
  | lhs=type '->'<assoc=right> rhs=type { $v = new FunctionType($lhs.v, $rhs.v); }
  | '{' (id ':' type) { recordParts.add(new RecordTypePart($id.v, $type.v)); } (semi (id ':' type) { recordParts.add(new RecordTypePart($id.v, $type.v)); } )* '}' {
      $v = new RecordType(recordParts);
    }
  ;

id returns [Identifier v] : ID { $v = new Identifier($ID.text); };

qualId returns [QualifiedIdentifier v]
  @init {
      val ids = new Vector<Identifier>();
    }
  : id { ids.add($id.v); } ('.' id { ids.add($id.v); })* { $v = new QualifiedIdentifier(ids); }
  ;

genId returns [GenericIdentifier v] : GEN_ID {
    val text = $GEN_ID.text;
    $v = new GenericIdentifier(text.substring(1, text.length()));
  };

op1 : opTimes | opDiv | opPercent;
op2 : opMinus | opPlus;

matchPart returns [MatchPart v]
  @init {
      val params = new Vector<Identifier>();
    }
  : id '(' (id { params.add($id.v); })* ')' ('if' cond=expression)? '->' expression {
      val c = $cond.ctx == null ? null : $cond.v;
      $v = new MatchPart($id.v, params, c, $expression.v);
    }
  ;

matchExpression returns [MatchExpression v]
  @init {
      val parts = new Vector<MatchPart>();
    }
  : 'match' expression ('case' matchPart { parts.add($matchPart.v); })+ {
      $v = new MatchExpression($expression.v, parts);
    }
  ;

expression returns [Expression v]
  @init {
      val partials = new Vector<Partial>();
      val recordParts = new Vector<RecordPart>();
      val compoundExpressionParts = new Vector<Expression>();
      val variantParts = new Vector<VariantPart>();
    }
  : '(' expression ')' { $v = $expression.v; }
  | literal { $v = new LiteralExpression($literal.v); }
  | id { $v = new IdentifierExpression($id.v); }
  | expression '.' id { $v = new DotExpression($expression.v, $id.v); }
  | operator expression { $v = new UnaryExpression(new Operator($operator.text), $expression.v); }
  | lhs=expression '(' rhs=expression ')' { $v = new ApplicationExpression($lhs.v, $rhs.v); }
  | lhs=expression op1 rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op1.text), $rhs.v); }
  | lhs=expression op2 rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op2.text), $rhs.v); }
  | lhs=expression op3=opColon<assoc=right> rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op3.text), $rhs.v); }
  | lhs=expression op4=operator rhs=expression { $v = new OperatorExpression($lhs.v, new Operator($op4.text), $rhs.v); }
  | lhs=expression op5=','<assoc=right> rhs=expression { $v = new OperatorExpression($lhs.v, new Operator(","), $rhs.v); }
  | 'if' '(' cond=expression ')' lhs=expression 'else' rhs=expression { $v = new IfExpression($cond.v, $lhs.v, $rhs.v); }
  | 'fun' id '->' expression { $v = new LambdaExpression($id.v, $expression.v); }
  // 'partial' partial { $v = new PartialExpression($partial.v); }
  // expression 'match' partialList { $v = new MatchExpression($expression.v, $partialList.v); }
  | 'let' 'rec' id '=' lhs=expression semi? rhs=expression { $v = new LetRecExpression($id.v, $lhs.v, $rhs.v); }
  | 'let' id '=' lhs=expression semi? rhs=expression { $v = new LetExpression($id.v, $lhs.v, $rhs.v); }
  //| 'def' 'rec' id '=' lhs=expression semi? rhs=expression { $v = new ValRecExpression($id.v, $lhs.v, $rhs.v); }
  | 'def' id '=' lhs=expression semi? rhs=expression { $v = new DefExpression($id.v, $lhs.v, $rhs.v); }
  | (id '=' expression) { recordParts.add(new RecordPart($id.v, $expression.v)); } (',' (id '=' expression) { recordParts.add(new RecordPart($id.v, $expression.v)); })* {
      $v = new RecordExpression(recordParts);
    }
  | '{' expression { compoundExpressionParts.add($expression.v); } (semi expression { compoundExpressionParts.add($expression.v); } )* '}' {
      $v = new CompoundExpression(compoundExpressionParts);
    }
  //| 'import' id ('.' id)* ('.' '_')? semi expression
  | 'inline' id INLINE_BLOCK {
      val block = $INLINE_BLOCK.text;
      $v = new InlineExpression($id.v, block.substring(2, block.length() - 2));
    }
  | 'variant' name=id '=' '{' (id ':' type) { variantParts.add(new VariantPart($id.v, $type.v)); } (semi (id ':' type) { variantParts.add(new VariantPart($id.v, $type.v)); })* semi? '}' exp=expression {
      $v = new VariantExpression($name.v, variantParts, $exp.v);
    }
  | matchExpression { $v = $matchExpression.v; }
  ;

boolean_literal : 'true' | 'false';

literal returns [Literal<?> v]
  : INTEGER_LITERAL {
      val text = $INTEGER_LITERAL.text;
      val c = text.charAt(text.length() - 1);
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
      val text = $FLOATING_POINT_LITERAL.text;
      val c = text.charAt(text.length() - 1);
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
      val text = $STRING_LITERAL.text;
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

semi @init { util.promoteNEW_LINE(_input); } : SEMICOLON | EOF | NEW_LINE ;

// operators

fragment UnicodeCategorySm
  : ~[\u0000-\u00ff\ud800-\udbff] { Character.getType(_input.LA(-1)) == MATH_SYMBOL }?
  | [\ud800-\udbff] [\udc00-\udfff] { Character.getType(toCodePoint((char)_input.LA(-2), (char)_input.LA(-1))) == MATH_SYMBOL }?
  ;

fragment OpChar : '%' | '!' | '#' | '%' | '&' | '*' | '/' | '?' | '@' | '^' | '|' | '-' | '~' | UnicodeCategorySm;

fragment OpSuffix : '_' IdentifierPart*;

OP_ALLOW : '->'; // reserved

OP_SINGLE_COLON : ':'; // reserved

OP_PLUS : '+' OpChar* OpSuffix?;

OP_MINUS : '-' OpChar* OpSuffix?;

OP_TIMES : '*' OpChar* OpSuffix?;

OP_DIV : '/' OpChar* OpSuffix?;

OP_PERCENT : '%' OpChar* OpSuffix?;

OP_COLON : ':' OpChar* OpSuffix?;

OP_OTHER : OpChar+ OpSuffix?;

// expressions


// declarations

// declaration
//   : 'val' ID type_annotation '=' expression
//   | 'operator' ID ID ID? type_annotation '=' expression
//   | 'type' ID ID* '=' type
//   | 'variant' ID '=' record_type
//   | 'import' ID ('.' ID)* ('.' '_')? semi declarations
//   | 'inline' ID INLINE_BLOCK
//   ;
// 
// declarations : declaration (semi declaration)*;

// lexical rules

fragment NewLineChar : '\u000D' | '\u000A' | '\u0085' | '\u2028' | '\u2029';

SINGLE_LINE_COMMENT : ('//' ~ [\u000D''\u000A''\u0085''\u2028''\u2029']*) -> channel(HIDDEN);

fragment Space : '\u0009' | '\u000B' | '\u000C' | '\u0020' | '\u1680' | '\u180E' | '\u2000'..'\u200A' | '\u202F' | '\u205F' | '\u3000';

SPACE : Space+ -> channel(HIDDEN);

NEW_LINE : ('\u000D' | '\u000A' | '\u000D' '\u000A' | '\u0085' | '\u2028' | '\u2029') -> channel(HIDDEN);

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

LPAREN : '(' ;
RPAREN : ')' ;
EQUAL : '=' ;
MINUS : '-' ;
LCBRACKET : '{' ;
RCBRACKET : '}' ;
COMMA : ',' ;
DOUBLE_ARROW : '=>' ;
//ARROW : '->' ;
DOT : '.' ;
//COLON : ':' ;
LBRACKET : '[';
RBRACKET : ']';
LESS_THAN : '<' ;
GREATER_THAN : '>' ;
OR : '|' ;
BACK_QUOTE : '`' ;

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

//STRING_LITERAL : '"' (~ '"')* '"' ;
STRING_LITERAL : '"' .*? '"';

SEMICOLON : ';' ;

INLINE_BLOCK : '#{' .*? '}#';