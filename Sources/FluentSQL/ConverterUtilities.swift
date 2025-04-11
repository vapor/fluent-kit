import SQLKit

func custom(_ any: Any) -> any SQLExpression {
    if let sql = any as? any SQLExpression {
        sql
    } else if let string = any as? String {
        SQLRaw(string)
    } else if let stringConvertible = any as? any CustomStringConvertible {
        SQLRaw(stringConvertible.description)
    } else {
        fatalError("Could not convert \(any) to a SQL-compatible type.")
    }
}
