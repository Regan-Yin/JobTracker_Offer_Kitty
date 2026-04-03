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
        .preferredColorScheme(appState.appearanceMode == .light ? .light : .dark)
    }
}
