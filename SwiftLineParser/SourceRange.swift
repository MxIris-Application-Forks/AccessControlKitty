public struct SourceRange: Hashable {
    public let start: SourceLocation
    public let end: SourceLocation

    public init(start: SourceLocation, end: SourceLocation) {
        self.start = start
        self.end = end
    }

    public var isEmpty: Bool {
        return start == end
    }

    public var length: Int {
        return end.line - start.line + 1
    }
}

public struct SourceLocation: Hashable {
    public let line: Int
    public let column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
}
