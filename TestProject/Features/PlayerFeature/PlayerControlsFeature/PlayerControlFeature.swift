import ComposableArchitecture
import SwiftUI

@Reducer
struct PlayerControlFeature {
    @ObservableState
    struct State: Equatable {
        var chapter: Chapter
        var isPlaying = false
        var isLoading = false
        var isPreviousChapterButtonDisabled: Bool = true
        var isNextChapterButtonDisabled: Bool = false
    }
    
    enum Action {
        case previousChapterButtonTapped
        case seekBackward
        case togglePlayPause
        case seekForward
        case nextChapterButtonTapped
    }
}

struct PlayerControlView: View {
    enum Constant {
        static let previousChapterImage = "backward.end.fill"
        static let seekBackwardImage = "gobackward.5"
        static let playImage = "play.fill"
        static let pauseImage = "pause.fill"
        static let seekForwardImage = "goforward.10"
        static let nextChapterImage = "forward.end.fill"
        
        static let playButtonPreservedSpace: CGFloat = 30
        static let viewheight: CGFloat = 40
    }
    let store: StoreOf<PlayerControlFeature>
    
    var body: some View {
        HStack(spacing: UIConstant.Spacing.largeA) {
            Button(action: {
                store.send(.previousChapterButtonTapped)
            }) {
                Image(systemName: Constant.previousChapterImage)
                    .font(.title2)
                    .foregroundColor(store.isPreviousChapterButtonDisabled ? .gray : .black)
            }
            .disabled(store.isPreviousChapterButtonDisabled)
            Button(action: {
                store.send(.seekBackward)
            }) {
                Image(systemName: Constant.seekBackwardImage)
                    .font(.title2)
                    .foregroundColor(.black)
            }
            Button(action: {
                store.send(.togglePlayPause)
            }) {
                if store.isLoading {
                    ProgressView()
                }
                
                else {
                    Image(systemName: store.isPlaying ? Constant.pauseImage : Constant.playImage)
                        .font(.largeTitle)
                        .foregroundColor(.black)
                        .bold()
                }
            }
            .frame(width: Constant.playButtonPreservedSpace)
            
            Button(action: {
                store.send(.seekForward)
            }) {
                Image(systemName: Constant.seekForwardImage)
                    .font(.title2)
                    .foregroundColor(.black)
            }
            Button(action: {
                store.send(.nextChapterButtonTapped)
            }) {
                Image(systemName: Constant.nextChapterImage)
                    .font(.title2)
                    .foregroundColor(store.isNextChapterButtonDisabled ? .gray : .black)
            }
            .disabled(store.isNextChapterButtonDisabled)
        }
        .frame(height: Constant.viewheight)
    }
}
