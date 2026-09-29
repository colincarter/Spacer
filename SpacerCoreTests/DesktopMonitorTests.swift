import Testing
@testable import SpacerCore

struct DesktopMonitorTests {
    let provider = FakeDesktopProvider()
    let one = [Desktop(id: "A", index: 1, isCurrent: true)]
    let two = [Desktop(id: "A", index: 1, isCurrent: false), Desktop(id: "B", index: 2, isCurrent: true)]

    private func monitor(recording states: Recorder) -> DesktopMonitor {
        let monitor = DesktopMonitor(provider: provider)
        monitor.onChange = { states.values.append($0) }
        return monitor
    }

    final class Recorder { var values: [DesktopState] = [] }

    @Test func firstRefreshPublishes() {
        let recorder = Recorder()
        provider.result = .success(one)
        monitor(recording: recorder).refresh()
        #expect(recorder.values == [.loaded(one)])
    }

    @Test func identicalRefreshDoesNotPublish() {
        let recorder = Recorder()
        let m = monitor(recording: recorder)
        provider.result = .success(one)
        m.refresh()
        m.refresh()
        #expect(recorder.values.count == 1)
    }

    @Test func changedDesktopsPublish() {
        let recorder = Recorder()
        let m = monitor(recording: recorder)
        provider.result = .success(one)
        m.refresh()
        provider.result = .success(two)
        m.refresh()
        #expect(recorder.values == [.loaded(one), .loaded(two)])
        #expect(m.state == .loaded(two))
    }

    @Test func errorsPublishUnavailableOnce() {
        let recorder = Recorder()
        let m = monitor(recording: recorder)
        provider.result = .failure(DesktopProviderError.apiUnavailable)
        m.refresh()
        m.refresh()
        #expect(recorder.values == [.unavailable])
    }

    @Test func recoversAfterError() {
        let recorder = Recorder()
        let m = monitor(recording: recorder)
        provider.result = .failure(DesktopProviderError.unexpectedData)
        m.refresh()
        provider.result = .success(one)
        m.refresh()
        #expect(recorder.values == [.unavailable, .loaded(one)])
    }
}
