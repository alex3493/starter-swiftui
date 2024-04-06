//
//  PusherService.swift
//  Starter
//
//  Created by Alex on 28/3/24.
//

import Foundation
import PusherSwift
import Combine

struct NotificationChannel {
    let channelName: String
    var channel: PusherChannel? = nil
    var events: [String: NotificationEvent] = [:]
    
    let presencePublisher: PassthroughSubject<(PresenceEvent, [User]), Error>?
    
    let pusherManager: PusherManager
    
    enum PresenceEvent {
        case connection
        case member_added
        case member_removed
    }
    
    init(channelName: String) {
        self.channelName = channelName
        self.pusherManager = PusherManager.shared
        
        if channelName.hasPrefix("presence-") {
            self.presencePublisher = PassthroughSubject<(PresenceEvent, [User]), Error>()
        } else {
            self.presencePublisher = nil
        }
        
        subscribeChannel(channelName: channelName)
    }
    
    mutating func subscribeChannel(channelName: String) {
        guard let pusher = pusherManager.pusher else { return }
        
        if channelName.hasPrefix("presence-") {
            channel = pusher.subscribeToPresenceChannel(channelName: channelName, onMemberAdded: onMemberAdded, onMemberRemoved: onMemberRemoved)
            
            subscribeToPresenceEvents()
        } else {
            channel = pusher.subscribe(channelName: channelName)
        }
        
        //        if let channel = channel {
        //
        //            channel.bind(eventName: "pusher:subscription_succeeded", eventCallback: { event in
        //                print("Subscribed!", event.channelName as Any)
        //
        //                if channel.isKind(of: PusherPresenceChannel.self) {
        //                    let chan: PusherPresenceChannel = channel as! PusherPresenceChannel
        //                    print("I can now access my ID: \(String(describing: chan.myId))")
        //                    print("And here are the channel members: \(chan.members.compactMap { $0.userInfo })")
        //
        //                    guard let jsonData = try? JSONSerialization.data(withJSONObject: chan.members.compactMap { $0.userInfo }) else {
        //                        return
        //                    }
        //
        //                    let decoder = JSONDecoder()
        //                    if let decoded = try? decoder.decode([DBUser].self, from: jsonData) {
        //                        print(decoded as Any)
        //
        //                        presencePublisher.send(["connection": decoded])
        //                    }
        //                }
        //            })
        //        }
        
        // print("Subscribed to channel \(channelName)")
    }
    
    func subscribeToPresenceEvents() {
        guard let _ = pusherManager.pusher else { return }
        
        guard let chan = channel as? PusherPresenceChannel else { return }
        
        chan.bind(eventName: "pusher:subscription_succeeded", eventCallback: { event in
            guard let jsonData = try? JSONSerialization.data(withJSONObject: chan.members.compactMap { $0.userInfo }) else {
                return
            }
            
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([User].self, from: jsonData) {
                // print(decoded as Any)
                
                presencePublisher?.send((.connection, decoded))
            }
        })
    }
    
    func onMemberAdded(member: PusherPresenceChannelMember) {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: member.userInfo as Any) else {
            return
        }
        
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(User.self, from: jsonData) {
            // print(decoded as Any)
            
            presencePublisher?.send((.member_added, [decoded]))
        }
    }
    
    func onMemberRemoved(member: PusherPresenceChannelMember) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: member.userInfo as Any) else {
            return
        }
        
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode(User.self, from: jsonData) {
            // print(decoded as Any)
            
            presencePublisher?.send((.member_removed, [decoded]))
        }
    }
    
    mutating func subscribeEvent<T>(eventName: String, as type: T.Type) where T: Decodable {
        guard let channel = channel else { return }
        
        if events[eventName] != nil && events[eventName]?.callbackId != nil {
            // TODO: check this case!
            print("Existing callback for event \(channelName) :: \(eventName)")
        } else {
            
            var notificationEvent = NotificationEvent(eventName: eventName)
            
            notificationEvent.callbackId = channel.bind(eventName: eventName, eventCallback: { (event: PusherEvent) -> Void in
                
                guard let json: String = event.data,
                      let jsonData: Data = json.data(using: .utf8)
                else {
                    print("Could not convert JSON string to data")
                    return
                }
                
                let decoder = JSONDecoder()
                let decoded = try? decoder.decode(T.self, from: jsonData)
                
                guard let decoded = decoded else {
                    print("Could not decode event data to type \(type)")
                    return
                }
                
                // print("Decoded", decoded)
                
                if let chan = channel as? PusherPresenceChannel {
                    notificationEvent.eventPublisher.send([
                        "data": decoded,
                        // Add presence data to response.
                        "presence": [
                            "me": chan.me()?.userInfo,
                            "members": chan.members.compactMap { $0.userInfo }
                        ]
                    ])
                } else {
                    // Regular channel.
                    notificationEvent.eventPublisher.send(["data": decoded])
                }
            })
            
            events[eventName] = notificationEvent
            
            print("Subscribed to event \(channelName) :: \(eventName)")
        }
    }
    
    mutating func unsubscribeChannel() {
        channel?.unbindAll()
        events = [:]
        
        channel = nil
        
        print("Unsubscribed from channel \(channelName)")
    }
    
    mutating func unsubscribeEvent(eventName: String) {
        channel?.unbindAll(forEventName: eventName)
        events.removeValue(forKey: eventName)
        
        print("Unsubscribed from event \(channelName) :: \(eventName)")
    }
    
    func triggerClientEvent(eventName: String, data: Any) {
        guard let channel = channel else { return }
        
        channel.trigger(eventName: eventName, data: data)
    }
    
}

struct NotificationEvent {
    let eventName: String
    var callbackId: String? = nil
    let eventPublisher: PassthroughSubject<[String: Any], Error>
    
    init(eventName: String) {
        self.eventName = eventName
        self.eventPublisher = PassthroughSubject<[String: Any], Error>()
    }
}

class AuthRequestBuilder: AuthRequestBuilderProtocol {
    let authToken: String?
    
    init(authToken: String) {
        self.authToken = authToken
    }
    
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        
        guard let authToken = authToken else { return nil }
        
        // print("AuthRequestBuilder requestFor:", socketID, channelName)
        
        var request = URLRequest(url: URL(string: "http://localhost/broadcasting/auth")!)
        
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // request.setValue("*", forHTTPHeaderField: "Access-Control-Allow-Origin")
        
        request.httpMethod = "POST"
        request.httpBody = "socket_id=\(socketID)&channel_name=\(channelName)".data(using: String.Encoding.utf8)
        
        return request
    }
}

class ConnectionDelegate: PusherDelegate {
    
    let statusPublisher = PassthroughSubject<ConnectionStatus, Never>()
    
    enum ConnectionStatus {
        case connectionChanged(old: ConnectionState, new: ConnectionState)
        case subscriptionSuccess(channelName: String)
        case subscriptionError(channelName: String, code: Int?)
    }
    
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        // print("changedConnectionState from \(old) to \(new)")
        
        statusPublisher.send(.connectionChanged(old: old, new: new))
    }
    
    func debugLog(message: String) {
        // print("DEBUG :: \(message)")
    }
    
    func subscribedToChannel(name: String) {
        // print("subscribedToChannel \(name)")
        
        statusPublisher.send(.subscriptionSuccess(channelName: name))
    }
    
    func failedToSubscribeToChannel(name: String, response: URLResponse?, data: String?, error: NSError?) {
        // print("failedToSubscribeToChannel \(name)")
        
        statusPublisher.send(.subscriptionError(channelName: name, code: response?.http?.statusCode))
    }
    
    func receivedError(error: PusherError) {
        let message = error.message
        if let code = error.code {
            print("ERROR :: \(code) :: \(message)")
        }
    }
    
    func failedToDecryptEvent(eventName: String, channelName: String, data: String?) {
        print("failedToDecryptEvent \(channelName) :: \(eventName)")
    }
}

final class PusherManager {
    
    static let shared = PusherManager()
    
    var channels: [String: NotificationChannel] = [:]
    
    var pusher: Pusher? = nil
    
    let connectionDelegate = ConnectionDelegate()
    
    var cancellables = Set<AnyCancellable>()
    
    var keepAliveCallbackId: String? = nil
    
    private init() {}
    
    public func configure() {
        let token = KeychainService.shared.read(service: "access-token", account: "org.smartcalc.starter", type: AuthToken.self)?.token
        guard let authToken = token else {
            pusher = nil
            return
        }
        
        /*
         Pusher settings.
         */
        let options = PusherClientOptions(
            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder(authToken: authToken)),
            host: .host("0.0.0.0"),
            port: 8080,
            useTLS: false
        )
        pusher = Pusher(key: "silextnxvnuat4blcxwg", options: options)
        
        /*
         Soketi settings.
         */
//        let options = PusherClientOptions(
//            authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: AuthRequestBuilder(authToken: authToken)),
//            host: .host("127.0.0.1"),
//            port: 6001,
//            useTLS: false
//        )
//        pusher = Pusher(key: "app-key", options: options)
        
        /*
         Common code.
         */
        
        pusher?.connection.delegate = connectionDelegate
        
        pusher?.connect()
        
        connectionDelegate.statusPublisher
            .sink { [weak self] value in
                // print("Status publisher event", value)
                // TODO: use self? to update channels and display warnings.
                switch value {
                case .subscriptionSuccess(let name):
                    if name.hasPrefix("presence-") {
                        print("Successfully subscribed to presence channel \(name)")
                        // let presenceChannel = self?.pusher?.connection.channels.findPresence(name: name)
                        // print("Presence channel \(name)", presenceChannel?.myId, presenceChannel?.members)
                    } else {
                        print("Successfully subscribed to channel \(name)")
                    }
                    
                case .subscriptionError(let name, let code):
                    print("Error subscribing to channel \(name). Error code: \(String(describing: code))")
                case .connectionChanged(let old, let new):
                    if new == .connected {
                        self?.keepAlive(value: true)
                    } else {
                        self?.keepAlive(value: false)
                    }
                    print("Connection state changed from \(old.stringValue()) to \(new.stringValue())")
                }
            }
            .store(in: &cancellables)
        
        print("***** Pusher init done")
    }
    
    var isConfigured: Bool {
        return pusher != nil
    }
    
    public func getPublisher<T>(channelName: String, eventName: String, as type: T.Type) -> PassthroughSubject<[String: Any], Error>?  where T: Decodable {
        if channels[channelName] == nil {
            channels[channelName] = NotificationChannel(channelName: channelName)
        }
        
        channels[channelName]?.subscribeEvent(eventName: eventName, as: T.self)
        
        return channels[channelName]?.events[eventName]?.eventPublisher
    }
    
    public func disconnectEvent(channelName: String, eventName: String) {
        guard var channel = channels[channelName] else { return }
        
        print("Disconnecting event", channelName, eventName)
        channel.unsubscribeEvent(eventName: eventName)
    }
    
    public func disconnectChannel(channelName: String) {
        guard var channel = channels[channelName] else { return }
        
        print("Disconnecting channel", channelName)
        channel.unsubscribeChannel()
        
        pusher?.unsubscribe(channelName)
        channels.removeValue(forKey: channelName)
    }
    
    public func disconnectAll() {
        print("Disconnecting all channels", channels.keys)
        for channelName in channels.keys {
            channels[channelName]?.unsubscribeChannel()
            
            pusher?.unsubscribe(channelName)
            channels.removeValue(forKey: channelName)
        }
    }
    
    func keepAlive(value: Bool) {
        if value {
            keepAliveCallbackId = pusher?.bind(eventCallback: { event in
                if event.eventName == "pusher:ping" {
                    print("Keep pusher connection alive")
                    self.pusher?.connection.sendEvent(event: "pusher:pong", data: [])
                }
            })
        } else if let keepAliveCallbackId = keepAliveCallbackId {
            print("Unbind keep-alive callback")
            pusher?.unbind(callbackId: keepAliveCallbackId)
        }
    }
    
    func triggerClientEvent(channelName: String, eventName: String, data: Any) {
        guard let channel = channels[channelName] else { return }
        
        channel.triggerClientEvent(eventName: eventName, data: data)
    }
    
    deinit {
        print("Pusher manager destructor!")
        pusher?.unbindAll()
    }
}
