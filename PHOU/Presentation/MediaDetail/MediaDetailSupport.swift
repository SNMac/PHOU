//
//  MediaDetailSupport.swift
//  PHOU
//
//  Created by Codex on 4/23/26.
//

import SwiftUI
import UIKit
import AVFoundation
import CoreLocation
import ImageIO
@preconcurrency import Photos

struct MediaAssetDetails: Equatable, Identifiable {
    let id: String
    let titlePrimaryText: String
    let titleSecondaryText: String
    let captureDateText: String
    let locationText: String
    let filenameText: String
    let deviceText: String
    let albumText: String
    let isFavorite: Bool
    let mediaTypeText: String
    let pixelSizeText: String

    static func placeholder(for asset: PhotoAsset) -> Self {
        let title = titleTexts(
            date: asset.creationDate,
            locationText: nil
        )
        return Self(
            id: asset.id,
            titlePrimaryText: title.primary,
            titleSecondaryText: title.secondary,
            captureDateText: Self.formattedInfoDate(asset.creationDate),
            locationText: "위치 없음",
            filenameText: "정보 확인 중",
            deviceText: "정보 확인 중",
            albumText: "정보 확인 중",
            isFavorite: asset.isFavorite,
            mediaTypeText: Self.mediaTypeText(asset.mediaType),
            pixelSizeText: "-"
        )
    }

    static func titleTexts(date: Date?, locationText: String?) -> (primary: String, secondary: String) {
        let formattedDate = formattedTitleDate(date)
        let formattedTime = formattedTime(date)

        guard let locationText, locationText != "위치 없음" else {
            return (formattedDate, formattedTime)
        }

        return (locationText, "\(formattedDate) \(formattedTime)")
    }

    static func formattedInfoDate(_ date: Date?) -> String {
        guard let date else { return "날짜 없음" }
        return DateFormatter.mediaDetailInfoDate.string(from: date)
    }

    static func mediaTypeText(_ mediaType: PhotoAsset.MediaType) -> String {
        switch mediaType {
        case .image:
            return "사진"
        case .video:
            return "동영상"
        case .unknown:
            return "미디어"
        }
    }
}

struct MediaInfoItem: Identifiable {
    let id = UUID()
    let details: MediaAssetDetails
}

enum MediaDetailAssetLoader {
    private static let imageManager = PHCachingImageManager()
    nonisolated(unsafe) private static let assetCache = NSCache<NSString, PHAsset>()
    nonisolated(unsafe) private static let imageCache = NSCache<NSString, UIImage>()
    nonisolated(unsafe) private static let locationCache = NSCache<NSString, NSString>()

    static func displayImage(for assetID: String, targetSize: CGSize) async -> UIImage? {
        let requestSize = await pixelSize(from: targetSize)
        let cacheKey = imageCacheKey(assetID: assetID, requestSize: requestSize)
        if let cached = imageCache.object(forKey: cacheKey as NSString) {
            return cached
        }

        guard let asset = asset(for: assetID) else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        if let image = await requestImage(
            for: asset,
            targetSize: requestSize,
            contentMode: .aspectFit,
            options: options
        ) {
            imageCache.setObject(image, forKey: cacheKey as NSString)
            return image
        }

        return nil
    }

    static func playerItem(for assetID: String) async -> AVPlayerItem? {
        guard let asset = asset(for: assetID) else { return nil }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic

        return await requestPlayerItem(for: asset, options: options)
    }

    static func summaryDetails(for asset: PhotoAsset) async -> MediaAssetDetails {
        guard let phAsset = self.asset(for: asset.id) else {
            return .placeholder(for: asset)
        }

        let captureDate = phAsset.creationDate ?? asset.creationDate
        let locationText = await resolvedLocationText(for: asset.id, location: phAsset.location)
        let title = MediaAssetDetails.titleTexts(
            date: captureDate,
            locationText: locationText == "위치 없음" ? nil : locationText
        )

        return MediaAssetDetails(
            id: asset.id,
            titlePrimaryText: title.primary,
            titleSecondaryText: title.secondary,
            captureDateText: MediaAssetDetails.formattedInfoDate(captureDate),
            locationText: locationText,
            filenameText: resolvedFilename(for: phAsset),
            deviceText: "상세정보에서 확인 가능",
            albumText: "상세정보에서 확인 가능",
            isFavorite: phAsset.isFavorite,
            mediaTypeText: MediaAssetDetails.mediaTypeText(asset.mediaType),
            pixelSizeText: "\(phAsset.pixelWidth) × \(phAsset.pixelHeight)"
        )
    }

    static func details(for asset: PhotoAsset) async -> MediaAssetDetails {
        guard let phAsset = self.asset(for: asset.id) else {
            return .placeholder(for: asset)
        }

        let summary = await summaryDetails(for: asset)
        async let deviceTextTask = resolvedDeviceText(for: phAsset)
        async let albumTextTask = resolvedAlbumText(for: phAsset)

        return MediaAssetDetails(
            id: summary.id,
            titlePrimaryText: summary.titlePrimaryText,
            titleSecondaryText: summary.titleSecondaryText,
            captureDateText: summary.captureDateText,
            locationText: summary.locationText,
            filenameText: summary.filenameText,
            deviceText: await deviceTextTask,
            albumText: await albumTextTask,
            isFavorite: summary.isFavorite,
            mediaTypeText: summary.mediaTypeText,
            pixelSizeText: summary.pixelSizeText
        )
    }

    static func shareItems(for asset: PhotoAsset) async -> [Any]? {
        guard let phAsset = self.asset(for: asset.id) else { return nil }

        switch asset.mediaType {
        case .image, .unknown:
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            guard let image = await requestImage(
                for: phAsset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) else { return nil }
            return [image]

        case .video:
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat

            guard let url = await requestVideoURL(for: phAsset, options: options) else { return nil }
            return [url]
        }
    }

    static func asset(for assetID: String) -> PHAsset? {
        let cacheKey = assetID as NSString
        if let cached = assetCache.object(forKey: cacheKey) {
            return cached
        }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }
        assetCache.setObject(asset, forKey: cacheKey)
        return asset
    }

    private static func resolvedLocationText(for assetID: String, location: CLLocation?) async -> String {
        if let cached = locationCache.object(forKey: assetID as NSString) {
            return cached as String
        }

        guard let location else {
            locationCache.setObject("위치 없음", forKey: assetID as NSString)
            return "위치 없음"
        }

        let fallback = coordinateText(for: location)

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let resolved = detailedLocationText(from: placemark) ?? fallback
                locationCache.setObject(resolved as NSString, forKey: assetID as NSString)
                return resolved
            }
        } catch {
            // Fall through to coordinates.
        }

        locationCache.setObject(fallback as NSString, forKey: assetID as NSString)
        return fallback
    }

    private static func detailedLocationText(from placemark: CLPlacemark) -> String? {
        let administrativeArea = normalizedText(placemark.administrativeArea)
        let locality = normalizedText(placemark.locality)
        let subLocality = normalizedText(placemark.subLocality)
        let thoroughfare = normalizedText(placemark.thoroughfare)
        let name = normalizedText(placemark.name)

        let prefersAdministrativeArea = administrativeArea.map {
            $0.contains("특별시") || $0.contains("광역시") || $0.contains("특별자치시")
        } ?? false

        let primary = deduplicatedLocationComponent(
            prefersAdministrativeArea ? administrativeArea : locality,
            fallback: administrativeArea ?? locality
        )

        let neighborhood = preferredNeighborhoodText(subLocality: subLocality, name: name)

        let secondary = [neighborhood, thoroughfare, name]
            .compactMap { $0 }
            .first { candidate in
                guard let primary else { return !candidate.isEmpty }
                return candidate != primary && !candidate.contains(primary)
            }

        if let primary, let secondary {
            return "\(primary) - \(secondary)"
        }

        return primary ?? secondary
    }

    private static func preferredNeighborhoodText(subLocality: String?, name: String?) -> String? {
        guard let subLocality else {
            return neighborhoodLikeText(from: name)
        }

        guard
            let name,
            isMoreSpecificNeighborhood(name, than: subLocality)
        else {
            return subLocality
        }

        return name
    }

    private static func neighborhoodLikeText(from value: String?) -> String? {
        guard let value else { return nil }
        let suffixes = ["동", "가", "리", "읍", "면"]
        return suffixes.contains(where: value.hasSuffix) ? value : nil
    }

    private static func isMoreSpecificNeighborhood(_ candidate: String, than base: String) -> Bool {
        let normalizedCandidate = candidate.replacingOccurrences(
            of: "\\d+",
            with: "",
            options: .regularExpression
        )
        let normalizedBase = base.replacingOccurrences(
            of: "\\d+",
            with: "",
            options: .regularExpression
        )

        guard normalizedCandidate == normalizedBase else { return false }
        return candidate != base
    }

    private static func deduplicatedLocationComponent(_ preferred: String?, fallback: String?) -> String? {
        if let preferred {
            return preferred
        }
        return fallback
    }

    private static func normalizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func resolvedFilename(for asset: PHAsset) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let preferred = resources.first { resource in
            switch resource.type {
            case .fullSizePhoto, .photo, .fullSizeVideo, .video:
                return true
            default:
                return false
            }
        }

        return preferred?.originalFilename ?? resources.first?.originalFilename ?? "파일명 없음"
    }

    private static func resolvedAlbumText(for asset: PHAsset) -> String {
        var titles: [String] = []

        for collectionType in [PHAssetCollectionType.smartAlbum, .album] {
            let collections = PHAssetCollection.fetchAssetCollectionsContaining(
                asset,
                with: collectionType,
                options: nil
            )

            collections.enumerateObjects { collection, _, _ in
                guard let title = normalizedText(collection.localizedTitle) else { return }
                if !titles.contains(title) {
                    titles.append(title)
                }
            }
        }

        return titles.isEmpty ? "앨범 정보 없음" : titles.joined(separator: ", ")
    }

    private static func resolvedDeviceText(for asset: PHAsset) async -> String {
        guard asset.mediaType == .image else {
            return "정보 없음"
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        guard
            let data = await requestImageData(for: asset, options: options),
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return "정보 없음"
        }

        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let make = normalizedText(tiff?[kCGImagePropertyTIFFMake] as? String)
        let model = normalizedText(tiff?[kCGImagePropertyTIFFModel] as? String)

        if let model, let make {
            return model.contains(make) ? model : "\(make) \(model)"
        }

        return model ?? make ?? "정보 없음"
    }

    private static func coordinateText(for location: CLLocation) -> String {
        let latitude = String(format: "%.4f", location.coordinate.latitude)
        let longitude = String(format: "%.4f", location.coordinate.longitude)
        return "\(latitude), \(longitude)"
    }

    private static func imageCacheKey(assetID: String, requestSize: CGSize) -> String {
        "\(assetID)-\(Int(requestSize.width))x\(Int(requestSize.height))"
    }

    @MainActor
    private static func pixelSize(from size: CGSize) -> CGSize {
        let scale = max(UIScreen.main.scale, 1)
        return CGSize(width: max(size.width * scale, 1), height: max(size.height * scale, 1))
    }

    private static func requestImage(
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

    private static func requestPlayerItem(
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

    private static func requestVideoURL(
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

    private static func requestImageData(
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

private extension DateFormatter {
    static let mediaDetailTitleWeekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    static let mediaDetailTitleMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter
    }()

    static let mediaDetailTitleYearMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }()

    static let mediaDetailInfoDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = mediaDetailUses24HourTime ? "yyyy년 M월 d일 EEEE H:mm" : "yyyy년 M월 d일 EEEE a h:mm"
        return formatter
    }()

    static let mediaDetailTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = mediaDetailUses24HourTime ? "H:mm" : "a h:mm"
        return formatter
    }()
}

private let mediaDetailUses24HourTime: Bool = {
    let format = DateFormatter.dateFormat(
        fromTemplate: "j",
        options: 0,
        locale: .autoupdatingCurrent
    ) ?? ""
    return !format.contains("a")
}()

private extension MediaAssetDetails {
    static func formattedTitleDate(_ date: Date?) -> String {
        guard let date else { return "날짜 없음" }

        let calendar = Calendar.autoupdatingCurrent
        let now = Date()

        if let recentBoundary = calendar.date(byAdding: .day, value: -6, to: now) {
            let start = calendar.startOfDay(for: recentBoundary)
            if date >= start {
                return DateFormatter.mediaDetailTitleWeekday.string(from: date)
            }
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            return DateFormatter.mediaDetailTitleMonthDay.string(from: date)
        }

        return DateFormatter.mediaDetailTitleYearMonthDay.string(from: date)
    }

    static func formattedTime(_ date: Date?) -> String {
        guard let date else { return "시간 없음" }
        return DateFormatter.mediaDetailTime.string(from: date)
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {
        // No-op
    }
}
