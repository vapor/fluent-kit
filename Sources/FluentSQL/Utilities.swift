import SQLKit

func custom(_ any: Any) -> SQLExpression {
    if let sql = any as? SQLExpression {
        return sql
    }
    if let string = any as? String {
        return SQLRaw(string)
    }
    if let stringConvertible = any as? CustomStringConvertible {
        return SQLRaw(stringConvertible.description)
    }
    fatalError("Could not convert \(any) to a SQL-compatible type.")
}
