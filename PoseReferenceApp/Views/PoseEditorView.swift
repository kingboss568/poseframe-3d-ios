import SwiftUI

struct PoseEditorView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore
    @ObservedObject var editor: PoseEditorState
    @State private var selectedSlot: CharacterSlot = .a

    var body: some View {
        ZStack(alignment: .bottom) {
            SceneKitPoseView(editor: editor)
                .ignoresSafeArea()

            CompositionGuideOverlay(guide: editor.compositionGuide)
                .opacity(shouldShowCompositionGuide ? 1 : 0)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if let joint = editor.selectedJoint {
                    jointEditingHint(joint)
                }
                Spacer()
                quickActions
                editorPanel
            }
        }
        .statusBarHidden()
        .sheet(isPresented: $editor.showExportSheet) {
            ExportSheet(editor: editor)
                .environmentObject(appState)
                .environmentObject(premiumStore)
        }
        // 編輯器是 fullScreenCover，主畫面的 Paywall sheet 無法呈現，必須掛在這裡。
        .sheet(isPresented: editorPaywallBinding) {
            ProUnlockView(feature: appState.selectedPremiumFeature)
                .environmentObject(appState)
                .environmentObject(premiumStore)
        }
    }

    private var editorPaywallBinding: Binding<Bool> {
        Binding(
            get: { appState.showPaywall && !editor.showExportSheet },
            set: { appState.showPaywall = $0 }
        )
    }

    private func jointEditingHint(_ joint: JointRole) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "rotate.3d")
                .font(.caption.weight(.bold))
            Text("調整中：\(joint.title)・拖曳旋轉・點空白處完成")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(AppTheme.teal.opacity(0.92), in: Capsule())
        .padding(.top, 10)
        .transition(.opacity)
    }

    private var shouldShowCompositionGuide: Bool {
        premiumStore.isProUnlocked || !editor.compositionGuide.isPremium
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                appState.finishEditor(editor)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.36), in: Circle())
            }
            .accessibilityLabel("返回")

            VStack(alignment: .leading, spacing: 2) {
                Text(editor.exportName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(editor.selectedPose.title) · \(editor.mode.title)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }

            Spacer()

            Button {
                editor.capture()
                editor.showExportSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.headline.weight(.semibold))
                    .frame(width: 42, height: 38)
                    .foregroundStyle(.white)
                    .background(AppTheme.teal.opacity(0.92), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .accessibilityLabel("匯出")
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            QuickActionButton(icon: "arrow.counterclockwise", title: "重置") {
                editor.resetPose()
            }

            QuickActionButton(icon: "arrow.left.and.right.righttriangle.left.righttriangle.right", title: "鏡像") {
                editor.mirrored.toggle()
            }

            QuickActionButton(icon: editor.showGrid ? "grid" : "grid.circle", title: "格線") {
                editor.showGrid.toggle()
            }

            QuickActionButton(icon: "camera.viewfinder", title: "預覽") {
                editor.capture()
            }

            QuickActionButton(icon: editor.silhouetteAssist ? "person.fill.checkmark" : "person.crop.circle.badge.exclamationmark", title: "輪廓") {
                if premiumStore.isProUnlocked {
                    editor.silhouetteAssist.toggle()
                } else {
                    appState.requestPremiumUnlock(.compositionGuides)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var editorPanel: some View {
        VStack(spacing: 12) {
            panelTabs
            Divider().overlay(.white.opacity(0.18))
            panelContent
        }
        .padding(.top, 12)
        .padding(.horizontal, 14)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
        .background(AppTheme.panel.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    private var panelTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(EditorPanel.allCases) { panel in
                    Button {
                        editor.activePanel = panel
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: panel.icon)
                                .font(.headline)
                            Text(panel.rawValue)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(width: 62)
                        .padding(.vertical, 8)
                        .foregroundStyle(editor.activePanel == panel ? .white : .white.opacity(0.62))
                        .background(editor.activePanel == panel ? panelTabColor(panel).opacity(0.9) : .white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func panelTabColor(_ panel: EditorPanel) -> Color {
        panel == .pro ? AppTheme.gold : AppTheme.teal
    }

    @ViewBuilder
    private var panelContent: some View {
        switch editor.activePanel {
        case .characters:
            characterPanel
        case .pose:
            posePanel
        case .joints:
            jointsPanel
        case .camera:
            cameraPanel
        case .lighting:
            lightingPanel
        case .props:
            propsPanel
        case .pro:
            proPanel
        }
    }

    private var characterPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if editor.mode == .duo {
                Picker("角色槽", selection: $selectedSlot) {
                    ForEach(CharacterSlot.allCases) { slot in
                        Text(slot.title).tag(slot)
                    }
                }
                .pickerStyle(.segmented)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AppData.characters) { character in
                        let selected = selectedSlot == .a ? editor.characterA.id == character.id : editor.characterB?.id == character.id
                        let locked = character.isPremium && !premiumStore.isProUnlocked

                        Button {
                            if locked {
                                appState.requestPremiumUnlock(.premiumCharacters)
                            } else {
                                if selectedSlot == .a {
                                    editor.characterA = character
                                } else {
                                    editor.characterB = character
                                }
                            }
                        } label: {
                            ZStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: character.symbol)
                                            .font(.title3.weight(.semibold))
                                            .frame(width: 42, height: 42)
                                            .foregroundStyle(.white)
                                            .background(character.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        Spacer()
                                        if character.isPremium {
                                            PremiumBadge(compact: true)
                                        }
                                    }
                                    Text(character.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    Text("\(character.gender.rawValue) · \(character.style.rawValue)")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                                .frame(width: 126, alignment: .leading)
                                .padding(10)
                                .background(selected ? character.accent.opacity(0.62) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                                if locked {
                                    LockedContentOverlay(title: "Pro 角色")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var posePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AppData.poses) { pose in
                        let locked = pose.isPremium && !premiumStore.isProUnlocked

                        Button {
                            if locked {
                                appState.requestPremiumUnlock(.premiumPoses)
                            } else {
                                editor.applyPose(pose)
                                if pose.isPair {
                                    selectedSlot = .b
                                }
                            }
                        } label: {
                            ZStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: pose.isPair ? "person.2.fill" : "figure.cooldown")
                                        Spacer()
                                        if pose.isPremium {
                                            PremiumBadge(compact: true)
                                        } else if editor.selectedPose.id == pose.id {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                    }
                                    .font(.headline)
                                    .foregroundStyle(pose.category.color)

                                    Text(pose.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    Text(pose.category.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                                .frame(width: 128, alignment: .leading)
                                .padding(10)
                                .background(editor.selectedPose.id == pose.id ? pose.category.color.opacity(0.54) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                                if locked {
                                    LockedContentOverlay(title: "Pro 姿勢")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var jointsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("點 3D 模型上的部位、或從下方選取關節，拖曳畫面即可旋轉。")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.64))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(JointRole.allCases) { joint in
                        Button {
                            editor.selectedJoint = editor.selectedJoint == joint ? nil : joint
                        } label: {
                            CapsuleTag(title: joint.title, color: AppTheme.teal, selected: editor.selectedJoint == joint)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let joint = editor.selectedJoint {
                ForEach(JointAxis.allCases) { axis in
                    EditorSlider(
                        title: "\(joint.title)・\(axis.rawValue)",
                        value: jointAngleBinding(joint, axis),
                        range: -160...160,
                        suffix: "°"
                    )
                }

                HStack(spacing: 10) {
                    Button {
                        editor.resetJoint(joint)
                    } label: {
                        Label("重置此關節", systemImage: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)

                    Button {
                        editor.resetJointEdits()
                    } label: {
                        Label("全部還原", systemImage: "arrow.uturn.backward")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.coral)
                    .disabled(!editor.hasJointEdits)
                }
            } else {
                Text("尚未選取關節。試試直接點模型的手臂或腿。")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }

            EditorSlider(title: "姿勢強度（寫實模型）", value: $editor.poseInfluence, range: 0.2...1.0, suffix: "")
        }
    }

    private func jointAngleBinding(_ joint: JointRole, _ axis: JointAxis) -> Binding<Double> {
        Binding(
            get: { Double(editor.angle(of: joint, axis: axis)) },
            set: { editor.setAngle(Float($0), joint: joint, axis: axis) }
        )
    }

    private var cameraPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CameraPreset.allCases) { preset in
                        Button {
                            editor.setCameraPreset(preset)
                        } label: {
                            CapsuleTag(title: preset.rawValue, color: AppTheme.teal, selected: abs(editor.cameraYaw - preset.yaw) < 1 && abs(editor.cameraPitch - preset.pitch) < 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("單指拖曳＝旋轉視角・捏合＝縮放・雙指上下＝視線高度・雙擊＝回正")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.58))

            EditorSlider(title: "焦距", value: $editor.focalLength, range: 28...95, suffix: "mm")
            EditorSlider(title: "距離", value: Binding(
                get: { Double(editor.cameraDistance) },
                set: { editor.cameraDistance = Float($0) }
            ), range: 1.6...9.0, suffix: "m")
            EditorSlider(title: "高度", value: Binding(
                get: { Double(editor.cameraHeight) },
                set: { editor.cameraHeight = Float($0) }
            ), range: 0.4...1.8, suffix: "m")

            Picker("畫布", selection: $editor.canvasRatio) {
                ForEach(CanvasRatio.allCases) { ratio in
                    Text(ratio.rawValue).tag(ratio)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var lightingPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("顯示陰影", isOn: $editor.showShadows)
                .foregroundStyle(.white)
                .tint(AppTheme.amber)

            EditorSlider(title: "主光", value: $editor.keyLightIntensity, range: 120...1400, suffix: "")
            EditorSlider(title: "補光", value: $editor.fillLightIntensity, range: 0...900, suffix: "")
            EditorSlider(title: "背光", value: $editor.backLightIntensity, range: 0...900, suffix: "")
            EditorSlider(title: "背景", value: $editor.backgroundBrightness, range: 0.18...1.0, suffix: "")
        }
    }

    private var propsPanel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AppData.props) { prop in
                    let locked = prop.isPremium && !premiumStore.isProUnlocked

                    Button {
                        if locked {
                            appState.requestPremiumUnlock(.premiumProps)
                        } else {
                            editor.toggleProp(prop)
                        }
                    } label: {
                        ZStack {
                            VStack(spacing: 7) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: prop.icon)
                                        .font(.headline)
                                        .frame(width: 36, height: 36)
                                        .foregroundStyle(.white)
                                        .background(prop.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    if prop.isPremium {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(AppTheme.gold)
                                            .offset(x: 5, y: -5)
                                    }
                                }
                                Text(prop.title)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(width: 80)
                            .padding(.vertical, 8)
                            .background(editor.selectedPropIDs.contains(prop.id) ? prop.color.opacity(0.46) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                            if locked {
                                LockedContentOverlay(title: "Pro 道具")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var proPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if premiumStore.isProUnlocked {
                Toggle("輪廓強化", isOn: $editor.silhouetteAssist)
                    .foregroundStyle(.white)
                    .tint(AppTheme.gold)

                VStack(alignment: .leading, spacing: 6) {
                    Text("構圖輔助")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                    Picker("構圖輔助", selection: $editor.compositionGuide) {
                        ForEach(CompositionGuide.allCases) { guide in
                            Text(guide.rawValue).tag(guide)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("渲染情緒")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                    Picker("渲染情緒", selection: $editor.renderMood) {
                        ForEach(RenderMood.allCases) { mood in
                            Text(mood.rawValue).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Text("Pro 設定會直接影響目前 3D 預覽、匯出畫面和多視角輸出。")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.64))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.headline.weight(.bold))
                            .frame(width: 38, height: 38)
                            .foregroundStyle(.white)
                            .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("解鎖 Pro 編輯器")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("輪廓強化、頭身比例、黃金構圖、分鏡格與商稿渲染。")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.68))
                        }
                    }

                    Button {
                        appState.requestPremiumUnlock(.compositionGuides)
                    } label: {
                        Label("查看 Pro 價值", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.gold)
                }
            }
        }
    }
}

private struct CompositionGuideOverlay: View {
    let guide: CompositionGuide

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let width = proxy.size.width
                let height = proxy.size.height
                switch guide {
                case .thirds:
                    addVerticalLine(&path, x: width / 3, height: height)
                    addVerticalLine(&path, x: width * 2 / 3, height: height)
                    addHorizontalLine(&path, y: height / 3, width: width)
                    addHorizontalLine(&path, y: height * 2 / 3, width: width)
                case .headHeight:
                    let usableHeight = height * 0.68
                    let top = height * 0.12
                    for index in 0...8 {
                        let y = top + usableHeight * CGFloat(index) / 8
                        addHorizontalLine(&path, y: y, width: width)
                    }
                    addVerticalLine(&path, x: width / 2, height: height)
                case .golden:
                    let left = width * 0.382
                    let right = width * 0.618
                    let top = height * 0.382
                    let bottom = height * 0.618
                    addVerticalLine(&path, x: left, height: height)
                    addVerticalLine(&path, x: right, height: height)
                    addHorizontalLine(&path, y: top, width: width)
                    addHorizontalLine(&path, y: bottom, width: width)
                case .storyboard:
                    let inset = min(width, height) * 0.08
                    path.addRoundedRect(in: CGRect(x: inset, y: inset * 1.5, width: width - inset * 2, height: height - inset * 3), cornerSize: CGSize(width: 8, height: 8))
                    addVerticalLine(&path, x: width / 2, height: height)
                    addHorizontalLine(&path, y: height * 0.58, width: width)
                }
            }
            .stroke(.white.opacity(0.36), style: StrokeStyle(lineWidth: 1, dash: [7, 6]))
        }
    }

    private func addVerticalLine(_ path: inout Path, x: CGFloat, height: CGFloat) {
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: height))
    }

    private func addHorizontalLine(_ path: inout Path, y: CGFloat, width: CGFloat) {
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: width, y: y))
    }
}

private enum CharacterSlot: String, CaseIterable, Identifiable {
    case a
    case b

    var id: String { rawValue }
    var title: String { self == .a ? "角色 A" : "角色 B" }
}

private struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.34), in: Circle())
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .lineLimit(1)
            }
        }
        .accessibilityLabel(title)
    }
}

private struct EditorSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String

    private var displayValue: String {
        if range.upperBound - range.lowerBound <= 4 {
            return String(format: "%.1f%@", value, suffix)
        }
        return "\(Int(value))\(suffix)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text(displayValue)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.64))
            }
            Slider(value: $value, in: range)
                .tint(AppTheme.teal)
        }
    }
}
