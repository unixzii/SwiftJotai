import XCTest
@testable import SwiftJotai

@MainActor
final class SwiftJotaiTests: XCTestCase {
    func testGeneralUsage() throws {
        let countAtom = Atom(0)
        let countIsLargeAtom = Atom { store in
            return store.get(countAtom) > 10
        }
        
        let store = Store.shared
        
        XCTAssertEqual(store.get(countIsLargeAtom), false)
        store.set(countAtom, value: 233)
        XCTAssertEqual(store.get(countIsLargeAtom), true)
    }
    
    func testPubSub() throws {
        let countAtom = Atom(0)
        let countIsLargeAtom = Atom { store in
            return store.get(countAtom) > 10
        }
        
        let store = Store.shared
        
        class _Box<T> {
            var value: T? = nil
        }
        let box = _Box<Bool>()
        
        let disposer = store.subscribe(atom: countIsLargeAtom) {
            box.value = store.get(countIsLargeAtom)
        }
        
        // Initial value should be published.
        store.set(countAtom, value: 6)
        XCTAssertFalse(try XCTUnwrap(box.value))
        box.value = nil
        
        // Subscribers should not be notified when the derived
        // value is not changed.
        store.set(countAtom, value: 7)
        XCTAssertNil(box.value)
        
        // Derived value is changed.
        store.set(countAtom, value: 42)
        XCTAssertTrue(try XCTUnwrap(box.value))
        box.value = nil
        
        // Cancellations should work.
        disposer.dispose()
        store.set(countAtom, value: 1)
        XCTAssertNil(box.value)
    }
}
