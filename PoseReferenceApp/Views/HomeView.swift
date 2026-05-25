import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore
    @State private var showSupportAndPrivacy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    heroStudio
                    quickStart
                    recentProjects
                    featuredPoseStrip
                    proStudioCard
                    characterShortcut
                }
                .padding(.horizontal, 18)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PoseFrame Studio")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("3D 姿勢構圖工作室")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()

                Button {
                    showSupportAndPrivacy = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .foregroundStyle(AppTheme.ink)
                        .background(.white, in: Circle())
                }
                .accessibilityLabel("設定")
            }

            HStack(spacing: 10) {
                MetricPill(icon: "person.2", title: "角色", value: "\(AppData.characters.count)")
                MetricPill(icon: "figure.cooldown", title: "姿勢", value: "\(AppData.poses.count)")
                MetricPill(icon: "crown", title: "Pro", value: premiumStore.isProUnlocked ? "已解鎖" : "可升級")
            }
        }
        .padding(.top, 20)
    }

    private var heroStudio: some View {
        Button {
            appState.startProject(mode: .duo, pose: AppData.poses.first { $0.id == "hold-hands" })
        } label: {
            ZStack(alignment: .bottomLeading) {
                Image("HeroPoseStudio")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 230)
                    .clipped()

                LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.72)], startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        CapsuleTag(title: "免費開始", color: AppTheme.mint, selected: true)
                        PremiumBadge(compact: true)
                    }
                    Text("先把角度、張力、光線定好")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("用 3D 假人、商稿模板和構圖輔助，讓草圖更快進入可交付狀態。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速開始")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 12) {
                QuickStartButton(mode: .solo, color: AppTheme.teal) {
                    appState.startProject(mode: .solo)
                }

                QuickStartButton(mode: .duo, color: AppTheme.coral) {
                    appState.startProject(mode: .duo)
                }
            }
        }
    }

    private var recentProjects: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近專案")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 10) {
                ForEach(appState.recentProjects.prefix(3)) { project in
                    Button {
                        appState.startFromRecent(project)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: project.mode.icon)
                                .font(.headline)
                                .frame(width: 38, height: 38)
                                .foregroundStyle(.white)
                                .background(project.mode == .solo ? AppTheme.teal : AppTheme.coral, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(project.title)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                Text("\(project.poseTitle) · \(project.characterNames)")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.muted)
                        }
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var featuredPoseStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("熱門模板")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text("含 Pro 商稿姿勢")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppData.featuredPoses + Array(AppData.poses.filter(\.isPremium).prefix(2))) { pose in
                        Button {
                            if pose.isPremium, !premiumStore.isProUnlocked {
                                appState.requestPremiumUnlock(.premiumPoses)
                            } else {
                                appState.startProject(mode: pose.isPair ? .duo : .solo, pose: pose)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: pose.isPair ? "person.2.fill" : "figure.cooldown")
                                    .font(.title2)
                                    .foregroundStyle(pose.category.color)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(pose.title)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.ink)
                                    Text(pose.summary)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.muted)
                                }
                                HStack(spacing: 6) {
                                    CapsuleTag(title: pose.category.rawValue, color: pose.category.color)
                                    if pose.isPremium {
                                        PremiumBadge(compact: true)
                                    }
                                }
                            }
                            .frame(width: 146, alignment: .leading)
                            .padding(14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 18)
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
            HStack(spacing: 14) {
                Image(systemName: premiumStore.isProUnlocked ? "checkmark.seal.fill" : "crown.fill")
                    .font(.title2.weight(.bold))
                    .frame(width: 52, height: 52)
                    .foregroundStyle(.white)
                    .background(AppTheme.gold, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(premiumStore.isProUnlocked ? "Pro 工作室已啟用" : "Pro 工作室解鎖")
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("商稿角色、強透視姿勢、構圖輔助、透明與多視角輸出。")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var characterShortcut: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("角色入口")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 12) {
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

private struct QuickStartButton: View {
    let mode: ProjectMode
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: mode.icon)
                    .font(.title2.weight(.semibold))
                    .frame(width: 42, height: 42)
                    .foregroundStyle(.white)
                    .background(color.opacity(0.84), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("新建\(mode.title)")
                        .font(.headline)
                    Text(mode == .solo ? "一個角色開始" : "雙角色互動")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct CharacterMiniCard: View {
    let character: CharacterProfile

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: character.symbol)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(.white)
                .background(character.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("\(character.gender.rawValue) · \(character.style.rawValue)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
