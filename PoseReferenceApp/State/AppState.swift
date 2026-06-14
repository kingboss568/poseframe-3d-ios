import StoreKit
import SwiftUI

final class AppState: ObservableObject {
    @Published var activeEditor: PoseEditorState?
    @Published var showPaywall = false
    @Published var selectedPremiumFeature: PremiumFeature = .studioPack
    @Published var favoriteCharacterIDs: Set<String> = ["female-anime-a"]
    @Published var favoritePoseIDs: Set<String> = ["run", "reach"]
    @Published var recentProjects: [RecentProject] = [
        RecentProject(title: "奔跑參考 A", mode: .solo, poseTitle: "奔跑", characterNames: "Akio 少年"),
        RecentProject(title: "雙人牽手草圖", mode: .duo, poseTitle: "牽手", characterNames: "Akio 少年 + Mika 少女"),
        RecentProject(title: "回頭視角", mode: .solo, poseTitle: "回頭", characterNames: "Aya 寫實女")
    ]

    func startProject(
        mode: ProjectMode,
        character: CharacterProfile? = nil,
        pose: PoseTemplate? = nil
    ) {
        let firstCharacter = character ?? AppData.defaultCharacterA
        let template = pose ?? AppData.defaultPose
        activeEditor = PoseEditorState(
            mode: mode,
            characterA: firstCharacter,
            characterB: mode == .duo ? AppData.defaultCharacterB : nil,
            pose: template
        )
    }

    func startFromRecent(_ project: RecentProject) {
        let pose = AppData.poses.first { $0.title == project.poseTitle } ?? AppData.defaultPose
        activeEditor = PoseEditorState(mode: project.mode, pose: pose)
    }

    func finishEditor(_ editor: PoseEditorState) {
        let names: String
        if let characterB = editor.characterB {
            names = "\(editor.characterA.name) + \(characterB.name)"
        } else {
            names = editor.characterA.name
        }

        let recent = RecentProject(
            title: editor.exportName.isEmpty ? editor.selectedPose.title : editor.exportName,
            mode: editor.mode,
            poseTitle: editor.selectedPose.title,
            characterNames: names
        )

        recentProjects.removeAll { $0.title == recent.title }
        recentProjects.insert(recent, at: 0)
        recentProjects = Array(recentProjects.prefix(5))
        activeEditor = nil
    }

    func toggleFavorite(character: CharacterProfile) {
        if favoriteCharacterIDs.contains(character.id) {
            favoriteCharacterIDs.remove(character.id)
        } else {
            favoriteCharacterIDs.insert(character.id)
        }
    }

    func toggleFavorite(pose: PoseTemplate) {
        if favoritePoseIDs.contains(pose.id) {
            favoritePoseIDs.remove(pose.id)
        } else {
            favoritePoseIDs.insert(pose.id)
        }
    }

    func requestPremiumUnlock(_ feature: PremiumFeature = .studioPack) {
        selectedPremiumFeature = feature
        showPaywall = true
    }
}

@MainActor
final class PremiumStore: ObservableObject {
    static let proProductID = "com.yushang.poseframe3d.pro"
    private static let unlockCacheKey = "poseframe.pro.unlocked"

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var storeMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        // 離線或冷啟動時先用本機快取，讓已購買的使用者立刻看到解鎖狀態，
        // 之後再由 StoreKit currentEntitlements 校正。
        if UserDefaults.standard.bool(forKey: Self.unlockCacheKey) {
            purchasedProductIDs = [Self.proProductID]
        }
    }

    var proProduct: Product? {
        products.first { $0.id == Self.proProductID }
    }

    var isProUnlocked: Bool {
        purchasedProductIDs.contains(Self.proProductID)
    }

    var displayPrice: String {
        proProduct?.displayPrice ?? "一次解鎖"
    }

    func configure() async {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { continue }
                await self.handle(transactionResult: result)
            }
        }
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: [Self.proProductID])
            if products.isEmpty {
                storeMessage = "目前無法取得 Pro 解鎖商品，請確認網路後點「重新載入價格」。"
            } else {
                storeMessage = nil
            }
        } catch {
            storeMessage = "無法連線 App Store，請確認網路後點「重新載入價格」再試一次。"
        }
    }

    func purchasePro() async {
        if proProduct == nil {
            await loadProducts()
        }

        guard let product = proProduct else {
            storeMessage = "目前無法取得購買項目，請確認網路後再試一次。"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(transactionResult: verification)
                storeMessage = isProUnlocked ? "Pro 功能已解鎖。" : "交易完成後尚未取得解鎖狀態，請使用恢復購買。"
            case .pending:
                storeMessage = "購買待確認，完成付款或家人核准後會自動解鎖。"
            case .userCancelled:
                storeMessage = "已取消購買。"
            @unknown default:
                storeMessage = "購買流程未完成，請稍後再試。"
            }
        } catch {
            storeMessage = "購買失敗，請稍後再試或確認 App Store 帳號狀態。"
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements(authoritative: true)
            storeMessage = isProUnlocked ? "已恢復 Pro 解鎖。" : "目前 Apple ID 沒有可恢復的 Pro 購買。"
        } catch {
            storeMessage = "恢復購買失敗，請稍後再試。"
        }
    }

    func refreshEntitlements(authoritative: Bool = false) async {
        var unlockedIDs = Set<String>()
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            unlockedIDs.insert(transaction.productID)
        }

        // 一般刷新時若 StoreKit 暫時回傳空集合（離線等），不要降級已快取的解鎖狀態；
        // 只有「恢復購買」這類權威查詢才會以結果為準。
        if unlockedIDs.isEmpty, !authoritative, UserDefaults.standard.bool(forKey: Self.unlockCacheKey) {
            return
        }

        purchasedProductIDs = unlockedIDs
        cacheUnlockState()
    }

    private func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = transactionResult else {
            storeMessage = "交易驗證失敗，未解鎖 Pro 功能。"
            return
        }

        if transaction.productID == Self.proProductID {
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
            cacheUnlockState()
        }

        await transaction.finish()
    }

    private func cacheUnlockState() {
        UserDefaults.standard.set(isProUnlocked, forKey: Self.unlockCacheKey)
    }

    deinit {
        updatesTask?.cancel()
    }
}
