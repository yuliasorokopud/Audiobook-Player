import ComposableArchitecture
import SwiftUI

struct BookGridView: View {
    private enum Constant {
        static let bookItemMinimum: CGFloat = 150
    }
    @Bindable var store: StoreOf<BooksListFeature>
    
    let columns = [
        GridItem(.adaptive(minimum: Constant.bookItemMinimum), spacing: UIConstant.Spacing.mediumC)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: UIConstant.Spacing.mediumC) {
                ForEach(store.books) { book in
                    Button {
                        store.send(.bookTapped(book))
                    } label: {
                        BookItemView(url: book.imageUrl)
                    }
                }
            }
            .padding()
        }
        .fullScreenCover(item: $store.scope(state: \.destination?.player, action: \.destination.player)) { playerStore in
            NavigationStack {
                AudioBookPlayerView(store: playerStore)
                    .background(Color("buttercup"))
            }
        }
        .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        .navigationTitle("Books")
        .task {
            store.send(.loadBooks)
        }
    }
}

struct BookItemView: View {
    let url: String
    
    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(UIConstant.Radius.medium)
                .shadow(radius: UIConstant.Radius.medium)
        } placeholder: {
            ProgressView()
        }
    }
}
