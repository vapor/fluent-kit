import NIOCore

public extension SiblingsProperty {
    
    func load(on database: any Database) async throws {
        try await self.load(on: database).get()
    }
    
    // MARK: Checking state
    
    func isAttached(to: To, on database: any Database) async throws -> Bool {
        try await self.isAttached(to: to, on: database).get()
    }
    
    func isAttached(toID: To.IDValue, on database: any Database) async throws -> Bool {
        try await self.isAttached(toID: toID, on: database).get()
    }
    
    // MARK: Operations
    
    /// Attach multiple models with plain edit closure.
    func attach(_ tos: [To], on database: any Database, _ edit: (Through) -> () = { _ in }) async throws {
        try await self.attach(tos, on: database, edit).get()
    }

    /// Attach single model with plain edit closure.
    func attach(_ to: To, on database: any Database, _ edit: @escaping (Through) -> ()) async throws {
        try await self.attach(to, method: .always, on: database, edit)
    }
    
    /// Attach single model by specific method with plain edit closure.
    func attach(
        _ to: To, method: AttachMethod, on database: any Database,
        _ edit: @escaping (Through) -> () = { _ in }
    ) async throws {
        try await self.attach(to, method: method, on: database, edit).get()
    }
    
    /// A version of ``attach(_:on:_:)-791gu`` whose edit closure is async and can throw.
    ///
    /// This method provides "all or none" semantics- if the edit closure throws an error, any already-
    /// processed pivots are discarded. Only if all pivots are successfully edited are any of them saved.
    ///
    /// These semantics require us to reimplement, rather than calling through to, the ELF version.
    func attach(
        _ tos: [To],
        on database: any Database,
        _ edit: @Sendable @escaping (Through) async throws -> ()
    ) async throws {
        guard let fromID = self.idValue else {
            throw SiblingsPropertyError.owningModelIdRequired(property: self.name)
        }
        
        var pivots: [Through] = []
        pivots.reserveCapacity(tos.count)
        
        for to in tos {
            guard let toID = to.id else {
                throw SiblingsPropertyError.operandModelIdRequired(property: self.name)
            }
            let pivot = Through()
            pivot[keyPath: self.from].id = fromID
            pivot[keyPath: self.to].id = toID
            pivot[keyPath: self.to].value = to
            try await edit(pivot)
            pivots.append(pivot)
        }
        try await pivots.create(on: database)
    }

    /// A version of ``attach(_:on:_:)-791gu`` whose edit closure is async and can throw.
    ///
    /// These semantics require us to reimplement, rather than calling through to, the ELF version.
    func attach(_ to: To, on database: any Database, _ edit: @Sendable @escaping (Through) async throws -> ()) async throws {
        try await self.attach(to, method: .always, on: database, edit)
    }
    
    /// A version of ``attach(_:method:on:_:)-20vs`` whose edit closure is async and can throw.
    ///
    /// These semantics require us to reimplement, rather than calling through to, the ELF version.
    func attach(
        _ to: To, method: AttachMethod, on database: any Database,
        _ edit: @Sendable @escaping (Through) async throws -> ()
    ) async throws {
        switch method {
        case .ifNotExists:
            guard try await !self.isAttached(to: to, on: database) else { return }
            fallthrough
        case .always:
            try await self.attach([to], on: database, edit)
        }
    }
    
    func detach(_ tos: [To], on database: any Database) async throws {
        try await self.detach(tos, on: database).get()
    }
    
    func detach(_ to: To, on database: any Database) async throws {
        try await self.detach(to, on: database).get()
    }
    
    func detachAll(on database: any Database) async throws {
        try await self.detachAll(on: database).get()
    }
}
