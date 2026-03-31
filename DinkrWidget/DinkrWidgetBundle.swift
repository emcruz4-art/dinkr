// DinkrWidgetBundle.swift
// DinkrWidget — @main entry point; registers all widget kinds

import WidgetKit
import SwiftUI

@main
struct DinkrWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen — Small (2×2)
        DinkrNextGameWidget()
        DinkrStreakWidget()

        // Home Screen — Medium (2×4)
        DinkrTodayGamesWidget()
        DinkrMyStatsWidget()

        // Home Screen — Large (4×4)
        DinkrDashboardWidget()

        // Lock Screen (iOS 16+)
        DinkrLockCircleWidget()
        DinkrLockRectWidget()
        DinkrLockInlineWidget()
    }
}
