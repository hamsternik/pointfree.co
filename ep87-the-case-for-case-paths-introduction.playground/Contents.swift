struct User {
    var id: Int
    let isAdmin: Bool
    var name: String
}

let idKeyPath = \User.id as WritableKeyPath
let nameKeyPath = \User.name as WritableKeyPath<User, String>
//\User.isAdmin as WritableKeyPath<User, Bool>
\User.isAdmin as KeyPath<User, Bool>
\User.name as KeyPath<User, String>

var user = User(id: 42, isAdmin: true, name: "Bob")

let result = user[keyPath: \.id]
result

user[keyPath: \.id] = 57
user.id

/// The idea of using KeyPath in Swift

import Foundation

/// let's just consider we can use here `UILabel` instead.
class Label {
    @objc dynamic var font = "Arial"
    @objc dynamic var fontSize = 12
    @objc dynamic var text = ""
}

class Model {
    @objc dynamic var username = ""
}

let model = Model()
let label = Label()
//bind(model: model, \.userName, to: label, \.text)
label.text
model.username = "new username"
label.text
model.username = "XxHamsterXx88"
label.text

/// That should work ^^ (based on pointfree video) but I don't have an implementation of the `bind(model:, to:)` function.

import Combine

class Label1 {
    var font = "Arial"
    let fontSize = 12
    var text = ""
}

class Model1 {
    var font = ""
    var username = ""
}

let model1 = Model1()
let label1 = Label1()

let subject = PassthroughSubject<String, Never>()
subject.assign(to: \Label1.text, on: label1)
subject.send("MaTh_FaN1995")
label1.text

//subject.assign(to: \Label1.fontSize, on: label)
/// Error: Cannot convert value of type 'KeyPath<Label1, Int>' to expected argument type 'ReferenceWritableKeyPath<Label, String>'

subject.assign(to: \Label1.font, on: label1)
subject.send("Times New Roman")
label.font
/// But there's no changes at the `\.font` property in the `label1` instance 'cause I've used the same `subject` instance.

/// Let's go and create the new passthrough subject
let label1FontSubject = PassthroughSubject<String, Never>()
label1FontSubject.assign(to: \Label1.font, on: label1)
label1FontSubject.send("Times New Roman")
label1.font

/// Use Case #2: using KeyPath with reducers in ComposableArchitecture from the pointfree
typealias Reducer<State, Action> = (inout State, Action) -> Void

func pullback<GlobalState, LocalState, Action>(
    reducer: @escaping Reducer<LocalState, Action>,
    value: WritableKeyPath<GlobalState, LocalState>
) -> Reducer<GlobalState, Action> {
    return { globalState, action in
//        var localState = globalState[keyPath: value]
//        reducer(&localState, action)
//        globalState[keyPath: value] = localState
        reducer(&globalState[keyPath: value], action)
    }
}

let counterReducer: Reducer<Int, Void> = { count, _ in count += 1 }

/// The custom **case path** implementation

struct _WritableKeyPath<Root, Value> {
    let get: (Root) -> Value
    let set: (inout Root, Value) -> Void
}

struct CasePath<Root, Value> {
    let extract: (Root) -> Value?
    let embed: (Value) -> Root
}

extension Result {
    static var successCasePath: CasePath<Result, Success> {
        CasePath<Result, Success>(
            extract: { result -> Success? in
                if case .success(let value) = result {
                    return value
                }
                return nil
            },
            embed: Result.success
        )
    }

    static var failureCasePath: CasePath<Result, Failure> {
        CasePath<Result, Failure>(
            extract: { result -> Failure? in
                if case .failure(let error) = result {
                    return error
                }
                return nil
            },
            embed: Result.failure
        )
    }
}
