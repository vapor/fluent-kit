import class NIO.ThreadSpecificVariable
import Foundation

// MARK: Format

public protocol TimestampFormat {
    associatedtype Value: Codable

    func parse(_ value: Value) -> Date?
    func serialize(_ date: Date) -> Value?
}

public struct TimestampFormatFactory<Format> {
    public let makeFormat: () -> Format
    
    public init(_ makeFormat: @escaping () -> Format) {
        self.makeFormat = makeFormat
    }
}

// MARK: Default

extension TimestampFormatFactory {
    public static var `default`: TimestampFormatFactory<DefaultTimestampFormat> {
        .init {
            DefaultTimestampFormat()
        }
    }
}

public struct DefaultTimestampFormat: TimestampFormat {
    public typealias Value = Date

    public func parse(_ value: Date) -> Date? {
        value
    }

    public func serialize(_ date: Date) -> Date? {
        date
    }
}


// MARK: ISO8601

extension TimestampFormatFactory {
    public static var iso8601: TimestampFormatFactory<ISO8601TimestampFormat> {
        .iso8601(withMilliseconds: false)
    }

    public static func iso8601(
        withMilliseconds: Bool
    ) -> TimestampFormatFactory<ISO8601TimestampFormat> {
        .init {
            let formatter = ISO8601DateFormatter.threadSpecific
            if withMilliseconds {
                formatter.formatOptions.insert(.withFractionalSeconds)
            }
            return ISO8601TimestampFormat(formatter: formatter)
        }
    }
}

extension ISO8601DateFormatter {
    private static var cache: ThreadSpecificVariable<ISO8601DateFormatter> = .init()

    static var threadSpecific: ISO8601DateFormatter {
        let formatter: ISO8601DateFormatter
        if let existing = ISO8601DateFormatter.cache.currentValue {
            formatter = existing
        } else {
            let new = ISO8601DateFormatter()
            self.cache.currentValue = new
            formatter = new
        }
        return formatter
    }
}

public struct ISO8601TimestampFormat: TimestampFormat {
    public typealias Value = String

    let formatter: ISO8601DateFormatter

    public func parse(_ value: String) -> Date? {
        self.formatter.date(from: value)
    }

    public func serialize(_ date: Date) -> String? {
        self.formatter.string(from: date)
    }
}

// MARK: Unix


extension TimestampFormatFactory {
    public static var unix: TimestampFormatFactory<UnixTimestampFormat> {
        .init {
            UnixTimestampFormat()
        }
    }
}

public struct UnixTimestampFormat: TimestampFormat {
    public typealias Value = Double

    public func parse(_ value: Double) -> Date? {
        Date(timeIntervalSince1970: value)
    }

    public func serialize(_ date: Date) -> Double? {
        date.timeIntervalSince1970
    }
}

