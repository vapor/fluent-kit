<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/vapor/fluent-kit/assets/1130717/1da9ba22-253a-43ba-ac03-5cecf0075c30">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/vapor/fluent-kit/assets/1130717/89800da9-2651-4fff-900a-be8f691bedb9">
  <img src="https://github.com/vapor/fluent-kit/assets/1130717/89800da9-2651-4fff-900a-be8f691bedb9" height="96" alt="FluentKit">
</picture> 
<br>
<br>
<a href="https://docs.vapor.codes/4.0/"><img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation"></a>
<a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
<a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
<a href="https://github.com/vapor/fluent-kit/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/vapor/fluent-kit/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration"></a>
<a href="https://codecov.io/github/vapor/fluent-kit"><img src="https://img.shields.io/codecov/c/github/vapor/fluent-kit?style=plastic&logo=codecov&label=codecov"></a>
<a href="https://swift.org"><img src="https://design.vapor.codes/images/swift58up.svg" alt="Swift 5.8+"></a>
</p>

<br>

An Object-Relational Mapper (ORM) for Swift. It allows you to write type safe, database agnostic models and queries. It takes advantage of Swift's type system to provide a powerful, yet easy to use API.

An example query looks like:

```swift
let planets = try await Planet.query(on: database)
    .filter(\.$type == .gasGiant)
    .sort(\.$name)
    .with(\.$star)
    .all()
```

For more information, see the [Fluent documentation](https://docs.vapor.codes/fluent/overview/).
