package volpts
package internal

sealed trait Node
case class Identifier(name: String) extends Node
case class QualifiedIdentifier(ids: Seq[Identifier]) extends Node
case class GenericIdentifier(name: String) extends Node
case class Operator(name: String) extends Node
sealed trait Literal[A] extends Node {
  def value: A
}
case class BooleanLiteral(value: Boolean) extends Literal[Boolean]
case class FloatLiteral(value: Float) extends Literal[Float]
case class DoubleLiteral(value: Double) extends Literal[Double]
case class IntegerLiteral(value: Int) extends Literal[Int]
case class LongLiteral(value: Long) extends Literal[Long]
case class StringLiteral(value: String) extends Literal[String]
case class RecordPart(id: Identifier, name: Expression)
case class VariantPart(id: Identifier, `type`: Type)
case class MatchPart(id: Identifier, params: Seq[Identifier], cond: Option[Expression], expression: Expression)
sealed trait Expression extends Node
case class IdentifierExpression(value: Identifier) extends Expression
case class LiteralExpression[A](value: Literal[A]) extends Expression
case class DotExpression(lhs: Expression, rhs: Identifier) extends Expression
case class UnaryExpression(op: Operator, expression: Expression) extends Expression
case class ApplicationExpression(lhs: Expression, rhs: Expression) extends Expression
case class OperatorExpression(lhs: Expression, op: Operator, rhs: Expression) extends Expression
case class IfExpression(cond: Expression, lhs: Expression, rhs: Expression) extends Expression
case class LambdaExpression(id: Identifier, expression: Expression) extends Expression
case class LetRecExpression(id: Identifier, lhs: Expression, rhs: Expression) extends Expression
case class LetExpression(id: Identifier, lhs: Expression, rhs: Expression) extends Expression
case class DefExpression(id: Identifier, lhs: Expression, rhs: Expression) extends Expression
case class RecordExpression(parts: Seq[RecordPart]) extends Expression
case class CompoundExpression(expressions: Seq[Expression]) extends Expression
case class InlineExpression(id: Identifier, text: String) extends Expression
case class VariantExpression(id: Identifier, parts: Seq[VariantPart], expression: Expression) extends Expression
case class MatchExpression(expression: Expression, parts: Seq[MatchPart]) extends Expression
sealed trait Type extends Node
case class IdentifierType(id: QualifiedIdentifier) extends Type
case class GenericType(id: GenericIdentifier) extends Type
case class TupleType(lhs: Type, rhs: Type) extends Type
case class FunctionType(lhs: Type, rhs: Type) extends Type
case class RecordTypePart(id: Identifier, `type`: Type)
case class RecordType(parts: Seq[RecordTypePart]) extends Type
sealed trait Declaration extends Node
case class DefDeclaration(id: Identifier, expression: Expression) extends Declaration
case class VariantDeclaration(id: Identifier, parts: Seq[VariantPart]) extends Declaration
case class ModuleDeclaration(declarations: Seq[Declaration]) extends Node
