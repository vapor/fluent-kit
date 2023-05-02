#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import FluentKit
@_documentation(visibility: internal) @_exported import XCTest

#elseif !BUILDING_DOCC

@_exported import FluentKit
@_exported import XCTest

#endif
