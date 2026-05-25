import SwiftUI
import UIKit

final class PoseEditorState: ObservableObject, Identifiable {
    let id = UUID()
    let mode: ProjectMode

    @Published var characterA: CharacterProfile
    @Published var characterB: CharacterProfile?
    @Published var selectedPose: PoseTemplate
    @Published var activePanel: EditorPanel = .pose

    @Published var cameraYaw: Float = -18
    @Published var cameraPitch: Float = -4
    @Published var cameraDistance: Float = 4.1
    @Published var focalLength: Double = 55
    @Published var perspective: Double = 0.6
    @Published var canvasRatio: CanvasRatio = .portrait

    @Published var keyLightIntensity: Double = 820
    @Published var fillLightIntensity: Double = 260
    @Published var backLightIntensity: Double = 360
    @Published var backgroundBrightness: Double = 0.92
    @Published var showShadows = true
    @Published var showGrid = true
    @Published var compositionGuide: CompositionGuide = .thirds
    @Published var renderMood: RenderMood = .studio
    @Published var silhouetteAssist = false
    @Published var transparentBackground = false

    @Published var selectedPropIDs: Set<String> = ["box"]
    @Published var mirrored = false
    @Published var lastSnapshot: UIImage?
    @Published var showExportSheet = false
    @Published var exportFormat: ExportFormat = .png
    @Published var exportName = "pose-reference"

    var snapshotProvider: (() -> UIImage?)?

    init(
        mode: ProjectMode,
        characterA: CharacterProfile = AppData.defaultCharacterA,
        characterB: CharacterProfile? = nil,
        pose: PoseTemplate = AppData.defaultPose
    ) {
        self.mode = mode
        self.characterA = characterA
        self.characterB = mode == .duo ? (characterB ?? AppData.defaultCharacterB) : nil
        self.selectedPose = pose
        self.exportName = "\(pose.title)-\(characterA.name)"
    }

    func applyPose(_ pose: PoseTemplate) {
        selectedPose = pose
        if pose.isPair, mode == .solo {
            characterB = AppData.defaultCharacterB
        }
        exportName = "\(pose.title)-\(characterA.name)"
    }

    func setCameraPreset(_ preset: CameraPreset) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            cameraYaw = preset.yaw
            cameraPitch = preset.pitch
        }
    }

    func restoreCamera(yaw: Float, pitch: Float) {
        cameraYaw = yaw
        cameraPitch = pitch
    }

    func toggleProp(_ prop: PropItem) {
        if selectedPropIDs.contains(prop.id) {
            selectedPropIDs.remove(prop.id)
        } else {
            selectedPropIDs.insert(prop.id)
        }
    }

    func resetPose() {
        applyPose(AppData.defaultPose)
        mirrored = false
    }

    @discardableResult
    func capture() -> UIImage? {
        let image = snapshotProvider?()
        lastSnapshot = image
        return image
    }
}
