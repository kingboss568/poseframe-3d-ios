import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetRoot = root.appendingPathComponent("PoseReferenceApp/Resources/Assets.xcassets")
let appIconRoot = assetRoot.appendingPathComponent("AppIcon.appiconset")

try FileManager.default.createDirectory(at: appIconRoot, withIntermediateDirectories: true)

func image(size: CGSize, alpha: Bool = true, draw: (CGContext, CGRect) -> Void) -> CGImage {
    let width = Int(size.width.rounded())
    let height = Int(size.height.rounded())
    let bitmapInfo = alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo
    )!

    let rect = CGRect(origin: .zero, size: size)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    draw(context, rect)
    return context.makeImage()!
}

func savePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "AssetGeneration", code: 1)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "AssetGeneration", code: 2)
    }
}

func writeJSON(_ object: Any, to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
}

func fillGradient(_ context: CGContext, rect: CGRect, colors: [NSColor]) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let cgColors = colors.map { $0.cgColor } as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: nil)!
    context.drawLinearGradient(gradient, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func iconImage(size: CGFloat) -> CGImage {
    image(size: CGSize(width: size, height: size), alpha: false) { context, rect in
        fillGradient(context, rect: rect, colors: [
            NSColor(calibratedRed: 0.03, green: 0.08, blue: 0.12, alpha: 1),
            NSColor(calibratedRed: 0.03, green: 0.44, blue: 0.42, alpha: 1),
            NSColor(calibratedRed: 0.89, green: 0.31, blue: 0.22, alpha: 1)
        ])

        context.setFillColor(NSColor(calibratedWhite: 1, alpha: 0.12).cgColor)
        context.addPath(roundedRect(CGRect(x: size * 0.10, y: size * 0.13, width: size * 0.80, height: size * 0.72), radius: size * 0.11))
        context.fillPath()

        context.setStrokeColor(NSColor(calibratedWhite: 1, alpha: 0.25).cgColor)
        context.setLineWidth(size * 0.010)
        for index in 0...4 {
            let y = size * (0.22 + CGFloat(index) * 0.115)
            context.move(to: CGPoint(x: size * 0.15, y: y))
            context.addLine(to: CGPoint(x: size * 0.85, y: y))
        }
        context.strokePath()

        let skin = NSColor(calibratedRed: 0.86, green: 0.68, blue: 0.55, alpha: 1)
        let suit = NSColor(calibratedWhite: 1, alpha: 0.92)
        let hair = NSColor(calibratedRed: 0.13, green: 0.10, blue: 0.09, alpha: 1)

        context.setStrokeColor(skin.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setLineWidth(size * 0.042)
        context.move(to: CGPoint(x: size * 0.40, y: size * 0.36))
        context.addLine(to: CGPoint(x: size * 0.31, y: size * 0.22))
        context.move(to: CGPoint(x: size * 0.57, y: size * 0.36))
        context.addLine(to: CGPoint(x: size * 0.71, y: size * 0.26))
        context.move(to: CGPoint(x: size * 0.39, y: size * 0.58))
        context.addLine(to: CGPoint(x: size * 0.24, y: size * 0.49))
        context.move(to: CGPoint(x: size * 0.60, y: size * 0.58))
        context.addLine(to: CGPoint(x: size * 0.77, y: size * 0.55))
        context.strokePath()

        context.setFillColor(suit.cgColor)
        context.fillEllipse(in: CGRect(x: size * 0.36, y: size * 0.34, width: size * 0.28, height: size * 0.34))
        context.fillEllipse(in: CGRect(x: size * 0.38, y: size * 0.29, width: size * 0.23, height: size * 0.10))

        context.setFillColor(skin.cgColor)
        context.fillEllipse(in: CGRect(x: size * 0.41, y: size * 0.67, width: size * 0.18, height: size * 0.20))
        context.setFillColor(hair.cgColor)
        context.fillEllipse(in: CGRect(x: size * 0.40, y: size * 0.78, width: size * 0.20, height: size * 0.08))

        context.setStrokeColor(NSColor(calibratedRed: 0.96, green: 0.70, blue: 0.22, alpha: 1).cgColor)
        context.setLineWidth(size * 0.027)
        context.addEllipse(in: CGRect(x: size * 0.22, y: size * 0.20, width: size * 0.56, height: size * 0.56))
        context.strokePath()
    }
}

func heroImage(size: CGSize, dark: Bool) -> CGImage {
    image(size: size) { context, rect in
        fillGradient(context, rect: rect, colors: dark ? [
            NSColor(calibratedRed: 0.05, green: 0.09, blue: 0.13, alpha: 1),
            NSColor(calibratedRed: 0.04, green: 0.35, blue: 0.34, alpha: 1),
            NSColor(calibratedRed: 0.72, green: 0.25, blue: 0.20, alpha: 1)
        ] : [
            NSColor(calibratedRed: 0.93, green: 0.95, blue: 0.91, alpha: 1),
            NSColor(calibratedRed: 0.77, green: 0.86, blue: 0.78, alpha: 1),
            NSColor(calibratedRed: 0.90, green: 0.62, blue: 0.45, alpha: 1)
        ])

        let gridColor = NSColor(calibratedWhite: dark ? 1 : 0, alpha: dark ? 0.18 : 0.12).cgColor
        context.setStrokeColor(gridColor)
        context.setLineWidth(2)
        for index in 0...10 {
            let x = rect.width * CGFloat(index) / 10
            context.move(to: CGPoint(x: x, y: rect.height * 0.08))
            context.addLine(to: CGPoint(x: rect.width * 0.50 + (x - rect.width * 0.50) * 0.28, y: rect.height * 0.54))
        }
        for index in 0...6 {
            let y = rect.height * (0.10 + CGFloat(index) * 0.07)
            context.move(to: CGPoint(x: rect.width * 0.08, y: y))
            context.addLine(to: CGPoint(x: rect.width * 0.92, y: y))
        }
        context.strokePath()

        func drawFigure(centerX: CGFloat, baseY: CGFloat, scale: CGFloat, accent: NSColor, flipped: Bool) {
            let skin = NSColor(calibratedRed: 0.62, green: 0.43, blue: 0.33, alpha: 1)
            let skinLight = NSColor(calibratedRed: 0.78, green: 0.58, blue: 0.46, alpha: 1)
            let pants = NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.18, alpha: 1)
            let hair = NSColor(calibratedRed: 0.13, green: 0.09, blue: 0.08, alpha: 1)
            let direction: CGFloat = flipped ? -1 : 1

            func limb(from: CGPoint, to: CGPoint, width: CGFloat, color: NSColor) {
                context.setStrokeColor(color.cgColor)
                context.setLineWidth(width * scale)
                context.setLineCap(.round)
                context.move(to: from)
                context.addLine(to: to)
                context.strokePath()
            }

            context.setShadow(offset: CGSize(width: 0, height: -10 * scale), blur: 22 * scale, color: NSColor(calibratedWhite: 0, alpha: dark ? 0.35 : 0.18).cgColor)
            context.setLineCap(.round)
            context.setLineJoin(.round)

            let hip = CGPoint(x: centerX + 10 * direction * scale, y: baseY + 126 * scale)
            let chest = CGPoint(x: centerX - 8 * direction * scale, y: baseY + 246 * scale)
            let shoulderLeft = CGPoint(x: centerX - 58 * direction * scale, y: baseY + 242 * scale)
            let shoulderRight = CGPoint(x: centerX + 58 * direction * scale, y: baseY + 236 * scale)

            limb(from: CGPoint(x: hip.x - 24 * direction * scale, y: hip.y + 6 * scale), to: CGPoint(x: centerX - 82 * direction * scale, y: baseY + 42 * scale), width: 22, color: pants)
            limb(from: CGPoint(x: hip.x + 24 * direction * scale, y: hip.y + 8 * scale), to: CGPoint(x: centerX + 84 * direction * scale, y: baseY + 58 * scale), width: 22, color: pants)
            limb(from: shoulderLeft, to: CGPoint(x: centerX - 126 * direction * scale, y: baseY + 190 * scale), width: 20, color: accent)
            limb(from: shoulderRight, to: CGPoint(x: centerX + 128 * direction * scale, y: baseY + 204 * scale), width: 20, color: accent)
            limb(from: CGPoint(x: centerX - 126 * direction * scale, y: baseY + 190 * scale), to: CGPoint(x: centerX - 168 * direction * scale, y: baseY + 152 * scale), width: 15, color: skinLight)
            limb(from: CGPoint(x: centerX + 128 * direction * scale, y: baseY + 204 * scale), to: CGPoint(x: centerX + 170 * direction * scale, y: baseY + 166 * scale), width: 15, color: skinLight)

            let torso = CGMutablePath()
            torso.move(to: CGPoint(x: chest.x - 60 * scale, y: chest.y + 8 * scale))
            torso.addCurve(
                to: CGPoint(x: centerX - 42 * scale, y: baseY + 124 * scale),
                control1: CGPoint(x: centerX - 82 * scale, y: baseY + 220 * scale),
                control2: CGPoint(x: centerX - 64 * scale, y: baseY + 162 * scale)
            )
            torso.addCurve(
                to: CGPoint(x: centerX + 44 * scale, y: baseY + 124 * scale),
                control1: CGPoint(x: centerX - 16 * scale, y: baseY + 112 * scale),
                control2: CGPoint(x: centerX + 20 * scale, y: baseY + 112 * scale)
            )
            torso.addCurve(
                to: CGPoint(x: chest.x + 60 * scale, y: chest.y + 8 * scale),
                control1: CGPoint(x: centerX + 64 * scale, y: baseY + 164 * scale),
                control2: CGPoint(x: centerX + 82 * scale, y: baseY + 222 * scale)
            )
            torso.addCurve(
                to: CGPoint(x: chest.x - 60 * scale, y: chest.y + 8 * scale),
                control1: CGPoint(x: centerX + 34 * scale, y: chest.y + 36 * scale),
                control2: CGPoint(x: centerX - 34 * scale, y: chest.y + 38 * scale)
            )
            torso.closeSubpath()
            context.setFillColor(accent.cgColor)
            context.addPath(torso)
            context.fillPath()

            context.setFillColor(pants.cgColor)
            context.fillEllipse(in: CGRect(x: centerX - 56 * scale, y: baseY + 102 * scale, width: 112 * scale, height: 46 * scale))
            context.setFillColor(skin.cgColor)
            context.fillEllipse(in: CGRect(x: centerX - 36 * scale, y: baseY + 290 * scale, width: 74 * scale, height: 92 * scale))
            context.setFillColor(hair.cgColor)
            context.fillEllipse(in: CGRect(x: centerX - 42 * scale, y: baseY + 352 * scale, width: 86 * scale, height: 34 * scale))
            context.setFillColor(NSColor(calibratedWhite: 0.04, alpha: 1).cgColor)
            context.fillEllipse(in: CGRect(x: centerX - 17 * scale, y: baseY + 336 * scale, width: 6 * scale, height: 6 * scale))
            context.fillEllipse(in: CGRect(x: centerX + 13 * scale, y: baseY + 336 * scale, width: 6 * scale, height: 6 * scale))
            context.fill(CGRect(x: centerX - 18 * scale, y: baseY + 316 * scale, width: 36 * scale, height: 4 * scale))
            context.setShadow(offset: .zero, blur: 0, color: nil)
        }

        drawFigure(centerX: rect.width * 0.38, baseY: rect.height * 0.18, scale: rect.width / 1200, accent: NSColor(calibratedRed: 0.25, green: 0.43, blue: 0.48, alpha: 1), flipped: false)
        drawFigure(centerX: rect.width * 0.62, baseY: rect.height * 0.16, scale: rect.width / 1250, accent: NSColor(calibratedRed: 0.48, green: 0.26, blue: 0.36, alpha: 1), flipped: true)

        context.setFillColor(NSColor(calibratedWhite: 1, alpha: dark ? 0.16 : 0.28).cgColor)
        context.addPath(roundedRect(CGRect(x: rect.width * 0.07, y: rect.height * 0.70, width: rect.width * 0.30, height: rect.height * 0.18), radius: 26))
        context.fillPath()
        context.addPath(roundedRect(CGRect(x: rect.width * 0.68, y: rect.height * 0.12, width: rect.width * 0.23, height: rect.height * 0.16), radius: 24))
        context.fillPath()
    }
}

let iconSpecs: [(String, CGFloat)] = [
    ("Icon-20@1x.png", 20), ("Icon-20@2x.png", 40), ("Icon-20@3x.png", 60),
    ("Icon-29@1x.png", 29), ("Icon-29@2x.png", 58), ("Icon-29@3x.png", 87),
    ("Icon-40@1x.png", 40), ("Icon-40@2x.png", 80), ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120), ("Icon-60@3x.png", 180),
    ("Icon-76@2x.png", 152),
    ("Icon-83.5@2x.png", 167), ("Icon-1024.png", 1024)
]

let iconFilenames = Set(iconSpecs.map(\.0))
if let existingIconFiles = FileManager.default.enumerator(at: appIconRoot, includingPropertiesForKeys: nil) {
    for case let fileURL as URL in existingIconFiles where fileURL.pathExtension.lowercased() == "png" {
        if !iconFilenames.contains(fileURL.lastPathComponent) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}

for spec in iconSpecs {
    try savePNG(iconImage(size: spec.1), to: appIconRoot.appendingPathComponent(spec.0))
}

let appIconContents: [String: Any] = [
    "images": [
        ["idiom": "iphone", "size": "20x20", "scale": "2x", "filename": "Icon-20@2x.png"],
        ["idiom": "iphone", "size": "20x20", "scale": "3x", "filename": "Icon-20@3x.png"],
        ["idiom": "iphone", "size": "29x29", "scale": "2x", "filename": "Icon-29@2x.png"],
        ["idiom": "iphone", "size": "29x29", "scale": "3x", "filename": "Icon-29@3x.png"],
        ["idiom": "iphone", "size": "40x40", "scale": "2x", "filename": "Icon-40@2x.png"],
        ["idiom": "iphone", "size": "40x40", "scale": "3x", "filename": "Icon-40@3x.png"],
        ["idiom": "iphone", "size": "60x60", "scale": "2x", "filename": "Icon-60@2x.png"],
        ["idiom": "iphone", "size": "60x60", "scale": "3x", "filename": "Icon-60@3x.png"],
        ["idiom": "ipad", "size": "20x20", "scale": "1x", "filename": "Icon-20@1x.png"],
        ["idiom": "ipad", "size": "20x20", "scale": "2x", "filename": "Icon-20@2x.png"],
        ["idiom": "ipad", "size": "29x29", "scale": "1x", "filename": "Icon-29@1x.png"],
        ["idiom": "ipad", "size": "29x29", "scale": "2x", "filename": "Icon-29@2x.png"],
        ["idiom": "ipad", "size": "40x40", "scale": "1x", "filename": "Icon-40@1x.png"],
        ["idiom": "ipad", "size": "40x40", "scale": "2x", "filename": "Icon-40@2x.png"],
        ["idiom": "ipad", "size": "76x76", "scale": "2x", "filename": "Icon-76@2x.png"],
        ["idiom": "ipad", "size": "83.5x83.5", "scale": "2x", "filename": "Icon-83.5@2x.png"],
        ["idiom": "ios-marketing", "size": "1024x1024", "scale": "1x", "filename": "Icon-1024.png"]
    ],
    "info": ["author": "xcode", "version": 1]
]
try writeJSON(appIconContents, to: appIconRoot.appendingPathComponent("Contents.json"))

func writeImageSet(name: String, image: CGImage) throws {
    let folder = assetRoot.appendingPathComponent("\(name).imageset")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try savePNG(image, to: folder.appendingPathComponent("\(name).png"))
    let contents: [String: Any] = [
        "images": [["idiom": "universal", "scale": "1x", "filename": "\(name).png"]],
        "info": ["author": "xcode", "version": 1]
    ]
    try writeJSON(contents, to: folder.appendingPathComponent("Contents.json"))
}

try writeImageSet(name: "HeroPoseStudio", image: heroImage(size: CGSize(width: 1200, height: 820), dark: true))
try writeImageSet(name: "ProValuePreview", image: heroImage(size: CGSize(width: 1200, height: 820), dark: false))

print("Generated PoseFrame Studio app icons and illustration assets.")
