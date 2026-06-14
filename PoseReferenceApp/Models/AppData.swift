import SwiftUI

enum ProjectMode: String, CaseIterable, Identifiable {
    case solo
    case duo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solo:
            return "單人"
        case .duo:
            return "雙人"
        }
    }

    var icon: String {
        switch self {
        case .solo:
            return "person.fill"
        case .duo:
            return "person.2.fill"
        }
    }
}

enum CharacterGender: String, CaseIterable, Identifiable {
    case male = "男"
    case female = "女"

    var id: String { rawValue }
}

enum CharacterStyle: String, CaseIterable, Identifiable {
    case anime = "動漫"
    case realistic = "寫實"
    case editorial = "商稿"

    var id: String { rawValue }
}

struct CharacterProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let gender: CharacterGender
    let style: CharacterStyle
    let poseCount: Int
    let accentHex: String
    let symbol: String
    let proportion: Double
    let isPremium: Bool
    let studioRole: String
    let detail: String
    let usdzName: String?

    var accent: Color { Color(hex: accentHex) }

    init(
        id: String,
        name: String,
        gender: CharacterGender,
        style: CharacterStyle,
        poseCount: Int,
        accentHex: String,
        symbol: String,
        proportion: Double,
        isPremium: Bool = false,
        studioRole: String = "角色比例參考",
        detail: String = "適合快速建立乾淨的人體比例與動態草圖。",
        usdzName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.style = style
        self.poseCount = poseCount
        self.accentHex = accentHex
        self.symbol = symbol
        self.proportion = proportion
        self.isPremium = isPremium
        self.studioRole = studioRole
        self.detail = detail
        self.usdzName = usdzName
    }
}

enum PoseCategory: String, CaseIterable, Identifiable {
    case standing = "站姿"
    case action = "動作"
    case seated = "坐姿"
    case pair = "雙人"
    case drama = "情緒"
    case pro = "Pro"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .standing:
            return AppTheme.teal
        case .action:
            return AppTheme.coral
        case .seated:
            return AppTheme.violet
        case .pair:
            return AppTheme.amber
        case .drama:
            return Color(red: 0.48, green: 0.42, blue: 0.33)
        case .pro:
            return AppTheme.gold
        }
    }
}

struct EulerAngles: Hashable {
    var x: Float = 0
    var y: Float = 0
    var z: Float = 0
}

struct JointPose: Hashable {
    var torso = EulerAngles()
    var head = EulerAngles()
    var leftUpperArm = EulerAngles()
    var leftForearm = EulerAngles()
    var rightUpperArm = EulerAngles()
    var rightForearm = EulerAngles()
    var leftThigh = EulerAngles()
    var leftShin = EulerAngles()
    var rightThigh = EulerAngles()
    var rightShin = EulerAngles()

    static let neutral = JointPose(
        torso: EulerAngles(x: 0, y: 0, z: 0),
        head: EulerAngles(x: -4, y: 0, z: 0),
        leftUpperArm: EulerAngles(x: 8, y: 0, z: -7),
        leftForearm: EulerAngles(x: 5, y: 0, z: 3),
        rightUpperArm: EulerAngles(x: 8, y: 0, z: 7),
        rightForearm: EulerAngles(x: 5, y: 0, z: -3),
        leftThigh: EulerAngles(x: 0, y: 0, z: 2),
        leftShin: EulerAngles(x: 0, y: 0, z: 0),
        rightThigh: EulerAngles(x: 0, y: 0, z: -2),
        rightShin: EulerAngles(x: 0, y: 0, z: 0)
    )
}

enum JointAxis: String, CaseIterable, Identifiable {
    case x = "前後"
    case y = "扭轉"
    case z = "側向"

    var id: String { rawValue }
}

extension EulerAngles {
    subscript(axis: JointAxis) -> Float {
        get {
            switch axis {
            case .x: return x
            case .y: return y
            case .z: return z
            }
        }
        set {
            switch axis {
            case .x: x = newValue
            case .y: y = newValue
            case .z: z = newValue
            }
        }
    }
}

enum JointRole: String, CaseIterable, Identifiable {
    case head
    case torso
    case leftUpperArm
    case leftForearm
    case rightUpperArm
    case rightForearm
    case leftThigh
    case leftShin
    case rightThigh
    case rightShin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .head: return "頭部"
        case .torso: return "軀幹"
        case .leftUpperArm: return "左上臂"
        case .leftForearm: return "左前臂"
        case .rightUpperArm: return "右上臂"
        case .rightForearm: return "右前臂"
        case .leftThigh: return "左大腿"
        case .leftShin: return "左小腿"
        case .rightThigh: return "右大腿"
        case .rightShin: return "右小腿"
        }
    }

    var keyPath: WritableKeyPath<JointPose, EulerAngles> {
        switch self {
        case .head: return \.head
        case .torso: return \.torso
        case .leftUpperArm: return \.leftUpperArm
        case .leftForearm: return \.leftForearm
        case .rightUpperArm: return \.rightUpperArm
        case .rightForearm: return \.rightForearm
        case .leftThigh: return \.leftThigh
        case .leftShin: return \.leftShin
        case .rightThigh: return \.rightThigh
        case .rightShin: return \.rightShin
        }
    }
}

struct PoseTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let category: PoseCategory
    let summary: String
    let isPair: Bool
    let joints: JointPose
    let isPremium: Bool
    let studioUse: String

    init(
        id: String,
        title: String,
        category: PoseCategory,
        summary: String,
        isPair: Bool,
        joints: JointPose,
        isPremium: Bool = false,
        studioUse: String = "適合一般插畫、漫畫和分鏡草圖。"
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.summary = summary
        self.isPair = isPair
        self.joints = joints
        self.isPremium = isPremium
        self.studioUse = studioUse
    }
}

struct PropItem: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let colorHex: String
    let isPremium: Bool

    var color: Color { Color(hex: colorHex) }

    init(id: String, title: String, icon: String, colorHex: String, isPremium: Bool = false) {
        self.id = id
        self.title = title
        self.icon = icon
        self.colorHex = colorHex
        self.isPremium = isPremium
    }
}

enum EditorPanel: String, CaseIterable, Identifiable {
    case characters = "角色"
    case pose = "Pose"
    case joints = "關節"
    case camera = "相機"
    case lighting = "燈光"
    case props = "道具"
    case pro = "Pro"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .characters:
            return "person.crop.square"
        case .pose:
            return "figure.cooldown"
        case .joints:
            return "rotate.3d"
        case .camera:
            return "camera.viewfinder"
        case .lighting:
            return "sun.max"
        case .props:
            return "shippingbox"
        case .pro:
            return "wand.and.stars"
        }
    }
}

enum CameraPreset: String, CaseIterable, Identifiable {
    case front = "前視"
    case side = "側視"
    case threeQuarter = "3/4"
    case top = "俯視"
    case low = "仰視"

    var id: String { rawValue }

    var yaw: Float {
        switch self {
        case .front:
            return 0
        case .side:
            return -90
        case .threeQuarter:
            return -35
        case .top:
            return 0
        case .low:
            return 0
        }
    }

    var pitch: Float {
        switch self {
        case .top:
            return -58
        case .low:
            return 16
        default:
            return -4
        }
    }
}

enum CanvasRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case portrait = "3:4"
    case story = "9:16"
    case wide = "16:9"

    var id: String { rawValue }
}

enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case transparent = "透明 PNG"
    case multiAngle = "多視角"

    var id: String { rawValue }

    var isPremium: Bool {
        self != .png
    }

    var summary: String {
        switch self {
        case .png:
            return "免費輸出單張參考圖。"
        case .transparent:
            return "去背素材，方便放進 Procreate、Photoshop 或分鏡稿。"
        case .multiAngle:
            return "一次輸出前視、側視、3/4 與仰視，建立完整造型參考。"
        }
    }
}

enum CompositionGuide: String, CaseIterable, Identifiable {
    case thirds = "三分線"
    case headHeight = "頭身比例"
    case golden = "黃金構圖"
    case storyboard = "分鏡格"

    var id: String { rawValue }

    var isPremium: Bool {
        self != .thirds
    }
}

enum RenderMood: String, CaseIterable, Identifiable {
    case studio = "棚拍"
    case paper = "稿紙"
    case silhouette = "剪影"
    case warmKey = "暖光"

    var id: String { rawValue }

    var isPremium: Bool {
        self != .studio
    }
}

enum PremiumFeature: String, Identifiable {
    case studioPack
    case premiumCharacters
    case premiumPoses
    case premiumProps
    case proExport
    case compositionGuides

    var id: String { rawValue }

    var title: String {
        switch self {
        case .studioPack:
            return "PoseFrame Studio Pro"
        case .premiumCharacters:
            return "Pro 角色庫"
        case .premiumPoses:
            return "進階姿勢包"
        case .premiumProps:
            return "創作道具包"
        case .proExport:
            return "商稿匯出工具"
        case .compositionGuides:
            return "構圖與比例輔助"
        }
    }

    var subtitle: String {
        switch self {
        case .studioPack:
            return "一次解鎖高階角色、商稿姿勢、構圖輔助和專業輸出。"
        case .premiumCharacters:
            return "解鎖更適合商業插畫與漫畫分鏡的人物比例。"
        case .premiumPoses:
            return "解鎖強透視、戰鬥互動、分鏡張力和情緒鏡頭。"
        case .premiumProps:
            return "解鎖畫面張力、速度線、鏡頭架和布料輔助道具。"
        case .proExport:
            return "解鎖透明 PNG 與多視角輸出，省下重畫參考的時間。"
        case .compositionGuides:
            return "解鎖頭身比例、黃金構圖和分鏡格輔助線。"
        }
    }

    var icon: String {
        switch self {
        case .studioPack:
            return "crown.fill"
        case .premiumCharacters:
            return "person.crop.rectangle.stack.fill"
        case .premiumPoses:
            return "figure.run"
        case .premiumProps:
            return "shippingbox.and.arrow.backward.fill"
        case .proExport:
            return "square.and.arrow.up.on.square.fill"
        case .compositionGuides:
            return "rectangle.3.group.fill"
        }
    }
}

struct RecentProject: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let mode: ProjectMode
    let poseTitle: String
    let characterNames: String
}

enum AppData {
    static let characters: [CharacterProfile] = [
        CharacterProfile(id: "male-anime-a", name: "Akio 少年", gender: .male, style: .anime, poseCount: 42, accentHex: "#277E9A", symbol: "figure.stand", proportion: 1.04, studioRole: "漫畫主角比例", detail: "肩線清楚、四肢乾淨，適合快速起稿。", usdzName: "Male_Adult_03"),
        CharacterProfile(id: "male-real-b", name: "Ren 寫實男", gender: .male, style: .realistic, poseCount: 38, accentHex: "#59636E", symbol: "figure.walk", proportion: 1.12, studioRole: "寫實男體比例", detail: "偏成人比例，適合商業分鏡與產品人物。", usdzName: "Sports_Male_01"),
        CharacterProfile(id: "female-anime-a", name: "Mika 少女", gender: .female, style: .anime, poseCount: 45, accentHex: "#C75C7A", symbol: "figure.dance", proportion: 0.98, studioRole: "動漫女角比例", detail: "動勢輕盈，適合角色設計與封面草圖。", usdzName: "Female_Adult_03"),
        CharacterProfile(id: "female-real-b", name: "Aya 寫實女", gender: .female, style: .realistic, poseCount: 36, accentHex: "#8B6F47", symbol: "figure.stand.line.dotted.figure.stand", proportion: 1.02, studioRole: "寫實女體比例", detail: "比例穩定，適合姿態檢查和光影參考。", usdzName: "Sports_Female_01"),
        CharacterProfile(id: "male-editorial-pro", name: "Kai 商稿男", gender: .male, style: .editorial, poseCount: 68, accentHex: "#1F6F8B", symbol: "figure.strengthtraining.traditional", proportion: 1.18, isPremium: true, studioRole: "海報強透視", detail: "強化肩寬、手臂和鏡頭張力，適合封面與廣告人物。", usdzName: "Business_Male_01"),
        CharacterProfile(id: "female-editorial-pro", name: "Noa 商稿女", gender: .female, style: .editorial, poseCount: 72, accentHex: "#C14667", symbol: "figure.mind.and.body", proportion: 1.08, isPremium: true, studioRole: "時裝與封面", detail: "長線條比例，適合時尚、封面、角色定裝與手勢研究。", usdzName: "Business_Female_01"),
        CharacterProfile(id: "male-action-pro", name: "Theo 動作男", gender: .male, style: .realistic, poseCount: 64, accentHex: "#3A3F58", symbol: "figure.boxing", proportion: 1.16, isPremium: true, studioRole: "動作分鏡", detail: "下盤穩、重心明確，適合打鬥、運動和低角度鏡頭。", usdzName: "Military_Male_01"),
        CharacterProfile(id: "female-action-pro", name: "Luna 動作女", gender: .female, style: .anime, poseCount: 70, accentHex: "#8F4CA7", symbol: "figure.run", proportion: 1.03, isPremium: true, studioRole: "動態剪影", detail: "肢體延展明顯，適合跳躍、閃避、舞蹈和強烈剪影。", usdzName: "Female_Party_01")
    ]

    static let props: [PropItem] = [
        PropItem(id: "box", title: "方箱", icon: "shippingbox", colorHex: "#D89938"),
        PropItem(id: "chair", title: "椅子", icon: "chair", colorHex: "#6E7F80"),
        PropItem(id: "staff", title: "長棍", icon: "line.diagonal", colorHex: "#7E6752"),
        PropItem(id: "sword", title: "劍", icon: "bolt.horizontal", colorHex: "#A7B1BA"),
        PropItem(id: "phone", title: "手機", icon: "iphone", colorHex: "#20242A"),
        PropItem(id: "panel", title: "畫板", icon: "rectangle.on.rectangle", colorHex: "#46857C"),
        PropItem(id: "sphere", title: "球體", icon: "circle.fill", colorHex: "#B94738"),
        PropItem(id: "bag", title: "包包", icon: "handbag", colorHex: "#534A77"),
        PropItem(id: "ribbon", title: "飄帶", icon: "scribble", colorHex: "#D36C56"),
        PropItem(id: "step", title: "台階", icon: "stairs", colorHex: "#757B83"),
        PropItem(id: "speed", title: "速度線", icon: "wind", colorHex: "#D14B3E", isPremium: true),
        PropItem(id: "camera-rig", title: "鏡頭架", icon: "camera.metering.matrix", colorHex: "#20242A", isPremium: true),
        PropItem(id: "drape", title: "布料", icon: "waveform.path.ecg.rectangle", colorHex: "#2D8E80", isPremium: true),
        PropItem(id: "perspective", title: "透視框", icon: "perspective", colorHex: "#8A6BD1", isPremium: true)
    ]

    static let poses: [PoseTemplate] = [
        PoseTemplate(id: "neutral", title: "自然站立", category: .standing, summary: "乾淨比例參考", isPair: false, joints: .neutral, studioUse: "檢查頭身、肩線與腳掌落點的基準姿勢。"),
        PoseTemplate(id: "contrapposto", title: "重心站姿", category: .standing, summary: "肩胯反向", isPair: false, joints: JointPose(
            torso: EulerAngles(x: 0, y: -8, z: 7),
            head: EulerAngles(x: -5, y: 10, z: -3),
            leftUpperArm: EulerAngles(x: 10, y: 4, z: -12),
            leftForearm: EulerAngles(x: 8, y: 0, z: 6),
            rightUpperArm: EulerAngles(x: 3, y: -2, z: 10),
            rightForearm: EulerAngles(x: 18, y: 0, z: -24),
            leftThigh: EulerAngles(x: -6, y: 0, z: 5),
            leftShin: EulerAngles(x: 8, y: 0, z: 0),
            rightThigh: EulerAngles(x: 9, y: 0, z: -7),
            rightShin: EulerAngles(x: -4, y: 0, z: 0)
        ), studioUse: "適合角色設計、服裝定裝與封面站姿。"),
        PoseTemplate(id: "sit", title: "坐姿", category: .seated, summary: "下半身摺疊", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -7, y: 0, z: 0),
            head: EulerAngles(x: -3, y: -8, z: 0),
            leftUpperArm: EulerAngles(x: 36, y: -4, z: -18),
            leftForearm: EulerAngles(x: 52, y: 0, z: 12),
            rightUpperArm: EulerAngles(x: 38, y: 4, z: 18),
            rightForearm: EulerAngles(x: 54, y: 0, z: -12),
            leftThigh: EulerAngles(x: -82, y: 0, z: 7),
            leftShin: EulerAngles(x: 78, y: 0, z: -4),
            rightThigh: EulerAngles(x: -82, y: 0, z: -7),
            rightShin: EulerAngles(x: 78, y: 0, z: 4)
        ), studioUse: "適合坐姿、咖啡廳、教室、訪談和室內分鏡。"),
        PoseTemplate(id: "run", title: "奔跑", category: .action, summary: "強動勢剪影", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -14, y: -8, z: -4),
            head: EulerAngles(x: 5, y: 6, z: 2),
            leftUpperArm: EulerAngles(x: -64, y: 0, z: -18),
            leftForearm: EulerAngles(x: -72, y: 0, z: 10),
            rightUpperArm: EulerAngles(x: 48, y: 0, z: 21),
            rightForearm: EulerAngles(x: 66, y: 0, z: -12),
            leftThigh: EulerAngles(x: 58, y: 0, z: 9),
            leftShin: EulerAngles(x: -72, y: 0, z: 0),
            rightThigh: EulerAngles(x: -50, y: 0, z: -8),
            rightShin: EulerAngles(x: 58, y: 0, z: 0)
        ), studioUse: "適合速度感插畫、遊戲動作和運動漫畫。"),
        PoseTemplate(id: "jump", title: "跳躍", category: .action, summary: "上升張力", isPair: false, joints: JointPose(
            torso: EulerAngles(x: 12, y: 0, z: -7),
            head: EulerAngles(x: -10, y: 0, z: 4),
            leftUpperArm: EulerAngles(x: -128, y: 0, z: -32),
            leftForearm: EulerAngles(x: -16, y: 0, z: 2),
            rightUpperArm: EulerAngles(x: -118, y: 0, z: 34),
            rightForearm: EulerAngles(x: -18, y: 0, z: -2),
            leftThigh: EulerAngles(x: -32, y: 0, z: 16),
            leftShin: EulerAngles(x: 52, y: 0, z: -7),
            rightThigh: EulerAngles(x: 36, y: 0, z: -18),
            rightShin: EulerAngles(x: -40, y: 0, z: 8)
        ), studioUse: "適合封面跳躍、魔法動作和上升動勢。"),
        PoseTemplate(id: "guard", title: "格鬥防禦", category: .action, summary: "拳擊架勢", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -8, y: -24, z: 2),
            head: EulerAngles(x: 0, y: 18, z: 0),
            leftUpperArm: EulerAngles(x: -40, y: -20, z: -36),
            leftForearm: EulerAngles(x: -88, y: 0, z: 26),
            rightUpperArm: EulerAngles(x: -28, y: 22, z: 38),
            rightForearm: EulerAngles(x: -92, y: 0, z: -30),
            leftThigh: EulerAngles(x: 22, y: 0, z: 16),
            leftShin: EulerAngles(x: -22, y: 0, z: -4),
            rightThigh: EulerAngles(x: -18, y: 0, z: -19),
            rightShin: EulerAngles(x: 24, y: 0, z: 4)
        ), studioUse: "適合格鬥漫畫、防禦站位與角色對峙。"),
        PoseTemplate(id: "punch", title: "直拳", category: .action, summary: "前臂透視", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -5, y: -36, z: 0),
            head: EulerAngles(x: 0, y: 22, z: 0),
            leftUpperArm: EulerAngles(x: -76, y: -14, z: -18),
            leftForearm: EulerAngles(x: -18, y: 0, z: 6),
            rightUpperArm: EulerAngles(x: -24, y: 18, z: 44),
            rightForearm: EulerAngles(x: -92, y: 0, z: -20),
            leftThigh: EulerAngles(x: 20, y: 0, z: 12),
            leftShin: EulerAngles(x: -20, y: 0, z: -2),
            rightThigh: EulerAngles(x: -16, y: 0, z: -16),
            rightShin: EulerAngles(x: 20, y: 0, z: 4)
        ), studioUse: "適合強透視出拳、動作格與廣告人物。"),
        PoseTemplate(id: "kick", title: "側踢", category: .action, summary: "腿部延展", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -6, y: 28, z: -13),
            head: EulerAngles(x: 4, y: -18, z: 5),
            leftUpperArm: EulerAngles(x: 4, y: 0, z: -48),
            leftForearm: EulerAngles(x: 18, y: 0, z: 8),
            rightUpperArm: EulerAngles(x: -8, y: 0, z: 52),
            rightForearm: EulerAngles(x: 20, y: 0, z: -8),
            leftThigh: EulerAngles(x: -4, y: 0, z: 72),
            leftShin: EulerAngles(x: -8, y: 0, z: -4),
            rightThigh: EulerAngles(x: 18, y: 0, z: -20),
            rightShin: EulerAngles(x: -28, y: 0, z: 3)
        ), studioUse: "適合武打、運動姿勢和腿部延展練習。"),
        PoseTemplate(id: "reach", title: "伸手拿物", category: .drama, summary: "肩線向上", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -3, y: -12, z: -6),
            head: EulerAngles(x: -10, y: 14, z: 4),
            leftUpperArm: EulerAngles(x: -118, y: 8, z: -21),
            leftForearm: EulerAngles(x: -20, y: 0, z: 5),
            rightUpperArm: EulerAngles(x: 12, y: -2, z: 12),
            rightForearm: EulerAngles(x: 28, y: 0, z: -8),
            leftThigh: EulerAngles(x: 8, y: 0, z: 4),
            leftShin: EulerAngles(x: -8, y: 0, z: 0),
            rightThigh: EulerAngles(x: -6, y: 0, z: -5),
            rightShin: EulerAngles(x: 8, y: 0, z: 0)
        ), studioUse: "適合伸手拿物、告白、告別和視線引導畫面。"),
        PoseTemplate(id: "bow", title: "鞠躬", category: .drama, summary: "禮貌彎身", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -46, y: 0, z: 0),
            head: EulerAngles(x: -18, y: 0, z: 0),
            leftUpperArm: EulerAngles(x: 28, y: 0, z: -5),
            leftForearm: EulerAngles(x: 18, y: 0, z: 4),
            rightUpperArm: EulerAngles(x: 28, y: 0, z: 5),
            rightForearm: EulerAngles(x: 18, y: 0, z: -4),
            leftThigh: EulerAngles(x: 6, y: 0, z: 2),
            leftShin: EulerAngles(x: -6, y: 0, z: 0),
            rightThigh: EulerAngles(x: 6, y: 0, z: -2),
            rightShin: EulerAngles(x: -6, y: 0, z: 0)
        ), studioUse: "適合禮儀動作、舞台謝幕和情緒收束。"),
        PoseTemplate(id: "kneel", title: "單膝跪地", category: .seated, summary: "膝蓋支點", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -12, y: 12, z: 2),
            head: EulerAngles(x: 5, y: -10, z: 0),
            leftUpperArm: EulerAngles(x: 28, y: 0, z: -16),
            leftForearm: EulerAngles(x: 42, y: 0, z: 12),
            rightUpperArm: EulerAngles(x: 8, y: 0, z: 20),
            rightForearm: EulerAngles(x: 36, y: 0, z: -10),
            leftThigh: EulerAngles(x: -82, y: 0, z: 9),
            leftShin: EulerAngles(x: 96, y: 0, z: -4),
            rightThigh: EulerAngles(x: 12, y: 0, z: -10),
            rightShin: EulerAngles(x: -80, y: 0, z: 2)
        ), studioUse: "適合求婚、武士蹲、道具拿取和低姿態構圖。"),
        PoseTemplate(id: "over-shoulder", title: "回頭", category: .drama, summary: "頭身反向", isPair: false, joints: JointPose(
            torso: EulerAngles(x: 0, y: 28, z: -3),
            head: EulerAngles(x: -3, y: -52, z: 4),
            leftUpperArm: EulerAngles(x: 16, y: 0, z: -10),
            leftForearm: EulerAngles(x: 28, y: 0, z: 4),
            rightUpperArm: EulerAngles(x: 8, y: 0, z: 18),
            rightForearm: EulerAngles(x: 42, y: 0, z: -8),
            leftThigh: EulerAngles(x: 8, y: 0, z: 4),
            leftShin: EulerAngles(x: -8, y: 0, z: 0),
            rightThigh: EulerAngles(x: -10, y: 0, z: -5),
            rightShin: EulerAngles(x: 10, y: 0, z: 0)
        ), studioUse: "適合回眸鏡頭、懸疑分鏡和服裝展示。"),
        PoseTemplate(id: "hold-hands", title: "牽手", category: .pair, summary: "雙人距離參考", isPair: true, joints: JointPose(
            torso: EulerAngles(x: 0, y: -16, z: 0),
            head: EulerAngles(x: -4, y: 18, z: 0),
            leftUpperArm: EulerAngles(x: -38, y: -8, z: -48),
            leftForearm: EulerAngles(x: -24, y: 0, z: 24),
            rightUpperArm: EulerAngles(x: 10, y: 0, z: 18),
            rightForearm: EulerAngles(x: 22, y: 0, z: -8),
            leftThigh: EulerAngles(x: 0, y: 0, z: 3),
            leftShin: EulerAngles(x: 0, y: 0, z: 0),
            rightThigh: EulerAngles(x: 0, y: 0, z: -3),
            rightShin: EulerAngles(x: 0, y: 0, z: 0)
        ), studioUse: "適合距離感、牽引線和雙人互動練習。"),
        PoseTemplate(id: "embrace", title: "擁抱", category: .pair, summary: "胸腔接近", isPair: true, joints: JointPose(
            torso: EulerAngles(x: -8, y: -8, z: 2),
            head: EulerAngles(x: 4, y: 18, z: 4),
            leftUpperArm: EulerAngles(x: -64, y: -12, z: -62),
            leftForearm: EulerAngles(x: -34, y: 0, z: 28),
            rightUpperArm: EulerAngles(x: -62, y: 12, z: 62),
            rightForearm: EulerAngles(x: -34, y: 0, z: -28),
            leftThigh: EulerAngles(x: 4, y: 0, z: 6),
            leftShin: EulerAngles(x: -6, y: 0, z: 0),
            rightThigh: EulerAngles(x: -4, y: 0, z: -6),
            rightShin: EulerAngles(x: 6, y: 0, z: 0)
        ), studioUse: "適合親密互動、胸腔距離和雙人輪廓參考。"),
        PoseTemplate(id: "pro-foreshorten", title: "強透視伸手", category: .pro, summary: "鏡頭壓縮張力", isPair: false, joints: JointPose(
            torso: EulerAngles(x: -10, y: -32, z: -4),
            head: EulerAngles(x: 2, y: 24, z: 0),
            leftUpperArm: EulerAngles(x: -92, y: -18, z: -46),
            leftForearm: EulerAngles(x: -34, y: 0, z: 10),
            rightUpperArm: EulerAngles(x: 24, y: 12, z: 42),
            rightForearm: EulerAngles(x: 48, y: 0, z: -18),
            leftThigh: EulerAngles(x: 18, y: 0, z: 12),
            leftShin: EulerAngles(x: -28, y: 0, z: -4),
            rightThigh: EulerAngles(x: -18, y: 0, z: -16),
            rightShin: EulerAngles(x: 24, y: 0, z: 2)
        ), isPremium: true, studioUse: "給商稿封面、主視覺和短影音縮圖用的強烈前景手勢。"),
        PoseTemplate(id: "pro-sword-clash", title: "雙人對峙", category: .pro, summary: "戰鬥距離與視線", isPair: true, joints: JointPose(
            torso: EulerAngles(x: -8, y: -34, z: 4),
            head: EulerAngles(x: 0, y: 28, z: 0),
            leftUpperArm: EulerAngles(x: -58, y: -24, z: -54),
            leftForearm: EulerAngles(x: -72, y: 0, z: 26),
            rightUpperArm: EulerAngles(x: -24, y: 20, z: 48),
            rightForearm: EulerAngles(x: -84, y: 0, z: -22),
            leftThigh: EulerAngles(x: 26, y: 0, z: 18),
            leftShin: EulerAngles(x: -34, y: 0, z: -4),
            rightThigh: EulerAngles(x: -22, y: 0, z: -18),
            rightShin: EulerAngles(x: 30, y: 0, z: 4)
        ), isPremium: true, studioUse: "適合戰鬥分鏡、對峙海報和武器距離檢查。"),
        PoseTemplate(id: "pro-fashion-turn", title: "時裝轉身", category: .pro, summary: "S 線條與服裝展示", isPair: false, joints: JointPose(
            torso: EulerAngles(x: 2, y: 30, z: 10),
            head: EulerAngles(x: -7, y: -46, z: -2),
            leftUpperArm: EulerAngles(x: 18, y: 0, z: -28),
            leftForearm: EulerAngles(x: 46, y: 0, z: 18),
            rightUpperArm: EulerAngles(x: 8, y: 0, z: 32),
            rightForearm: EulerAngles(x: 54, y: 0, z: -20),
            leftThigh: EulerAngles(x: 8, y: 0, z: 18),
            leftShin: EulerAngles(x: -10, y: 0, z: -6),
            rightThigh: EulerAngles(x: -14, y: 0, z: -22),
            rightShin: EulerAngles(x: 18, y: 0, z: 4)
        ), isPremium: true, studioUse: "適合服裝設計、角色定裝和封面姿勢。"),
        PoseTemplate(id: "pro-rescue-carry", title: "扶抱搬移", category: .pro, summary: "重量與支撐", isPair: true, joints: JointPose(
            torso: EulerAngles(x: -18, y: -12, z: 8),
            head: EulerAngles(x: 4, y: 18, z: 0),
            leftUpperArm: EulerAngles(x: -72, y: -14, z: -64),
            leftForearm: EulerAngles(x: -44, y: 0, z: 30),
            rightUpperArm: EulerAngles(x: -52, y: 16, z: 58),
            rightForearm: EulerAngles(x: -46, y: 0, z: -24),
            leftThigh: EulerAngles(x: 18, y: 0, z: 12),
            leftShin: EulerAngles(x: -26, y: 0, z: -4),
            rightThigh: EulerAngles(x: -12, y: 0, z: -14),
            rightShin: EulerAngles(x: 20, y: 0, z: 4)
        ), isPremium: true, studioUse: "適合劇情分鏡、英雄救援和雙人重量支撐。")
    ]

    static var featuredPoses: [PoseTemplate] {
        ["neutral", "run", "guard", "reach", "hold-hands"].compactMap { id in
            poses.first { $0.id == id }
        }
    }

    static var defaultCharacterA: CharacterProfile { characters[0] }
    static var defaultCharacterB: CharacterProfile { characters[2] }
    static var defaultPose: PoseTemplate { poses[0] }
}
