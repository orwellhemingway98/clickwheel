import SwiftUI

@main
struct ClickWheelApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The iPod lives in a borderless window created by AppDelegate.
        Settings { EmptyView() }
    }
}
