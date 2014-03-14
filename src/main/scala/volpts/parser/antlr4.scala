package volpts
package parser
package antlr4

import scala.collection._

class ParserUtils {
  def seq[A](xs: java.util.List[A]): Seq[A] = {
    import JavaConversions._
    xs.toVector
  }
  def option[A](x: A): Option[A] = Option(x)
}
