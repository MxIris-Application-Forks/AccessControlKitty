import SwiftSyntax
import SwiftParser

public struct Core {
    private var lines: [String]

    public init(lines: [String]) {
        self.lines = lines
    }

    public func newLines(at lineNumbersToAlter: [Int], accessChange: AccessChange) -> [Int: String] {
        var newLines: [Int: String] = [:]

        let sourceFile = Parser.parse(source: lineNumbersToAlter.map { lines[$0] }.joined())

        let rewriter = AccessControlRewriter(accessChange: accessChange)

        let modifiedSyntax = rewriter.rewrite(sourceFile)

        let newContents = modifiedSyntax.description
        
        let splitContents = newContents.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        
        for (lineNumber, content) in zip(lineNumbersToAlter, splitContents) {
            newLines[lineNumber] = content
        }

        return newLines
    }
}
