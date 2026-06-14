import SwiftUI
import UIKit

struct ExportSheet: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore
    @ObservedObject var editor: PoseEditorState
    @State private var previewImage: UIImage?
    @State private var shareItems: [UIImage] = []
    @State private var showShareSheet = false
    @State private var saveMessage: String?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    formatOptions
                    preview
                    outputOptions
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("匯出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("更新預覽") {
                        previewImage = editor.capture()
                    }
                }
            }
            .onAppear {
                previewImage = editor.lastSnapshot ?? editor.capture()
                editor.transparentBackground = editor.exportFormat == .transparent
            }
            .onDisappear {
                editor.transparentBackground = false
            }
            .onChange(of: editor.exportFormat) { _, newValue in
                guard newValue.isPremium, !premiumStore.isProUnlocked else {
                    editor.transparentBackground = newValue == .transparent
                    return
                }
                editor.exportFormat = .png
                editor.transparentBackground = false
                appState.requestPremiumUnlock(.proExport)
            }
            .sheet(isPresented: $showShareSheet) {
                if !shareItems.isEmpty {
                    ShareSheet(activityItems: shareItems)
                }
            }
            .sheet(isPresented: exportPaywallBinding) {
                ProUnlockView(feature: appState.selectedPremiumFeature)
                    .environmentObject(appState)
                    .environmentObject(premiumStore)
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// 匯出頁本身是 sheet，主畫面的 Paywall 無法蓋上來，所以在這裡接手呈現。
    private var exportPaywallBinding: Binding<Bool> {
        Binding(
            get: { appState.showPaywall && editor.showExportSheet },
            set: { appState.showPaywall = $0 }
        )
    }

    private var formatOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("格式")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 8) {
                ForEach(ExportFormat.allCases) { format in
                    Button {
                        if format.isPremium, !premiumStore.isProUnlocked {
                            appState.requestPremiumUnlock(.proExport)
                        } else {
                            editor.exportFormat = format
                            editor.transparentBackground = format == .transparent
                            previewImage = editor.capture()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: editor.exportFormat == format ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(format.isPremium ? AppTheme.gold : AppTheme.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(format.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                    if format.isPremium {
                                        PremiumBadge(compact: true)
                                    }
                                }
                                Text(format.summary)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(editor.exportFormat == format ? AppTheme.soft(format.isPremium ? AppTheme.gold : AppTheme.teal) : .white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("檔名", text: $editor.exportName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("預覽")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            Group {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 220)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 220)
            .background(.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var outputOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("顯示格線", isOn: $editor.showGrid)
                .tint(AppTheme.teal)
            Toggle("顯示陰影", isOn: $editor.showShadows)
                .tint(AppTheme.amber)

            Picker("畫布比例", selection: $editor.canvasRatio) {
                ForEach(CanvasRatio.allCases) { ratio in
                    Text(ratio.rawValue).tag(ratio)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Button {
                    Task {
                        await saveImagesToPhotos()
                    }
                } label: {
                    Label(isRendering ? "產生中" : "儲存照片", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.teal)
                .disabled(isRendering)

                Button {
                    Task {
                        await prepareShareItems()
                    }
                } label: {
                    Label(isRendering ? "產生中" : "分享", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isRendering)
            }

            if let saveMessage {
                Text(saveMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @MainActor
    private func prepareShareItems() async {
        isRendering = true
        defer { isRendering = false }
        shareItems = await renderedImages()
        showShareSheet = !shareItems.isEmpty
    }

    @MainActor
    private func saveImagesToPhotos() async {
        isRendering = true
        defer { isRendering = false }
        let images = await renderedImages()
        images.forEach { UIImageWriteToSavedPhotosAlbum($0, nil, nil, nil) }
        saveMessage = images.isEmpty ? "尚未產生可儲存的圖像" : "已送出 \(images.count) 張儲存請求"
    }

    @MainActor
    private func renderedImages() async -> [UIImage] {
        guard editor.exportFormat == .multiAngle else {
            if let image = previewImage ?? editor.capture() {
                previewImage = image
                return [image]
            }
            return []
        }

        let originalYaw = editor.cameraYaw
        let originalPitch = editor.cameraPitch
        let presets: [CameraPreset] = [.front, .threeQuarter, .side, .low]
        var images: [UIImage] = []

        for preset in presets {
            editor.setCameraPreset(preset)
            try? await Task.sleep(nanoseconds: 180_000_000)
            if let image = editor.capture() {
                images.append(image)
            }
        }

        editor.restoreCamera(yaw: originalYaw, pitch: originalPitch)
        try? await Task.sleep(nanoseconds: 120_000_000)
        previewImage = editor.capture() ?? previewImage
        return images
    }
}
