import ComposableArchitecture
import SwiftUI

@Reducer
struct PlayerProgressFeature {
    @ObservableState
    struct State: Equatable {
        var draggedTime: TimeInterval?
        var currentTime: TimeInterval = 0
        var audioDuration: TimeInterval = 0
        var speed: Double = 1
        var isLoading = false
    }
    
    enum Action {
        case speedButtonTapped
        case updateCurrentTime(TimeInterval)
        case editingMode(Bool)
    }
}

struct PlayerProgressView: View {
    enum Constant {
        static let timeStringWidth: CGFloat = 50
        static let viewHeight: CGFloat = 50
    }
    
    let store: StoreOf<PlayerProgressFeature>
    
    var body: some View {
        VStack {
            if !store.isLoading {
                HStack(spacing: UIConstant.Spacing.smallB) {
                    Text(store.draggedTime?.timeString ?? store.currentTime.timeString)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: Constant.timeStringWidth, alignment: .leading)
                    
                    Slider(
                        value: Binding(
                            get: { store.draggedTime ?? store.currentTime },
                            set: { newValue in
                                store.send(.updateCurrentTime(newValue))
                            }
                        ),
                        in : .zero...store.audioDuration) { isEditing in
                            store.send(.editingMode(isEditing))
                        }
                    
                    Text(store.audioDuration.timeString)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(width: Constant.timeStringWidth, alignment: .trailing)
                }
                .padding(.horizontal)
                
                Button(action: {
                    store.send(.speedButtonTapped)
                }) {
                    Text("Speed " + store.speed.formattedCurrentRate + "x")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, UIConstant.Spacing.mediumA)
                        .padding(.vertical, UIConstant.Spacing.smallC)
                        .background(Color.gray.opacity(UIConstant.Alpha.almostClear))
                        .tint(.black)
                        .cornerRadius(UIConstant.Radius.small)
                        .padding(.bottom, UIConstant.Spacing.largeA)
                }
            }
        }
        .frame(height: Constant.viewHeight)
    }
}
