# Contributing to FluentKit

👋 Welcome to the Vapor team! 

## Overview

Fluent is an ORM framework for Swift. You can read more about it at [docs.vapor.codes/4.0/fluent/overview/](https://docs.vapor.codes/4.0/fluent/overview/).

Fluent strives to:

- Create an easy to use abstraction for storing data

- Provide consistency across varying database backends

- Feel at home alongside Swift's standard library

- Use Swift's type system to eliminate common errors

- Take advantage of advanced Swift features

Fluent is not:

- A SQL builder (see [sql-kit](https://github.com/vapor/sql-kit))

- Suitable for working with arbitrary table structures (restrictions and assumptions exist)

- The most performant way to access your data (abstraction cost)

## Packages

Fluent consists of several packages. 

- [`fluent-kit`](https://github.com/vapor/fluent-kit): Core of the ORM. Models, relations, query builder, etc. 
- [`fluent`](https://github.com/vapor/fluent): Integrates FluentKit with [`Vapor`](https://github.com/vapor/vapor).
- [`fluent-postgres-driver`](https://github.com/vapor/fluent-postgres-driver): PostgreSQL driver for Fluent built on [PostgresKit](https://github.com/vapor/postgres-kit).
- [`fluent-mysql-driver`](https://github.com/vapor/fluent-mysql-driver): MySQL driver for Fluent built on [MySQLKit](https://github.com/vapor/mysql-kit).
- [`fluent-sqlite-driver`](https://github.com/vapor/fluent-sqlite-driver): SQLite driver for Fluent built on [SQLiteKit](https://github.com/vapor/sqlite-kit).
- [`fluent-mongo-driver`](https://github.com/vapor/fluent-mongo-driver): MongoDB driver for Fluent built on [MongoKitten](https://github.com/OpenKitten/MongoKitten).

When submitting issues, try to find the most appropriate package. When in doubt, use [`fluent-kit`](https://github.com/vapor/fluent-kit).

## Feature Requests

Please read these guidelines before submitting a feature request to FluentKit. Due to the large volume of issues we receive, feature requests that do not follow these guidelines will be closed.

### Do:

- ✅ Clearly define a problem currently affecting Fluent users.

> Make it clear what you are currently _not able_ to do with Fluent and why you think this matters to most people using it. 

- ✅ Clearly define a solution, with plenty of examples.

> Show what a solution to this problem looks like to use. Pretend you are writing documentation for it.

- ✅ Propose more than one solution.

> If you have lots of ideas, share them. They will help in the brainstorming process. 

- ✅ Relate the problem and solution to Fluent's existing APIs such as models, query builder, and relations. 

> Explain clearly how your feature would fit in with the rest of what Fluent offers. 

- ✅ Show examples from other ORMs. 

> If the feature you are requesting exists in other ORMs, include examples. This will help everyone understand the idea better as well as provide additional sources of inspiration. 

- ✅ Suggest possible implementations. 

> It is critical that Fluent's APIs work consistently across all of it's supported database drivers. Researching how your solution could be implemented at the driver level ahead of time will help speed up the process.

### Do not:

- ❌ Propose an API soley because it exists in one of the database drivers. 

> Just because one of the underlying database drivers supports something does not mean Fluent should offer an API for it. Fluent is meant to abstract database functionality, making it easier to use.

- ❌ Define your problem or solution in terms of the underlying database driver.

> How a Fluent feature is works in the underlying database drivers is an implementation detail. Possible implementations are worth suggesting as a part of your feature request, but they should not be the focus. 

- ❌ Propose features soley for working with existing databases.

> Fluent is not built for working with existing database schemas or databases created by different ORMs. Other libraries, like SQLKit, are better suited for this.

- ❌ Submit large PRs without discussion first.

> Give everyone a chance to understand your idea and get on the same page before submitting code. This can be through a GitHub issue or the Swift forums. 

## SemVer

Vapor follows [SemVer](https://semver.org). This means that any changes to the source code that can cause
existing code to stop compiling _must_ wait until the next major version to be included. 

Code that is only additive and will not break any existing code can be included in the next minor release.

----------

Join us in Chat if you have any questions: [http://vapor.team](http://vapor.team).

&mdash; Thanks! 🙌
