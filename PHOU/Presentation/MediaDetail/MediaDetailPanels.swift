//
//  MediaDetailPanels.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import SwiftUI

struct MediaDetailsScrollSection: View {
    let details: MediaAssetDetails?
    let layout: MediaDetailLayout

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            if let details {
                MediaInlineInfoContent(details: details)
                    .padding(.bottom, layout.detailsBottomPadding)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(minHeight: layout.detailsSectionMinHeight, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)
                .padding(.top, 54)
        }
    }
}

private struct MediaInlineInfoContent: View {
    let details: MediaAssetDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("캡션 추가")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            Divider()
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 12) {
                Text(details.captureDateText)
                    .font(.title2.weight(.semibold))

                infoLine(systemImage: "checkmark.square", text: details.filenameText)
                infoLine(systemImage: "camera", text: details.deviceText)
                infoLine(systemImage: "arrow.up.left.and.down.right.magnifyingglass", text: details.pixelSizeText)
                infoLine(systemImage: "mappin.and.ellipse", text: details.locationText)
                infoLine(systemImage: "rectangle.stack.badge.person.crop", text: details.albumText)
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 6)
    }

    private func infoLine(systemImage: String, text: String) -> some View {
        Label {
            Text(text)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
        .font(.body)
    }
}

struct MediaDetailLayout {
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets

    var viewportSize: CGSize {
        CGSize(
            width: max(containerSize.width, 1),
            height: max(containerSize.height, 1)
        )
    }

    var detailsSectionMinHeight: CGFloat {
        max(containerSize.height * 0.72, 520)
    }

    var detailsBottomPadding: CGFloat {
        max(safeAreaInsets.bottom + 96, 120)
    }
}

struct AlbumPickerSheet: View {
    let albums: [AlbumGroup]
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(albums.enumerated()), id: \.element.id) { _, album in
                    Button {
                        onSelect(album.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(album.title)
                                    .foregroundStyle(.primary)
                                Text("\(album.assetCount)개")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("앨범에 추가")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
