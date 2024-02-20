#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import struct Foundation.Date
@_documentation(visibility: internal) @_exported import struct Foundation.UUID

@_documentation(visibility: internal) @_exported import Logging

@_documentation(visibility: internal) @_exported import protocol NIO.EventLoop
@_documentation(visibility: internal) @_exported import class NIO.EventLoopFuture
@_documentation(visibility: internal) @_exported import struct NIO.EventLoopPromise
@_documentation(visibility: internal) @_exported import protocol NIO.EventLoopGroup
@_documentation(visibility: internal) @_exported import class NIO.NIOThreadPool

#else

@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID

@_exported import Logging

@_exported import protocol NIO.EventLoop
@_exported import class NIO.EventLoopFuture
@_exported import struct NIO.EventLoopPromise
@_exported import protocol NIO.EventLoopGroup
@_exported import class NIO.NIOThreadPool

#endif
