import SwiftUI
import OSCKit
import WatchConnectivity

struct ContentView: View {
    let sessionDelegator = PhoneSessionDelegator()
    let client = OSCClient()
    let serverPort: UInt16 = 9000
    @State var serverHost = UserDefaults.standard.string(forKey: "serverHost") ?? ""

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("ModKnob")
                .font(.largeTitle)
            Spacer()
            VStack(alignment: .center) {
                Text("Enter your OSC server's IP/hostname:")
                TextField("x.x.x.x", text: $serverHost, onCommit: {
                    saveServerHost()
                })
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
            }
                .padding()
                .onAppear {
                    sessionDelegator.activateSession { message in
                        self.handleMessage(message: message)
                    }
                }
            Spacer()
        }
    }

    func saveServerHost() {
        UserDefaults.standard.set(serverHost, forKey: "serverHost")
        print("Saved OSC server host: \(serverHost)")
    }

    func handleMessage(message: [String: Any]) {
        print("Watch sent: \(message)")

        if let parameter = message["parameter"] as? String,
           let value = message["value"] {
            sendOSCValue(parameter: parameter, value: value)
        }
    }

    func sendOSCValue(parameter: String, value: Any) {
        let message: OSCMessage
        if let floatValue = value as? Float {
            message = OSCMessage(parameter, values: [floatValue])
        } else if let intValue = value as? Int32 {
            message = OSCMessage(parameter, values: [intValue])
        } else if let intValue = value as? Int {
            message = OSCMessage(parameter, values: [intValue])
        } else if let boolValue = value as? Bool {
            message = OSCMessage(parameter, values: [boolValue])
        } else {
            print("Unsupported value type")
            return
        }
        do {
            try client.send(message, to: serverHost, port: serverPort)
            print("Sending OSC: \(parameter) = \(value)")
        } catch {
            print("Error sending OSC message: \(error.localizedDescription)")
        }
    }
}

class PhoneSessionDelegator: NSObject, WCSessionDelegate {
    var messageReceivedHandler: (([String: Any]) -> Void)?

    func activateSession(messageReceivedHandler: @escaping ([String: Any]) -> Void) {
        self.messageReceivedHandler = messageReceivedHandler
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let handler = self.messageReceivedHandler {
            handler(message)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
}
