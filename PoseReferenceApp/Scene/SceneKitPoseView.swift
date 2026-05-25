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
        editor.snapshotProvider = { [weak view] in
            view?.snapshot()
        }
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.update(uiView, editor: editor)
    }

    final class Coordinator {
        private let scene = SCNScene()
        private let cameraRig = SCNNode()
        private let cameraNode = SCNNode()
        private let keyLight = SCNNode()
        private let fillLight = SCNNode()
        private let backLight = SCNNode()
        private let ambientLight = SCNNode()
        private let floorNode = SCNNode()
        private let gridNode = SCNNode()
        private let characterA = MannequinRig()
        private let characterB = MannequinRig()
        private var propNodes: [String: SCNNode] = [:]
        private var lastPropIDs = Set<String>()

        func configure(_ view: SCNView) {
            view.scene = scene
            view.allowsCameraControl = true
            view.autoenablesDefaultLighting = false
            view.antialiasingMode = .multisampling4X
            view.preferredFramesPerSecond = 60

            cameraNode.camera = SCNCamera()
            cameraNode.camera?.zNear = 0.01
            cameraNode.camera?.zFar = 100
            cameraRig.addChildNode(cameraNode)
            scene.rootNode.addChildNode(cameraRig)
            scene.rootNode.addChildNode(characterA.root)
            scene.rootNode.addChildNode(characterB.root)

            configureLights()
            configureFloor()
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
            cameraNode.camera?.fieldOfView = CGFloat(68 - (editor.perspective * 30))
            cameraRig.eulerAngles = SCNVector3(0, editor.cameraYaw.degreesToRadians, 0)
            cameraNode.position = SCNVector3(0, 1.35, editor.cameraDistance)
            cameraNode.eulerAngles = SCNVector3(editor.cameraPitch.degreesToRadians, 0, 0)

            keyLight.light?.intensity = CGFloat(editor.keyLightIntensity)
            fillLight.light?.intensity = CGFloat(editor.fillLightIntensity)
            backLight.light?.intensity = CGFloat(editor.backLightIntensity)
            floorNode.isHidden = !editor.showShadows || editor.transparentBackground
            gridNode.isHidden = !editor.showGrid

            let pairMode = editor.mode == .duo || editor.selectedPose.isPair || editor.characterB != nil
            characterA.root.position = SCNVector3(pairMode ? -0.42 : 0, 0.02, 0)
            characterA.root.eulerAngles.y = pairMode ? 8.degreesToRadians : 0
            characterA.update(profile: editor.characterA, pose: editor.selectedPose.joints, mirrored: editor.mirrored, silhouette: editor.silhouetteAssist)

            if pairMode {
                let second = editor.characterB ?? AppData.defaultCharacterB
                characterB.root.isHidden = false
                characterB.root.position = SCNVector3(0.42, 0.02, -0.08)
                characterB.root.eulerAngles.y = (-172).degreesToRadians
                characterB.update(profile: second, pose: editor.selectedPose.joints, mirrored: !editor.mirrored, silhouette: editor.silhouetteAssist)
            } else {
                characterB.root.isHidden = true
            }

            if lastPropIDs != editor.selectedPropIDs {
                rebuildProps(editor.selectedPropIDs)
            }
        }

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

private final class MannequinRig {
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

    private let bodyMaterial = SCNMaterial()
    private let jointMaterial = SCNMaterial()
    private let accentMaterial = SCNMaterial()
    private let hairMaterial = SCNMaterial()
    private let shirtMaterial = SCNMaterial()
    private let pantsMaterial = SCNMaterial()
    private let shoeMaterial = SCNMaterial()
    private let faceMaterial = SCNMaterial()

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

    func update(profile: CharacterProfile, pose: JointPose, mirrored: Bool, silhouette: Bool) {
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
