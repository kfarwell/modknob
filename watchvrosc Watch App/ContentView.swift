import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var immersion: Float = 1.0
    @FocusState private var isFocused: Bool
    @State private var mode: Float = 0.0
    let modeValues: [Float] = [0.0, 0.25, 0.5, 0.75]
    let modeLabels = ["Portal Fade", "Portal Simple", "Transparency", "Toggle"]

    let sessionDelegator = WatchSessionDelegator()

    var body: some View {
        VStack {
            Text("\(Int(immersion * 100))%")
                .font(.title2)
                .padding()
                .focusable(true)
                .focused($isFocused)
                .digitalCrownRotation(
                    $immersion,
                    from: 0,
                    through: 1.0,
                    by: 0.01,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: immersion) { newValue in
                    sessionDelegator.sendParameter(parameter: "/avatar/parameters/ModKnob/Immersion", value: newValue)
                }

            Spacer()

            Button(action: {
                let currentIndex = modeValues.firstIndex(of: mode) ?? 0
                let nextIndex = (currentIndex + 1) % modeValues.count
                mode = modeValues[nextIndex]
                sessionDelegator.sendParameter(parameter: "/avatar/parameters/ModKnob/Mode", value: mode)
            }) {
                Text(modeLabels[Int(mode * 4)])
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .onAppear {
            isFocused = true
            sessionDelegator.activateSession()
        }
    }
}

class WatchSessionDelegator: NSObject, WCSessionDelegate {
    func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func sendParameter(parameter: String, value: Any) {
        if WCSession.default.isReachable {
            let message: [String: Any] = [
                "parameter": parameter,
                "value": value
            ]
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending parameter: \(error.localizedDescription)")
            })
            print("Sending Phone: \(message)")
        } else {
            print("Session not reachable")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if (session.isReachable) {
            print("Session connected")
        } else {
            print("Session disconnected")
        }
    }
}
