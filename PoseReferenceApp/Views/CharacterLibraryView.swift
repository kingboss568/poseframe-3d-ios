import SwiftUI

struct CharacterLibraryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var premiumStore: PremiumStore
    @State private var searchText = ""
    @State private var selectedGender: CharacterGender?
    @State private var selectedStyle: CharacterStyle?
    @State private var favoritesOnly = false

    private var filteredCharacters: [CharacterProfile] {
        AppData.characters.filter { character in
            let matchesSearch = searchText.isEmpty || character.name.localizedCaseInsensitiveContains(searchText)
            let matchesGender = selectedGender == nil || character.gender == selectedGender
            let matchesStyle = selectedStyle == nil || character.style == selectedStyle
            let matchesFavorite = !favoritesOnly || appState.favoriteCharacterIDs.contains(character.id)
            return matchesSearch && matchesGender && matchesStyle && matchesFavorite
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filters

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 12)], spacing: 12) {
                        ForEach(filteredCharacters) { character in
                            CharacterCard(
                                character: character,
                                isFavorite: appState.favoriteCharacterIDs.contains(character.id),
                                isLocked: character.isPremium && !premiumStore.isProUnlocked,
                                onFavorite: { appState.toggleFavorite(character: character) },
                                onStart: {
                                    if character.isPremium, !premiumStore.isProUnlocked {
                                        appState.requestPremiumUnlock(.premiumCharacters)
                                    } else {
                                        appState.startProject(mode: .solo, character: character)
                                    }
                                },
                                onUnlock: { appState.requestPremiumUnlock(.premiumCharacters) }
                            )
                        }
                    }
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("角色庫")
            .searchable(text: $searchText, prompt: "搜尋角色")
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        selectedGender = nil
                    } label: {
                        CapsuleTag(title: "全部性別", color: AppTheme.ink, selected: selectedGender == nil)
                    }
                    .buttonStyle(.plain)

                ForEach(CharacterGender.allCases) { gender in
                    Button {
                        selectedGender = gender
                        } label: {
                            CapsuleTag(title: gender.rawValue, color: AppTheme.teal, selected: selectedGender == gender)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    selectedGender = nil
                    selectedStyle = .editorial
                } label: {
                    CapsuleTag(title: "Pro 商稿", color: AppTheme.gold, selected: selectedStyle == .editorial)
                }
                .buttonStyle(.plain)

                Button {
                    favoritesOnly.toggle()
                } label: {
                        CapsuleTag(title: "收藏", color: AppTheme.coral, selected: favoritesOnly)
                    }
                    .buttonStyle(.plain)
                }
            }

            Picker("風格", selection: $selectedStyle) {
                Text("全部").tag(CharacterStyle?.none)
                ForEach(CharacterStyle.allCases) { style in
                    Text(style.rawValue).tag(CharacterStyle?.some(style))
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct CharacterCard: View {
    let character: CharacterProfile
    let isFavorite: Bool
    let isLocked: Bool
    let onFavorite: () -> Void
    let onStart: () -> Void
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: character.symbol)
                    .font(.system(size: 52, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 128)
                    .foregroundStyle(.white)
                    .background(character.accent, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                if character.isPremium {
                    PremiumBadge(compact: true)
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                if isLocked {
                    LockedContentOverlay(title: "解鎖角色")
                }

                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.headline)
                        .frame(width: 34, height: 34)
                        .foregroundStyle(isFavorite ? AppTheme.coral : .white)
                        .background(.black.opacity(0.18), in: Circle())
                }
                .padding(8)
                .accessibilityLabel("收藏")
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(character.name)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 6) {
                    CapsuleTag(title: character.gender.rawValue, color: character.accent)
                    CapsuleTag(title: character.style.rawValue, color: AppTheme.violet)
                }

                Text(character.studioRole)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text("\(character.poseCount) 個姿勢 · \(character.detail)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }

            Button(action: onStart) {
                Label(isLocked ? "解鎖 Pro" : "套用", systemImage: isLocked ? "crown.fill" : "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isLocked ? AppTheme.gold : character.accent)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contextMenu {
            Button(isLocked ? "解鎖 Pro 角色" : "加入單人專案", systemImage: isLocked ? "crown.fill" : "person.fill", action: isLocked ? onUnlock : onStart)
            Button(isFavorite ? "移除收藏" : "加入收藏", systemImage: isFavorite ? "heart.slash" : "heart", action: onFavorite)
        }
    }
}
