import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.95, green: 0.96, blue: 0.94)
    static let surface = Color(red: 0.99, green: 0.985, blue: 0.96)
    static let ink = Color(red: 0.08, green: 0.10, blue: 0.13)
    static let muted = Color(red: 0.42, green: 0.45, blue: 0.48)
    static let panel = Color(red: 0.07, green: 0.08, blue: 0.10)
    static let teal = Color(red: 0.05, green: 0.53, blue: 0.50)
    static let coral = Color(red: 0.88, green: 0.30, blue: 0.24)
    static let amber = Color(red: 0.91, green: 0.62, blue: 0.20)
    static let violet = Color(red: 0.34, green: 0.31, blue: 0.69)
    static let gold = Color(red: 0.83, green: 0.56, blue: 0.16)
    static let blueprint = Color(red: 0.10, green: 0.17, blue: 0.25)
    static let mint = Color(red: 0.70, green: 0.88, blue: 0.76)

    static func soft(_ color: Color) -> Color {
        color.opacity(0.14)
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.04, green: 0.09, blue: 0.13), Color(red: 0.04, green: 0.43, blue: 0.41), Color(red: 0.78, green: 0.32, blue: 0.24)],
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
