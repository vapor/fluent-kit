# ``FluentKit``

FluentKit is an ORM framework for Swift. It allows you to write type safe, database agnostic models and queries. It takes advantage of Swift's type system to provide a powerful, yet easy to use API.

An example query looks like:

```swift
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

For more information, see the [Vapor documentation](https://docs.vapor.codes/fluent/overview/).