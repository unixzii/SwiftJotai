# SwiftJotai

SwiftJotai is an atomic approach to global SwiftUI state management, inspired by [Jotai](https://jotai.org/).

# Getting Started

To use SwiftJotai in your project, add this repository to the `Package.swift` manifest:

```swift
// swift-tools-version:5.7
import PackageDescription

let package = Package(
  name: "MyPackage",
  dependencies: [
    .package(url: "https://github.com/unixzii/SwiftJotai.git", .branch("main")),
  ],
  targets: [
    .target(name: "MyApp", dependencies: [
      .product(name: "SwiftJotai", package: "SwiftJotai"),
    ]),
  ]
)
```

# Tutorial

## Atom

The `Atom` is a config for an atomic state, as it's just a definition and it doesn't yet hold a value.

An atom config is an immutable object. The atom config object doesn't hold a value. The atom value exists in a store.

```swift
let priceAtom = Atom(defaultValue: 10)
let messageAtom = Atom(defaultValue: "hello")
```

You can create derived atoms, we pass a getter closure when doing so:

```swift
let doubledPriceAtom = Atom { store in
    return store.get(priceAtom) * 2
}
```

## Store

The `Store` is an object where state values live in. You can create you own stores or just use the shared instance via `Store.shared`.

You can call...

- `get`: to get the value of an atom.
- `set`: to update the value of an atom.
- `subscribe`: to subscribe the updates of an atom.

### Cancel a subscription

`Store.subscribe` returns a `Disposable` object. You must call the `dispose` method when the subscription is no longer needed, or there may be memory leaks.

## AtomValue

To combine SwiftJotai with SwiftUI, `AtomValue` is your friend. It's an `ObservableObject` which can be used in any SwiftUI views to trigger re-renders when the atom updates.

```swift
let countAtom = Atom(defaultValue: 0)

struct CounterView: View {
    @StateObject var count = AtomValue(countAtom)

    var body: some View {
        Text("\(count.value)")
    }
}
```

# License

MIT
