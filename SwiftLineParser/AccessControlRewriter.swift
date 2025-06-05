import SwiftSyntax
import SwiftParser

final class AccessControlRewriter: SyntaxRewriter {
    let accessChange: AccessChange

    init(accessChange: AccessChange) {
        self.accessChange = accessChange
        super.init(viewMode: .sourceAccurate)
    }

    private func createNewAccessModifierSyntax(for keyword: Keyword) -> DeclModifierSyntax {
        return DeclModifierSyntax(name: .keyword(keyword))
    }

    private func isNestedFunction(_ node: FunctionDeclSyntax) -> Bool {
        // 一个函数 F_inner 是嵌套的，如果它的父节点链条是：
        // F_inner -> CodeBlockItemSyntax -> CodeBlockItemListSyntax -> CodeBlockSyntax (F_outer的body) -> FunctionDeclSyntax (F_outer)
        return node.parent?.parent?.parent?.parent?.is(FunctionDeclSyntax.self) ?? false
    }

    private func processModifiers(
        existingModifiers: DeclModifierListSyntax?,
        declKeywordOriginalLeadingTrivia: Trivia,
        targetAccess: Access
    ) -> (finalModifiers: DeclModifierListSyntax, finalDeclKeywordLeadingTrivia: Trivia) {
        var modifiersArray: [DeclModifierSyntax] = existingModifiers?.children(viewMode: .sourceAccurate).compactMap { $0.as(DeclModifierSyntax.self) } ?? []

        var effectiveInitialLeadingTrivia: Trivia
        if let firstOriginalModifier = modifiersArray.first {
            effectiveInitialLeadingTrivia = firstOriginalModifier.leadingTrivia
        } else {
            effectiveInitialLeadingTrivia = declKeywordOriginalLeadingTrivia
        }

        var removedAccessModifierOriginalLeadingTrivia: Trivia? = nil
        let modifiersArrayCopy = modifiersArray
        modifiersArray.removeAll { modifier in
            let nameToken = modifier.name
            if case .keyword(let kw) = nameToken.tokenKind,
               Access.allKeywords.contains(kw) {
                if removedAccessModifierOriginalLeadingTrivia == nil && modifier == modifiersArrayCopy.first {
                    removedAccessModifierOriginalLeadingTrivia = modifier.leadingTrivia
                }
                return true
            }
            return false
        }
        if let removedTrivia = removedAccessModifierOriginalLeadingTrivia {
            effectiveInitialLeadingTrivia = removedTrivia
        }

        var newAccessModSyntax: DeclModifierSyntax? = nil
        if let targetKeyword = targetAccess.keyword {
            newAccessModSyntax = createNewAccessModifierSyntax(for: targetKeyword)
        }

        if let newMod = newAccessModSyntax {
            modifiersArray.insert(newMod, at: 0)
        }

        var finalKeywordLeadingTrivia = declKeywordOriginalLeadingTrivia
        if modifiersArray.isEmpty {
            finalKeywordLeadingTrivia = effectiveInitialLeadingTrivia
            return (DeclModifierListSyntax([]), finalKeywordLeadingTrivia)
        }

        for i in 0 ..< modifiersArray.count {
            var currentModifier = modifiersArray[i]
            if i == 0 {
                currentModifier = currentModifier.with(\.leadingTrivia, effectiveInitialLeadingTrivia)
                finalKeywordLeadingTrivia = .init()
            } else {
                if currentModifier.leadingTrivia.allSatisfy({ $0.isSpaceOrTab }) {
                    currentModifier = currentModifier.with(\.leadingTrivia, .init())
                }
            }
            currentModifier = currentModifier.with(\.trailingTrivia, .spaces(1))
            modifiersArray[i] = currentModifier
        }

        return (DeclModifierListSyntax(modifiersArray), finalKeywordLeadingTrivia)
    }

    // MARK: - Visit Methods

    private func _visit<TargetDeclSyntax: AccessControlDeclSyntax>(_ node: TargetDeclSyntax) -> DeclSyntax {
        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.keyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.keyword = newNode.keyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }

        return DeclSyntax(newNode)
    }

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if isNestedFunction(node) {
            return super.visit(node)
        }

        return _visit(node)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }

    override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        return _visit(node)
    }
}

protocol AccessControlDeclSyntax: DeclSyntaxProtocol {
    var keyword: TokenSyntax { set get }
    var modifiers: DeclModifierListSyntax { set get }
}

extension FunctionDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { funcKeyword = newValue }
        get { funcKeyword }
    }
}

extension ClassDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { classKeyword = newValue }
        get { classKeyword }
    }
}

extension StructDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { structKeyword = newValue }
        get { structKeyword }
    }
}

extension EnumDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { enumKeyword = newValue }
        get { enumKeyword }
    }
}

extension ProtocolDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { protocolKeyword = newValue }
        get { protocolKeyword }
    }
}

extension VariableDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { bindingSpecifier = newValue }
        get { bindingSpecifier }
    }
}

extension InitializerDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { initKeyword = newValue }
        get { initKeyword }
    }
}

extension SubscriptDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { subscriptKeyword = newValue }
        get { subscriptKeyword }
    }
}

extension TypeAliasDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { typealiasKeyword = newValue }
        get { typealiasKeyword }
    }
}

extension ImportDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { importKeyword = newValue }
        get { importKeyword }
    }
}

extension ExtensionDeclSyntax: AccessControlDeclSyntax {
    var keyword: TokenSyntax {
        set { extensionKeyword = newValue }
        get { extensionKeyword }
    }
}
