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

struct Location {
    var name: String
}

struct User {
    var location: Location
}

/// The type's generic looks like `<User, String>` so the `Root` takes a `User` instance and returns it's location `name`.

let locationNamePartialKeyPath = (\User.location).appending(path: \Location.name)

let location = Location(name: "Ukraine")
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

/// How to use such `appending(path:)` function.

let _userLocationPartialKeyPath = _WritableKeyPath<User, Location>(
    get: { $0.location },
    set: { $0.location = $1 }
)
let _locationNamePartialKeyPath = _WritableKeyPath<Location, String>(
    get: { $0.name },
    set: { $0.name = $1 }
)
let _userLocationNamePartialKeyPath = _userLocationPartialKeyPath.appending(path: _locationNamePartialKeyPath)
