import Foundation

enum GregorianDateError: Error {
    case invalidStringFormat
}

/**
 A Gregorian date with no time or timezone, intended to pair with
 the SQL `DATE` type
 */
public struct GregorianDate {
    private static let gregorianCalendar = Calendar(identifier: .gregorian)
    
    public var year: Int
    public var month: Int
    public var day: Int
    
    public var dateComponents: DateComponents {
        return DateComponents(calendar: GregorianDate.gregorianCalendar,
                       year: year,
                       month: month,
                       day: day)
    }
    
    /**
     Create a GregorianDate from the current date in the current timezone.
     */
    public init() {
        self.init(Date())
    }
    
    /**
     Create a GregorianDate from a year, month, and day.
     The inputs are not validated to ensure they form a valid date.
     
     - Parameters:
         - year: >= 0
         - month: 1 – 12
         - day: 1 – 31
     */
    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    /**
     Create a GregorianDate from the year, month, and day in the
     DateComponents. Other fields in the components are ignored.
     */
    public init?(_ components: DateComponents) {
        guard let year = components.year,
            let month = components.month,
            let day = components.day else { return nil }
        
        self.year = year
        self.month = month
        self.day = day
    }
    
    /**
     Create a GregorianDate from the date portion of a Date object,
     using the timezone stored in that Date.
     */
    public init(_ date: Date) {
        let components = GregorianDate.gregorianCalendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year!
        self.month = components.month!
        self.day = components.day!
    }
    
    /**
     Create a GregorianDate from a string in YYYY-MM-dd format.
     */
    public init(string: String) throws {
        // Yes, this is a horrendous amount of code just to parse the "YYYY-MM-dd" date format.
        // It could also be done with NSRegularExpression, or by converting to Date and using
        // a DateFormatter. Feel free.
        let zero = CChar(48)
        let digits = CChar(48) ... CChar(57)
        let hyphen = CChar(45)
        
        let s = string.utf8CString
        guard s.count == 11 else { throw GregorianDateError.invalidStringFormat } // remember that trailing null is included
        let y1 = s[0]
        guard digits.contains(y1) else { throw GregorianDateError.invalidStringFormat }
        let y2 = s[1]
        guard digits.contains(y2) else { throw GregorianDateError.invalidStringFormat }
        let y3 = s[2]
        guard digits.contains(y3) else { throw GregorianDateError.invalidStringFormat }
        let y4 = s[3]
        guard digits.contains(y4) else { throw GregorianDateError.invalidStringFormat }
        guard s[4] == hyphen else { throw GregorianDateError.invalidStringFormat }
        let m1 = s[5]
        guard digits.contains(m1) else { throw GregorianDateError.invalidStringFormat }
        let m2 = s[6]
        guard digits.contains(m2) else { throw GregorianDateError.invalidStringFormat }
        guard s[7] == hyphen else { throw GregorianDateError.invalidStringFormat }
        let d1 = s[8]
        guard digits.contains(d1) else { throw GregorianDateError.invalidStringFormat }
        let d2 = s[9]
        guard digits.contains(d2) else { throw GregorianDateError.invalidStringFormat }
        
        year = (Int(y1 - zero) * 1000) + (Int(y2 - zero) * 100) + (Int(y3 - zero) * 10) + Int(y4 - zero)
        month = (Int(m1 - zero) * 10) + Int(m2 - zero)
        day = (Int(d1 - zero) * 10) + Int(d2 - zero)
    }
}

extension GregorianDate: CustomStringConvertible {
    /// The date in "YYYY-MM-dd" format
    public var description: String {
        let y = String(format: "%04d", year)
        let m = String(format: "%02d", month)
        let d = String(format: "%02d", day)
        return "\(y)-\(m)-\(d)"
    }
}

/*
 Override the default implementation of Codable to use "YYYY-MM-dd" format
 rather than individual year, month, and day fields.
 */
extension GregorianDate: Codable {
    public func encode(to encoder: Encoder) throws {
        try description.encode(to: encoder)
    }
    
    public init(from decoder: Decoder) throws {
        try self.init(string: String(from: decoder))
    }
}

extension GregorianDate: Comparable {
    public static func < (lhs: GregorianDate, rhs: GregorianDate) -> Bool {
        if lhs.year < rhs.year { return true }
        if lhs.year > rhs.year { return false }
        if lhs.month < rhs.month { return true }
        if lhs.month > rhs.month { return false }
        return lhs.day < rhs.day
    }
}
