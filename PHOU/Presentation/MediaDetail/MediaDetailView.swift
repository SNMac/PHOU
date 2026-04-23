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

    @Environment(\.dismiss) private var dismiss

    @State private var usesImmersiveBackground = false
    @State private var currentDetails: MediaAssetDetails?
    @State private var shareItems: [Any] = []
    @State private var isPreparingShare = false
    @State private var infoItem: MediaInfoItem?
    @State private var showsEditUnavailableAlert = false

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
            .sheet(item: $infoItem) { item in
                MediaInfoSheet(details: item.details)
                    .presentationDetents([.medium])
            }
            .alert("기본 사진 편집을 열 수 없어요", isPresented: $showsEditUnavailableAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("PhotoKit은 앱 내부에서 시스템 사진 편집 UI를 직접 여는 공개 API를 제공하지 않아요.")
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
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        titleView
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Image(systemName: (displayedDetails?.isFavorite ?? false) ? "heart.fill" : "heart")
                            .foregroundStyle((displayedDetails?.isFavorite ?? false) ? .pink : .primary)
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
        HStack {
            Button {
                guard let asset = currentAsset, !isPreparingShare else { return }
                Task {
                    await prepareShare(for: asset)
                }
            } label: {
                Label("공유", systemImage: isPreparingShare ? "ellipsis.circle" : "square.and.arrow.up")
            }
            .disabled(isPreparingShare)

            Spacer()

            Button {
                guard let details = currentDetails else { return }
                infoItem = MediaInfoItem(details: details)
            } label: {
                Label("상세정보", systemImage: "info.circle")
            }

            Spacer()

            Button {
                showsEditUnavailableAlert = true
            } label: {
                Label("편집", systemImage: "crop")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.thinMaterial)
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
        currentDetails = await MediaDetailAssetLoader.details(for: currentAsset)
    }

    private func prepareShare(for asset: PhotoAsset) async {
        isPreparingShare = true
        defer { isPreparingShare = false }

        if let items = await MediaDetailAssetLoader.shareItems(for: asset) {
            shareItems = items
        }
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
                    infoRow(title: "종류", value: details.mediaTypeText)
                    infoRow(title: "크기", value: details.pixelSizeText)
                    infoRow(title: "즐겨찾기", value: details.isFavorite ? "예" : "아니요")
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
