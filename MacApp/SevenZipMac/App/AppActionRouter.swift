import Foundation

enum ExternalExtractMode {
    case prompt
    case sameFolder
    case subfolder
}

enum AppOpenAction {
    case openArchive(URL)
    case compressFiles([URL])
    case quickCompress([URL], ArchiveFormat)
    case extractArchives([URL], ExternalExtractMode)
    case testArchives([URL])

    var isBackgroundJob: Bool {
        switch self {
        case .quickCompress, .testArchives:
            return true
        case .extractArchives(_, let mode):
            return mode != .prompt
        case .openArchive, .compressFiles:
            return false
        }
    }
}

@MainActor
final class AppActionRouter: ObservableObject {
    static let shared = AppActionRouter()

    @Published private(set) var pendingActions: [AppOpenAction] = []

    private init() {}

    func dispatch(_ action: AppOpenAction) {
        pendingActions.append(action)
    }

    func dequeue() -> AppOpenAction? {
        guard !pendingActions.isEmpty else { return nil }
        return pendingActions.removeFirst()
    }
}
