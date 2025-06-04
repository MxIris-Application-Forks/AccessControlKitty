//
//  Access.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 6/2/19.
//  Copyright © 2018-9 Zoë Smith. Distributed under the MIT License.
//

import Foundation

public enum AccessChange {
    case singleLevel(Access)
    case increaseAccess
    case decreaseAccess
    case makeAPI
    case removeAPI
}

public enum Access: String {
    case `public` = "public"
    case `private` = "private"
    case `internal` = "internal"
    case `fileprivate` = "fileprivate"
    case remove = ""
    case `open` = "open"
    case package = "package"
}

extension Access: Comparable {
    
    public static func <(_ lhs: Access, _ rhs: Access) -> Bool {
        return lhs.order < rhs.order
    }
    
    var order: Int {
        switch self {
        case .private: return -2
        case .fileprivate: return -1
        case .internal: return 0
        case .remove: return 0
        case .public: return 1
        case .open: return 2
        case .package: return 3
        }
    }
}

extension Access {
    init?(_ keyword: Keyword?) {
        guard let keyword = keyword else {
            return nil
        }
        
        if let a = Access.init(rawValue: keyword.rawValue) {
            self = a
        } else if keyword ==  .privateset { self = .private }
        else if keyword == .fileprivateset { self = .fileprivate }
        else if keyword == .internalset { self = .internal }
        else { return nil }
    }
}

extension Access {
    var setterString: String? {
        switch self {
        case .private:
            return Keyword.privateset.rawValue
        case .internal:
            return Keyword.internalset.rawValue
        case .fileprivate:
            return Keyword.fileprivateset.rawValue
        default: return nil
        }
    }
}
