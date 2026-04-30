//
//  MediaDetailView.swift
//  PHOU
//
//  Created by Codex on 4/23/26.
//

import SwiftUI
import UIKit
import ComposableArchitecture

struct MediaDetailView: View {
    @Bindable var store: StoreOf<MediaDetailFeature>
    let transitionNamespace: Namespace.ID?

    private let chromeAnimation = Animation.easeInOut(duration: 0.24)
    private let detailsPrefetchRadius = 1

    @State private var usesImmersiveBackground = false
    @State private var showsDetailsPanel = false
    @State private var currentDetails: MediaAssetDetails?
    @State private var detailsCache: [String: MediaAssetDetails] = [:]
    @State private var isPreparingDetailsPanel = false
    @State private var shareItems: [Any] = []
    @State private var isPreparingShare = false
    @State private var showsCropUnavailableAlert = false
    @State private var showsAdjustmentUnavailableAlert = false
    @State private var adjustmentUnavailableMessage = ""
    @State private var showsDeleteConfirmation = false

    private var currentAssetID: String {
        guard store.items.indices.contains(store.currentIndex) else { return "media-detail-fallback" }
        return store.items[store.currentIndex].id
    }

    private var currentAsset: PhotoAsset? {
        guard store.items.indices.contains(store.currentIndex) else { return nil }
        return store.items[store.currentIndex]
    }

    private var backgroundColor: Color {
        usesImmersiveBackground ? .black : Color(uiColor: .systemBackground)
    }

    private var displayedDetails: MediaAssetDetails? {
        detailsCache[currentAssetID] ?? currentDetails ?? currentAsset.map(MediaAssetDetails.placeholder)
    }

    private var detailsPanelDetails: MediaAssetDetails? {
        detailsCache[currentAssetID]
    }

    var body: some View {
        rootContent
            .task(id: currentAssetID) {
                await refreshCurrentDetails()
            }
            .interactiveDismissDisabled(showsDetailsPanel)
            .sheet(isPresented: shareSheetBinding) {
                ShareSheetView(activityItems: shareItems)
            }
            .sheet(
                isPresented: Binding(
                    get: { store.isAlbumPickerPresented },
                    set: { isPresented in
                        if !isPresented {
                            store.send(.view(.albumPickerDismissed))
                        }
                    }
                )
            ) {
                AlbumPickerSheet(albums: store.userAlbums) { albumID in
                    store.send(.view(.albumSelected(albumID)))
                }
            }
            .alert("크롭은 다음 세션에서 이어서 구현할게요", isPresented: $showsCropUnavailableAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("이번 변경에서는 버튼 배치만 맞추고, 실제 크롭 편집은 다음 세션 범위로 남겨둘게요.")
            }
            .alert("아직 준비 중이에요", isPresented: $showsAdjustmentUnavailableAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(adjustmentUnavailableMessage)
            }
            .alert(
                "오류",
                isPresented: Binding(
                    get: { store.noticeMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            store.send(.view(.noticeDismissed))
                        }
                    }
                )
            ) {
                Button("확인", role: .cancel) {
                    store.send(.view(.noticeDismissed))
                }
            } message: {
                Text(store.noticeMessage ?? "")
            }
            .confirmationDialog(
                "이 미디어를 삭제할까요?",
                isPresented: $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("삭제", role: .destructive) {
                    store.send(.view(.deleteConfirmedTapped))
                }
                Button("취소", role: .cancel) {}
            }
    }

    @ViewBuilder
    private var rootContent: some View {
        let content = NavigationStack {
            GeometryReader { proxy in
                let layout = MediaDetailLayout(
                    containerSize: proxy.size,
                    safeAreaInsets: proxy.safeAreaInsets
                )

                ZStack {
                    backgroundColor
                        .ignoresSafeArea()

                    self.content(layout: layout)
                        .animation(chromeAnimation, value: usesImmersiveBackground)

                    detailsPanel(layout: layout)
                }
                .contentShape(Rectangle())
                .simultaneousGesture(detailsRevealGesture)
                .animation(chromeAnimation, value: usesImmersiveBackground)
                .statusBarHidden(usesImmersiveBackground)
                .toolbar(usesImmersiveBackground ? .hidden : .visible, for: .navigationBar)
                .toolbar(usesImmersiveBackground ? .hidden : .visible, for: .bottomBar)
                .toolbarBackgroundVisibility(.automatic, for: .navigationBar, .bottomBar)
                .toolbar {
                    mediaDetailToolbar
                }
                .toolbarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .onChange(of: currentAssetID) { _, _ in
                    if let currentAsset {
                        setCurrentDetails(
                            detailsCache[currentAsset.id]
                                ?? MediaDetailAssetLoader.provisionalSummaryDetails(for: currentAsset)
                        )
                    } else {
                        setCurrentDetails(nil)
                    }
                }
                .onChange(of: usesImmersiveBackground) { _, isImmersive in
                    if isImmersive {
                        showsDetailsPanel = false
                    }
                }
            }
        }

        if let transitionNamespace {
            content
                .navigationTransition(.zoom(sourceID: currentAssetID, in: transitionNamespace))
        } else {
            content
        }
    }

    @ViewBuilder
    private func content(layout: MediaDetailLayout) -> some View {
        TabView(
            selection: Binding(
                get: { store.currentIndex },
                set: { store.send(.view(.currentIndexChanged($0))) }
            )
        ) {
            ForEach(Array(store.items.enumerated()), id: \.element.id) { index, asset in
                let pageLiftOffset = MediaDetailRevealGeometry.pageContentLiftOffset(
                    isDetailsPresented: showsDetailsPanel,
                    mediaLift: layout.mediaLift
                )

                MediaPageView(
                    asset: asset,
                    viewportSize: layout.viewportSize,
                    isActive: index == store.currentIndex,
                    shouldLoad: abs(index - store.currentIndex) <= 1,
                    isDetailsPanelPresented: showsDetailsPanel,
                    backgroundColor: usesImmersiveBackground ? .black : .systemBackground,
                    onSingleTap: toggleBackground
                )
                .frame(maxWidth: .infinity)
                .frame(height: layout.viewportSize.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .visualEffect { content, _ in
                    content.offset(y: pageLiftOffset)
                }
                .animation(chromeAnimation, value: pageLiftOffset)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }

    private func toggleBackground() {
        if showsDetailsPanel {
            closeDetailsPanel()
        }

        withAnimation(chromeAnimation) {
            usesImmersiveBackground.toggle()
        }
    }

    @MainActor
    private func refreshCurrentDetails() async {
        guard let currentAsset else {
            setCurrentDetails(nil)
            return
        }

        let index = store.currentIndex
        if let cached = detailsCache[currentAsset.id] {
            setCurrentDetails(cached)
        } else {
            setCurrentDetails(MediaDetailAssetLoader.provisionalSummaryDetails(for: currentAsset))
        }

        await prefetchDetails(around: index)
    }

    @MainActor
    private func prefetchDetails(around centerIndex: Int) async {
        guard store.items.indices.contains(centerIndex) else { return }

        let lowerBound = max(centerIndex - detailsPrefetchRadius, store.items.startIndex)
        let upperBound = min(centerIndex + detailsPrefetchRadius, store.items.index(before: store.items.endIndex))

        let assetsToLoad = (lowerBound...upperBound)
            .map { store.items[$0] }
            .filter { detailsCache[$0.id] == nil }

        guard !assetsToLoad.isEmpty else { return }

        await withTaskGroup(of: (String, MediaAssetDetails).self) { group in
            for asset in assetsToLoad {
                group.addTask {
                    (asset.id, await MediaDetailAssetLoader.details(for: asset))
                }
            }

            for await (assetID, details) in group {
                detailsCache[assetID] = details

                if assetID == currentAssetID {
                    setCurrentDetails(details)
                }
            }
        }
    }

    private func setCurrentDetails(_ details: MediaAssetDetails?) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentDetails = details
        }
    }

    private func prepareShare(for asset: PhotoAsset) async {
        isPreparingShare = true
        defer { isPreparingShare = false }

        if let items = await MediaDetailAssetLoader.shareItems(for: asset) {
            shareItems = items
        }
    }

    private func presentInfo() {
        if showsDetailsPanel {
            closeDetailsPanel()
        } else {
            Task {
                await openDetailsPanel()
            }
        }
    }

    private func presentUnavailableAdjustment(_ message: String) {
        adjustmentUnavailableMessage = message
        showsAdjustmentUnavailableAlert = true
    }

    private var shareSheetBinding: Binding<Bool> {
        Binding(
            get: { !shareItems.isEmpty },
            set: { isPresented in
                if !isPresented {
                    shareItems = []
                }
            }
        )
    }

    @ToolbarContentBuilder
    private var mediaDetailToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                store.send(.view(.dismissTapped))
            } label: {
                Image(systemName: "chevron.backward")
            }
        }

        if #available(iOS 26, *) {
            ToolbarItem(placement: .principal) {
                titleToolbarLabel
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .principal) {
                titleToolbarLabel
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            topTrailingMenu
        }

        if #available(iOS 26, *) {
            ToolbarItem(placement: .bottomBar) {
                shareToolbarButton
            }

            ToolbarSpacer(.flexible, placement: .bottomBar)

            ToolbarItemGroup(placement: .bottomBar) {
                favoriteToolbarButton
                infoToolbarButton
                cropToolbarButton
            }

            ToolbarSpacer(.flexible, placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                deleteToolbarButton
            }
        } else {
            ToolbarItem(placement: .bottomBar) {
                shareToolbarButton
            }

            ToolbarItemGroup(placement: .status) {
                favoriteToolbarButton
                infoToolbarButton
                cropToolbarButton
            }

            ToolbarItem(placement: .bottomBar) {
                deleteToolbarButton
            }
        }
    }

    private var titleToolbarLabel: some View {
        VStack(spacing: 2) {
            Text(displayedDetails?.titlePrimaryText ?? "사진")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(displayedDetails?.titleSecondaryText ?? "정보 확인 중")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .frame(width: 220)
        .multilineTextAlignment(.center)
    }

    private var topTrailingMenu: some View {
        Menu {
            Button {
                store.send(.view(.addToAlbumTapped))
            } label: {
                Label("앨범에 추가", systemImage: "text.badge.plus")
            }

            Button {
                presentUnavailableAdjustment(
                    "날짜 및 시간 조정은 아직 준비 중이에요."
                )
            } label: {
                Label("날짜 및 시간 조정", systemImage: "calendar.badge.clock")
            }

            Button {
                presentUnavailableAdjustment(
                    "위치 조정은 Apple 지도 연동 설계와 같이 다음 단계에서 다루겠습니다."
                )
            } label: {
                Label("위치 조정", systemImage: "mappin.and.ellipse")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }

    private var shareToolbarButton: some View {
        Button {
            guard let asset = currentAsset else { return }
            Task {
                await prepareShare(for: asset)
            }
        } label: {
            if isPreparingShare {
                ProgressView()
            } else {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .disabled(isPreparingShare || currentAsset == nil)
    }

    private var favoriteToolbarButton: some View {
        Button {
            store.send(.view(.favoriteTapped))
        } label: {
            Image(systemName: (currentAsset?.isFavorite ?? false) ? "heart.fill" : "heart")
        }
        .tint((currentAsset?.isFavorite ?? false) ? .pink : .accentColor)
    }

    private var infoToolbarButton: some View {
        Button {
            presentInfo()
        } label: {
            if isPreparingDetailsPanel {
                ProgressView()
            } else {
                Image(systemName: showsDetailsPanel ? "info.circle.fill" : "info.circle")
            }
        }
        .disabled(isPreparingDetailsPanel)
    }

    private var cropToolbarButton: some View {
        Button {
            showsCropUnavailableAlert = true
        } label: {
            Image(systemName: "crop")
        }
    }

    private var deleteToolbarButton: some View {
        Button(role: .destructive) {
            showsDeleteConfirmation = true
        } label: {
            Image(systemName: "trash")
        }
        .disabled(currentAsset == nil)
    }

    @ViewBuilder
    private func detailsPanel(layout: MediaDetailLayout) -> some View {
        MediaDetailsPanel(
            details: detailsPanelDetails,
            layout: layout,
            isPresented: showsDetailsPanel,
            onDismiss: closeDetailsPanel
        )
    }

    private var detailsRevealGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                if value.translation.height < -72 {
                    Task {
                        await openDetailsPanel()
                    }
                } else if value.translation.height > 72, showsDetailsPanel {
                    closeDetailsPanel()
                }
            }
    }

    @MainActor
    private func openDetailsPanel() async {
        guard !showsDetailsPanel, !isPreparingDetailsPanel else { return }

        guard let currentAsset else { return }

        if detailsCache[currentAsset.id] == nil {
            isPreparingDetailsPanel = true
            defer { isPreparingDetailsPanel = false }

            let assetID = currentAsset.id
            let details = await MediaDetailAssetLoader.details(for: currentAsset)
            guard assetID == currentAssetID else { return }
            detailsCache[assetID] = details
            setCurrentDetails(details)
        }

        withAnimation(chromeAnimation) {
            usesImmersiveBackground = false
            showsDetailsPanel = true
        }
    }

    private func closeDetailsPanel() {
        withAnimation(chromeAnimation) {
            showsDetailsPanel = false
        }
    }

}
