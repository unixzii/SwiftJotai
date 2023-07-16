//
//  Jotai.swift
//  SwiftJotai
//
//  Created by Cyandev on 2023/7/16.
//

import Foundation

fileprivate var globalId = 0

// TODO: thread safety
fileprivate func nextId() -> Int {
    globalId += 1
    return globalId
}

public class BaseAtom: Hashable {
    fileprivate let key: Int
    
    public static func == (lhs: BaseAtom, rhs: BaseAtom) -> Bool {
        return lhs === rhs
    }
    
    init(key: Int) {
        self.key = key
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    fileprivate func _get(store: Store) -> Any {
        fatalError("Not implemented")
    }
}

@MainActor
public class Atom<T: Equatable>: BaseAtom {
    fileprivate let getter: (Store) -> T
    
    public init(_ defaultValue: T) {
        let key = nextId()
        self.getter = {
            return $0.getRaw(key: key, defaultValue: defaultValue)
        }
        super.init(key: key)
    }
    
    public init(getter: @escaping (Store) -> T) {
        self.getter = getter
        super.init(key: nextId())
    }
    
    override func _get(store: Store) -> Any {
        return getter(store)
    }
}

public protocol Subscriber {
    func receiveUpdate()
}

public class AnySubscriberBase: Subscriber, Hashable {
    public static func == (lhs: AnySubscriberBase, rhs: AnySubscriberBase) -> Bool {
        return lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    public func receiveUpdate() {
        fatalError("Not implemented")
    }
}

public class AnySubscriber<S>: AnySubscriberBase where S: Subscriber {
    public let subscriber: S
    
    public init(subscriber: S) {
        self.subscriber = subscriber
    }
    
    public override func receiveUpdate() {
        self.subscriber.receiveUpdate()
    }
}

public protocol Disposable {
    func dispose()
}

fileprivate struct ClosureSubscriber: Subscriber {
    let closure: () -> ()
    
    func receiveUpdate() {
        closure()
    }
}

fileprivate struct ClosureDisposable: Disposable {
    let closure: () -> ()
    
    func dispose() {
        closure()
    }
}

fileprivate class AtomInternals {
    let comparator: (Any, Any) -> Bool
    var value: Any?
    var memorizedValue: Any?
    var dependents = Set<BaseAtom>()
    var subscribers = Set<AnySubscriberBase>()
    
    init<T: Equatable>(value: T?) {
        self.comparator = { lhs, rhs in
            return (lhs as! T) == (rhs as! T)
        }
        self.value = value
    }
}

@MainActor
public class Store {
    public static let shared = Store()
    
    private var stateMap: [Int : AtomInternals] = [:]
    private var readScope: [BaseAtom] = []
    
    public func `get`<T: Equatable>(_ atom: Atom<T>) -> T {
        readScope.append(atom)
        defer {
            assert(readScope.popLast() != nil)
        }
        return atom.getter(self)
    }
    
    public func `set`<T: Equatable>(_ atom: Atom<T>, value: T) {
        let key = atom.key
        if let internals = stateMap[key] {
            internals.value = value
        } else {
            stateMap[key] = .init(value: value)
        }
        triggerUpdate(for: key, newValue: value)
    }
    
    public func subscribe<T: Equatable, S: Subscriber>(atom: Atom<T>, subscriber: S) -> Disposable {
        // Get the atom's value once to track its dependencies.
        let _ = get(atom)
        
        let typeErasedSubscriber = AnySubscriber(subscriber: subscriber)
        
        let key = atom.key
        if let internals = stateMap[key] {
            internals.subscribers.insert(typeErasedSubscriber)
        } else {
            let internals = AtomInternals(value: nil as T?)
            internals.subscribers.insert(typeErasedSubscriber)
            stateMap[key] = internals
        }
        
        return ClosureDisposable {
            if let internals = self.stateMap[key] {
                internals.subscribers.remove(typeErasedSubscriber)
            }
        }
    }
    
    public func subscribe<T: Equatable>(atom: Atom<T>, action: @escaping () -> ()) -> Disposable {
        let subscriber = ClosureSubscriber(closure: action)
        return subscribe(atom: atom, subscriber: subscriber)
    }
    
    func getRaw<T: Equatable>(key: Int, defaultValue: T) -> T {
        let internals: AtomInternals
        if let _internals = stateMap[key] {
            internals = _internals
        } else {
            internals = .init(value: defaultValue)
            stateMap[key] = internals
        }
        
        // Track the dependencies of this leaf atom.
        for dependent in readScope {
            guard dependent.key != key else {
                // Don't self-track.
                continue
            }
            
            internals.dependents.insert(dependent)
        }
        
        if let value = internals.value {
            return value as! T
        }
        internals.value = defaultValue
        return defaultValue
    }
    
    private func triggerUpdate(for key: Int, newValue: Any) {
        guard let internals = stateMap[key] else {
            return
        }
        
        if let memorizedValue = internals.memorizedValue {
            if internals.comparator(newValue, memorizedValue) {
                // Value is not changed.
                return
            }
        }
        internals.memorizedValue = newValue
        
        for subscriber in internals.subscribers {
            subscriber.receiveUpdate()
        }
        
        // Emit updates for dependents.
        for dependent in internals.dependents {
            let newDependentValue = dependent._get(store: self)
            triggerUpdate(for: dependent.key, newValue: newDependentValue)
        }
    }
}
