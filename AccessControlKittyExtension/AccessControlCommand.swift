import Foundation
import XcodeKit
import SwiftLineParser

class AccessControlCommand: NSObject, XCSourceEditorCommand {
    func selectedLines(in buffer: XCSourceTextBuffer) -> [Int] {
        guard let selections = buffer.selections as? [XCSourceTextRange] else { return [] }
        let selectedLines = selections.flatMap { lines($0, totalLinesInBuffer: buffer.lines.count) }
        let set = Set(selectedLines)
        return Array(set).sorted()
    }

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void) {
        // Implement your command here, invoking the completion handler when done. Pass it nil on success, and an NSError on failure.
        guard (invocation.buffer.contentUTI == "com.apple.dt.playground") || (invocation.buffer.contentUTI == "public.swift-source") else {
            completionHandler(AccessControlError.unsupportedContentType)
            return
        }

        guard let accessLevel = AccessChange(commandIdentifier: invocation.commandIdentifier) else {
            completionHandler(nil)
            return
        }

        do {
            try changeAccessLevel(accessLevel, invocation.buffer)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }

    func changeAccessLevel(_ access: AccessChange, _ buffer: XCSourceTextBuffer) throws {
        guard let lines = buffer.lines as? [String] else { return }

        let selectedLineNumbers = selectedLines(in: buffer)

        guard !selectedLineNumbers.isEmpty else {
            throw AccessControlError.noSelection
        }

        let core = Core(lines: lines)
        let changedSelections = core.newLines(at: Array(selectedLineNumbers), accessChange: access)
        for lineNumber in selectedLineNumbers {
            if let line = changedSelections[lineNumber] {
                buffer.lines[lineNumber] = line
            }
        }
    }
}

func lines(_ range: XCSourceTextRange, totalLinesInBuffer: Int) -> [Int] {
    // Always include the whole line UNLESS the start and end positions are exactly the same, in which return an empty array
    if range.start.line == range.end.line, range.start.column == range.end.column {
        return []
    } else if totalLinesInBuffer == range.end.line {
        return Array(range.start.line ..< range.end.line)
    } else if range.end.column == 0 {
        return Array(range.start.line ..< range.end.line)
    } else {
        return Array(range.start.line ... range.end.line)
    }
}

extension AccessChange {
    init?(commandIdentifier: String) {
        guard let id = commandIdentifier.split(separator: ".").last,
              case let idString = String(id),
              let accessChange = AccessChange.commandIdentifiers[idString] else {
            return nil
        }
        self = accessChange
    }

    static var commandIdentifiers: [String: AccessChange] {
        return [
            "DecreaseAccess": .decreaseAccess,
            "IncreaseAccess": .increaseAccess,
            "MakeAPI": .makeAPI,
            "RemoveAPI": .removeAPI,
            "MakePublic": .singleLevel(.public),
            "MakeInternal": .singleLevel(.internal),
            "MakePrivate": .singleLevel(.private),
            "MakeFileprivate": .singleLevel(.fileprivate),
            "MakeOpen": .singleLevel(.open),
            "MakePackage": .singleLevel(.package),
            "Remove": .singleLevel(.remove),
        ]
    }
}

let identifierPrefix: String = Bundle.main.bundleIdentifier ?? ""

protocol SourceEditorCommand: NSObject {
    var commandClassName: String { get }
    var identifier: String { get }
    var name: String { get }
}

extension SourceEditorCommand {
    var commandClassName: String { Self.className() }
    var identifier: String { commandClassName }

    func makeCommandDefinition() -> [XCSourceEditorCommandDefinitionKey: Any] {
        [.classNameKey: commandClassName,
         .identifierKey: identifierPrefix + identifier,
         .nameKey: name]
    }
}

func makeCommandDefinition(_ command: SourceEditorCommand)
    -> [XCSourceEditorCommandDefinitionKey: Any] {
    command.makeCommandDefinition()
}
