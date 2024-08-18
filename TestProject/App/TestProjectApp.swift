import SwiftUI
import ComposableArchitecture

@main
struct TestProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                BookGridView(
                    store: Store(
                        initialState: BooksListFeature.State(),
                        reducer: {
                            BooksListFeature()
                                ._printChanges()
                        }
                    )
                )
                .background(Color("buttercup"))
            }
        }
    }
}
