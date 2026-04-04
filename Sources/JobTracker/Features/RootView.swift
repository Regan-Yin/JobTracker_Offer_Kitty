import AppKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            JobTrackerTheme.background
                .ignoresSafeArea()

            Group {
                if appState.onboardingCompleted {
                    MainSplitView()
                } else {
                    OnboardingView()
                }
            }
        }
        // Do not use `.preferredColorScheme` here. It can change the process
        // effective appearance so macOS selects the wrong App Icon variant in
        // Dock/Finder. The UI colors come from `JobTrackerTheme` + `appearanceMode`
        // explicitly; system chrome follows the OS for icon selection when
        // `NSApp.appearance` is left unset (see `JobTrackerApp` / `AppDelegate`).
    }
}
