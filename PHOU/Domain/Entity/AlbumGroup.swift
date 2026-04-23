//
//  AlbumGroup.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import Foundation

struct AlbumGroup: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let assetCount: Int
    let coverAssetId: String?
    let albumType: AlbumType

    enum AlbumType: Equatable, Sendable {
        case smartAlbum, userAlbum
    }
}
