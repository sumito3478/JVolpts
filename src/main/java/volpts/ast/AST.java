package volpts.ast;

import lombok.Value;
import java.util.List;

public interface AST {
  @Value
  public static class Identifier implements AST {
    String name;
  }
  @Value
  public static class QualifiedIdentifier implements AST {
    List<Identifier> ids;
  }
  @Value
  public static class GenericIdentifier implements AST {
    String name;
  }
  @Value
  public static class Operator implements AST {
    String name;
  }
  public static interface Literal<A> extends AST {
    A getValue();
  }
  @Value
  public static class BooleanLiteral implements Literal<Boolean> {
    Boolean value;
  }
  @Value
  public static class IntegerLiteral implements Literal<Integer> {
    Integer value;
  }
  @Value
  public static class LongLiteral implements Literal<Long> {
    Long value;
  }
  @Value
  public static class FloatLiteral implements Literal<Float> {
    Float value;
  }
  @Value
  public static class DoubleLiteral implements Literal<Double> {
    Double value;
  }
  @Value
  public static class StringLiteral implements Literal<String> {
    String value;
  }
  @Value
  public static class Partial {

  }
  @Value
  public static class RecordPart {
    Identifier id;
    Expression name;
  }
  @Value
  public static class VariantPart {
    Identifier id;
    Type type;
  }
  @Value
  public static class MatchPart {
    Identifier id;
    List<Identifier> params;
    Expression cond;
    Expression expression;
  }
  public static interface Expression extends AST {

  }
  @Value
  public static class IdentifierExpression implements Expression {
    Identifier value;
  }
  @Value
  public static class LiteralExpression implements Expression {
    Literal<?> value;
  }
  @Value
  public static class DotExpression implements Expression {
    Expression lhs;
    Identifier rhs;
  }
  @Value
  public static class UnaryExpression implements Expression {
    Operator op;
    Expression expression;
  }
  @Value
  public static class ApplicationExpression implements Expression {
    Expression lhs;
    Expression rhs;
  }
  @Value
  public static class OperatorExpression implements Expression {
    Expression lhs;
    Operator op;
    Expression rhs;
  }
  @Value
  public static class IfExpression implements Expression {
    Expression cond;
    Expression lhs;
    Expression rhs;
  }
  @Value
  public static class LambdaExpression implements Expression {
    Identifier id;
    Expression exp;
  }
  @Value
  public static class PartialExpression implements Expression {
    Partial partial;
  }
  @Value
  public static class LetRecExpression implements Expression {
    Identifier id;
    Expression lhs;
    Expression rhs;
  }
  @Value
  public static class LetExpression implements Expression {
    Identifier id;
    Expression lhs;
    Expression rhs;
  }
  @Value
  public static class DefExpression implements Expression {
    Identifier id;
    Expression lhs;
    Expression rhs;
  }
  @Value
  public static class RecordExpression implements Expression {
    List<RecordPart> parts;
  }
  @Value
  public static class CompoundExpression implements Expression {
    List<Expression> expressions;
  }
  @Value
  public static class InlineExpression implements Expression {
    Identifier id;
    String text;
  }
  @Value
  public static class VariantExpression implements Expression {
    Identifier id;
    List<VariantPart> parts;
    Expression expression;
  }
  @Value
  public static class MatchExpression implements Expression {
    Expression expression;
    List<MatchPart> parts;
  }
  public static interface Type extends AST {
  }
  @Value
  public static class IdentifierType implements Type {
    QualifiedIdentifier id;
  }
  @Value
  public static class GenericType implements Type {
    GenericIdentifier id;
  }
  @Value
  public static class TupleType implements Type {
    Type lhs;
    Type rhs;
  }
  @Value
  public static class FunctionType implements Type {
    Type lhs;
    Type rhs;
  }
  @Value
  public static class RecordTypePart {
    Identifier name;
    Type type;
  }
  @Value
  public static class RecordType implements Type {
    List<RecordTypePart> parts;
  }
  public static interface Declaration extends AST {
  }
  @Value
  public static class DefDeclaration implements Declaration {
	  Identifier name;
	  Expression expression;
  }
  @Value
  public static class VariantDeclaration implements Declaration {
	  Identifier name;
	  List<VariantPart> parts;
  }
  @Value
  public static class ModuleDeclaration implements AST {
	  List<Declaration> declarations;
  }
//  @Value public static class ImportExpression implements Expression {
//    
//  }
}
