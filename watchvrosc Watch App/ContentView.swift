import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var crownValue: Double = 0.5
    @FocusState private var isFocused: Bool
    @State private var isPassthroughMode: Bool = true
    @State private var toggle1State: Bool = false
    @State private var particlesValue: Int = 0

    let sessionDelegator = WatchSessionDelegator()

    var body: some View {
        VStack {
            HStack {
                Toggle(isOn: $isPassthroughMode) {
                    Text(isPassthroughMode ? "Passthrough" : "Spectrum")
                }
                .onChange(of: isPassthroughMode) { newValue in
                    let mode = newValue ? "Passthrough" : "Spectrum"
                    print("Control mode changed to: \(mode)")
                }
                
                Text(String(format: "%.2f", crownValue))
                    .focusable(true)
                    .focused($isFocused)
                    .digitalCrownRotation(
                        $crownValue,
                        from: 0.03,
                        through: 1.0,
                        by: 0.01,
                        sensitivity: .medium,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )
                    .onChange(of: crownValue) { newValue in
                        print("Crown Value Changed: \(newValue)")
                        let mode = isPassthroughMode ? "passthrough" : "spectrum"
                        sessionDelegator.sendCrownValueToPhone(value: newValue, mode: mode)
                    }
            }

            HStack {
                Button(action: {
                    particlesValue = (particlesValue + 1) % 6
                    sessionDelegator.sendParticlesValueToPhone(value: particlesValue)
                }) {
                    Text("P")
                        .frame(width: 30, height: 30)
                        .background(Color.purple)
                        .cornerRadius(5)
                }
                
                Toggle(isOn: $toggle1State) {
                    Text("L")
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .frame(width: 50)
                .onChange(of: toggle1State) { newValue in
                    sessionDelegator.sendBooleanToPhone(parameter: "VF95_Sound/1", value: newValue)
                }
            }
            
            HStack {
                Button(action: {
                    sessionDelegator.sendFalseTrueToPhone(parameter: "VF96_Sound/1")
                }) {
                    Text("1")
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                
                Button(action: {
                    sessionDelegator.sendFalseTrueToPhone(parameter: "VF97_Sound/3")
                }) {
                    Text("2")
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                
                Button(action: {
                    sessionDelegator.sendFalseTrueToPhone(parameter: "VF98_Sound/4")
                }) {
                    Text("3")
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                
                Button(action: {
                    sessionDelegator.sendFalseTrueToPhone(parameter: "VF99_Sound/5")
                }) {
                    Text("4")
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
            }
            
            HStack {
                Button(action: {
                    sessionDelegator.sendFalseTrueToPhone(parameter: "VF100_Sound/6")
                }) {
                    Text("5")
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                
                Button(action: {
                    sessionDelegator.sendFalseTrueToPhone(parameter: "VF101_Sound/7")
                }) {
                    Text("6")
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
                
                Button(action: {
                    sessionDelegator.sendFalseTrueToPhone(parameter: "VF102_Sound/8")
                }) {
                    Text("7")
                        .frame(width: 30, height: 30)
                        .background(Color.blue)
                        .cornerRadius(5)
                }
            }
        }
        .padding()
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

    func sendCrownValueToPhone(value: Double, mode: String) {
        if WCSession.default.isReachable {
            let message: [String: Any] = [
                "type": "crownValue",
                "value": value,
                "mode": mode
            ]
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending crown value to phone: \(error.localizedDescription)")
            })
            print("Sent crown value to phone: \(message)")
        } else {
            print("Phone is not reachable")
        }
    }

    func sendFalseTrueToPhone(parameter: String) {
        if WCSession.default.isReachable {
            let messageFalse: [String: Any] = [
                "type": "boolean",
                "parameter": parameter,
                "value": false
            ]
            let messageTrue: [String: Any] = [
                "type": "boolean",
                "parameter": parameter,
                "value": true
            ]
            WCSession.default.sendMessage(messageFalse, replyHandler: nil, errorHandler: { error in
                print("Error sending false to phone: \(error.localizedDescription)")
            })
            print("Sent false to phone: \(messageFalse)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                WCSession.default.sendMessage(messageTrue, replyHandler: nil, errorHandler: { error in
                    print("Error sending true to phone: \(error.localizedDescription)")
                })
                print("Sent true to phone: \(messageTrue)")
            }
        } else {
            print("Phone is not reachable")
        }
    }

    func sendBooleanToPhone(parameter: String, value: Bool) {
        if WCSession.default.isReachable {
            let message: [String: Any] = [
                "type": "boolean",
                "parameter": parameter,
                "value": value
            ]
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending boolean to phone: \(error.localizedDescription)")
            })
            print("Sent boolean to phone: \(message)")
        } else {
            print("Phone is not reachable")
        }
    }

    func sendParticlesValueToPhone(value: Int) {
        if WCSession.default.isReachable {
            let message: [String: Any] = [
                "type": "particles",
                "value": value
            ]
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: { error in
                print("Error sending particles value to phone: \(error.localizedDescription)")
            })
            print("Sent particles value to phone: \(message)")
        } else {
            print("Phone is not reachable")
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
        print("Session reachability changed: \(session.isReachable)")
    }
}
