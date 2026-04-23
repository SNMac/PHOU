//
//  PhotoThumbnailView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import SwiftUI
import UIKit
@preconcurrency import Photos

struct PhotoThumbnailView: View {
    let id: String
    let targetSize: CGSize

    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?

    private static let imageManager = PHCachingImageManager()
    private static let assetCache = NSCache<NSString, PHAsset>()

    private var requestKey: ThumbnailRequestKey {
        let scale = UIScreen.main.scale
        return ThumbnailRequestKey(
            id: id,
            pixelWidth: Int((targetSize.width * scale).rounded()),
            pixelHeight: Int((targetSize.height * scale).rounded())
        )
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(uiColor: .secondarySystemBackground)
            }
        }
        .task(id: requestKey) {
            image = await loadThumbnail()
        }
        .onDisappear {
            cancelThumbnailRequest()
            image = nil
        }
    }

    private func loadThumbnail() async -> UIImage? {
        cancelThumbnailRequest()

        let requestSize = resolvedTargetSize()
        guard requestSize.width > 0, requestSize.height > 0 else { return nil }
        guard let asset = resolvedAsset() else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            var resumed = false
            requestID = Self.imageManager.requestImage(
                for: asset,
                targetSize: requestSize,
                contentMode: .aspectFill,
                options: options
            ) { result, info in
                let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                guard !isCancelled else { return }
                guard !resumed else { return }
                resumed = true
                requestID = nil
                continuation.resume(returning: result)
            }
        }
    }

    private func cancelThumbnailRequest() {
        guard let requestID else { return }
        Self.imageManager.cancelImageRequest(requestID)
        self.requestID = nil
    }

    private func resolvedAsset() -> PHAsset? {
        let cacheKey = id as NSString
        if let asset = Self.assetCache.object(forKey: cacheKey) {
            return asset
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        Self.assetCache.setObject(asset, forKey: cacheKey)
        return asset
    }

    private func resolvedTargetSize() -> CGSize {
        let scale = UIScreen.main.scale
        return CGSize(
            width: max(targetSize.width * scale, 1),
            height: max(targetSize.height * scale, 1)
        )
    }
}

private struct ThumbnailRequestKey: Hashable {
    let id: String
    let pixelWidth: Int
    let pixelHeight: Int
}
