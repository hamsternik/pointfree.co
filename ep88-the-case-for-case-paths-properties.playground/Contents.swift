import Foundation

/// # The Case for Case Paths: Properties

/// the `CasePath` implementation:

struct CasePath<Root, Value> {
    let extract: (Root) -> Value?
    let embed: (Value) -> Root
}

/// Let's as example use existed `User` data type and extend it a little

struct User {
    var id: Int
    var isAdmin: Bool
    var location: Location
    var name: String
}
struct Location {
    var city: String
    var country: String
}

/// We can take the key path that goes from a user into their location:

\User.location

/// and a key path from a location to its city:

\Location.city

/// and append them together:

(\User.location).appending(path: \Location.city)

/// Swift also provides for us some syntactic sugar to make this a little nicer:

\User.location.city /// the same as `(\User.location).appending(path: \Location.city)`

/// Let's implement the same kind of composition as Swift `KeyPath` has for the `CasePath`:

extension CasePath {
    func appending<AppendedValue>(
        path: CasePath<Value, AppendedValue>
    ) -> CasePath<Root, AppendedValue> {
        CasePath<Root, AppendedValue>(
            extract: { root in self.extract(root).flatMap(path.extract) },
            embed: { appended in self.embed(path.embed(appended)) }
        )
    }
}

/// Let's show the example of how the case path's `append(path:)` could be used:

enum Authentication {
    case authenticated(AccessToken)
    case unauthenticated
}
struct AccessToken {
    var token: String
}

/// and let's create the case path for the `authenticated` case of the enum:

let authenticatedCasePath = CasePath<Authentication, AccessToken>(
    extract: { (auth: Authentication) -> AccessToken? in
        guard case .authenticated(let token) = auth else { return nil }
        return token
    },
    embed: { (token: AccessToken) -> Authentication in
        Authentication.authenticated(token)
    }
)

/// The first idea of how to reduce the amount of boilerplate code here is use our `Result` extension:

extension Result {
    static var successPath: CasePath<Result, Success> {
        CasePath<Result, Success>(
            extract: { (result: Result<Success, Failure>) -> Success? in
                guard case .success(let value) = result else { return nil }
                return value
            },
            embed: { (value: Success) -> Result<Success, Failure> in
                Result.success(value)
            }
        )
    }
}

Result<Authentication, Error>.successPath
    .appending(path: authenticatedCasePath)

/// # Introducing the `•` operator

infix operator ..

func .. <A,B,C>(lhs: CasePath<A,B>, rhs: CasePath<B,C>) -> CasePath<A,C> {
    lhs.appending(path: rhs)
}

/// the same code as at line#90:91

Result<Authentication, Error>.successPath .. authenticatedCasePath

/// # Identity paths

/// there's another nice little feature that key paths have in Swift, and it's known as the "identity" key path. We can type the next code and it will be 100% valid regarding from the Swift compiler:

\User.self
\Location.self
\String.self
\Bool.self

/// But perhaps that looks a little silly. We just want to operate the same value we get as an input, no so a big deal.

/// But how does it look for the case path? Let's create the `identity` variable which would do the same as `\Type.self` is doing for structures right now:

extension CasePath where Root == Value {
    static var identity: CasePath {
        CasePath(
            extract: { Optional.some($0) },
            embed: { $0 }
        )
    }
}

CasePath<Authentication, Authentication>.identity

/// # Re-introducing the `^` operator

prefix operator ^

prefix func ^ <Root, Value>(_ keyPath: KeyPath<Root, Value>) -> (Root) -> Value {
    return { root in root[keyPath: keyPath]}
}

let users = [
  User(
    id: 1,
    isAdmin: true,
    location: Location(city: "Brooklyn", country: "USA"),
    name: "Blob"
  ),
  User(
    id: 2,
    isAdmin: false,
    location: Location(city: "Los Angeles", country: "USA"),
    name: "Blob Jr."
  ),
  User(
    id: 3,
    isAdmin: true,
    location: Location(city: "Copenhagen", country: "DK"),
    name: "Blob Sr."
  ),
]

/// we could easily transform this array in various ways:

users.map(^\.name)

/// Currently I'm using Swift 5.2 so the `Key Path Expressions as Functions` proposal is already approved, merged and I can use it new option:

users.map(\.name)

/// The same we can implemet for our `CasePath` data struct:

prefix func ^ <Root, Value>(
  path: CasePath<Root, Value>
) -> (Root) -> Value? {
  return path.extract
}


^authenticatedCasePath

let authentications: [Authentication] = [
    .authenticated(AccessToken(token: "deadbefd")),
    .unauthenticated,
    .authenticated(AccessToken(token: "caged00d"))
]

authentications.compactMap(^authenticatedCasePath)

/// Without `^` operator we need to explicitly write down the implementation in the closure:

authentications.compactMap { (auth: Authentication) -> AccessToken? in
    guard case .authenticated(let token) = auth else {
        return nil
    }
    return token
}
