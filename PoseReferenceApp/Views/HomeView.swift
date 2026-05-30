import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore
    @State private var showSupportAndPrivacy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    commandBar
                    studioDashboard
                    metricsGrid
                    recentProjects
                    templateQueue
                    proStudioCard
                    characterShortcut
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showSupportAndPrivacy) {
            SupportAndPrivacyView()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "cube.transparent")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.mint)
                        .frame(width: 24, height: 24)
                        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("PoseFrame Studio")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                }

                Text("3D pose workspace for production reference")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer()

            Button {
                showSupportAndPrivacy = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .frame(width: 38, height: 38)
                    .foregroundStyle(AppTheme.ink)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.black.opacity(0.06), lineWidth: 1)
                    )
            }
            .accessibilityLabel("設定")
        }
        .padding(.top, 18)
    }

    private var commandBar: some View {
        HStack(spacing: 10) {
            WorkspaceCommand(title: "Solo", subtitle: "單人姿勢", icon: "person.fill", color: AppTheme.teal) {
                appState.startProject(mode: .solo)
            }

            WorkspaceCommand(title: "Duo", subtitle: "雙人互動", icon: "person.2.fill", color: AppTheme.coral) {
                appState.startProject(mode: .duo)
            }

            WorkspaceCommand(title: "Pro", subtitle: premiumStore.isProUnlocked ? "已啟用" : premiumStore.displayPrice, icon: "crown.fill", color: AppTheme.mint) {
                premiumStore.isProUnlocked ? appState.startProject(mode: .duo, pose: AppData.poses.first { $0.id == "pro-sword-clash" }) : appState.requestPremiumUnlock(.studioPack)
            }
        }
    }

    private var studioDashboard: some View {
        Button {
            appState.startProject(mode: .duo, pose: AppData.poses.first { $0.id == "hold-hands" })
        } label: {
            ZStack(alignment: .bottomLeading) {
                Image("HeroPoseStudio")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.05), .black.opacity(0.84)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        StatusChip(title: "Live viewport", color: AppTheme.teal)
                        StatusChip(title: "SaaS workspace", color: AppTheme.mint)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Studio Command Center")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("角色、姿勢、相機、光線與輸出集中在一個工作台。")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            DashboardMetric(title: "角色庫", value: "\(AppData.characters.count)", trend: "8 USDZ", icon: "person.crop.rectangle.stack")
            DashboardMetric(title: "姿勢模板", value: "\(AppData.poses.count)", trend: "含雙人", icon: "figure.run")
            DashboardMetric(title: "Pro 狀態", value: premiumStore.isProUnlocked ? "Active" : "Locked", trend: premiumStore.isProUnlocked ? "可輸出" : "IAP ready", icon: "bolt.badge.clock")
        }
    }

    private var recentProjects: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Production Queue", action: "最近專案")

            VStack(spacing: 0) {
                ForEach(Array(appState.recentProjects.prefix(4).enumerated()), id: \.element.id) { index, project in
                    Button {
                        appState.startFromRecent(project)
                    } label: {
                        ProjectQueueRow(project: project, index: index)
                    }
                    .buttonStyle(.plain)

                    if index < min(appState.recentProjects.count, 4) - 1 {
                        Divider()
                            .padding(.leading, 58)
                    }
                }
            }
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var templateQueue: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Template Library", action: "熱門模板")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AppData.featuredPoses + Array(AppData.poses.filter(\.isPremium).prefix(2))) { pose in
                        Button {
                            if pose.isPremium, !premiumStore.isProUnlocked {
                                appState.requestPremiumUnlock(.premiumPoses)
                            } else {
                                appState.startProject(mode: pose.isPair ? .duo : .solo, pose: pose)
                            }
                        } label: {
                            TemplateQueueCard(pose: pose)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 16)
            }
        }
    }

    private var proStudioCard: some View {
        Button {
            if premiumStore.isProUnlocked {
                appState.startProject(mode: .solo, character: AppData.characters.first { $0.isPremium })
            } else {
                appState.requestPremiumUnlock(.studioPack)
            }
        } label: {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.panel)
                    Image(systemName: premiumStore.isProUnlocked ? "checkmark.seal.fill" : "crown.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(AppTheme.mint)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(premiumStore.isProUnlocked ? "Pro workspace active" : "Upgrade to Pro workspace")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("商稿角色、構圖輔助、透明 PNG 與多視角輸出。")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(14)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var characterShortcut: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Character Slots", action: "角色入口")

            HStack(spacing: 10) {
                ForEach(AppData.characters.prefix(2)) { character in
                    Button {
                        appState.startProject(mode: .solo, character: character)
                    } label: {
                        CharacterMiniCard(character: character)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct WorkspaceCommand: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(11)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct StatusChip: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(title)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.black.opacity(0.42), in: Capsule())
    }
}

private struct SectionHeader: View {
    let title: String
    let action: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(action)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
        }
    }
}

private struct DashboardMetric: View {
    let title: String
    let value: String
    let trend: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.teal)
                Spacer()
                Circle()
                    .fill(AppTheme.mint)
                    .frame(width: 6, height: 6)
            }

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
                Text(trend)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted.opacity(0.85))
            }
        }
        .padding(11)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct ProjectQueueRow: View {
    let project: RecentProject
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(project.mode == .solo ? AppTheme.teal.opacity(0.14) : AppTheme.coral.opacity(0.14))
                Text("\(index + 1)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(project.mode == .solo ? AppTheme.teal : AppTheme.coral)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(project.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Text("\(project.poseTitle) / \(project.characterNames)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: project.mode.icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }
}

private struct TemplateQueueCard: View {
    let pose: PoseTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: pose.isPair ? "person.2.fill" : "figure.cooldown")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(pose.category.color)
                    .frame(width: 34, height: 34)
                    .background(pose.category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                Spacer()
                if pose.isPremium {
                    PremiumBadge(compact: true)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pose.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(pose.summary)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CapsuleTag(title: pose.category.rawValue, color: pose.category.color)
        }
        .frame(width: 154, alignment: .leading)
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct CharacterMiniCard: View {
    let character: CharacterProfile

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: character.symbol)
                .font(.headline.weight(.semibold))
                .frame(width: 42, height: 42)
                .foregroundStyle(character.accent)
                .background(character.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(character.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("\(character.gender.rawValue) / \(character.style.rawValue)")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06), lineWidth: 1)
        )
    }
}
