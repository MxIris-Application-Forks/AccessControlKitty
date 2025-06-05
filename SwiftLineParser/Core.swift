import Foundation
import SwiftSyntax
import SwiftParser

public struct Core {
    private var lines: [String]

    public init(lines: [String]) {
        self.lines = lines
    }

    public func newLines(at lineNumbersToAlter: [Int], accessChange: AccessChange) -> [Int: String] {
        var newLines: [Int: String] = [:]

        let sourceFile = Parser.parse(source: lineNumbersToAlter.map { lines[$0] }.joined(separator: "\n"))

        let rewriter = AccessControlRewriter(accessChange: accessChange)

        let modifiedSyntax = rewriter.rewrite(sourceFile)

        for (lineNumber, content) in zip(lineNumbersToAlter, modifiedSyntax.description.split(separator: "\n").map { String($0) }) {
            newLines[lineNumber] = content
        }

        return newLines
    }
}
