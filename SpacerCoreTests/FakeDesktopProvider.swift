@testable import SpacerCore

final class FakeDesktopProvider: DesktopProvider {
    var result: Result<[Desktop], Error> = .success([])
    var switchError: Error?
    private(set) var switched: [Desktop] = []

    func desktops() throws -> [Desktop] {
        try result.get()
    }

    func switchTo(_ desktop: Desktop) throws {
        if let switchError { throw switchError }
        switched.append(desktop)
    }
}
