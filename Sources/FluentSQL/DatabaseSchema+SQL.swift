extension DatabaseSchema.DataType {
    public static func sql(_ dataType: SQLDataType) -> Self {
        .custom(dataType)
    }
}
