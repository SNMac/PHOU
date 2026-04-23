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

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color.black
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
                            isActive: index == store.currentIndex
                        )
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()

                topBar
            }
            .preferredColorScheme(.dark)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                store.send(.view(.dismissTapped))
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(store.currentIndex + 1) / \(store.items.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.black.opacity(0.5))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

private struct MediaPageView: View {
    let asset: PhotoAsset
    let containerSize: CGSize
    let isActive: Bool

    var body: some View {
        switch asset.mediaType {
        case .image, .unknown:
            MediaImagePageView(assetID: asset.id, containerSize: containerSize)
        case .video:
            MediaVideoPageView(assetID: asset.id, isActive: isActive)
        }
    }
}

private struct MediaImagePageView: View {
    let assetID: String
    let containerSize: CGSize

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                ZoomableImageView(
                    image: image,
                    resetID: assetID,
                    containerSize: containerSize
                )
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: assetID) {
            image = await loadFullImage()
        }
    }

    private func loadFullImage() async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            var resumed = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { result, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: result)
            }
        }
    }
}

private struct MediaVideoPageView: View {
    let assetID: String
    let isActive: Bool

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
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)

                    Text(failedToLoad ? "동영상을 불러오지 못했어요" : "동영상을 준비 중이에요")
                        .foregroundStyle(.white)
                }
            }
        }
        .task(id: assetID) {
            isLoading = true
            failedToLoad = false
            player = await loadPlayer()
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

    @MainActor
    private func loadPlayer() async -> AVPlayer? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        let playerItem = await withCheckedContinuation(isolation: MainActor.shared) { continuation in
            var resumed = false
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: item)
            }
        }

        guard let playerItem else { return nil }
        return AVPlayer(playerItem: playerItem)
    }
}

private struct FillWidthPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        controller.showsPlaybackControls = true
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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black

        context.coordinator.configure(scrollView)
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        scrollView.frame = CGRect(origin: .zero, size: containerSize)
        context.coordinator.update(
            image: image,
            resetID: resetID,
            containerSize: containerSize,
            in: scrollView
        )
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        private let imageView = UIImageView()
        private var currentResetID: String?
        private var lastContainerSize: CGSize = .zero

        func configure(_ scrollView: UIScrollView) {
            imageView.contentMode = .scaleToFill
            scrollView.addSubview(imageView)
        }

        func update(
            image: UIImage,
            resetID: String,
            containerSize: CGSize,
            in scrollView: UIScrollView
        ) {
            let needsReset = currentResetID != resetID || lastContainerSize != containerSize
            currentResetID = resetID
            lastContainerSize = containerSize

            imageView.image = image

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
            let fittingWidth = max(containerSize.width, 1)
            let scaledHeight = max(image.size.height * (fittingWidth / max(image.size.width, 1)), 1)

            scrollView.minimumZoomScale = 1
            scrollView.maximumZoomScale = 4
            scrollView.zoomScale = 1

            imageView.frame = CGRect(
                origin: .zero,
                size: CGSize(width: fittingWidth, height: scaledHeight)
            )
            scrollView.contentSize = imageView.frame.size
            centerImage(in: scrollView)
            scrollView.setContentOffset(.zero, animated: false)
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
    }
}
