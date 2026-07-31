import WidgetKit
import SwiftUI

@main
struct MinimalClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        MinimalClockWidget()
        if #available(iOS 17.0, *) {
            CountdownWidget()
        }
    }
}
