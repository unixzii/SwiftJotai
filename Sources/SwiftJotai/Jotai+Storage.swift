//
//  Jotai+Storage.swift
//  SwiftJotai
//
//  Created by Cyandev on 2023/7/17.
//

import Foundation

public protocol UserDefaultsCompatible {
    static func read(from userDefaults: UserDefaults, key: String) throws -> Self?
    
    func write(to userDefaults: UserDefaults, key: String) throws
}

struct CodableUserDefaults<T: Codable>: UserDefaultsCompatible {
    var value: T
    
    static func read(from userDefaults: UserDefaults, key: String) throws -> CodableUserDefaults<T>? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        let value = try PropertyListDecoder().decode(T.self, from: data)
        return .init(value: value)
    }
    
    func write(to userDefaults: UserDefaults, key: String) throws {
        let data = try PropertyListEncoder().encode(value)
        userDefaults.set(data, forKey: key)
    }
}

extension Int: UserDefaultsCompatible {
    public static func read(from userDefaults: UserDefaults, key: String) throws -> Int? {
        return userDefaults.object(forKey: key) as? Int
    }
    
    public func write(to userDefaults: UserDefaults, key: String) throws {
        userDefaults.set(self, forKey: key)
    }
}

extension Float: UserDefaultsCompatible {
    public static func read(from userDefaults: UserDefaults, key: String) throws -> Float? {
        return userDefaults.object(forKey: key) as? Float
    }
    
    public func write(to userDefaults: UserDefaults, key: String) throws {
        userDefaults.set(self, forKey: key)
    }
}

extension Double: UserDefaultsCompatible {
    public static func read(from userDefaults: UserDefaults, key: String) throws -> Double? {
        return userDefaults.object(forKey: key) as? Double
    }
    
    public func write(to userDefaults: UserDefaults, key: String) throws {
        userDefaults.set(self, forKey: key)
    }
}

extension Bool: UserDefaultsCompatible {
    public static func read(from userDefaults: UserDefaults, key: String) throws -> Bool? {
        return userDefaults.object(forKey: key) as? Bool
    }
    
    public func write(to userDefaults: UserDefaults, key: String) throws {
        userDefaults.set(self, forKey: key)
    }
}

extension String: UserDefaultsCompatible {
    public static func read(from userDefaults: UserDefaults, key: String) throws -> String? {
        return userDefaults.object(forKey: key) as? String
    }
    
    public func write(to userDefaults: UserDefaults, key: String) throws {
        userDefaults.set(self, forKey: key)
    }
}

extension URL: UserDefaultsCompatible {
    public static func read(from userDefaults: UserDefaults, key: String) throws -> URL? {
        return userDefaults.object(forKey: key) as? URL
    }
    
    public func write(to userDefaults: UserDefaults, key: String) throws {
        userDefaults.set(self, forKey: key)
    }
}

public extension Atom where T: UserDefaultsCompatible {
    convenience init(userDefaultsKey key: String, defaultValue: T) {
        let userDefaults = UserDefaults.standard
        
        self.init {
            let value = try? T.read(from: userDefaults, key: key)
            return value ?? defaultValue
        } onUpdate: { value in
            // TODO: error handling
            try? value.write(to: userDefaults, key: key)
        }
    }
}
