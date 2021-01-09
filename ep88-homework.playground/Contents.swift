import Foundation

/// generic code necessary to complete all exercises:

struct CasePath<Root, Value> {
    let extract: (Root) -> Value?
    let embed: (Value) -> Root
}

enum Either<Left, Right> {
    case left(Left)
    case right(Right)
}

extension Either {
    var left: Left? {
        guard case .left(let value) = self else {
            return nil
        }
        return value
    }

    var right: Right? {
        guard case .right(let value) = self else {
            return nil
        }
        return value
    }
}

/// # Exercise #1
/// **Task**: case paths don't only need to focus on a single case of an enum. They cas also focus on multiple cases of an enum, we just have to do a little bit of manual work first.
/// Consider the following enum:
///```
enum AppAction {
    enum Activity { case didLaunch, didFinish }
    enum Dashboard { case first, second }
    enum Profile { case admin, user }

    case activity(Activity)
    case dashboard(Dashboard)
    case profile(Profile)
}
///```
/// Write a case path that can extract an `activity` or `profile` action from an app action, but not a dashboard action. Compare this how one would write a computed property that focues on two struct fields at the same time.

/// here: define the `Either` data struct to easily operate such definitions like `X` or `Y`

extension AppAction {
    var activityOrProfile: Either<Activity, Profile>? {
        switch self {
        case .activity(let value):
            return .left(value)
        case .profile(let value):
            return .right(value)
        case .dashboard:
            return nil
        }
    }
}

let actions1: [AppAction] = [
    .profile(.admin),
    .activity(.didLaunch),
    .dashboard(.first),
    .activity(.didFinish),
    .profile(.user)
]

actions1.compactMap(\AppAction.activityOrProfile)

//enum ActivityOrProfile {
//    case activity(AppAction.Activity)
//    case profile(AppAction.Profile)
//}

typealias ActivityOrProfile = Either<AppAction.Activity, AppAction.Profile>
extension CasePath where Root == AppAction, Value == ActivityOrProfile {
    static var activityOrProfile: CasePath {
        CasePath(
            extract: { appAction -> ActivityOrProfile? in
                switch appAction {
                case .activity(let value):
                    return .left(value)
                case .profile(let value):
                    return .right(value)
                case .dashboard:
                    return nil
                }
            },
            embed: { activityOrProfile -> AppAction in
                switch activityOrProfile {
                case .left(let activity):
                    return .activity(activity)
                case .right(let profile):
                    return .profile(profile)
                }
            }
        )
    }
}

let activityOrProfileCasePath
    = CasePath<AppAction, Either<AppAction.Activity, AppAction.Profile>>.activityOrProfile

/// # Exercise #2
/// **Task**: Every computed property on a type (struct, enums and classes) is given a key path for free by Swift compiler. For example:
///```
struct State {
    var count: Int
    var favorites: [Int]

    var isFavorite: Bool {
        get { self.favorites.contains(self.count) }
        set {
            newValue
                ? self.favorites.removeAll(where: { $0 == self.count })
                : self.favorites.append(self.count)
        }
    }
}
\State.isFavorite // WritableKeyPath<State, Bool>
///```
/// The `isFavorite` computed property is given a `WritableKeyPath`, even though it is not a stored field of the structure!
/// What is the equivalent concept for case paths? Theorize what a "computed case" syntax could look like in Swift.

/// Let's use `AppState` enum to make any examples in the ex. #2.
/// To test the concept of extracting the "computed" case let's use `activityOrProfile` variable defined at the `AppState` extension in the ex. #1.

prefix operator ^

prefix func ^ <Root, Value>(_ casePath: CasePath<Root, Value>) -> (Root) -> Value? {
    casePath.extract
}

let actions2: [AppAction] = [
    .profile(.admin),
    .activity(.didLaunch),
    .dashboard(.first),
    .activity(.didFinish),
    .profile(.user),
    .activity(.didLaunch)
]

actions2.compactMap { (appAction: AppAction) -> Either<AppAction.Activity, AppAction.Profile>? in
    switch appAction {
    case .activity(let value):
        return .left(value)
    case .profile(let value):
        return .right(value)
    case .dashboard:
        return nil
    }
}

/// **Optiona**: there is need to re-thinking the `^` operator I guess.

/// # Exercise #3
/// Although enums are a great source for case paths, it is not the only situation in which csae paths can occur. At its core, csae paths express only the idea of being able to try to extract some data from a value, and the ability to construct a value from the data.
/// Implement the following case paths. A natural place to hold these case paths is a static variables on `CasePath` with `Root` and `Value` suitable constrained.
/// * int: CasePath<String, Int>
extension CasePath where Root == String, Value == Int {
    static var intFromStringCasePath: CasePath {
        CasePath(
            extract: { Int($0) },
            embed: { String($0) }
        )
    }
}

/// * uuid: CasePath<String, UUID>
/// * literal: (String) -> CasePath<String, String>
/// * first: CasePath<[A], A>
/// * first: (where: (A) -> Bool) -> CasePath<[A], A>
/// * key: (K) -> CasePath<[K: V], V>
/// * rawValue: CasePath<R.RawValue, R> where R: RawRepresentable
