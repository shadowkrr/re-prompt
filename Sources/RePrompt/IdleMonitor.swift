import Foundation
import IOKit

protocol IdleMonitorDelegate: AnyObject {
    func idleMonitorDidExceedThreshold(_ monitor: IdleMonitor)
    func idleMonitorDidDetectInput(_ monitor: IdleMonitor)
}

final class IdleMonitor {
    var threshold: TimeInterval
    weak var delegate: IdleMonitorDelegate?

    private var timer: Timer?
    private var hasTriggered = false

    init(threshold: TimeInterval) {
        self.threshold = threshold
    }

    func start() {
        timer = Timer.scheduledTimer(
            withTimeInterval: Config.pollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// IOKit HIDIdleTime から現在のアイドル時間（秒）を取得
    var currentIdleTime: TimeInterval {
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOHIDSystem"),
            &iterator
        )
        guard result == KERN_SUCCESS else { return 0 }
        defer { IOObjectRelease(iterator) }

        let entry = IOIteratorNext(iterator)
        guard entry != 0 else { return 0 }
        defer { IOObjectRelease(entry) }

        var unmanagedDict: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(
            entry, &unmanagedDict, kCFAllocatorDefault, 0
        ) == KERN_SUCCESS else { return 0 }

        guard let dict = unmanagedDict?.takeRetainedValue() as? [String: Any],
              let nanoSeconds = dict["HIDIdleTime"] as? Int64 else {
            return 0
        }

        return TimeInterval(nanoSeconds) / 1_000_000_000
    }

    private func checkIdleState() {
        let idleTime = currentIdleTime

        if idleTime >= threshold && !hasTriggered {
            hasTriggered = true
            delegate?.idleMonitorDidExceedThreshold(self)
        } else if idleTime < threshold && hasTriggered {
            hasTriggered = false
            delegate?.idleMonitorDidDetectInput(self)
        }
    }
}
