//
//  Jotai+SwiftUI.swift
//  SwiftJotai
//
//  Created by Cyandev on 2023/7/16.
//

import SwiftUI
import Combine

extension ObservableObjectPublisher: SwiftJotai.Subscriber {
    public func receiveUpdate() {
        send()
    }
}

public class AtomValue<T>: ObservableObject where T: Equatable {
    public let objectWillChange = ObservableObjectPublisher()
    
    public let store: Store
    public let atom: Atom<T>
    
    private let disposer: Disposable
    
    public var value: T {
        get {
            return store.get(atom)
        }
        set {
            store.set(atom, value: newValue)
        }
    }
    
    deinit {
        disposer.dispose()
    }
    
    public init(_ atom: Atom<T>) {
        self.store = Store.shared
        self.atom = atom
        
        self.disposer = store.subscribe(atom: atom, subscriber: objectWillChange)
    }
}
