import SceneKit
import SwiftUI
import UIKit

struct SceneKitPoseView: UIViewRepresentable {
    @ObservedObject var editor: PoseEditorState

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        context.coordinator.configure(view)
        context.coordinator.editor = editor
        editor.snapshotProvider = { [weak view] in
            view?.snapshot()
        }
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.editor = editor
        context.coordinator.update(uiView, editor: editor)
    }

    final class Coordinator: NSObject {
        weak var editor: PoseEditorState?

        private let scene = SCNScene()
        private let cameraRig = SCNNode()
        private let cameraPitchNode = SCNNode()
        private let cameraNode = SCNNode()
        private let keyLight = SCNNode()
        private let fillLight = SCNNode()
        private let backLight = SCNNode()
        private let ambientLight = SCNNode()
        private let floorNode = SCNNode()
        private let gridNode = SCNNode()
        private let jointMarker = SCNNode()
        private let characterA = RealisticCharacterRig()
        private let characterB = RealisticCharacterRig()
        private var propNodes: [String: SCNNode] = [:]
        private var lastPropIDs = Set<String>()

        func configure(_ view: SCNView) {
            view.scene = scene
            view.allowsCameraControl = false
            view.autoenablesDefaultLighting = false
            view.antialiasingMode = .multisampling2X
            view.preferredFramesPerSecond = 60
            view.rendersContinuously = false
            view.isJitteringEnabled = false

            cameraNode.camera = SCNCamera()
            cameraNode.camera?.zNear = 0.01
            cameraNode.camera?.zFar = 100
            cameraNode.camera?.wantsExposureAdaptation = false

            cameraRig.position = SCNVector3(0, 1.05, 0)
            cameraRig.addChildNode(cameraPitchNode)
            cameraPitchNode.addChildNode(cameraNode)
            scene.rootNode.addChildNode(cameraRig)
            scene.rootNode.addChildNode(characterA.root)
            scene.rootNode.addChildNode(characterB.root)

            configureLights()
            configureFloor()
            configureJointMarker()
            attachGestures(to: view)
        }

        func update(_ view: SCNView, editor: PoseEditorState) {
            let brightness = CGFloat(editor.backgroundBrightness)
            if editor.transparentBackground {
                view.isOpaque = false
                view.backgroundColor = .clear
                scene.background.contents = UIColor.clear
            } else {
                view.isOpaque = true
                view.backgroundColor = backgroundColor(for: editor.renderMood, brightness: brightness)
                scene.background.contents = view.backgroundColor
            }

            cameraNode.camera?.focalLength = CGFloat(editor.focalLength)
            cameraRig.position = SCNVector3(0, editor.cameraHeight, 0)
            cameraRig.eulerAngles = SCNVector3(0, editor.cameraYaw.degreesToRadians, 0)
            cameraPitchNode.eulerAngles = SCNVector3(editor.cameraPitch.degreesToRadians, 0, 0)
            cameraNode.position = SCNVector3(0, 0, editor.cameraDistance)

            keyLight.light?.intensity = CGFloat(editor.keyLightIntensity)
            fillLight.light?.intensity = CGFloat(editor.fillLightIntensity)
            backLight.light?.intensity = CGFloat(editor.backLightIntensity)
            keyLight.light?.castsShadow = editor.showShadows && !editor.transparentBackground
            floorNode.isHidden = editor.transparentBackground
            gridNode.isHidden = !editor.showGrid || editor.transparentBackground

            let influence = Float(editor.poseInfluence)
            let pairMode = editor.mode == .duo || editor.selectedPose.isPair || editor.characterB != nil
            characterA.root.position = SCNVector3(pairMode ? -0.42 : 0, 0.02, 0)
            characterA.root.eulerAngles.y = pairMode ? 8.degreesToRadians : 0
            characterA.update(profile: editor.characterA, pose: editor.currentJoints, mirrored: editor.mirrored, silhouette: editor.silhouetteAssist, influence: influence)

            if pairMode {
                let second = editor.characterB ?? AppData.defaultCharacterB
                characterB.root.isHidden = false
                characterB.root.position = SCNVector3(0.42, 0.02, -0.08)
                characterB.root.eulerAngles.y = (-172).degreesToRadians
                characterB.update(profile: second, pose: editor.currentJoints, mirrored: !editor.mirrored, silhouette: editor.silhouetteAssist, influence: influence)
            } else {
                characterB.root.isHidden = true
            }

            updateJointMarker(editor: editor)

            if lastPropIDs != editor.selectedPropIDs {
                rebuildProps(editor.selectedPropIDs)
            }
        }

        // MARK: - Gestures

        private func attachGestures(to view: SCNView) {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.maximumNumberOfTouches = 1
            view.addGestureRecognizer(pan)

            let twoFingerPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan(_:)))
            twoFingerPan.minimumNumberOfTouches = 2
            twoFingerPan.maximumNumberOfTouches = 2
            view.addGestureRecognizer(twoFingerPan)

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            view.addGestureRecognizer(pinch)

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tap.require(toFail: doubleTap)
            view.addGestureRecognizer(tap)
        }

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let editor else { return }
            let translation = gesture.translation(in: gesture.view)
            gesture.setTranslation(.zero, in: gesture.view)

            if editor.selectedJoint != nil {
                editor.rotateSelectedJoint(
                    horizontalDegrees: Float(translation.x) * 0.5,
                    verticalDegrees: Float(translation.y) * 0.5
                )
            } else {
                editor.cameraYaw -= Float(translation.x) * 0.45
                editor.cameraPitch = min(max(editor.cameraPitch + Float(translation.y) * 0.3, -80), 45)
            }
        }

        @objc private func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            guard let editor else { return }
            let translation = gesture.translation(in: gesture.view)
            gesture.setTranslation(.zero, in: gesture.view)
            editor.cameraHeight = min(max(editor.cameraHeight - Float(translation.y) * 0.004, 0.4), 1.8)
        }

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let editor, gesture.scale > 0 else { return }
            editor.cameraDistance = min(max(editor.cameraDistance / Float(gesture.scale), 1.6), 9.0)
            gesture.scale = 1
        }

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let editor, let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)
            let options: [SCNHitTestOption: Any] = [
                .searchMode: SCNHitTestSearchMode.closest.rawValue,
                .ignoreHiddenNodes: true
            ]

            guard let hit = view.hitTest(location, options: options).first,
                  let role = jointRole(for: hit) else {
                if editor.selectedJoint != nil {
                    editor.selectedJoint = nil
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                return
            }

            editor.selectedJoint = role
            if editor.activePanel != .joints {
                editor.activePanel = .joints
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let editor else { return }
            if editor.selectedJoint != nil {
                editor.selectedJoint = nil
            } else {
                editor.setCameraPreset(.threeQuarter)
                editor.cameraDistance = 4.1
                editor.cameraHeight = 1.05
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        private func jointRole(for hit: SCNHitTestResult) -> JointRole? {
            var node: SCNNode? = hit.node
            while let current = node {
                if current === characterA.root {
                    return characterA.nearestJoint(to: hit.worldCoordinates)
                }
                if current === characterB.root {
                    return characterB.nearestJoint(to: hit.worldCoordinates)
                }
                node = current.parent
            }
            return nil
        }

        // MARK: - Joint marker

        private func configureJointMarker() {
            let sphere = SCNSphere(radius: 0.035)
            sphere.segmentCount = 16
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: 0.0, green: 0.78, blue: 0.82, alpha: 1)
            material.emission.contents = UIColor(red: 0.0, green: 0.78, blue: 0.82, alpha: 1)
            material.readsFromDepthBuffer = false
            sphere.firstMaterial = material
            jointMarker.geometry = sphere
            jointMarker.renderingOrder = 200
            jointMarker.opacity = 0.85
            jointMarker.isHidden = true
            scene.rootNode.addChildNode(jointMarker)
        }

        private func updateJointMarker(editor: PoseEditorState) {
            guard let role = editor.selectedJoint, let node = characterA.jointNode(role) else {
                jointMarker.isHidden = true
                return
            }
            jointMarker.isHidden = false
            jointMarker.worldPosition = node.worldPosition
        }

        // MARK: - Environment

        private func backgroundColor(for mood: RenderMood, brightness: CGFloat) -> UIColor {
            switch mood {
            case .studio:
                return UIColor(red: 0.72 + brightness * 0.20, green: 0.74 + brightness * 0.18, blue: 0.73 + brightness * 0.16, alpha: 1)
            case .paper:
                return UIColor(red: 0.92 + brightness * 0.06, green: 0.89 + brightness * 0.06, blue: 0.82 + brightness * 0.08, alpha: 1)
            case .silhouette:
                return UIColor(red: 0.12 + brightness * 0.06, green: 0.13 + brightness * 0.05, blue: 0.15 + brightness * 0.08, alpha: 1)
            case .warmKey:
                return UIColor(red: 0.74 + brightness * 0.16, green: 0.60 + brightness * 0.17, blue: 0.48 + brightness * 0.12, alpha: 1)
            }
        }

        private func configureLights() {
            keyLight.light = SCNLight()
            keyLight.light?.type = .directional
            keyLight.light?.castsShadow = true
            keyLight.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
            keyLight.light?.shadowSampleCount = 8
            keyLight.light?.shadowRadius = 7
            keyLight.light?.shadowColor = UIColor(white: 0, alpha: 0.34)
            keyLight.light?.automaticallyAdjustsShadowProjection = true
            keyLight.eulerAngles = SCNVector3((-44).degreesToRadians, (-32).degreesToRadians, 0)

            fillLight.light = SCNLight()
            fillLight.light?.type = .omni
            fillLight.position = SCNVector3(-2.6, 2.8, 2.8)

            backLight.light = SCNLight()
            backLight.light?.type = .omni
            backLight.position = SCNVector3(2.4, 2.4, -2.3)

            ambientLight.light = SCNLight()
            ambientLight.light?.type = .ambient
            ambientLight.light?.intensity = 145
            ambientLight.light?.color = UIColor(white: 0.78, alpha: 1)

            scene.rootNode.addChildNode(keyLight)
            scene.rootNode.addChildNode(fillLight)
            scene.rootNode.addChildNode(backLight)
            scene.rootNode.addChildNode(ambientLight)
        }

        private func configureFloor() {
            let floor = SCNFloor()
            floor.reflectivity = 0.03
            floor.firstMaterial?.diffuse.contents = UIColor(white: 0.94, alpha: 1)
            floor.firstMaterial?.roughness.contents = 0.85
            floorNode.geometry = floor
            floorNode.position = SCNVector3(0, 0, 0)
            scene.rootNode.addChildNode(floorNode)

            gridNode.addChildNode(makeGridLine(length: 7, horizontal: true))
            gridNode.addChildNode(makeGridLine(length: 7, horizontal: false))
            for index in -6...6 where index != 0 {
                let a = makeGridLine(length: 7, horizontal: true)
                a.position.z = Float(index) * 0.25
                let b = makeGridLine(length: 7, horizontal: false)
                b.position.x = Float(index) * 0.25
                gridNode.addChildNode(a)
                gridNode.addChildNode(b)
            }
            gridNode.position.y = 0.004
            scene.rootNode.addChildNode(gridNode)
        }

        private func makeGridLine(length: CGFloat, horizontal: Bool) -> SCNNode {
            let geometry = SCNBox(
                width: horizontal ? length : 0.006,
                height: 0.002,
                length: horizontal ? 0.006 : length,
                chamferRadius: 0
            )
            geometry.firstMaterial?.diffuse.contents = UIColor(white: 0.34, alpha: 0.28)
            return SCNNode(geometry: geometry)
        }

        private func rebuildProps(_ ids: Set<String>) {
            propNodes.values.forEach { $0.removeFromParentNode() }
            propNodes.removeAll()

            for prop in AppData.props where ids.contains(prop.id) {
                let node = makeProp(prop)
                propNodes[prop.id] = node
                scene.rootNode.addChildNode(node)
            }

            lastPropIDs = ids
        }

        private func makeProp(_ prop: PropItem) -> SCNNode {
            let parent = SCNNode()
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(hex: prop.colorHex)
            material.roughness.contents = 0.7

            switch prop.id {
            case "chair":
                parent.position = SCNVector3(0.92, 0.18, -0.18)
                parent.addChildNode(box(width: 0.48, height: 0.08, length: 0.42, position: SCNVector3(0, 0.36, 0), material: material))
                parent.addChildNode(box(width: 0.48, height: 0.46, length: 0.07, position: SCNVector3(0, 0.62, -0.18), material: material))
                for x in [-0.18, 0.18] {
                    for z in [-0.14, 0.14] {
                        parent.addChildNode(box(width: 0.05, height: 0.36, length: 0.05, position: SCNVector3(Float(x), 0.18, Float(z)), material: material))
                    }
                }
            case "staff":
                let cylinder = SCNCylinder(radius: 0.025, height: 1.55)
                cylinder.firstMaterial = material
                let node = SCNNode(geometry: cylinder)
                node.eulerAngles.z = 18.degreesToRadians
                node.position = SCNVector3(-0.86, 0.78, -0.04)
                parent.addChildNode(node)
            case "sword":
                parent.position = SCNVector3(0.86, 0.62, 0.05)
                parent.addChildNode(box(width: 0.045, height: 1.08, length: 0.018, position: SCNVector3(0, 0.16, 0), material: material))
                let handleMaterial = SCNMaterial()
                handleMaterial.diffuse.contents = UIColor(white: 0.18, alpha: 1)
                parent.addChildNode(box(width: 0.18, height: 0.035, length: 0.05, position: SCNVector3(0, -0.42, 0), material: handleMaterial))
                parent.eulerAngles.z = (-22).degreesToRadians
            case "phone":
                parent.position = SCNVector3(-0.62, 1.0, 0.2)
                parent.addChildNode(box(width: 0.18, height: 0.32, length: 0.025, position: SCNVector3(0, 0, 0), material: material))
                parent.eulerAngles = SCNVector3(14.degreesToRadians, 8.degreesToRadians, (-18).degreesToRadians)
            case "panel":
                parent.position = SCNVector3(-1.05, 0.78, -0.42)
                parent.addChildNode(box(width: 0.54, height: 0.72, length: 0.035, position: SCNVector3(0, 0, 0), material: material))
                parent.eulerAngles.y = 28.degreesToRadians
            case "sphere":
                let sphere = SCNSphere(radius: 0.2)
                sphere.firstMaterial = material
                let node = SCNNode(geometry: sphere)
                node.position = SCNVector3(0.72, 0.2, 0.56)
                parent.addChildNode(node)
            case "bag":
                parent.position = SCNVector3(-0.78, 0.34, 0.34)
                parent.addChildNode(box(width: 0.36, height: 0.34, length: 0.18, position: SCNVector3(0, 0, 0), material: material))
                parent.addChildNode(box(width: 0.24, height: 0.04, length: 0.04, position: SCNVector3(0, 0.2, 0), material: material))
            case "ribbon":
                parent.position = SCNVector3(0, 1.42, -0.18)
                for offset in [-0.24, 0, 0.24] {
                    let ribbon = box(width: 0.44, height: 0.025, length: 0.018, position: SCNVector3(Float(offset), Float(0.08 * offset), 0), material: material)
                    ribbon.eulerAngles.z = Float(offset * 70).degreesToRadians
                    parent.addChildNode(ribbon)
                }
            case "step":
                parent.position = SCNVector3(0, 0.08, -0.84)
                parent.addChildNode(box(width: 1.4, height: 0.16, length: 0.34, position: SCNVector3(0, 0, 0), material: material))
                parent.addChildNode(box(width: 1.4, height: 0.16, length: 0.34, position: SCNVector3(0, 0.16, -0.22), material: material))
            case "speed":
                parent.position = SCNVector3(-0.25, 1.02, -0.55)
                for index in 0..<6 {
                    let streak = box(width: 0.72, height: 0.018, length: 0.018, position: SCNVector3(Float(index) * 0.1, Float(index) * 0.09, 0), material: material)
                    streak.eulerAngles.z = (-16).degreesToRadians
                    parent.addChildNode(streak)
                }
            case "camera-rig":
                parent.position = SCNVector3(1.05, 0.7, 0.38)
                parent.addChildNode(box(width: 0.32, height: 0.22, length: 0.16, position: SCNVector3(0, 0.32, 0), material: material))
                parent.addChildNode(box(width: 0.46, height: 0.035, length: 0.035, position: SCNVector3(0, 0.12, 0), material: material))
                parent.addChildNode(box(width: 0.035, height: 0.58, length: 0.035, position: SCNVector3(0, -0.18, 0), material: material))
            case "drape":
                parent.position = SCNVector3(-0.88, 0.92, -0.24)
                for index in 0..<5 {
                    let cloth = box(width: 0.08, height: 0.78, length: 0.018, position: SCNVector3(Float(index) * 0.08, Float(sin(Double(index)) * 0.04), 0), material: material)
                    cloth.eulerAngles.z = Float(-18 + index * 8).degreesToRadians
                    parent.addChildNode(cloth)
                }
            case "perspective":
                parent.position = SCNVector3(0, 0.78, -0.72)
                parent.addChildNode(box(width: 1.45, height: 0.018, length: 0.018, position: SCNVector3(0, 0.44, 0), material: material))
                parent.addChildNode(box(width: 1.45, height: 0.018, length: 0.018, position: SCNVector3(0, -0.44, 0), material: material))
                parent.addChildNode(box(width: 0.018, height: 0.9, length: 0.018, position: SCNVector3(-0.72, 0, 0), material: material))
                parent.addChildNode(box(width: 0.018, height: 0.9, length: 0.018, position: SCNVector3(0.72, 0, 0), material: material))
            default:
                parent.position = SCNVector3(-0.78, 0.16, -0.34)
                parent.addChildNode(box(width: 0.34, height: 0.32, length: 0.34, position: SCNVector3(0, 0, 0), material: material))
            }

            return parent
        }

        private func box(width: CGFloat, height: CGFloat, length: CGFloat, position: SCNVector3, material: SCNMaterial) -> SCNNode {
            let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0.012)
            geometry.firstMaterial = material
            let node = SCNNode(geometry: geometry)
            node.position = position
            return node
        }
    }
}

private final class RealisticCharacterRig {
    let root = SCNNode()

    private let torsoPivot = SCNNode()
    private let headPivot = SCNNode()
    private let leftUpperArm = SCNNode()
    private let leftForearm = SCNNode()
    private let rightUpperArm = SCNNode()
    private let rightForearm = SCNNode()
    private let leftThigh = SCNNode()
    private let leftShin = SCNNode()
    private let rightThigh = SCNNode()
    private let rightShin = SCNNode()

    private var proceduralPivots: [JointRole: SCNNode] = [:]

    private let bodyMaterial = SCNMaterial()
    private let jointMaterial = SCNMaterial()
    private let accentMaterial = SCNMaterial()
    private let hairMaterial = SCNMaterial()
    private let shirtMaterial = SCNMaterial()
    private let pantsMaterial = SCNMaterial()
    private let shoeMaterial = SCNMaterial()
    private let faceMaterial = SCNMaterial()

    private var rocketboxRoot: SCNNode?
    private var loadedUSDZName: String?
    private var rocketboxBones: [String: SCNNode] = [:]
    private var rocketboxBaseAngles: [String: SCNVector3] = [:]
    private var armDropOffsets: [String: Float] = [:]
    private var originalDiffuse: [ObjectIdentifier: Any] = [:]
    private var originalLightingModels: [ObjectIdentifier: SCNMaterial.LightingModel] = [:]
    private var lastSilhouette: Bool?

    private let boneCandidates: [String: [String]] = [
        "torso": ["Spine1", "Spine_01", "Spine", "Bip01 Spine1", "Bip01_Spine1", "mixamorig:Spine1"],
        "head": ["Head", "Bip01 Head", "Bip01_Head", "mixamorig:Head"],
        "leftUpperArm": ["LeftArm", "L_UpperArm", "Bip01 L UpperArm", "Bip01_L_UpperArm", "mixamorig:LeftArm"],
        "leftForearm": ["LeftForeArm", "L_Forearm", "Bip01 L Forearm", "Bip01_L_Forearm", "mixamorig:LeftForeArm"],
        "rightUpperArm": ["RightArm", "R_UpperArm", "Bip01 R UpperArm", "Bip01_R_UpperArm", "mixamorig:RightArm"],
        "rightForearm": ["RightForeArm", "R_Forearm", "Bip01 R Forearm", "Bip01_R_Forearm", "mixamorig:RightForeArm"],
        "leftThigh": ["LeftUpLeg", "L_Thigh", "Bip01 L Thigh", "Bip01_L_Thigh", "mixamorig:LeftUpLeg"],
        "leftShin": ["LeftLeg", "L_Calf", "Bip01 L Calf", "Bip01_L_Calf", "mixamorig:LeftLeg"],
        "rightThigh": ["RightUpLeg", "R_Thigh", "Bip01 R Thigh", "Bip01_R_Thigh", "mixamorig:RightUpLeg"],
        "rightShin": ["RightLeg", "R_Calf", "Bip01 R Calf", "Bip01_R_Calf", "mixamorig:RightLeg"]
    ]

    init() {
        [bodyMaterial, jointMaterial, accentMaterial, hairMaterial, shirtMaterial, pantsMaterial, shoeMaterial, faceMaterial].forEach {
            $0.lightingModel = .blinn
        }

        bodyMaterial.diffuse.contents = UIColor(red: 0.78, green: 0.61, blue: 0.50, alpha: 1)
        bodyMaterial.specular.contents = UIColor(white: 0.25, alpha: 0.10)
        bodyMaterial.roughness.contents = 0.78
        bodyMaterial.metalness.contents = 0

        jointMaterial.diffuse.contents = UIColor(red: 0.66, green: 0.48, blue: 0.38, alpha: 1)
        jointMaterial.roughness.contents = 0.72
        jointMaterial.transparency = 1

        accentMaterial.roughness.contents = 0.52
        accentMaterial.specular.contents = UIColor(white: 0.65, alpha: 0.18)

        hairMaterial.diffuse.contents = UIColor(red: 0.16, green: 0.12, blue: 0.10, alpha: 1)
        hairMaterial.roughness.contents = 0.82

        shirtMaterial.diffuse.contents = UIColor(red: 0.15, green: 0.55, blue: 0.50, alpha: 1)
        shirtMaterial.roughness.contents = 0.74
        pantsMaterial.diffuse.contents = UIColor(red: 0.20, green: 0.23, blue: 0.26, alpha: 1)
        pantsMaterial.roughness.contents = 0.82
        shoeMaterial.diffuse.contents = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1)
        shoeMaterial.roughness.contents = 0.76
        faceMaterial.diffuse.contents = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1)
        faceMaterial.roughness.contents = 0.62
        build()
    }

    // MARK: - Joint lookup for tap selection

    func jointNode(_ role: JointRole) -> SCNNode? {
        if rocketboxRoot != nil, let bone = rocketboxBones[role.rawValue] {
            return bone
        }
        return proceduralPivots[role]
    }

    func nearestJoint(to worldPosition: SCNVector3) -> JointRole? {
        var best: (role: JointRole, distance: Float)?
        for role in JointRole.allCases {
            guard let node = jointNode(role) else { continue }
            let p = node.worldPosition
            let dx = p.x - worldPosition.x
            let dy = p.y - worldPosition.y
            let dz = p.z - worldPosition.z
            let distance = (dx * dx + dy * dy + dz * dz).squareRoot()
            if best == nil || distance < best!.distance {
                best = (role, distance)
            }
        }
        guard let best, best.distance < 0.55 else { return nil }
        return best.role
    }

    // MARK: - Update

    func update(profile: CharacterProfile, pose: JointPose, mirrored: Bool, silhouette: Bool, influence: Float) {
        if updateRocketboxIfAvailable(profile: profile, pose: pose, mirrored: mirrored, silhouette: silhouette, influence: influence) {
            return
        }

        accentMaterial.diffuse.contents = silhouette ? UIColor(white: 0.04, alpha: 1) : UIColor(hex: profile.accentHex)
        bodyMaterial.diffuse.contents = silhouette ? UIColor(white: 0.055, alpha: 1) : skinColor(for: profile)
        jointMaterial.diffuse.contents = silhouette ? UIColor(white: 0.02, alpha: 1) : anatomicalShade(for: profile)
        hairMaterial.diffuse.contents = silhouette ? UIColor(white: 0.02, alpha: 1) : hairColor(for: profile)
        shirtMaterial.diffuse.contents = silhouette ? UIColor(white: 0.04, alpha: 1) : shirtColor(for: profile)
        pantsMaterial.diffuse.contents = silhouette ? UIColor(white: 0.03, alpha: 1) : pantsColor(for: profile)
        shoeMaterial.diffuse.contents = silhouette ? UIColor(white: 0.02, alpha: 1) : UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1)
        faceMaterial.diffuse.contents = silhouette ? UIColor(white: 0.005, alpha: 1) : UIColor(red: 0.06, green: 0.045, blue: 0.04, alpha: 1)

        let styleScale: Float = profile.style == .anime ? 1.02 : 1.0
        let xScale: Float = mirrored ? -0.94 : 0.94
        let depthScale: Float = profile.style == .realistic ? 0.96 : 0.90
        root.scale = SCNVector3(xScale, Float(profile.proportion) * styleScale, depthScale)

        torsoPivot.eulerAngles = pose.torso.radians
        headPivot.eulerAngles = pose.head.radians
        leftUpperArm.eulerAngles = pose.leftUpperArm.radians
        leftForearm.eulerAngles = pose.leftForearm.radians
        rightUpperArm.eulerAngles = pose.rightUpperArm.radians
        rightForearm.eulerAngles = pose.rightForearm.radians
        leftThigh.eulerAngles = pose.leftThigh.radians
        leftShin.eulerAngles = pose.leftShin.radians
        rightThigh.eulerAngles = pose.rightThigh.radians
        rightShin.eulerAngles = pose.rightShin.radians
    }

    private func updateRocketboxIfAvailable(profile: CharacterProfile, pose: JointPose, mirrored: Bool, silhouette: Bool, influence: Float) -> Bool {
        guard loadRocketboxIfNeeded(profile: profile), let model = rocketboxRoot else {
            root.childNodes.forEach { child in
                if let loadedModel = rocketboxRoot {
                    child.isHidden = child === loadedModel
                } else {
                    child.isHidden = false
                }
            }
            return false
        }

        root.childNodes.forEach { child in
            child.isHidden = child !== model
        }

        let styleScale: Float = profile.style == .anime ? 1.02 : 1.0
        let xScale: Float = mirrored ? -0.94 : 0.94
        let depthScale: Float = profile.style == .realistic ? 0.96 : 0.90
        root.scale = SCNVector3(xScale, Float(profile.proportion) * styleScale, depthScale)

        applyRocketboxPose(pose: pose, mirrored: mirrored, influence: influence)
        applySilhouetteIfNeeded(silhouette, to: model)
        return true
    }

    private func loadRocketboxIfNeeded(profile: CharacterProfile) -> Bool {
        guard let name = profile.usdzName else { return false }
        if loadedUSDZName == name {
            return rocketboxRoot != nil
        }

        rocketboxRoot?.removeFromParentNode()
        rocketboxRoot = nil
        rocketboxBones.removeAll()
        rocketboxBaseAngles.removeAll()
        armDropOffsets.removeAll()
        originalDiffuse.removeAll()
        originalLightingModels.removeAll()
        lastSilhouette = nil

        let subdirectory = profile.isPremium ? "Models/Pro" : "Models/Free"
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "Models") else {
            return false
        }

        guard let scene = try? SCNScene(url: url, options: [.checkConsistency: true]) else {
            return false
        }

        let container = SCNNode()
        container.name = "Rocketbox-\(name)"
        scene.rootNode.childNodes.forEach { container.addChildNode($0) }
        normalizeRocketbox(container)
        root.addChildNode(container)
        rocketboxRoot = container
        loadedUSDZName = name
        bindRocketboxBones(in: container)
        calibrateRestPose()
        return true
    }

    private func normalizeRocketbox(_ node: SCNNode) {
        let bounds = node.boundingBox
        let xExtent = bounds.max.x - bounds.min.x
        let yExtent = bounds.max.y - bounds.min.y
        let zExtent = bounds.max.z - bounds.min.z
        let height = max(yExtent, zExtent)
        guard height > 0 else { return }

        let scale = 1.72 / height
        node.scale = SCNVector3(scale, scale, scale)

        if zExtent > yExtent && zExtent > xExtent {
            let centerX = (bounds.min.x + bounds.max.x) / 2
            let centerY = (bounds.min.y + bounds.max.y) / 2
            node.eulerAngles.x = (-90).degreesToRadians
            node.position = SCNVector3(-centerX * scale, -bounds.min.z * scale, centerY * scale)
        } else {
            let centerX = (bounds.min.x + bounds.max.x) / 2
            let centerZ = (bounds.min.z + bounds.max.z) / 2
            node.position = SCNVector3(-centerX * scale, -bounds.min.y * scale, -centerZ * scale)
        }
    }

    private func bindRocketboxBones(in node: SCNNode) {
        for (role, candidates) in boneCandidates {
            if let bone = candidates.compactMap({ findNode(named: $0, in: node) }).first {
                rocketboxBones[role] = bone
                rocketboxBaseAngles[role] = bone.eulerAngles
            }
        }
    }

    /// Rocketbox / Mixamo 模型常以 T-pose 綁定，直接套姿勢會像稻草人。
    /// 這裡用「試轉再量測前臂高度」的方式自動找出讓手臂自然下垂的旋轉方向，
    /// 不需要事先知道每套骨架的軸向慣例。
    private func calibrateRestPose() {
        let pairs: [(arm: String, forearm: String)] = [
            ("leftUpperArm", "leftForearm"),
            ("rightUpperArm", "rightForearm")
        ]

        for pair in pairs {
            guard let arm = rocketboxBones[pair.arm], let forearm = rocketboxBones[pair.forearm] else { continue }

            let armWorld = arm.worldPosition
            let forearmWorld = forearm.worldPosition
            let dx = forearmWorld.x - armWorld.x
            let dy = forearmWorld.y - armWorld.y
            let dz = forearmWorld.z - armWorld.z
            let boneLength = (dx * dx + dy * dy + dz * dz).squareRoot()
            guard boneLength > 0.02 else { continue }

            // dropRatio ≈ 1 代表手臂已自然下垂，≈ 0 代表 T-pose 水平
            let dropRatio = (armWorld.y - forearmWorld.y) / boneLength
            guard dropRatio < 0.55 else { continue }

            let baseAngles = arm.eulerAngles
            let testAngle: Float = 50.degreesToRadians
            var bestSign: Float = 0
            var lowestY = forearmWorld.y

            for sign: Float in [1, -1] {
                arm.eulerAngles = SCNVector3(baseAngles.x, baseAngles.y, baseAngles.z + sign * testAngle)
                let y = forearm.worldPosition.y
                if y < lowestY {
                    lowestY = y
                    bestSign = sign
                }
            }
            arm.eulerAngles = baseAngles

            if bestSign != 0 {
                armDropOffsets[pair.arm] = bestSign * 58.degreesToRadians
            }
        }
    }

    private func findNode(named targetName: String, in node: SCNNode) -> SCNNode? {
        if node.name == targetName {
            return node
        }

        for child in node.childNodes {
            if let match = findNode(named: targetName, in: child) {
                return match
            }
        }

        return nil
    }

    private func applyRocketboxPose(pose: JointPose, mirrored: Bool, influence: Float) {
        apply(pose.torso, to: "torso", influence: influence)
        apply(pose.head, to: "head", influence: influence)
        apply(mirrored ? pose.rightUpperArm : pose.leftUpperArm, to: "leftUpperArm", influence: influence)
        apply(mirrored ? pose.rightForearm : pose.leftForearm, to: "leftForearm", influence: influence)
        apply(mirrored ? pose.leftUpperArm : pose.rightUpperArm, to: "rightUpperArm", influence: influence)
        apply(mirrored ? pose.leftForearm : pose.rightForearm, to: "rightForearm", influence: influence)
        apply(mirrored ? pose.rightThigh : pose.leftThigh, to: "leftThigh", influence: influence)
        apply(mirrored ? pose.rightShin : pose.leftShin, to: "leftShin", influence: influence)
        apply(mirrored ? pose.leftThigh : pose.rightThigh, to: "rightThigh", influence: influence)
        apply(mirrored ? pose.leftShin : pose.rightShin, to: "rightShin", influence: influence)
    }

    private func apply(_ angles: EulerAngles, to role: String, influence: Float) {
        guard let node = rocketboxBones[role] else { return }
        let base = rocketboxBaseAngles[role] ?? SCNVector3Zero
        let drop = armDropOffsets[role] ?? 0
        node.eulerAngles = SCNVector3(
            base.x + angles.x.degreesToRadians * influence,
            base.y + angles.y.degreesToRadians * influence,
            base.z + drop + angles.z.degreesToRadians * influence
        )
    }

    /// 不再用單色蓋掉 USDZ 原始貼圖：一般模式保留原始材質，
    /// 只有剪影模式才整體塗黑，關閉時恢復原貌。
    private func applySilhouetteIfNeeded(_ enabled: Bool, to node: SCNNode) {
        guard lastSilhouette != enabled else { return }
        lastSilhouette = enabled

        node.enumerateChildNodes { child, _ in
            guard let materials = child.geometry?.materials else { return }
            for material in materials {
                let key = ObjectIdentifier(material)
                if enabled {
                    if originalDiffuse[key] == nil, let contents = material.diffuse.contents {
                        originalDiffuse[key] = contents
                        originalLightingModels[key] = material.lightingModel
                    }
                    material.diffuse.contents = UIColor(white: 0.02, alpha: 1)
                    material.lightingModel = .lambert
                } else {
                    if let original = originalDiffuse[key] {
                        material.diffuse.contents = original
                    }
                    if let model = originalLightingModels[key] {
                        material.lightingModel = model
                    }
                }
            }
        }
    }

    private func build() {
        root.addChildNode(ellipsoid(
            radius: 0.18,
            scale: SCNVector3(1.20, 0.72, 0.66),
            position: SCNVector3(0, 0.76, 0.01),
            material: pantsMaterial
        ))
        root.addChildNode(ellipsoid(
            radius: 0.12,
            scale: SCNVector3(1.42, 0.42, 0.50),
            position: SCNVector3(0, 0.88, 0.02),
            material: shirtMaterial
        ))

        torsoPivot.position = SCNVector3(0, 0.76, 0)
        root.addChildNode(torsoPivot)
        torsoPivot.addChildNode(ellipsoid(
            radius: 0.22,
            scale: SCNVector3(0.70, 1.06, 0.54),
            position: SCNVector3(0, 0.32, 0.01),
            material: shirtMaterial
        ))
        torsoPivot.addChildNode(ellipsoid(
            radius: 0.19,
            scale: SCNVector3(1.02, 0.76, 0.60),
            position: SCNVector3(0, 0.58, 0.03),
            material: shirtMaterial
        ))
        torsoPivot.addChildNode(ellipsoid(
            radius: 0.09,
            scale: SCNVector3(1.05, 0.36, 0.50),
            position: SCNVector3(0, 0.12, 0.02),
            material: shirtMaterial
        ))
        torsoPivot.addChildNode(capsule(radius: 0.044, height: 0.13, position: SCNVector3(0, 0.77, 0), material: bodyMaterial))
        torsoPivot.addChildNode(ellipsoid(radius: 0.070, scale: SCNVector3(1.08, 0.64, 0.64), position: SCNVector3(-0.32, 0.65, 0.02), material: shirtMaterial))
        torsoPivot.addChildNode(ellipsoid(radius: 0.070, scale: SCNVector3(1.08, 0.64, 0.64), position: SCNVector3(0.32, 0.65, 0.02), material: shirtMaterial))

        headPivot.position = SCNVector3(0, 0.86, 0)
        torsoPivot.addChildNode(headPivot)
        headPivot.addChildNode(ellipsoid(
            radius: 0.18,
            scale: SCNVector3(0.82, 1.08, 0.70),
            position: SCNVector3(0, 0.17, 0.02),
            material: bodyMaterial
        ))
        headPivot.addChildNode(ellipsoid(
            radius: 0.18,
            scale: SCNVector3(0.90, 0.42, 0.76),
            position: SCNVector3(0, 0.31, 0.04),
            material: hairMaterial
        ))
        headPivot.addChildNode(ellipsoid(radius: 0.050, scale: SCNVector3(0.70, 1.20, 0.52), position: SCNVector3(-0.12, 0.20, 0.00), material: hairMaterial))
        headPivot.addChildNode(ellipsoid(radius: 0.050, scale: SCNVector3(0.70, 1.20, 0.52), position: SCNVector3(0.12, 0.20, 0.00), material: hairMaterial))
        headPivot.addChildNode(ellipsoid(radius: 0.020, scale: SCNVector3(0.76, 1.10, 0.48), position: SCNVector3(-0.155, 0.15, 0.02), material: bodyMaterial))
        headPivot.addChildNode(ellipsoid(radius: 0.020, scale: SCNVector3(0.76, 1.10, 0.48), position: SCNVector3(0.155, 0.15, 0.02), material: bodyMaterial))
        headPivot.addChildNode(ellipsoid(radius: 0.010, scale: SCNVector3(1.18, 0.74, 0.40), position: SCNVector3(-0.045, 0.195, 0.145), material: faceMaterial))
        headPivot.addChildNode(ellipsoid(radius: 0.010, scale: SCNVector3(1.18, 0.74, 0.40), position: SCNVector3(0.045, 0.195, 0.145), material: faceMaterial))
        headPivot.addChildNode(capsule(radius: 0.008, height: 0.050, position: SCNVector3(0, 0.152, 0.150), material: jointMaterial))
        headPivot.addChildNode(box(width: 0.070, height: 0.010, length: 0.010, position: SCNVector3(0, 0.095, 0.150), material: faceMaterial))

        attachLimb(
            upperPivot: leftUpperArm,
            lowerPivot: leftForearm,
            to: torsoPivot,
            at: SCNVector3(-0.34, 0.68, 0),
            upperLength: 0.48,
            lowerLength: 0.42,
            radius: 0.055,
            terminalRadius: 0.055,
            terminalScale: SCNVector3(0.72, 1.12, 0.40),
            terminalOffset: SCNVector3(0, -0.46, 0.02),
            upperMaterial: shirtMaterial,
            lowerMaterial: shirtMaterial,
            connectorMaterial: shirtMaterial,
            terminalMaterial: bodyMaterial
        )
        attachLimb(
            upperPivot: rightUpperArm,
            lowerPivot: rightForearm,
            to: torsoPivot,
            at: SCNVector3(0.34, 0.68, 0),
            upperLength: 0.48,
            lowerLength: 0.42,
            radius: 0.055,
            terminalRadius: 0.055,
            terminalScale: SCNVector3(0.72, 1.12, 0.40),
            terminalOffset: SCNVector3(0, -0.46, 0.02),
            upperMaterial: shirtMaterial,
            lowerMaterial: shirtMaterial,
            connectorMaterial: shirtMaterial,
            terminalMaterial: bodyMaterial
        )
        attachLimb(
            upperPivot: leftThigh,
            lowerPivot: leftShin,
            to: root,
            at: SCNVector3(-0.15, 0.78, 0),
            upperLength: 0.58,
            lowerLength: 0.54,
            radius: 0.072,
            terminalRadius: 0.070,
            terminalScale: SCNVector3(0.90, 0.44, 1.72),
            terminalOffset: SCNVector3(0, -0.58, 0.08),
            upperMaterial: pantsMaterial,
            lowerMaterial: pantsMaterial,
            connectorMaterial: pantsMaterial,
            terminalMaterial: shoeMaterial
        )
        attachLimb(
            upperPivot: rightThigh,
            lowerPivot: rightShin,
            to: root,
            at: SCNVector3(0.15, 0.78, 0),
            upperLength: 0.58,
            lowerLength: 0.54,
            radius: 0.072,
            terminalRadius: 0.070,
            terminalScale: SCNVector3(0.90, 0.44, 1.72),
            terminalOffset: SCNVector3(0, -0.58, 0.08),
            upperMaterial: pantsMaterial,
            lowerMaterial: pantsMaterial,
            connectorMaterial: pantsMaterial,
            terminalMaterial: shoeMaterial
        )

        proceduralPivots = [
            .torso: torsoPivot,
            .head: headPivot,
            .leftUpperArm: leftUpperArm,
            .leftForearm: leftForearm,
            .rightUpperArm: rightUpperArm,
            .rightForearm: rightForearm,
            .leftThigh: leftThigh,
            .leftShin: leftShin,
            .rightThigh: rightThigh,
            .rightShin: rightShin
        ]
    }

    private func attachLimb(
        upperPivot: SCNNode,
        lowerPivot: SCNNode,
        to parent: SCNNode,
        at position: SCNVector3,
        upperLength: CGFloat,
        lowerLength: CGFloat,
        radius: CGFloat,
        terminalRadius: CGFloat,
        terminalScale: SCNVector3,
        terminalOffset: SCNVector3,
        upperMaterial: SCNMaterial,
        lowerMaterial: SCNMaterial,
        connectorMaterial: SCNMaterial,
        terminalMaterial: SCNMaterial
    ) {
        upperPivot.position = position
        parent.addChildNode(upperPivot)

        upperPivot.addChildNode(capsule(radius: radius, height: upperLength, position: SCNVector3(0, -Float(upperLength / 2), 0), material: upperMaterial))
        upperPivot.addChildNode(ellipsoid(radius: radius * 1.05, scale: SCNVector3(1.10, 0.82, 0.92), position: SCNVector3(0, 0, 0), material: connectorMaterial))

        lowerPivot.position = SCNVector3(0, -Float(upperLength), 0)
        upperPivot.addChildNode(lowerPivot)
        lowerPivot.addChildNode(capsule(radius: radius * 0.9, height: lowerLength, position: SCNVector3(0, -Float(lowerLength / 2), 0), material: lowerMaterial))
        lowerPivot.addChildNode(ellipsoid(radius: radius * 0.88, scale: SCNVector3(0.94, 0.70, 0.82), position: SCNVector3(0, 0, 0), material: connectorMaterial))
        lowerPivot.addChildNode(ellipsoid(radius: terminalRadius, scale: terminalScale, position: terminalOffset, material: terminalMaterial))
    }

    private func sphere(radius: CGFloat, position: SCNVector3, material: SCNMaterial) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.segmentCount = 24
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.position = position
        return node
    }

    private func ellipsoid(radius: CGFloat, scale: SCNVector3, position: SCNVector3, material: SCNMaterial) -> SCNNode {
        let node = sphere(radius: radius, position: position, material: material)
        node.scale = scale
        return node
    }

    private func capsule(radius: CGFloat, height: CGFloat, position: SCNVector3, material: SCNMaterial) -> SCNNode {
        let geometry = SCNCapsule(capRadius: radius, height: height)
        geometry.radialSegmentCount = 18
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.position = position
        return node
    }

    private func box(width: CGFloat, height: CGFloat, length: CGFloat, position: SCNVector3, material: SCNMaterial) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0.006)
        geometry.firstMaterial = material
        let node = SCNNode(geometry: geometry)
        node.position = position
        return node
    }

    private func skinColor(for profile: CharacterProfile) -> UIColor {
        if profile.id.contains("female-real") {
            return UIColor(red: 0.76, green: 0.58, blue: 0.47, alpha: 1)
        }
        if profile.id.contains("male-real") || profile.id.contains("action") {
            return UIColor(red: 0.70, green: 0.52, blue: 0.41, alpha: 1)
        }
        if profile.id.contains("editorial") {
            return UIColor(red: 0.82, green: 0.64, blue: 0.52, alpha: 1)
        }
        return UIColor(red: 0.84, green: 0.68, blue: 0.56, alpha: 1)
    }

    private func anatomicalShade(for profile: CharacterProfile) -> UIColor {
        if profile.id.contains("female-real") {
            return UIColor(red: 0.62, green: 0.44, blue: 0.35, alpha: 1)
        }
        return UIColor(red: 0.58, green: 0.40, blue: 0.31, alpha: 1)
    }

    private func hairColor(for profile: CharacterProfile) -> UIColor {
        if profile.gender == .female {
            return UIColor(red: 0.18, green: 0.10, blue: 0.12, alpha: 1)
        }
        return UIColor(red: 0.12, green: 0.10, blue: 0.09, alpha: 1)
    }

    private func pantsColor(for profile: CharacterProfile) -> UIColor {
        if profile.gender == .female {
            return UIColor(red: 0.17, green: 0.18, blue: 0.23, alpha: 1)
        }
        return UIColor(red: 0.14, green: 0.17, blue: 0.20, alpha: 1)
    }

    private func shirtColor(for profile: CharacterProfile) -> UIColor {
        if profile.id.contains("female-real") {
            return UIColor(red: 0.31, green: 0.43, blue: 0.47, alpha: 1)
        }
        if profile.id.contains("male-real") || profile.id.contains("action") {
            return UIColor(red: 0.28, green: 0.34, blue: 0.38, alpha: 1)
        }
        if profile.style == .editorial {
            return UIColor(hex: profile.accentHex)
        }
        return UIColor(red: 0.36, green: 0.42, blue: 0.48, alpha: 1)
    }
}

private extension EulerAngles {
    var radians: SCNVector3 {
        SCNVector3(x.degreesToRadians, y.degreesToRadians, z.degreesToRadians)
    }
}

private extension Float {
    var degreesToRadians: Float {
        self * .pi / 180
    }
}

private extension Int {
    var degreesToRadians: Float {
        Float(self).degreesToRadians
    }
}

private extension Double {
    var degreesToRadians: Float {
        Float(self).degreesToRadians
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
