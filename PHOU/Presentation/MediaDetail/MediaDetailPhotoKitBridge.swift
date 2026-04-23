//
//  MediaDetailPhotoKitBridge.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import UIKit
import AVFoundation
@preconcurrency import Photos

enum MediaDetailPhotoKitBridge {
    private static let imageManager = PHCachingImageManager()

    static func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions
    ) async -> UIImage? {
        let box = ImageContinuationBox()
        let requestIDBox = RequestIDBox()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                box.set(continuation)
                let requestID = imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: contentMode,
                    options: options
                ) { result, info in
                    let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                    let isError = info?[PHImageErrorKey] != nil
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false

                    if isCancelled || isError {
                        box.resume(nil)
                        return
                    }

                    if let result, !isDegraded {
                        box.resume(result)
                        return
                    }

                    if let result, options.deliveryMode == .highQualityFormat {
                        box.resume(result)
                    }
                }
                requestIDBox.set(requestID)
            }
        } onCancel: {
            let requestID = requestIDBox.value
            if requestID != PHInvalidImageRequestID {
                Task { @MainActor in
                    imageManager.cancelImageRequest(requestID)
                }
            }
            box.resume(nil)
        }
    }

    static func requestPlayerItem(
        for asset: PHAsset,
        options: PHVideoRequestOptions
    ) async -> AVPlayerItem? {
        let box = PlayerItemContinuationBox()
        let requestIDBox = RequestIDBox()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                box.set(continuation)
                let requestID = imageManager.requestPlayerItem(forVideo: asset, options: options) { item, info in
                    let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                    let isError = info?[PHImageErrorKey] != nil
                    if isCancelled || isError {
                        box.resume(nil)
                        return
                    }
                    box.resume(item)
                }
                requestIDBox.set(requestID)
            }
        } onCancel: {
            let requestID = requestIDBox.value
            if requestID != PHInvalidImageRequestID {
                Task { @MainActor in
                    imageManager.cancelImageRequest(requestID)
                }
            }
            box.resume(nil)
        }
    }

    static func requestVideoURL(
        for asset: PHAsset,
        options: PHVideoRequestOptions
    ) async -> URL? {
        let box = URLContinuationBox()
        let requestIDBox = RequestIDBox()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                box.set(continuation)
                let requestID = imageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                    let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                    let isError = info?[PHImageErrorKey] != nil
                    if isCancelled || isError {
                        box.resume(nil)
                        return
                    }
                    box.resume((avAsset as? AVURLAsset)?.url)
                }
                requestIDBox.set(requestID)
            }
        } onCancel: {
            let requestID = requestIDBox.value
            if requestID != PHInvalidImageRequestID {
                Task { @MainActor in
                    imageManager.cancelImageRequest(requestID)
                }
            }
            box.resume(nil)
        }
    }

    static func requestImageData(
        for asset: PHAsset,
        options: PHImageRequestOptions
    ) async -> Data? {
        let box = DataContinuationBox()
        let requestIDBox = RequestIDBox()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                box.set(continuation)
                let requestID = imageManager.requestImageDataAndOrientation(for: asset, options: options) {
                    data,
                    _,
                    _,
                    info in
                    let isCancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                    let isError = info?[PHImageErrorKey] != nil
                    if isCancelled || isError {
                        box.resume(nil)
                        return
                    }
                    box.resume(data)
                }
                requestIDBox.set(requestID)
            }
        } onCancel: {
            let requestID = requestIDBox.value
            if requestID != PHInvalidImageRequestID {
                Task { @MainActor in
                    imageManager.cancelImageRequest(requestID)
                }
            }
            box.resume(nil)
        }
    }
}

private final class ImageContinuationBox: @unchecked Sendable {
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

private final class PlayerItemContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<AVPlayerItem?, Never>?

    func set(_ continuation: CheckedContinuation<AVPlayerItem?, Never>) {
        lock.lock()
        defer { lock.unlock() }
        self.continuation = continuation
    }

    func resume(_ item: AVPlayerItem?) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume(returning: item)
    }
}

private final class URLContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<URL?, Never>?

    func set(_ continuation: CheckedContinuation<URL?, Never>) {
        lock.lock()
        defer { lock.unlock() }
        self.continuation = continuation
    }

    func resume(_ url: URL?) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume(returning: url)
    }
}

private final class DataContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data?, Never>?

    func set(_ continuation: CheckedContinuation<Data?, Never>) {
        lock.lock()
        defer { lock.unlock() }
        self.continuation = continuation
    }

    func resume(_ data: Data?) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume(returning: data)
    }
}

private final class RequestIDBox: @unchecked Sendable {
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
