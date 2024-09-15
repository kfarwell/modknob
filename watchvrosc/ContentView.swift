import SwiftUI
import OSCKit
import WatchConnectivity

struct ContentView: View {
    @State private var receivedValue: Double = 0.0
    let sessionDelegator = PhoneSessionDelegator()
    let client = OSCClient()
    let address = "192.168.8.11"
    let port: UInt16 = 9000

    var body: some View {
        Text("Received Value: \(String(format: "%.2f", receivedValue))")
            .padding()
            .onAppear {
                sessionDelegator.activateSession { message in
                    self.handleMessage(message: message)
                }
            }
    }

    func handleMessage(message: [String: Any]) {
        print("Received message from watch: \(message)")

        guard let messageType = message["type"] as? String else {
            print("Message does not contain 'type'")
            return
        }

        switch messageType {
        case "crownValue":
            if let value = message["value"] as? Double,
               let mode = message["mode"] as? String {
                let floatValue = Float(value)
                let parameter = "/avatar/parameters/\(mode)"
                sendOSCValue(parameter: parameter, value: floatValue)
                DispatchQueue.main.async {
                    self.receivedValue = value
                }
            }
        case "boolean":
            if let parameterName = message["parameter"] as? String,
               let value = message["value"] as? Bool {
                let parameter = "/avatar/parameters/\(parameterName)"
                sendOSCValue(parameter: parameter, value: value)
            }
        case "particles":
            if let value = message["value"] as? Int {
                let parameter = "/avatar/parameters/VF84_PC/Vis/Colormode"
                sendOSCValue(parameter: parameter, value: value)
            }
        default:
            print("Unknown message type: \(messageType)")
        }
    }

    func sendOSCValue(parameter: String, value: Any) {
        print("Preparing to send OSC value: \(value) to parameter: \(parameter)")
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
            try client.send(message, to: address, port: port)
            print("Sent OSC message with value: \(value) to parameter: \(parameter)")
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
