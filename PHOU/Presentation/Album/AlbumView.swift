import ComposableArchitecture
import SwiftUI

struct AlbumView: View {
    let store: StoreOf<AlbumFeature>

    var body: some View {
        NavigationStack {
            ContentUnavailableView("앨범", systemImage: "photo.on.rectangle", description: Text("앨범 기능을 준비 중입니다."))
                .navigationTitle("앨범")
        }
    }
}
