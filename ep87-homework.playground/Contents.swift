import Foundation

/// The custom **case path** implementation

struct CasePath<Root, Value> {
    let extract: (Root) -> Value?
    let embed: (Value) -> Root
}

/// # EXERCISES

/// ## EXERCISE #1

/// 1. Define the `never` case path: for any type `A` there exists a unique case path `CasePath<A, Never>`.
/// This operation is useful for when you don’t want to focus on any part of the type.


/// I thought about making a sort of function that operate the Never and generic `A` types the similar way
/// of how guys from the pointfree did with the `Result` type.

//func neverCasePath<A>(a: A) -> CasePath<A, Never> {
//    CasePath<A, Never>(
//        extract: { (a: A) -> Never? in
//            return Never
//        },
//        embed: { (never: Never) -> A in
//            return Never
//        }
//    )
//}

/// The correct answer is making an extension of the `CasePath` type and passing a sort of function (read *handler*)
/// to the `embed` (read *setter*) argument.

func absurd<A>(_ never: Never) -> A {}
extension CasePath where Value == Never {
    static var never: CasePath {
        CasePath(
            extract: { _ in nil },
            embed: absurd
        )
    }
}

/// I am also can write down the `embed` argument as an empty closure that returns nothing
/// In some reasones for generic type `A` it's okay.

//extension CasePath where Value == Never {
//    static var never: CasePath {
//        CasePath(extract: { _ in nil }, embed: { _ in return  })
//    }
//}

/// UPD: I cannot write the extension above 'cause Swift compiler produces the error:
/// ⚠️ error: cannot convert value of type '()' to closure result type 'Root'.
/// So the only one option is passing `absurd` empty method to the `embed` argument.


/// ## EXERCISE #2

/// 2. Define the "void" key path: for any type `A` there's a unique key path `_WritableKeyPath<A, Void>`
/// This operation is useful for when you do not want to focus on any part of the type.

struct _WritableKeyPath<Root, Value> {
    let get: (Root) -> Value
    let set: (inout Root, Value) -> Void
}

/// We can try to do the same as we did for the `never` extension variable for `CasePath` type.

extension _WritableKeyPath where Value == Void {
    static var void: _WritableKeyPath {
        _WritableKeyPath(
            get: { _ in },
            set: { _, _ in }
        )
    }
}

/// Is it possible to define this key path on Swift's `WritableKeyPath`?

//extension WritableKeyPath where Value == Void {
//    static var void: WritableKeyPath {
//        WritableKeyPath() /// ⚠️ Error: 'WritableKeyPath<Root, Void>' cannot be constructed because it has no accessible initializers
//    }
//}

/// In my first observation `WritableKeyPath` type does not have an initializer so we just can't define a variable for it 🤷🏻‍♂️

/// ## EXERCISE #3

/// 3. Key paths are equipped with an operation that allows you to append them. For example:

struct User {
    struct Location: ExpressibleByStringLiteral {
        struct Name {
            var value: String
        }

        var name: Name
        init(stringLiteral value: String) {
            self.name = Name(value: value)
        }
    }

    var location: Location
}

/// The type's generic looks like `<User, String>` so the `Root` takes a `User` instance and returns it's location `name`.

//let locationNamePartialKeyPath = (\User.location).appending(path: \Location.name)
let locationNamePartialKeyPath = (\User.location).appending(path: \User.Location.name)

let location: User.Location = "Ukraine"
let user = User(location: location)

locationNamePartialKeyPath

/// Define `appending(path:)` from scratch on `_WritableKeyPath`

extension _WritableKeyPath {
    func appending<LocalValue>(path: _WritableKeyPath<Value, LocalValue>) -> _WritableKeyPath<Root, LocalValue> {
        _WritableKeyPath<Root, LocalValue>(
            get: { (root: Root) -> LocalValue in path.get(get(root)) },
            set: { (root: inout Root, localValue: LocalValue) -> Void in
                var value = get(root)
                path.set(&value, localValue)
                set(&root, value)
            }
        )
    }
}

/// How to use `appending(path:)` function for the `_WritableKeyPath`.

let _userLocationPartialKeyPath = _WritableKeyPath<User, User.Location>(
    get: { $0.location },
    set: { $0.location = $1 }
)
let _locationNamePartialKeyPath = _WritableKeyPath<User.Location, String>(
    get: { $0.name.value },
    set: { $0.name.value = $1 }
)
/// result type is `_WritableKeyPath<User, String>`
let _userLocationNamePartialKeyPath = _userLocationPartialKeyPath
    .appending(path: _locationNamePartialKeyPath)

/// using Swift embedded `keyPath`

/// result type is `WritableKeyPath<User, String>`
//let userLocationNamePartialKeyPath = (\User.location).appending(path: \User.Location.name.value)

/// the same as in previous definition at 2 lines above
let userLocationNamePartialKeyPath = (\User.location)
    .appending(path: \User.Location.name)
    .appending(path: \User.Location.Name.value)

/// ## EXERCISE #4

/// 4. Define an `appending(path:)` method on `CasePath`, which allows you to combine a `CasePath<A, B>` and a `CasePath<B, C>`, into a `CasePath<A, C>`

extension CasePath {
    func appending<PartialValue>(path: CasePath<Value, PartialValue>) -> CasePath<Root, PartialValue> {
        CasePath<Root, PartialValue>(
            extract: { root -> PartialValue? in
//                guard let value = extract(root), let partial = path.extract(value) else { return nil }
//                return partial

                /// could be written in more elegant way
                self.extract(root).flatMap(path.extract)
            },
            embed: { partial -> Root in
                embed(path.embed(partial))
            }
        )
    }
}

/// How to use `appending(path:)` function for the `CasePath`.

// sourcery: casePath
enum GeneralError: Error {
    // sourcery: casePath
    enum NetworkError: Error {
        // sourcery: casePath
        enum ServerError: Error {
            case invalidData
            case incorrectFormat
            case failedRequest
        }

        case serverError(ServerError)
        case clientError
        case undefined
    }

    case localError
    case networkError(NetworkError)
    case unknown
}

let networkErrorCasePath = CasePath<GeneralError, GeneralError.NetworkError>(
    extract: { (error: GeneralError) -> GeneralError.NetworkError? in
        guard case .networkError(let networkError) = error else { return nil }
        return networkError
    },
    embed: { (networkError: GeneralError.NetworkError) -> GeneralError in
        GeneralError.networkError(networkError)
    }
)
let serverErrorCasePath = CasePath<GeneralError.NetworkError, GeneralError.NetworkError.ServerError>(
    extract: { (networkError: GeneralError.NetworkError) -> GeneralError.NetworkError.ServerError? in
        guard case .serverError(let serverError) = networkError else { return nil }
        return serverError
    },
    embed: { (serverError: GeneralError.NetworkError.ServerError) -> GeneralError.NetworkError in
        GeneralError.NetworkError.serverError(serverError)
    }
)
let serverErrorFromGeneralCasePath: CasePath<GeneralError, GeneralError.NetworkError.ServerError> = networkErrorCasePath.appending(path: serverErrorCasePath)

/// ## EXERCISE #5

/// 5. Every type in Swift automatically comes with a special key path known as the "identity" key path. One gets access to it with the following syntax.

let userIdentityKeyPath = \User.self /// return type is `WritableKeyPath<User, User>`
let intIdentityKeyPath = \Int.self /// return type is `WritableKeyPath<Int, Int>`

/// Define this operator for `_WritableKeyPath`

extension _WritableKeyPath where Root == Value {
    /// My implementation: using `static func` in case I can not define
    /// any generic types like `<Root, Root>` for the static variables.
//    static func identity() -> _WritableKeyPath<Root, Root> {
//        _WritableKeyPath<Root, Root>(
//            get: { $0 },
//            set: { $0 = $1 }
//        )
//    }

    /// pointfree implementation: w/o any generics using `identity` static variable
    /// instead of defining generic types explicitly at method/variable return type
    /// I can just restrict the `Root` type be the same as `Value` to make identity of any type
    static var `self`: _WritableKeyPath {
        _WritableKeyPath(
            get: { $0 },
            set: { (root, value) in root = value }
        )
    }
}

/// # EXERCISE #6

/// 6. Define the `self` case path: for any type `A` there is a case path `CasePath<A, A>`.
extension CasePath where Root == Value {
    /// I preferred to name this variable as `identity`
    /// instead of `self` as pointfree folks suggested.
    static var identity: CasePath {
        CasePath(
            extract: { Optional.some($0) },
            embed: { $0 }
        )
    }
}

let getNetworkErrorFromGeneralErrorCasePath = CasePath<GeneralError, GeneralError.NetworkError>(
    extract: { (general: GeneralError) -> GeneralError.NetworkError? in
        guard case .networkError(let networkErrorData) = general else { return nil }
        return networkErrorData
    },
    embed: { (networkErrorData: GeneralError.NetworkError) -> GeneralError in
        return GeneralError.networkError(networkErrorData)
    }
)
let generalNetworkIdentityCasePath = CasePath<GeneralError, GeneralError>.identity

/// # Exercise #7
/// **Task**: implement the "pair" key path: for any types `A`, `B`, and `C` one can combine two key paths `_WritableKeyPath<A,B>` and `_WritableKeyPath<B,C>` into a third key path `_WritableKeyPath<A,(B, C)>`.
/// This operator allows you to easily focus on two properties of a struct at once.
/// Note that this is not possible to do with Swift's `WritableKeyPath` because they are not directly constrictible by us, only by the compiler.

/// # Solution: my own implementation

extension _WritableKeyPath {
    func pair<LocalValue>(
        with localValueKeyPath: _WritableKeyPath<Value, LocalValue>
    ) -> _WritableKeyPath<Root, (Value, LocalValue)> {
        _WritableKeyPath<Root, (Value, LocalValue)>(
            get: { (root: Root) -> (Value, LocalValue) in
                let value = get(root)
                return (value, localValueKeyPath.get(value))
            },
            set: { (root: inout Root, combined: (Value, LocalValue)) in
                var value = combined.0
                localValueKeyPath.set(&value, combined.1)
                set(&root, value)
            }
        )
    }
}

/// Pre-define the data structures for tests:

struct Person7 {
    struct Address {
        var title: String
    }

    var address: Address
}

var homeAddress = Person7.Address(title: "Demiivska, 18")
var nikita = Person7(address: homeAddress)

let personAddressKeyPath = _WritableKeyPath<Person7, Person7.Address>(
    get: { $0.address },
    set: { $0.address = $1 }
)

let addressTitleKeyPath = _WritableKeyPath<Person7.Address, String>(
    get: { $0.title },
    set: { $0.title = $1 }
)

/// Let's use the `pair` function in example:

let personAddressWithTitleKeyPath: _WritableKeyPath<Person7, (Person7.Address, String)>
    = personAddressKeyPath.pair(with: addressTitleKeyPath)

let nikitaAddressWithTitle = personAddressWithTitleKeyPath.get(nikita)
nikitaAddressWithTitle.0
nikitaAddressWithTitle.1

var workAddressTitle = "Sofiivska Ploscha, 13"
var workAddress = Person7.Address(title: workAddressTitle)
personAddressWithTitleKeyPath.set(&nikita,(workAddress, workAddressTitle))
print(nikita)

/// # Solution: pointfree.co implementation

func pair<A,B,C>(
    _ lhs: _WritableKeyPath<A,B>,
    _ rhs: _WritableKeyPath<A,C>
) -> _WritableKeyPath<A,(B,C)> {
    _WritableKeyPath<A,(B,C)>(
        get: { a in (lhs.get(a), rhs.get(a)) },
        set: { a, bc in
            lhs.set(&a, bc.0)
            rhs.set(&a, bc.1)
        }
    )
}

/// Let's use the `pair` function in example (use the same `Person7` data structure):

let personWithAddressAndTitle = pair(
    personAddressKeyPath,
    personAddressKeyPath.appending(path: addressTitleKeyPath)
)

personWithAddressAndTitle.get(nikita)

var oldHomeAddressTitle = "Zhilanska, 55"
var oldHomeAddress = Person7.Address(title: oldHomeAddressTitle)
personWithAddressAndTitle.set(&nikita, (oldHomeAddress, oldHomeAddressTitle))
print(nikita)


/// # Exercise #8
/// **Task**: implement the "either" case path: for any types `A`, `B` and `C` one can combine two case paths `CasePath<A,B>`, `CasePath<A,C>` into a third case path `CasePath<A,Either<B,C>>`, where:
/// ```
enum Either<A,B> {
    case left(A)
    case right(B)
}
/// ```
/// This operation allows you to easily focus on two cases of an enum at once.

/// # Solution -- my own implementation

func either1<A,B,C>(
    _ lhs: CasePath<A,B>,
    _ rhs: CasePath<A,C>
) -> CasePath<A, Either<B,C>> {
    CasePath<A, Either<B,C>>(
        extract: { (a: A) -> Either<B,C>? in
            let _b = lhs.extract(a)
            let _c = rhs.extract(a)
            switch (_b, _c) {
                case (.some(let b), _): return .left(b)
                case (nil, .some(let c)): return .right(c)
                case (nil, nil): return nil
            }
        },
        embed: { (bc: Either<B,C>) -> A in
            switch bc {
            case .left(let b):
                return lhs.embed(b)
            case .right(let c):
                return rhs.embed(c)
            }
        }
    )
}

/// # Solution -- pointfree.co implementation

func either2<A,B,C>(
    _ lhs: CasePath<A,B>,
    _ rhs: CasePath<A,C>
) -> CasePath<A, Either<B,C>> {
    CasePath<A, Either<B,C>>(
        extract: { (a: A) -> Either<B,C>? in
            /// The all difference between solution #1 and #2 relates to the `extract` closure implementaion
            /// lectors provided a more elegant and more functional way of how to unwrap and extract the right value
            lhs.extract(a).map(Either.left)
                ?? rhs.extract(a).map(Either.right)
        },
        embed: { (bc: Either<B,C>) -> A in
            switch bc {
            case .left(let b):
                return lhs.embed(b)
            case .right(let c):
                return rhs.embed(c)
            }
        }
    )
}
