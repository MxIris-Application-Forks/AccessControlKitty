import SwiftSyntax
import SwiftParser

class AccessControlRewriter: SyntaxRewriter {
    let accessChange: AccessChange

    init(accessChange: AccessChange) {
        self.accessChange = accessChange
        super.init(viewMode: .sourceAccurate)
    }

    /// 创建新的访问修饰符节点 (无 Trivia)
    private func createNewAccessModifierSyntax(for keyword: Keyword) -> DeclModifierSyntax {
        return DeclModifierSyntax(name: .keyword(keyword))
    }

    /// 判断一个函数声明是否是嵌套函数 (定义在另一个函数内部)
    private func isNestedFunction(_ node: FunctionDeclSyntax) -> Bool {
        // 一个函数 F_inner 是嵌套的，如果它的父节点链条是：
        // F_inner -> CodeBlockItemSyntax -> CodeBlockItemListSyntax -> CodeBlockSyntax (F_outer的body) -> FunctionDeclSyntax (F_outer)
        return node.parent?.parent?.parent?.parent?.is(FunctionDeclSyntax.self) ?? false
    }

    /// 核心逻辑：更新修饰符并处理 Trivia
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
            modifiersArray.insert(newMod, at: 0) // 总是插入在开头
        }

        var finalKeywordLeadingTrivia = declKeywordOriginalLeadingTrivia
        if modifiersArray.isEmpty {
            finalKeywordLeadingTrivia = effectiveInitialLeadingTrivia
            return (DeclModifierListSyntax([]), finalKeywordLeadingTrivia)
        }

        for i in 0..<modifiersArray.count {
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
    // (只展示 FunctionDeclSyntax 和 ClassDeclSyntax 作为示例，其他类似)

    override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if isNestedFunction(node) {
            return super.visit(node) // 跳过嵌套函数
        }

        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.funcKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.funcKeyword = newNode.funcKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }

        return DeclSyntax(newNode)
    }

    override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        // 如果需要，这里可以添加逻辑来跳过在函数内部定义的类
        // 例如: if isDeclaredInsideFunctionContext(node) { return super.visit(node) }
        // 目前，我们只特殊处理嵌套函数。

        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.classKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.classKeyword = newNode.classKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }

        return DeclSyntax(newNode)
    }

    override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.structKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.structKeyword = newNode.structKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }
        return DeclSyntax(newNode)
    }

    override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.enumKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.enumKeyword = newNode.enumKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }
        return DeclSyntax(newNode)
    }
    
    override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.protocolKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.protocolKeyword = newNode.protocolKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }
        return DeclSyntax(newNode)
    }

    override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        // 注意：VariableDeclSyntax 可能在函数内部（局部变量）或类型/全局作用域。
        // 如果要跳过函数内的变量，需要添加类似 isNestedFunction 的检查，但更通用。
        // 例如，检查其父级链条是否包含 FunctionDeclSyntax 的 body。
        // 暂时不添加此复杂性，除非明确要求。

        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.bindingSpecifier.leadingTrivia, // 'let' or 'var'
                targetAccess: access
            )

            newNode.modifiers = processedModifiers
            newNode.bindingSpecifier = newNode.bindingSpecifier.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }
        return DeclSyntax(newNode)
    }
    
    override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.initKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.initKeyword = newNode.initKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }
        return DeclSyntax(newNode)
    }

    override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.subscriptKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.subscriptKeyword = newNode.subscriptKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }
        return DeclSyntax(newNode)
    }

    override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
        var newNode = node
        if case .singleLevel(let access) = accessChange {
            let (processedModifiers, finalKeywordLeadingTrivia) = processModifiers(
                existingModifiers: node.modifiers,
                declKeywordOriginalLeadingTrivia: node.typealiasKeyword.leadingTrivia,
                targetAccess: access
            )
            newNode.modifiers = processedModifiers
            newNode.typealiasKeyword = newNode.typealiasKeyword.with(\.leadingTrivia, finalKeywordLeadingTrivia)
        }
        return DeclSyntax(newNode)
    }
    // ... 其他 visit 方法，例如 Struct, Enum, Protocol, Variable, Initializer, Subscript, Typealias ...
    // 都遵循类似的模式：检查是否应跳过，然后调用 processModifiers，更新节点，记录修改。
}
