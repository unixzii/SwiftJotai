//
//  ContentView.swift
//  SwiftJotai
//
//  Created by Cyandev on 2023/7/16.
//

import SwiftJotai
import SwiftUI

@MainActor
fileprivate enum Atoms {
    static let countAtom = Atom(0)
    static let largeThresholdAtom = Atom(userDefaultsKey: "LargeThreshold", defaultValue: 10)
    static let countIsLargeAtom = Atom { store in
        store.get(countAtom) > store.get(largeThresholdAtom)
    }
}

extension View {
    /// Prints a log when this method is called
    func debugPrint(_ message: String? = nil) -> Self {
        print(message ?? "\(self)")
        return self
    }
}

struct ContentView: View {
    @StateObject var countIsLarge = AtomValue(Atoms.countIsLargeAtom)

    var body: some View {
        VStack {
            CounterView()
                .scaleEffect(countIsLarge.value ? .init(1.5) : .init(1))
                .animation(.spring(), value: countIsLarge.value)

            HStack {
                Button("-") {
                    let currentValue = Store.shared.get(Atoms.countAtom)
                    Store.shared.set(Atoms.countAtom, value: currentValue - 1)
                }
                Button("+") {
                    let currentValue = Store.shared.get(Atoms.countAtom)
                    Store.shared.set(Atoms.countAtom, value: currentValue + 1)
                }
            }
            .padding(.bottom, 32)
            
            InputView(title: "Count", atom: Atoms.countAtom)
            InputView(title: "Large Threshold", atom: Atoms.largeThresholdAtom)
        }
        .padding()
        .debugPrint("(A) ContentView is updated")
    }
}

struct CounterView: View {
    @StateObject var count = AtomValue(Atoms.countAtom)

    var body: some View {
        Text("\(count.value)")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .contentTransition(.numericText())
            .animation(.spring(), value: count.value)
            .debugPrint("(B) CounterView is updated")
    }
}

struct InputView: View {
    let title: String
    let atom: Atom<Int>
    
    @StateObject var count: AtomValue<Int>
    
    init(title: String, atom: Atom<Int>) {
        self.title = title
        self.atom = atom
        _count = .init(wrappedValue: .init(atom))
    }
    
    var body: some View {
        HStack {
            Text(title)
                .frame(width: 100, alignment: .trailing)
            TextField(title, value: count.binding, formatter: NumberFormatter())
                .frame(maxWidth: 120)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
