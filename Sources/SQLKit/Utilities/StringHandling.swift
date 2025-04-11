extension StringProtocol where Self: RangeReplaceableCollection, Self.Element: Equatable {
    /// Returns the string with its first character lowercased.
    @inlinable
    var decapitalized: String {
        self.isEmpty ? "" : "\(self[self.startIndex].lowercased())\(self.dropFirst())"
    }

    /// Returns the string with its first character uppercased.
    @inlinable
    var encapitalized: String {
        self.isEmpty ? "" : "\(self[self.startIndex].uppercased())\(self.dropFirst())"
    }

    /// Returns the string with any `snake_case` converted to `camelCase`.
    ///
    /// This is a modified version of Foundation's implementation:
    /// https://github.com/apple/swift-foundation/blob/8010dfe6b1c38cdf363c8d3d3b43d7d4f4c9987b/Sources/FoundationEssentials/JSON/JSONDecoder.swift
    ///
    /// > Note: This method is _not_ idempotent with respect to `convertedToSnakeCase` for all inputs.
    var convertedFromSnakeCase: String {
        guard !self.isEmpty, let firstNonUnderscore = self.firstIndex(where: { $0 != "_" }) else {
            return .init(self)
        }

        var lastNonUnderscore = self.endIndex
        repeat {
            self.formIndex(before: &lastNonUnderscore)
        } while lastNonUnderscore > firstNonUnderscore && self[lastNonUnderscore] == "_"

        let keyRange = self[firstNonUnderscore...lastNonUnderscore]
        let leading = self[self.startIndex..<firstNonUnderscore]
        let trailing = self[self.index(after: lastNonUnderscore)..<self.endIndex]
        let words = keyRange.split(separator: "_")

        guard words.count > 1 else {
            return "\(leading)\(keyRange)\(trailing)"
        }
        return "\(leading)\(([words[0].decapitalized] + words[1...].map(\.encapitalized)).joined())\(trailing)"
    }

    /// Returns the string with any `camelCase` converted to `snake_case`.
    ///
    /// This is a modified version of Foundation's implementation:
    /// https://github.com/apple/swift-foundation/blob/8010dfe6b1c38cdf363c8d3d3b43d7d4f4c9987b/Sources/FoundationEssentials/JSON/JSONEncoder.swift
    ///
    /// > Note: This method is _not_ idempotent with respect to `convertedFromSnakeCase` for all inputs.
    var convertedToSnakeCase: String {
        guard !self.isEmpty else {
            return .init(self)
        }

        var words: [Range<String.Index>] = []
        var wordStart = self.startIndex
        var searchIndex = self.index(after: wordStart)

        while let upperCaseIndex = self[searchIndex...].firstIndex(where: \.isUppercase) {
            words.append(wordStart..<upperCaseIndex)
            wordStart = upperCaseIndex
            guard let lowerCaseIndex = self[upperCaseIndex...].firstIndex(where: \.isLowercase) else {
                break
            }
            searchIndex = lowerCaseIndex
            if lowerCaseIndex != self.index(after: upperCaseIndex) {
                let beforeLowerIndex = self.index(before: lowerCaseIndex)
                words.append(upperCaseIndex..<beforeLowerIndex)
                wordStart = beforeLowerIndex
            }
        }
        words.append(wordStart..<self.endIndex)
        return words.map { self[$0].decapitalized }.joined(separator: "_")
    }

    /// Remove the given optional prefix from the string, if present.
    ///
    /// - Parameter prefix: The prefix to remove, if non-`nil`.
    /// - Returns: The string with the prefix removed, if it exists. The string unmodified if not,
    ///   or if `prefix` is `nil`.
    func drop(prefix: (some StringProtocol)?) -> Self.SubSequence {
        prefix.map(self.trimmingPrefix(_:)) ?? self[...]
    }
}
