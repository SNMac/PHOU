//
//  MediaDetailPages.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import SwiftUI
import UIKit
import AVFoundation

struct MediaPageView: View {
    let asset: PhotoAsset
    let viewportSize: CGSize
    let isActive: Bool
    let shouldLoad: Bool
    let isDetailsPanelPresented: Bool
    let backgroundColor: UIColor
    let onSingleTap: () -> Void

    var body: some View {
        switch asset.mediaType {
        case .image, .unknown:
            MediaImagePageView(
                assetID: asset.id,
                containerSize: viewportSize,
                shouldLoad: shouldLoad,
                isDetailsPanelPresented: isDetailsPanelPresented,
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
    let isDetailsPanelPresented: Bool
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
                    isDetailsPanelPresented: isDetailsPanelPresented,
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
                PlayerLayerView(player: player)
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
