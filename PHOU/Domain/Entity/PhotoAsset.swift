//
//  PhotoAsset.swift
//  PHOU
//
//  Created by 서동환 on 4/22/26.
//

import Foundation

struct PhotoAsset: Identifiable, Equatable, Sendable {
    let id: String
    let creationDate: Date?
    let isFavorite: Bool
    let mediaType: MediaType

    enum MediaType: Equatable, Sendable {
        case image, video, unknown
    }
}
