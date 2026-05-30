import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.945, green: 0.958, blue: 0.972)
    static let surface = Color(red: 0.985, green: 0.99, blue: 1.0)
    static let ink = Color(red: 0.055, green: 0.071, blue: 0.094)
    static let muted = Color(red: 0.39, green: 0.43, blue: 0.49)
    static let panel = Color(red: 0.045, green: 0.058, blue: 0.075)
    static let teal = Color(red: 0.00, green: 0.66, blue: 0.70)
    static let coral = Color(red: 0.96, green: 0.39, blue: 0.34)
    static let amber = Color(red: 0.88, green: 0.64, blue: 0.22)
    static let violet = Color(red: 0.28, green: 0.34, blue: 0.78)
    static let gold = Color(red: 0.76, green: 0.55, blue: 0.18)
    static let blueprint = Color(red: 0.075, green: 0.105, blue: 0.145)
    static let mint = Color(red: 0.72, green: 0.94, blue: 0.22)

    static func soft(_ color: Color) -> Color {
        color.opacity(0.14)
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.035, green: 0.047, blue: 0.063), Color(red: 0.00, green: 0.55, blue: 0.62), Color(red: 0.82, green: 0.93, blue: 0.20)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: String, opacity: Double = 1) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch cleaned.count {
        case 3:
            r = (value >> 8) * 17
            g = ((value >> 4) & 0xF) * 17
            b = (value & 0xF) * 17
        default:
            r = value >> 16
            g = (value >> 8) & 0xFF
            b = value & 0xFF
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: opacity
        )
    }
}

struct MetricPill: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.footnote.weight(.semibold))
                .frame(width: 24, height: 24)
                .background(AppTheme.ink.opacity(0.08), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CapsuleTag: View {
    let title: String
    var color: Color = AppTheme.teal
    var selected = false

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? .white : color)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? color : AppTheme.soft(color), in: Capsule())
    }
}

struct PremiumBadge: View {
    var compact = false

    var body: some View {
        Label(compact ? "Pro" : "Pro 解鎖", systemImage: "crown.fill")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, compact ? 7 : 9)
            .padding(.vertical, 5)
            .background(AppTheme.gold, in: Capsule())
    }
}

struct LockedContentOverlay: View {
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .foregroundStyle(.white)
                .background(AppTheme.gold, in: Circle())
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
