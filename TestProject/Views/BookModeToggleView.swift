import ComposableArchitecture
import SwiftUI

struct BookModeToggle: View {
    var store: StoreOf<PlayerFeature>

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Toggle(isOn: viewStore.binding(
                get: \.currentPage.isPlayer,
                send: { _ in .togglePage}
            )) {
                EmptyView()
            }
            .toggleStyle(CheckmarkToggleStyle())
            .padding(.horizontal)
            .padding(.bottom, UIConstant.Spacing.largeA)
        }
    }
}

