//
//  MediaDetailPanels.swift
//  PHOU
//
//  Created by Codex on 4/24/26.
//

import SwiftUI

struct MediaDetailsPanel: View {
    let details: MediaAssetDetails?
    let layout: MediaDetailLayout
    let isPresented: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let details {
                ScrollView(showsIndicators: false) {
                    MediaInlineInfoContent(details: details)
                        .padding(.bottom, layout.detailsBottomPadding)
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: layout.panelHeight, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .offset(y: isPresented ? 0 : layout.panelHiddenOffset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(isPresented)
        .highPriorityGesture(detailsDismissGesture)
    }

    private var detailsDismissGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard value.translation.height > 48 else { return }
                onDismiss()
            }
    }
}

private struct MediaInlineInfoContent: View {
    let details: MediaAssetDetails

    private let horizontalPadding: CGFloat = 24
    private let iconWidth: CGFloat = 28
    private let titleHeight: CGFloat = 34
    private let rowHeight: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(details.captureDateText)
                .font(.title2.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: titleHeight, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                infoLine(systemImage: "checkmark.square", text: details.filenameText)
                infoLine(systemImage: "camera", text: details.deviceText)
                infoLine(systemImage: "arrow.up.left.and.down.right.magnifyingglass", text: details.pixelSizeText)
                infoLine(systemImage: "mappin.and.ellipse", text: details.locationText)
                infoLine(systemImage: "rectangle.stack.badge.person.crop", text: details.albumText)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 24)
    }

    private func infoLine(systemImage: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: iconWidth, alignment: .center)

            Text(text)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.body)
        .frame(height: rowHeight)
        .accessibilityLabel(text)
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

    var panelHeight: CGFloat {
        min(max(containerSize.height * 0.46, 300), 430)
    }

    var detailsBottomPadding: CGFloat {
        max(safeAreaInsets.bottom + 96, 120)
    }

    var panelHiddenOffset: CGFloat {
        panelHeight + safeAreaInsets.bottom + 24
    }

    var mediaLift: CGFloat {
        min(max(panelHeight * 0.62, 180), containerSize.height * 0.34)
    }
}

struct AlbumPickerSheet: View {
    let albums: [AlbumGroup]
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(albums) { album in
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
