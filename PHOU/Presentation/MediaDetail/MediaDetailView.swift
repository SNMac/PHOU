//
//  MediaDetailView.swift
//  PHOU
//
//  Created by Codex on 4/23/26.
//

import SwiftUI
import AVKit
import ComposableArchitecture
@preconcurrency import Photos

struct MediaDetailView: View {
    @Bindable var store: StoreOf<MediaDetailFeature>

    var body: some View {
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
                    MediaPageView(asset: asset)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            topBar
        }
        .preferredColorScheme(.dark)
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

    var body: some View {
        switch asset.mediaType {
        case .image, .unknown:
            MediaImagePageView(assetID: asset.id)
        case .video:
            MediaVideoPageView(assetID: asset.id)
        }
    }
}

private struct MediaImagePageView: View {
    let assetID: String

    @State private var image: UIImage?
    @State private var baseScale: CGFloat = 1
    @State private var pinchScale: CGFloat = 1

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(displayScale)
                    .gesture(magnificationGesture)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .padding(.horizontal, 12)
        .task(id: assetID) {
            baseScale = 1
            pinchScale = 1
            image = await loadFullImage()
        }
    }

    private var displayScale: CGFloat {
        min(max(baseScale * pinchScale, 1), 4)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                pinchScale = value
            }
            .onEnded { value in
                baseScale = min(max(baseScale * value, 1), 4)
                pinchScale = 1
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

    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var failedToLoad = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
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
            player?.play()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func loadPlayer() async -> AVPlayer? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat

        let url = await withCheckedContinuation { continuation in
            var resumed = false
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: (avAsset as? AVURLAsset)?.url)
            }
        }

        guard let url else { return nil }
        return AVPlayer(url: url)
    }
}
