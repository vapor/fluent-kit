/// The method used by a table join clause.
///
/// Used by ``SQLJoin`` and ``SQLJoinBuilder``.
///
/// The set of joins expressible with this type is known to be very limited. This is partly on purpose, given the
/// relatively large number of join types that exist across the various SQL dialects, the relatively few of those types
/// which are supported by more than one dialect, and the ability to specify join methods as arbitrary
/// ``SQLExpression``s. It is also, however, a side effect of yet another of SQLKit's current API design flaws, in this
/// case the choice to have ``SQLJoinMethod`` serialize only to the join type, not even including the `JOIN` keyword,
/// which makes it that much more difficult to express nontrivial join methods syntactically correctly.
public enum SQLJoinMethod: SQLExpression {
    /// An inner join.
    ///
    /// Most often, this type of join is what's meant when saying simply, "a join". An inner join is the result of
    /// filtering the Cartesian product (a cross join) of all rows in both tables with the join condition/predicate.
    case inner
    
    /// A left (outer) join.
    ///
    /// A left join is the result of performing an inner join, followed by adding additional result rows for every row
    /// of the left-side table which has no match in the right-side table with `NULL` values for any columns belonging
    /// to the right-side table.
    case left
    
    /// A right (outer) join.
    ///
    /// A right join is simply the mirror version of a left join; additional result rows are for missing matches in the
    /// left-side table etc.
    case right
    
    // See `SQLExpression.serialize(to:)`.
    @inlinable
    public func serialize(to serializer: inout SQLSerializer) {
        switch self {
        case .inner: serializer.write("INNER")
        case .left: serializer.write("LEFT")
        case .right: serializer.write("RIGHT")
        }
    }
}
