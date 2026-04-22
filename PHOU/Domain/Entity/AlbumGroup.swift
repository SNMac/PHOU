import Foundation

struct AlbumGroup: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let assetCount: Int
    let albumType: AlbumType

    enum AlbumType: Equatable, Sendable {
        case smartAlbum, userAlbum
    }
}
