import ComposableArchitecture
import SwiftUI

struct AudioBookPlayerView: View {
    private enum Constant {
        static let imageWidth: CGFloat = 230
        static let playerProgressViewHeight: CGFloat = 70
    }
    
    var store: StoreOf<PlayerFeature>
    
    var body: some View {
        VStack(spacing: 20) {
            AsyncImage(url: URL(string: store.book.imageUrl)!) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(UIConstant.Radius.medium)
                        .frame(width: Constant.imageWidth)
                case .failure(let error):
                    Image(systemName: "exclamationmark.triangle").padding()
                    Text(error.localizedDescription)
                        .onAppear {
                            print(error.localizedDescription)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .padding(.top, UIConstant.Spacing.largeB * 2)
            
            Text(store.book.chapters[store.currentChapterIndex].keyPointNumber + " of  \(store.book.chapters.count)")
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .padding(.top)
                .bold()
            
            Text(store.book.chapters[store.currentChapterIndex].description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .padding(.horizontal, UIConstant.Spacing.largeA)
            
            VStack {
                PlayerProgressView(
                    store: store.scope(state: \.playerProgress, action: \.playerProgress)
                )
            }
            .frame(height: Constant.playerProgressViewHeight)
            
            PlayerControlView(
                store: store.scope(state: \.playerControl, action: \.playerControl)
            )
            
            BookModeToggle(store: store)
                .padding(.top, UIConstant.Spacing.largeA)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(store: store.scope(state: \.$alert, action: \.alert))
        .ignoresSafeArea()
        .task {
            store.send(.loadAudio)
        }
    }
}
