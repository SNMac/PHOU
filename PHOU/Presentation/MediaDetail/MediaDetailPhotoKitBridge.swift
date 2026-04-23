//
//  MediaDetailPhotoKitBridge.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import UIKit
import AVFoundation
import ImageIO
@preconcurrency import Photos

enum MediaDetailPhotoKitBridge {
    private static let imageManager = PHCachingImageManager()
    private static let resourceManager = PHAssetResourceManager.default()

    struct ImageDeviceMetadata: Sendable {
        let make: String?
        let model: String?
        let ownerName: String?
    }

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

    static func requestImageDeviceMetadata(
        for resource: PHAssetResource,
        options: PHAssetResourceRequestOptions,
        probeByteLimit: Int = 512 * 1024
    ) async -> ImageDeviceMetadata? {
        let box = ImagePropertiesContinuationBox()
        let requestIDBox = ResourceRequestIDBox()
        let incrementalSource = CGImageSourceCreateIncremental(nil)
        let accumulatedData = NSMutableData()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<ImageDeviceMetadata?, Never>) in
                box.set(continuation)

                let requestID = resourceManager.requestData(
                    for: resource,
                    options: options,
                    dataReceivedHandler: { chunk in
                        if box.hasResumed {
                            return
                        }

                        accumulatedData.append(chunk)
                        CGImageSourceUpdateData(
                            incrementalSource,
                            accumulatedData as CFMutableData,
                            false
                        )

                        if let properties = CGImageSourceCopyPropertiesAtIndex(incrementalSource, 0, nil) as? [CFString: Any] {
                            box.resume(deviceMetadata(from: properties))
                            let requestID = requestIDBox.value
                            if requestID != 0 {
                                resourceManager.cancelDataRequest(requestID)
                            }
                            return
                        }

                        if accumulatedData.length >= probeByteLimit {
                            box.resume(nil)
                            let requestID = requestIDBox.value
                            if requestID != 0 {
                                resourceManager.cancelDataRequest(requestID)
                            }
                        }
                    },
                    completionHandler: { error in
                        if error != nil {
                            if box.hasResumed {
                                return
                            }
                            box.resume(nil)
                            return
                        }

                        CGImageSourceUpdateData(
                            incrementalSource,
                            accumulatedData as CFMutableData,
                            true
                        )
                        let properties = CGImageSourceCopyPropertiesAtIndex(incrementalSource, 0, nil) as? [CFString: Any]
                        box.resume(properties.flatMap(deviceMetadata(from:)))
                    }
                )
                requestIDBox.set(requestID)
            }
        } onCancel: {
            let requestID = requestIDBox.value
            if requestID != 0 {
                resourceManager.cancelDataRequest(requestID)
            }
            box.resume(nil)
        }
    }

    private static func deviceMetadata(from properties: [CFString: Any]) -> ImageDeviceMetadata {
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]

        return ImageDeviceMetadata(
            make: trimmedText(tiff?[kCGImagePropertyTIFFMake] as? String),
            model: trimmedText(tiff?[kCGImagePropertyTIFFModel] as? String),
            ownerName: trimmedText(exif?[kCGImagePropertyExifCameraOwnerName] as? String)
        )
    }

    private static func trimmedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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

private final class ImagePropertiesContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<MediaDetailPhotoKitBridge.ImageDeviceMetadata?, Never>?

    var hasResumed: Bool {
        lock.lock()
        defer { lock.unlock() }
        return continuation == nil
    }

    func set(_ continuation: CheckedContinuation<MediaDetailPhotoKitBridge.ImageDeviceMetadata?, Never>) {
        lock.lock()
        defer { lock.unlock() }
        self.continuation = continuation
    }

    func resume(_ properties: MediaDetailPhotoKitBridge.ImageDeviceMetadata?) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume(returning: properties)
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

private final class ResourceRequestIDBox: @unchecked Sendable {
    private let lock = NSLock()
    private var requestID: PHAssetResourceDataRequestID = 0

    var value: PHAssetResourceDataRequestID {
        lock.lock()
        defer { lock.unlock() }
        return requestID
    }

    func set(_ requestID: PHAssetResourceDataRequestID) {
        lock.lock()
        defer { lock.unlock() }
        self.requestID = requestID
    }
}
