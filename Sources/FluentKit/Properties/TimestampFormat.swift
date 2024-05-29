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
            ISO8601TimestampFormat(formatter: (withMilliseconds ?
                ISO8601DateFormatter.sharedWithMs :
                ISO8601DateFormatter.sharedWithoutMs
            ).value)
        }
    }
}

extension ISO8601DateFormatter {
    // We use this to suppress warnings about ISO8601DateFormatter not being Sendable. It's safe to do so because we
    // know that in reality, the formatter is safe to use simultaneously from multiple threads as long as the options
    // are not changed, and we never change the options after the formatter is first created.
    fileprivate struct FakeSendable<T>: @unchecked Sendable { let value: T }
    
    fileprivate static let sharedWithoutMs: FakeSendable<ISO8601DateFormatter> = .init(value: .init())
    fileprivate static let sharedWithMs: FakeSendable<ISO8601DateFormatter> = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        return .init(value: formatter)
    }()
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

