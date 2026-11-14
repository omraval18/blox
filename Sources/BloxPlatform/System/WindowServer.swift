import BloxCore
import CoreGraphics
import Foundation

/// What the window server knows about a window, without a round trip to the app that owns it.
enum WindowServer {
    /// Where a window is on screen right now (top-left space). Apps may refuse or alter the frame
    /// they are asked for (fixed-size windows, character grids), so overlays that must hug a
    /// window follow this, not the request.
    static func bounds(of id: WindowID) -> CGRect? {
        let info = CGWindowListCopyWindowInfo(
            .optionIncludingWindow,
            CGWindowID(id.rawValue),
        ) as? [NSDictionary]
        guard let bounds = info?.first?[kCGWindowBounds] as? NSDictionary else { return nil }
        return CGRect(dictionaryRepresentation: bounds)
    }
}
