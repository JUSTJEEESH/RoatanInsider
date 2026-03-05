import Foundation

@Observable
final class HomeViewModel {
    var selectedGuideType: GuideType?

    enum GuideType: Identifiable {
        case cruise, areas, essentials
        var id: Int { hashValue }
    }
}
