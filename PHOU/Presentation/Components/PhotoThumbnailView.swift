//
//  PhotoThumbnailView.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

@preconcurrency import Photos
import SwiftUI

struct PhotoThumbnailView: View {
    let id: String
    @State private var image: UIImage?

    private static let targetSize = CGSize(width: 300, height: 300)

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
        .task(id: id) {
            image = await loadThumbnail()
        }
    }

    private func loadThumbnail() async -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: Self.targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, _ in
                continuation.resume(returning: result)
            }
        }
    }
}
