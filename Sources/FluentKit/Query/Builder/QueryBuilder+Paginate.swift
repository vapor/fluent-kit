extension QueryBuilder {
    /// Returns a single `Page` out of the complete result set according to the supplied `PageRequest`.
    ///
    /// This method will first `count()` the result set, then request a subset of the results using `range()` and `all()`.
    /// - Parameters:
    ///     - request: Describes which page should be fetched.
    /// - Returns: A single `Page` of the result set containing the requested items and page metadata.
    public func paginate(
        _ request: PageRequest
    ) -> EventLoopFuture<Page<Model>> {
        let count = self.count()
        let items = self.copy().range(request.start..<request.end).all()
        return items.and(count).map { (models, total) in
            Page(
                items: models,
                metadata: .init(
                    page: request.page,
                    per: request.per,
                    total: total
                )
            )
        }
    }
}

/// A single section of a larger, traversable result set.
public struct Page<T>: Codable where T: Codable {
    /// The page's items. Usually models.
    public let items: [T]

    /// Metadata containing information about current page, items per page, and total items.
    public let metadata: PageMetadata

    /// Creates a new `Page`.
    public init(items: [T], metadata: PageMetadata) {
        self.items = items
        self.metadata = metadata
    }

    /// Maps a page's items to a different type using the supplied closure.
    public func map<U>(_ transform: (T) throws -> (U)) rethrows -> Page<U>
        where U: Codable
    {
        try .init(
            items: self.items.map(transform),
            metadata: self.metadata
        )
    }
}

/// Metadata for a given `Page`.
public struct PageMetadata: Codable {
    /// Current page number. Starts at `1`.
    public let page: Int

    /// Max items per page.
    public let per: Int

    /// Total number of items available.
    public let total: Int
    
    /// Creates a new `PageMetadata` instance.
    ///
    /// - Parameters:
    ///.  - page: Current page number.
    ///.  - per: Max items per page.
    ///.  - total: Total number of items available.
    public init(page: Int, per: Int, total: Int) {
        self.page = page
        self.per = per
        self.total = total
    }
}

/// Represents information needed to generate a `Page` from the full result set.
public struct PageRequest: Decodable {
    /// Page number to request. Starts at `1`.
    public let page: Int

    /// Max items per page.
    public let per: Int

    enum CodingKeys: String, CodingKey {
        case page = "page"
        case per = "per"
    }

    /// `Decodable` conformance.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        self.per = try container.decodeIfPresent(Int.self, forKey: .per) ?? 10
    }

    /// Crates a new `PageRequest`
    /// - Parameters:
    ///   - page: Page number to request. Starts at `1`.
    ///   - per: Max items per page.
    public init(page: Int, per: Int) {
        self.page = page
        self.per = per
    }

    var start: Int {
        (self.page - 1) * self.per
    }

    var end: Int {
        self.page * self.per
    }
}
