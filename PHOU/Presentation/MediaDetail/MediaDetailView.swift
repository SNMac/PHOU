//
//  MediaDetailView.swift
//  PHOU
//
//  Created by Codex on 4/23/26.
//

import SwiftUI
import AVKit
import UIKit
import ComposableArchitecture
@preconcurrency import Photos

struct MediaDetailView: View {
    @Bindable var store: StoreOf<MediaDetailFeature>
    let transitionNamespace: Namespace.ID?

    @State private var usesImmersiveBackground = false
    @State private var currentDetails: MediaAssetDetails?
    @State private var shareItems: [Any] = []
    @State private var isPreparingShare = false
    @State private var infoItem: MediaInfoItem?
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
        currentDetails ?? currentAsset.map(MediaAssetDetails.placeholder)
    }

    var body: some View {
        rootContent
            .task(id: currentAssetID) {
                await refreshCurrentDetails()
            }
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
            .sheet(item: $infoItem) { item in
                MediaInfoSheet(details: item.details)
                    .presentationDetents([.medium])
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
        let navigationContent = NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            store.send(.view(.dismissTapped))
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        titleView
                    }

                    ToolbarItem(placement: .topBarTrailing) {
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
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    bottomBar
                }
        }

        if let transitionNamespace {
            navigationContent
                .navigationTransition(.zoom(sourceID: currentAssetID, in: transitionNamespace))
        } else {
            navigationContent
        }
    }

    @ViewBuilder
    private var content: some View {
        let detailContent = GeometryReader { proxy in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                TabView(
                    selection: Binding(
                        get: { store.currentIndex },
                        set: { store.send(.view(.currentIndexChanged($0))) }
                    )
                ) {
                    ForEach(Array(store.items.enumerated()), id: \.element.id) { index, asset in
                        MediaPageView(
                            asset: asset,
                            containerSize: proxy.size,
                            isActive: index == store.currentIndex,
                            shouldLoad: abs(index - store.currentIndex) <= 1,
                            backgroundColor: usesImmersiveBackground ? .black : .systemBackground,
                            onSingleTap: toggleBackground
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        detailContent
    }

    private var bottomBar: some View {
        HStack(spacing: 20) {
            chromeCircleButton(
                systemImage: isPreparingShare ? "ellipsis.circle" : "square.and.arrow.up",
                tint: .accentColor,
                isDisabled: isPreparingShare || currentAsset == nil
            ) {
                guard let asset = currentAsset else { return }
                Task {
                    await prepareShare(for: asset)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                chromeCapsuleButton(
                    systemImage: (currentAsset?.isFavorite ?? false) ? "heart.fill" : "heart",
                    tint: (currentAsset?.isFavorite ?? false) ? .pink : .accentColor
                ) {
                    store.send(.view(.favoriteTapped))
                }

                chromeCapsuleButton(
                    systemImage: "info.circle",
                    tint: .accentColor
                ) {
                    presentInfo()
                }

                chromeCapsuleButton(
                    systemImage: "crop",
                    tint: .accentColor
                ) {
                    showsCropUnavailableAlert = true
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .clipShape(Capsule())

            Spacer(minLength: 0)

            chromeCircleButton(
                systemImage: "trash",
                tint: .red,
                isDisabled: currentAsset == nil
            ) {
                showsDeleteConfirmation = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private func toggleBackground() {
        withAnimation(.easeInOut(duration: 0.2)) {
            usesImmersiveBackground.toggle()
        }
    }

    private func refreshCurrentDetails() async {
        guard let currentAsset else {
            currentDetails = nil
            return
        }

        currentDetails = .placeholder(for: currentAsset)
        let assetID = currentAsset.id
        let details = await MediaDetailAssetLoader.summaryDetails(for: currentAsset)
        guard assetID == currentAssetID else { return }
        currentDetails = details
    }

    private func prepareShare(for asset: PhotoAsset) async {
        isPreparingShare = true
        defer { isPreparingShare = false }

        if let items = await MediaDetailAssetLoader.shareItems(for: asset) {
            shareItems = items
        }
    }

    private func presentInfo() {
        guard let currentAsset else { return }

        infoItem = MediaInfoItem(details: displayedDetails ?? .placeholder(for: currentAsset))

        Task {
            let assetID = currentAsset.id
            let details = await MediaDetailAssetLoader.details(for: currentAsset)

            guard assetID == currentAssetID else { return }

            currentDetails = details
            infoItem = MediaInfoItem(details: details)
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

    private var titleView: some View {
        VStack(spacing: 1) {
            Text(displayedDetails?.titlePrimaryText ?? "사진")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(displayedDetails?.titleSecondaryText ?? "정보 확인 중")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
    }

    private func chromeCircleButton(
        systemImage: String,
        tint: Color,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 58, height: 58)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
        .disabled(isDisabled)
    }

    private func chromeCapsuleButton(
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 54, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct MediaPageView: View {
    let asset: PhotoAsset
    let containerSize: CGSize
    let isActive: Bool
    let shouldLoad: Bool
    let backgroundColor: UIColor
    let onSingleTap: () -> Void

    var body: some View {
        switch asset.mediaType {
        case .image, .unknown:
            MediaImagePageView(
                assetID: asset.id,
                containerSize: containerSize,
                shouldLoad: shouldLoad,
                backgroundColor: backgroundColor,
                onSingleTap: onSingleTap
            )
        case .video:
            MediaVideoPageView(
                assetID: asset.id,
                isActive: isActive,
                shouldLoad: isActive,
                onSingleTap: onSingleTap
            )
        }
    }
}

private struct MediaImagePageView: View {
    let assetID: String
    let containerSize: CGSize
    let shouldLoad: Bool
    let backgroundColor: UIColor
    let onSingleTap: () -> Void

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                ZoomableImageView(
                    image: image,
                    resetID: assetID,
                    containerSize: containerSize,
                    backgroundColor: backgroundColor,
                    onSingleTap: onSingleTap
                )
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if shouldLoad {
                ProgressView()
                    .tint(Color(uiColor: .secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: loadTaskID) {
            guard shouldLoad else {
                image = nil
                return
            }
            image = await MediaDetailAssetLoader.displayImage(
                for: assetID,
                targetSize: targetSize
            )
        }
    }

    private var loadTaskID: String {
        "\(assetID)-\(shouldLoad)-\(Int(targetSize.width))x\(Int(targetSize.height))"
    }

    private var targetSize: CGSize {
        CGSize(width: containerSize.width * 1.6, height: containerSize.height * 1.6)
    }
}

private struct MediaVideoPageView: View {
    let assetID: String
    let isActive: Bool
    let shouldLoad: Bool
    let onSingleTap: () -> Void

    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var failedToLoad = false

    var body: some View {
        ZStack {
            if let player {
                FillWidthPlayerView(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        if isActive {
                            player.play()
                        } else {
                            player.pause()
                        }
                    }
                    .overlay {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onSingleTap)
                    }
            } else if isLoading && shouldLoad {
                ProgressView()
                    .tint(Color(uiColor: .secondaryLabel))
            } else if !shouldLoad {
                Color.clear
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text(failedToLoad ? "동영상을 불러오지 못했어요" : "동영상을 준비 중이에요")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task(id: "\(assetID)-\(isActive)-\(shouldLoad)") {
            guard shouldLoad else {
                player?.pause()
                player = nil
                isLoading = false
                failedToLoad = false
                return
            }
            isLoading = true
            failedToLoad = false
            player = await MediaDetailAssetLoader.playerItem(for: assetID).map(AVPlayer.init(playerItem:))
            isLoading = false
            failedToLoad = player == nil
            if isActive {
                player?.play()
            } else {
                player?.pause()
            }
        }
        .onChange(of: isActive) { _, isActive in
            guard let player else { return }
            if isActive {
                player.play()
            } else {
                player.pause()
            }
        }
        .onDisappear {
            player?.pause()
        }
    }
}

private struct FillWidthPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        controller.showsPlaybackControls = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player {
            controller.player = player
        }
    }
}

private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let resetID: String
    let containerSize: CGSize
    let backgroundColor: UIColor
    let onSingleTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LayoutAwareScrollView {
        let scrollView = LayoutAwareScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = backgroundColor
        scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.configure(scrollView)
        return scrollView
    }

    func updateUIView(_ scrollView: LayoutAwareScrollView, context: Context) {
        scrollView.frame = CGRect(origin: .zero, size: containerSize)
        context.coordinator.update(
            image: image,
            resetID: resetID,
            containerSize: containerSize,
            backgroundColor: backgroundColor,
            onSingleTap: onSingleTap,
            in: scrollView
        )
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        private let imageView = UIImageView()
        private var currentResetID: String?
        private var lastContainerSize: CGSize = .zero
        private var onSingleTap: (() -> Void)?

        func configure(_ scrollView: UIScrollView) {
            imageView.contentMode = .scaleAspectFit
            scrollView.addSubview(imageView)

            let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTapGesture.numberOfTapsRequired = 2
            scrollView.addGestureRecognizer(doubleTapGesture)

            let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
            singleTapGesture.require(toFail: doubleTapGesture)
            scrollView.addGestureRecognizer(singleTapGesture)
        }

        func update(
            image: UIImage,
            resetID: String,
            containerSize: CGSize,
            backgroundColor: UIColor,
            onSingleTap: @escaping () -> Void,
            in scrollView: LayoutAwareScrollView
        ) {
            let needsReset = currentResetID != resetID || lastContainerSize != containerSize
            currentResetID = resetID
            lastContainerSize = containerSize
            self.onSingleTap = onSingleTap

            imageView.image = image
            scrollView.backgroundColor = backgroundColor
            scrollView.onLayout = { [weak self] updatedScrollView in
                self?.centerImage(in: updatedScrollView)
            }

            if needsReset {
                resetZoom(in: scrollView, image: image, containerSize: containerSize)
            }
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerImage(in: scrollView)
        }

        private func resetZoom(in scrollView: UIScrollView, image: UIImage, containerSize: CGSize) {
            let safeWidth = max(containerSize.width, 1)
            let safeHeight = max(containerSize.height, 1)
            let widthScale = safeWidth / max(image.size.width, 1)
            let heightScale = safeHeight / max(image.size.height, 1)
            let fittingScale = min(widthScale, heightScale)
            let fittedSize = CGSize(
                width: max(image.size.width * fittingScale, 1),
                height: max(image.size.height * fittingScale, 1)
            )

            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 4
            scrollView.zoomScale = 1

            imageView.frame = CGRect(
                origin: .zero,
                size: fittedSize
            )
            scrollView.contentSize = imageView.frame.size
            scrollView.contentOffset = .zero
            scrollView.layoutIfNeeded()
            centerImage(in: scrollView)
        }

        private func centerImage(in scrollView: UIScrollView) {
            let boundsSize = scrollView.bounds.size
            var frameToCenter = imageView.frame

            frameToCenter.origin.x = frameToCenter.width < boundsSize.width
                ? (boundsSize.width - frameToCenter.width) / 2
                : 0
            frameToCenter.origin.y = frameToCenter.height < boundsSize.height
                ? (boundsSize.height - frameToCenter.height) / 2
                : 0

            imageView.frame = frameToCenter
        }

        @objc
        private func handleSingleTap() {
            onSingleTap?()
        }

        @objc
        private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }

            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
                return
            }

            let tapPoint = gesture.location(in: imageView)
            let zoomScale = min(scrollView.maximumZoomScale, 2.5)
            let zoomWidth = scrollView.bounds.width / zoomScale
            let zoomHeight = scrollView.bounds.height / zoomScale
            let zoomRect = CGRect(
                x: tapPoint.x - (zoomWidth / 2),
                y: tapPoint.y - (zoomHeight / 2),
                width: zoomWidth,
                height: zoomHeight
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
}

private struct MediaInfoSheet: View {
    let details: MediaAssetDetails

    var body: some View {
        NavigationStack {
            List {
                Section("기본 정보") {
                    infoRow(title: "날짜", value: details.captureDateText)
                    infoRow(title: "파일명", value: details.filenameText)
                    infoRow(title: "촬영 기기", value: details.deviceText)
                    infoRow(title: "위치", value: details.locationText)
                    infoRow(title: "앨범", value: details.albumText)
                    infoRow(title: "크기", value: details.pixelSizeText)
                }
            }
            .navigationTitle("상세정보")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private final class LayoutAwareScrollView: UIScrollView {
    var onLayout: ((UIScrollView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(self)
    }
}

private struct AlbumPickerSheet: View {
    let albums: [AlbumGroup]
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(albums.enumerated()), id: \.element.id) { _, album in
                    Button {
                        onSelect(album.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(album.title)
                                    .foregroundStyle(.primary)
                                Text("\(album.assetCount)개")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("앨범에 추가")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
