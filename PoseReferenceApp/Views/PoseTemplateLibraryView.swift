import SwiftUI

struct PoseTemplateLibraryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore
    @State private var selectedCategory: PoseCategory?
    @State private var searchText = ""
    @State private var favoritesOnly = false

    private var filteredPoses: [PoseTemplate] {
        AppData.poses.filter { pose in
            let searchMatches = searchText.isEmpty || pose.title.localizedCaseInsensitiveContains(searchText) || pose.summary.localizedCaseInsensitiveContains(searchText)
            let categoryMatches = selectedCategory == nil || pose.category == selectedCategory
            let favoriteMatches = !favoritesOnly || appState.favoritePoseIDs.contains(pose.id)
            return searchMatches && categoryMatches && favoriteMatches
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    categoryFilters

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                        ForEach(filteredPoses) { pose in
                            PoseCard(
                                pose: pose,
                                isFavorite: appState.favoritePoseIDs.contains(pose.id),
                                isLocked: pose.isPremium && !premiumStore.isProUnlocked,
                                onFavorite: { appState.toggleFavorite(pose: pose) },
                                onStart: {
                                    if pose.isPremium, !premiumStore.isProUnlocked {
                                        appState.requestPremiumUnlock(.premiumPoses)
                                    } else {
                                        appState.startProject(mode: pose.isPair ? .duo : .solo, pose: pose)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("姿勢模板")
            .searchable(text: $searchText, prompt: "搜尋姿勢、用途")
        }
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    selectedCategory = nil
                } label: {
                    CapsuleTag(title: "全部", color: AppTheme.ink, selected: selectedCategory == nil)
                }
                .buttonStyle(.plain)

                ForEach(PoseCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        CapsuleTag(title: category.rawValue, color: category.color, selected: selectedCategory == category)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    favoritesOnly.toggle()
                } label: {
                    CapsuleTag(title: "收藏", color: AppTheme.coral, selected: favoritesOnly)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct PoseCard: View {
    let pose: PoseTemplate
    let isFavorite: Bool
    let isLocked: Bool
    let onFavorite: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .top) {
                    Image(systemName: pose.isPair ? "person.2.fill" : "figure.cooldown")
                        .font(.title)
                        .frame(width: 52, height: 52)
                        .foregroundStyle(.white)
                        .background(pose.category.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer()

                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.headline)
                            .foregroundStyle(isFavorite ? AppTheme.amber : AppTheme.muted)
                    }
                    .accessibilityLabel("收藏姿勢")
                }

                if isLocked {
                    LockedContentOverlay(title: "解鎖姿勢")
                        .frame(height: 74)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(pose.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(pose.summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
                Text(pose.studioUse)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    CapsuleTag(title: pose.category.rawValue, color: pose.category.color)
                    if pose.isPremium {
                        PremiumBadge(compact: true)
                    }
                }
            }

            Button(action: onStart) {
                Label(isLocked ? "解鎖 Pro" : "套用到新專案", systemImage: isLocked ? "crown.fill" : "arrow.up.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(isLocked ? AppTheme.gold : pose.category.color)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
