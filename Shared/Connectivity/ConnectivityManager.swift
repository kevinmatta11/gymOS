import Foundation
import WatchConnectivity

// Handles bidirectional Watch ↔ iPhone sync.
// Transfers: active exercise selection, completed session data.
final class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()

    @Published var activeExerciseId: UUID?
    @Published var isReachable: Bool = false

    private let session: WCSession

    private override init() {
        session = WCSession.default
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: — Sending

    func sendExerciseSelection(_ exerciseId: UUID) {
        guard session.isReachable else {
            // Store in application context so it syncs when reachable
            try? session.updateApplicationContext([
                MessageKey.exerciseId: exerciseId.uuidString
            ])
            return
        }
        session.sendMessage(
            [MessageKey.exerciseId: exerciseId.uuidString],
            replyHandler: nil,
            errorHandler: nil
        )
    }

    func sendSessionData(_ sessionData: SessionTransferPayload) {
        guard let encoded = try? JSONEncoder().encode(sessionData) else { return }
        guard session.isReachable else {
            session.transferUserInfo([MessageKey.sessionPayload: encoded])
            return
        }
        session.sendMessageData(encoded, replyHandler: nil, errorHandler: nil)
    }

    // MARK: — WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let idString = message[MessageKey.exerciseId] as? String,
           let id = UUID(uuidString: idString) {
            DispatchQueue.main.async { self.activeExerciseId = id }
        }
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        if let payload = try? JSONDecoder().decode(SessionTransferPayload.self, from: messageData) {
            NotificationCenter.default.post(name: .sessionReceived, object: payload)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let data = userInfo[MessageKey.sessionPayload] as? Data,
           let payload = try? JSONDecoder().decode(SessionTransferPayload.self, from: data) {
            NotificationCenter.default.post(name: .sessionReceived, object: payload)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        if let idString = context[MessageKey.exerciseId] as? String,
           let id = UUID(uuidString: idString) {
            DispatchQueue.main.async { self.activeExerciseId = id }
        }
    }

    // iOS-only required delegate methods
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    private enum MessageKey {
        static let exerciseId = "exerciseId"
        static let sessionPayload = "sessionPayload"
    }
}

// MARK: — Transfer payload

// Plain Codable struct — safe to encode/decode across platforms.
struct SessionTransferPayload: Codable {
    let sessionId: UUID
    let startTime: Date
    let endTime: Date
    let sets: [SetTransferPayload]
}

struct SetTransferPayload: Codable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    let timestamp: Date
    let reps: Int
    let weightLbs: Double
    let velocitySamples: [Double]
    let autoSaved: Bool
}

extension Notification.Name {
    static let sessionReceived = Notification.Name("gymOS.sessionReceived")
}
