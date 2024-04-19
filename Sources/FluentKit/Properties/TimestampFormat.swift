import NIOConcurrencyHelpers
import class NIOPosix.ThreadSpecificVariable
import Foundation

// MARK: Format

public protocol TimestampFormat: Sendable {
    associatedtype Value: Codable & Sendable

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
            ISO8601DateFormatter.shared.withLockedValue {
                if withMilliseconds {
                    $0.formatOptions.insert(.withFractionalSeconds)
                }
                return ISO8601TimestampFormat(formatter: $0)
            }
        }
    }
}

extension ISO8601DateFormatter {
    fileprivate static let shared: NIOLockedValueBox<ISO8601DateFormatter> = .init(.init())
}

public struct ISO8601TimestampFormat: TimestampFormat, @unchecked Sendable {
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

