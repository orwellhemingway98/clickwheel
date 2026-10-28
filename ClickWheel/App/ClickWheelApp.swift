import SwiftUI

@main
struct ClickWheelApp: App {
    private let model: AppModel? = AppModel.isRunningTests ? nil : AppModel()

    var body: some Scene {
        WindowGroup {
            if let model {
                IPodView()
                    .environmentObject(model.settings)
                    .environmentObject(model.hub)
                    .environmentObject(model.navigator)
                    .environmentObject(model.artwork)
                    .padding(20)
                    .task { model.renderSnapshotIfRequested() }
            }
        }
        .windowResizability(.contentSize)
    }
}
