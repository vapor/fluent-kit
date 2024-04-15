import SQLKit

func custom(_ any: Any) -> any SQLExpression {
    if let sql = any as? any SQLExpression {
        return sql
    }
    if let string = any as? String {
        return SQLRaw(string)
    }
    if let stringConvertible = any as? any CustomStringConvertible {
        return SQLRaw(stringConvertible.description)
    }
    fatalError("Could not convert \(any) to a SQL-compatible type.")
}
