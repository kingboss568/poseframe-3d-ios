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
    @Published var cameraHeight: Float = 1.05
    @Published var focalLength: Double = 55
    @Published var perspective: Double = 0.6
    @Published var canvasRatio: CanvasRatio = .portrait

    @Published var jointOverrides: JointPose?
    @Published var selectedJoint: JointRole?
    @Published var poseInfluence: Double = 0.65

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

    var currentJoints: JointPose {
        jointOverrides ?? selectedPose.joints
    }

    var hasJointEdits: Bool {
        jointOverrides != nil
    }

    func applyPose(_ pose: PoseTemplate) {
        selectedPose = pose
        jointOverrides = nil
        if pose.isPair, mode == .solo {
            characterB = AppData.defaultCharacterB
        }
        exportName = "\(pose.title)-\(characterA.name)"
    }

    func angle(of joint: JointRole, axis: JointAxis) -> Float {
        currentJoints[keyPath: joint.keyPath][axis]
    }

    func setAngle(_ degrees: Float, joint: JointRole, axis: JointAxis) {
        var joints = currentJoints
        joints[keyPath: joint.keyPath][axis] = min(max(degrees, -160), 160)
        jointOverrides = joints
    }

    func rotateSelectedJoint(horizontalDegrees: Float, verticalDegrees: Float) {
        guard let joint = selectedJoint else { return }
        var joints = currentJoints
        var angles = joints[keyPath: joint.keyPath]
        angles.x = min(max(angles.x + verticalDegrees, -160), 160)
        let sideAxis: JointAxis = (joint == .torso || joint == .head) ? .y : .z
        angles[sideAxis] = min(max(angles[sideAxis] + horizontalDegrees, -160), 160)
        joints[keyPath: joint.keyPath] = angles
        jointOverrides = joints
    }

    func resetJoint(_ joint: JointRole) {
        var joints = currentJoints
        joints[keyPath: joint.keyPath] = selectedPose.joints[keyPath: joint.keyPath]
        jointOverrides = joints == selectedPose.joints ? nil : joints
    }

    func resetJointEdits() {
        jointOverrides = nil
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
        selectedJoint = nil
    }

    @discardableResult
    func capture() -> UIImage? {
        let image = snapshotProvider?()
        lastSnapshot = image
        return image
    }
}
