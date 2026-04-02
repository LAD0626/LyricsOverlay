import Foundation
import Network

final class NativeMessageServer {
    var onRawMessage: ((String) -> Void)?
    var onServerStateChanged: ((Bool) -> Void)?

    private let queue = DispatchQueue(label: "LyricsOverlay.NativeMessageServer")
    private var listener: NWListener?
    private var clients: [UUID: Client] = [:]

    func start() {
        guard listener == nil, let port = NWEndpoint.Port(rawValue: BridgeConstants.tcpPort) else {
            return
        }

        do {
            let listener = try NWListener(using: .tcp, on: port)
            listener.stateUpdateHandler = { [weak self] state in
                self?.handleListenerState(state)
            }
            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection: connection)
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.onServerStateChanged?(false)
            }
        }
    }

    func stop() {
        for client in clients.values {
            client.connection.cancel()
        }
        clients.removeAll()

        listener?.cancel()
        listener = nil

        DispatchQueue.main.async { [weak self] in
            self?.onServerStateChanged?(false)
        }
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            DispatchQueue.main.async { [weak self] in
                self?.onServerStateChanged?(true)
            }
        case .failed, .cancelled:
            DispatchQueue.main.async { [weak self] in
                self?.onServerStateChanged?(false)
            }
        default:
            break
        }
    }

    private func accept(connection: NWConnection) {
        let identifier = UUID()
        let client = Client(connection: connection)
        clients[identifier] = client

        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state, identifier: identifier, client: client)
        }

        connection.start(queue: queue)
    }

    private func handleConnectionState(
        _ state: NWConnection.State,
        identifier: UUID,
        client: Client
    ) {
        switch state {
        case .ready:
            guard isLoopbackConnection(client.connection.endpoint) else {
                removeClient(identifier)
                client.connection.cancel()
                return
            }
            receiveNextChunk(for: identifier)
        case .failed, .cancelled:
            removeClient(identifier)
        default:
            break
        }
    }

    private func receiveNextChunk(for identifier: UUID) {
        guard let client = clients[identifier] else { return }

        client.connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let data, !data.isEmpty {
                client.buffer.append(data)
                flushMessages(for: identifier)
            }

            if isComplete || error != nil {
                removeClient(identifier)
                client.connection.cancel()
                return
            }

            receiveNextChunk(for: identifier)
        }
    }

    private func flushMessages(for identifier: UUID) {
        guard let client = clients[identifier] else { return }

        while let newlineRange = client.buffer.firstRange(of: Data([0x0A])) {
            let lineData = client.buffer.subdata(in: client.buffer.startIndex..<newlineRange.lowerBound)
            client.buffer.removeSubrange(client.buffer.startIndex..<newlineRange.upperBound)

            guard !lineData.isEmpty else { continue }
            guard let message = String(data: lineData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  !message.isEmpty
            else {
                continue
            }

            DispatchQueue.main.async { [weak self] in
                self?.onRawMessage?(message)
            }
        }
    }

    private func removeClient(_ identifier: UUID) {
        clients.removeValue(forKey: identifier)
    }

    private func isLoopbackConnection(_ endpoint: NWEndpoint) -> Bool {
        guard case let .hostPort(host, _) = endpoint else {
            return false
        }

        switch host {
        case .ipv4(let address):
            return address.debugDescription == BridgeConstants.tcpHost
        case .ipv6(let address):
            return address.debugDescription == "::1"
        case .name(let name, _):
            return name == "localhost"
        @unknown default:
            return false
        }
    }
}

private final class Client {
    let connection: NWConnection
    var buffer = Data()

    init(connection: NWConnection) {
        self.connection = connection
    }
}
