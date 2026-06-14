import SwiftUI

enum AppStoreLinks {
    static let privacyURL = URL(string: "https://kingboss568.github.io/poseframe-3d-ios/privacy.html")!
    static let supportURL = URL(string: "https://kingboss568.github.io/poseframe-3d-ios/support.html")!
}

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore

    @ViewBuilder
    var body: some View {
        if let scenario = ScreenshotScenario.current {
            ScreenshotRootView(scenario: scenario)
        } else {
            mainTabs
        }
    }

    private var mainTabs: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house")
                }

            CharacterLibraryView()
                .tabItem {
                    Label("角色", systemImage: "person.3")
                }

            PoseTemplateLibraryView()
                .tabItem {
                    Label("姿勢", systemImage: "figure.mixed.cardio")
                }

            TutorialView()
                .tabItem {
                    Label("教學", systemImage: "sparkles.rectangle.stack")
                }

            ProStudioView()
                .tabItem {
                    Label("Pro", systemImage: "crown")
                }
        }
        .tint(AppTheme.teal)
        .fullScreenCover(item: $appState.activeEditor) { editor in
            PoseEditorView(editor: editor)
                .environmentObject(appState)
                .environmentObject(premiumStore)
        }
        // 注意：編輯器是 fullScreenCover，蓋住主畫面時這裡的 sheet 無法呈現，
        // 所以 Paywall 也掛在 PoseEditorView / ExportSheet 內；這裡只負責主畫面情境。
        .sheet(isPresented: rootPaywallBinding) {
            ProUnlockView(feature: appState.selectedPremiumFeature)
                .environmentObject(appState)
                .environmentObject(premiumStore)
                .presentationDetents([.large])
        }
    }

    private var rootPaywallBinding: Binding<Bool> {
        Binding(
            get: { appState.showPaywall && appState.activeEditor == nil },
            set: { appState.showPaywall = $0 }
        )
    }
}

private enum ScreenshotScenario: String {
    case home
    case characters
    case poses
    case editor
    case duo
    case paywall

    static var current: ScreenshotScenario? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "--screenshot-scenario"),
              arguments.indices.contains(index + 1) else {
            return nil
        }
        return ScreenshotScenario(rawValue: arguments[index + 1])
    }
}

private struct ScreenshotRootView: View {
    let scenario: ScreenshotScenario

    var body: some View {
        switch scenario {
        case .home:
            HomeView()
        case .characters:
            CharacterLibraryView()
        case .poses:
            PoseTemplateLibraryView()
        case .editor:
            ScreenshotEditorView(
                mode: .solo,
                characterA: AppData.characters.first { $0.id == "female-real-b" } ?? AppData.defaultCharacterA,
                characterB: nil,
                pose: AppData.poses.first { $0.id == "contrapposto" } ?? AppData.defaultPose
            )
        case .duo:
            ScreenshotEditorView(
                mode: .duo,
                characterA: AppData.characters.first { $0.id == "male-real-b" } ?? AppData.defaultCharacterA,
                characterB: AppData.characters.first { $0.id == "female-real-b" } ?? AppData.defaultCharacterB,
                pose: AppData.poses.first { $0.id == "hold-hands" } ?? AppData.defaultPose
            )
        case .paywall:
            ProUnlockView(feature: .studioPack)
        }
    }
}

private struct ScreenshotEditorView: View {
    @StateObject private var editor: PoseEditorState

    init(mode: ProjectMode, characterA: CharacterProfile, characterB: CharacterProfile?, pose: PoseTemplate) {
        _editor = StateObject(wrappedValue: PoseEditorState(mode: mode, characterA: characterA, characterB: characterB, pose: pose))
    }

    var body: some View {
        PoseEditorView(editor: editor)
            .onAppear {
                editor.activePanel = .lighting
                editor.showGrid = true
                editor.showShadows = true
                editor.cameraDistance = editor.mode == .duo ? 8.0 : 5.55
                editor.cameraPitch = editor.mode == .duo ? -7 : -4
                editor.focalLength = 46
                editor.perspective = 0.42
                editor.keyLightIntensity = 460
                editor.fillLightIntensity = 170
                editor.backLightIntensity = 220
                editor.backgroundBrightness = 0.64
            }
    }
}

struct SupportAndPrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("聯絡與支援") {
                    LabeledContent("Team", value: "Yu Shiung Jiang")
                    LabeledContent("Email", value: "jushiung@gmail.com")
                    LabeledContent("電話", value: "+886952413678")
                }

                Section("文件") {
                    Link(destination: AppStoreLinks.privacyURL) {
                        Label("隱私權政策", systemImage: "hand.raised")
                    }
                    Link(destination: AppStoreLinks.supportURL) {
                        Label("支援頁面", systemImage: "questionmark.circle")
                    }
                }

                Section("資料使用") {
                    Text("PoseFrame Studio 不建立帳號、不追蹤使用者、不使用第三方廣告或分析 SDK。照片權限只在你主動儲存匯出圖時用於新增照片。")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .navigationTitle("支援與隱私")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TutorialView: View {
    private let steps = [
        ("角色", "person.crop.square", "選一個角色或建立雙人構圖，先定比例再定姿態。"),
        ("Pose", "figure.cooldown", "套用站姿、動作、坐姿、雙人與 Pro 商稿模板。"),
        ("相機", "camera.viewfinder", "切換前視、側視、俯視、低角度與焦距。"),
        ("構圖", "rectangle.3.group", "用三分線、頭身比例與分鏡格檢查畫面張力。"),
        ("匯出", "square.and.arrow.up", "輸出 PNG、透明素材或多視角參考包。")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("5 步完成商稿姿勢")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.ink)
                        .padding(.top, 10)

                    ForEach(steps, id: \.0) { step in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: step.1)
                                .font(.title3.weight(.semibold))
                                .frame(width: 38, height: 38)
                                .foregroundStyle(.white)
                                .background(AppTheme.teal, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.0)
                                    .font(.headline)
                                Text(step.2)
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("教學")
        }
    }
}

struct ProStudioView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore

    private let benefits = [
        ("商稿角色", "person.crop.rectangle.stack", "4 組 Pro 人物比例，涵蓋封面、時裝、動作與寫實分鏡。"),
        ("高張力模板", "figure.run", "強透視、雙人對峙、扶抱搬移、封面轉身等高價值姿勢。"),
        ("構圖輔助", "rectangle.3.group", "頭身比例、黃金構圖與分鏡格，直接在編輯器疊圖檢查。"),
        ("專業輸出", "square.and.arrow.up.on.square", "透明 PNG 與多視角輸出，方便帶進繪圖與分鏡流程。")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image("ProValuePreview")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            PremiumBadge()
                                .padding(12)
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PoseFrame Studio Pro")
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.ink)
                        Text(premiumStore.isProUnlocked ? "已解鎖，所有 Pro 角色、姿勢、構圖和輸出工具可直接使用。" : "免費下載即可開始，Pro 一次解鎖真正省時間的商稿工作流。")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 12)], spacing: 12) {
                        ForEach(benefits, id: \.0) { benefit in
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: benefit.1)
                                    .font(.title3.weight(.semibold))
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.white)
                                    .background(AppTheme.blueprint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                Text(benefit.0)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)
                                Text(benefit.2)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }

                    Button {
                        if premiumStore.isProUnlocked {
                            appState.startProject(mode: .duo, pose: AppData.poses.first { $0.id == "pro-sword-clash" })
                        } else {
                            appState.requestPremiumUnlock(.studioPack)
                        }
                    } label: {
                        Label(premiumStore.isProUnlocked ? "開啟 Pro 雙人分鏡" : "查看 Pro 解鎖內容", systemImage: premiumStore.isProUnlocked ? "wand.and.stars" : "crown.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Pro 工作室")
        }
    }
}

struct ProUnlockView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var premiumStore: PremiumStore
    let feature: PremiumFeature

    private let unlockItems = [
        ("Pro 角色", "person.crop.rectangle.stack.fill", "商稿男、商稿女、動作男、動作女，補足封面與分鏡常用比例。"),
        ("Pro 姿勢", "figure.run", "強透視、雙人戰鬥、時裝轉身、扶抱搬移等高價值模板。"),
        ("Pro 構圖", "rectangle.3.group.fill", "頭身比例、黃金構圖、分鏡格輔助線，直接疊在 3D 畫面上。"),
        ("Pro 匯出", "square.and.arrow.up.on.square.fill", "透明 PNG 和多視角輸出，讓參考圖能立刻進入繪圖流程。")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image("ProValuePreview")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 4) {
                                PremiumBadge()
                                Text(feature.title)
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                Text(feature.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.78))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                        }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("為真正會反覆使用的創作者設計")
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.ink)
                        Text("免費版能完成基本姿勢參考；Pro 版把商稿常見的高張力人物、雙人互動、構圖校正和輸出格式一次補齊。")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                    }

                    ForEach(unlockItems, id: \.0) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.1)
                                .font(.headline.weight(.semibold))
                                .frame(width: 38, height: 38)
                                .foregroundStyle(.white)
                                .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.0)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)
                                Text(item.2)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    VStack(spacing: 10) {
                        Button {
                            Task {
                                await premiumStore.purchasePro()
                                if premiumStore.isProUnlocked {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if premiumStore.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                Text(purchaseButtonTitle)
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.gold)
                        .disabled(premiumStore.isLoading || premiumStore.isProUnlocked)

                        if premiumStore.proProduct == nil, !premiumStore.isProUnlocked, !premiumStore.isLoading {
                            Button {
                                Task {
                                    await premiumStore.loadProducts()
                                }
                            } label: {
                                Label("重新載入價格", systemImage: "arrow.clockwise")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        Button {
                            Task {
                                await premiumStore.restorePurchases()
                                if premiumStore.isProUnlocked {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("恢復購買")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(premiumStore.isLoading)
                    }

                    if let message = premiumStore.storeMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        Link("隱私權政策", destination: AppStoreLinks.privacyURL)
                        Text("·")
                            .foregroundStyle(AppTheme.muted)
                        Link("支援", destination: AppStoreLinks.supportURL)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.teal)
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("升級 Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .task {
                if premiumStore.proProduct == nil, !premiumStore.isProUnlocked {
                    await premiumStore.loadProducts()
                }
            }
        }
    }

    private var purchaseButtonTitle: String {
        if premiumStore.isProUnlocked {
            return "已解鎖 Pro"
        }
        if let product = premiumStore.proProduct {
            return "一次買斷解鎖 Pro - \(product.displayPrice)"
        }
        return premiumStore.isLoading ? "正在取得價格…" : "解鎖 Pro"
    }
}
