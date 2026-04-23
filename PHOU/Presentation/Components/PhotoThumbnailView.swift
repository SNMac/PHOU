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

        let box = ThumbnailContinuationBox()
        let requestIDBox = ThumbnailRequestIDBox()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                box.set(continuation)
                let requestID = Self.imageManager.requestImage(
                    for: asset,
                    targetSize: requestSize,
                    contentMode: .aspectFill,
                    options: options
                ) { result, info in
                    let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                    let isError = info?[PHImageErrorKey] != nil
                    if isCancelled || isError {
                        self.requestID = nil
                        box.resume(nil)
                        return
                    }

                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    if let result, !isDegraded {
                        self.requestID = nil
                        box.resume(result)
                    }
                }
                requestIDBox.set(requestID)
                self.requestID = requestID
            }
        } onCancel: {
            let requestID = requestIDBox.value
            if requestID != PHInvalidImageRequestID {
                Task { @MainActor in
                    Self.imageManager.cancelImageRequest(requestID)
                }
            }
            Task { @MainActor in
                self.requestID = nil
            }
            box.resume(nil)
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

private final class ThumbnailContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<UIImage?, Never>?

    func set(_ continuation: CheckedContinuation<UIImage?, Never>) {
        lock.lock()
        defer { lock.unlock() }
        self.continuation = continuation
    }

    func resume(_ image: UIImage?) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume(returning: image)
    }
}

private final class ThumbnailRequestIDBox: @unchecked Sendable {
    private let lock = NSLock()
    private var requestID: PHImageRequestID = PHInvalidImageRequestID

    var value: PHImageRequestID {
        lock.lock()
        defer { lock.unlock() }
        return requestID
    }

    func set(_ requestID: PHImageRequestID) {
        lock.lock()
        defer { lock.unlock() }
        self.requestID = requestID
    }
}
