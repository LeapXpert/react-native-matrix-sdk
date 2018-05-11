import Foundation
import SwiftMatrixSDK

@objc(RNMatrixSDK)
class RNMatrixSDK: RCTEventEmitter {
    var mxSession: MXSession!

    var roomEventsListeners: [String: Any] = [:]

    @objc
    override func supportedEvents() -> [String]! {
        return ["matrix.room.backwards", "matrix.room.forwards"]
    }

    @objc(login:username:password:resolver:rejecter:)
    func login(url: String, username: String, password: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let homeServer = URL(string: url)
        MXRestClient(homeServer: homeServer!, unrecognizedCertificateHandler: nil).login(username: username, password: password) { response in
            if response.isSuccess {
                let credentials = response.value

                resolve([
                    "homeServer": unNil(value: credentials?.homeServer),
                    "userId": unNil(value: credentials?.userId),
                    "accessToken": unNil(value: credentials?.accessToken),
                ])
            } else {
                reject(nil, nil, response.error)
            }
        }
    }

    @objc(createRoom:resolver:rejecter:)
    func createRoom(userId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        mxSession.createRoom(name: nil, visibility: nil, alias: nil, topic: nil, invite: [userId], invite3PID: nil, isDirect: true, preset: nil) { response in
            if response.isSuccess {
                let roomId = response.value?.roomId
                let roomName = response.value?.state.name
                let notificationCount = response.value?.notificationCount
                let highlightCount = response.value?.highlightCount
                let isDirect = response.value?.isDirect
                let lastMessage = response.value?.lastMessageWithType(in: ["m.room.message"])

                resolve([
                    "room_id": unNil(value: roomId),
                    "name": unNil(value: roomName),
                    "notification_count": unNil(value: notificationCount),
                    "highlight_count": unNil(value: highlightCount),
                    "is_direct": unNil(value: isDirect),
                    "last_message": convertMXEventToDictionary(event: lastMessage),
                ])
            } else {
                reject(nil, nil, response.error)
            }
        }
    }

    @objc(joinRoom:resolver:rejecter:)
    func joinRoom(roomId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        mxSession.joinRoom(roomId) { response in
            if response.isSuccess {
                let roomId = response.value?.roomId
                let roomName = response.value?.state.name
                let notificationCount = response.value?.notificationCount
                let highlightCount = response.value?.highlightCount
                let isDirect = response.value?.isDirect
                let lastMessage = response.value?.lastMessageWithType(in: ["m.room.message"])

                resolve([
                    "room_id": unNil(value: roomId),
                    "name": unNil(value: roomName),
                    "notification_count": unNil(value: notificationCount),
                    "highlight_count": unNil(value: highlightCount),
                    "is_direct": unNil(value: isDirect),
                    "last_message": convertMXEventToDictionary(event: lastMessage),
                ])
            } else {
                reject(nil, nil, response.error)
            }
        }
    }

    @objc(getInvitedRooms:rejecter:)
    func getInvitedRooms(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let rooms = mxSession.invitedRooms().map({
            (r: MXRoom) -> [String: Any?] in
            let room = mxSession.room(withRoomId: r.roomId)
            let lastMessage = room?.lastMessageWithType(in: ["m.room.message"])

            return [
                "room_id": unNil(value: room?.roomId),
                "name": unNil(value: room?.state.name),
                "notification_count": unNil(value: room?.notificationCount),
                "highlight_count": unNil(value: room?.highlightCount),
                "is_direct": unNil(value: room?.isDirect),
                "last_message": convertMXEventToDictionary(event: lastMessage),
            ]
        })

        resolve(rooms)
    }

    @objc(getPublicRooms:resolver:rejecter:)
    func getPublicRooms(url: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let homeServerUrl = URL(string: url)!
        let mxRestClient = MXRestClient(homeServer: homeServerUrl, unrecognizedCertificateHandler: nil)
        mxRestClient.publicRooms { response in
            switch response {
            case let .success(rooms):
                let data = rooms.map { [
                    "id": $0.roomId,
                    "aliases": unNil(value: $0.aliases) ?? [],
                    "name": unNil(value: $0.name) ?? "",
                    "guestCanJoin": $0.guestCanJoin,
                    "numJoinedMembers": $0.numJoinedMembers,
                ] }

                resolve(data)
                break
            case let .failure(error):
                reject(nil, nil, error)
                break
            }
        }
    }

    @objc(connect:resolver:rejecter:)
    func connect(credentials: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let url = unNil(value: credentials["homeServer"])
        let userId = unNil(value: credentials["userId"])
        let accessToken = unNil(value: credentials["accessToken"])

        if url == nil || userId == nil || accessToken == nil {
            reject(nil, "Unvalid credentials", nil)
            return
        }

        let credentials = MXCredentials(
            homeServer: url as! String?,
            userId: userId as! String?,
            accessToken: accessToken as! String?
        )!

        // Create a matrix client
        let mxRestClient = MXRestClient(credentials: credentials, unrecognizedCertificateHandler: nil)

        // Create a matrix session
        mxSession = MXSession(matrixRestClient: mxRestClient)!

        // Launch mxSession: it will first make an initial sync with the homeserver
        mxSession.start { response in
            guard response.isSuccess else {
                reject(nil, nil, response.error)
                return
            }

            let user = self.mxSession.myUser

            resolve([
                "id": unNil(value: user?.userId),
                "displayname": unNil(value: user?.displayname),
                "avatar": unNil(value: user?.avatarUrl),
                "last_active": unNil(value: user?.lastActiveAgo),
                "status": unNil(value: user?.statusMsg),
            ])
        }
    }

    @objc(getUnreadEventTypes:rejecter:)
    func getUnreadEventTypes(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        resolve(mxSession.unreadEventTypes)
    }

    @objc(getRecentEvents:resolver:rejecter:)
    func getRecentEvents(eventTypes: [String]!, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let recentEvents = mxSession.recentsWithType(in: eventTypes)

        let response = recentEvents.map({
            (events: [MXEvent]) -> [[String: Any]] in
            events.map(convertMXEventToDictionary)
        })

        resolve(response)
    }

    @objc(getJoinedRooms:rejecter:)
    func getJoinedRooms(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let rooms = mxSession.rooms.map({
            (r: MXRoom) -> [String: Any?] in
            let room = mxSession.room(withRoomId: r.roomId)
            let lastMessage = room?.lastMessageWithType(in: ["m.room.message"])

            return [
                "room_id": unNil(value: room?.roomId),
                "name": unNil(value: room?.state.name),
                "notification_count": unNil(value: room?.notificationCount),
                "highlight_count": unNil(value: room?.highlightCount),
                "is_direct": unNil(value: room?.isDirect),
                "last_message": convertMXEventToDictionary(event: lastMessage),
            ]
        })

        resolve(rooms)
    }

    @objc(listenToRoom:resolver:rejecter:)
    func listenToRoom(roomId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let room = mxSession.room(withRoomId: roomId)

        if room == nil {
            reject(nil, "Room not found", nil)
            return
        }

        if roomEventsListeners[roomId] != nil {
            reject(nil, "Only allow 1 listener to 1 room for now. Room id: " + roomId, nil)
            return
        }

        let listener = room?.liveTimeline.listenToEvents {
            event, direction, _ in
            switch direction {
            case .backwards:
                if self.bridge != nil {
                    self.sendEvent(
                        withName: "matrix.room.backwards",
                        body: convertMXEventToDictionary(event: event)
                    )
                }
                break
            case .forwards:
                if self.bridge != nil {
                    self.sendEvent(
                        withName: "matrix.room.forwards",
                        body: convertMXEventToDictionary(event: event)
                    )
                }
                break
            }
        }

        roomEventsListeners[roomId] = listener

        resolve(nil)
    }

    @objc(unlistenToRoom:resolver:rejecter:)
    func unlistenToRoom(roomId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let room = mxSession.room(withRoomId: roomId)

        if room == nil {
            reject(nil, "Room not found", nil)
            return
        }

        if roomEventsListeners[roomId] == nil {
            reject(nil, "No listener for this room. Room id: " + roomId, nil)
            return
        }

        room?.liveTimeline.removeListener(roomEventsListeners[roomId])
        roomEventsListeners[roomId] = nil

        resolve(nil)
    }

    @objc(loadMessagesInRoom:perPage:initialLoad:resolver:rejecter:)
    func loadMessagesInRoom(roomId: String, perPage: NSNumber, initialLoad: Bool, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let room = mxSession.room(withRoomId: roomId)

        if room == nil {
            reject(nil, "Room not found", nil)
            return
        }

        if roomEventsListeners[roomId] == nil {
            resolve(["success": false])
            return
        }

        if initialLoad {
            room?.liveTimeline.resetPagination()
        }

        _ = room?.liveTimeline.paginate(UInt(perPage), direction: .backwards, onlyFromStore: false) { response in
            if response.error != nil {
                reject(nil, nil, response.error)
                return
            }

            resolve(["success": true])
        }
    }

    @objc(searchMessagesInRoom:searchTerm:nextBatch:beforeLimit:afterLimit:resolver:rejecter:)
    func searchMessagesInRoom(roomId: String, searchTerm: String, nextBatch: String, beforeLimit: NSNumber, afterLimit: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let roomEventFilter = MXRoomEventFilter()
        roomEventFilter.rooms = [roomId]

        mxSession.matrixRestClient.searchMessages(withPattern: searchTerm, roomEventFilter: roomEventFilter, beforeLimit: UInt(beforeLimit), afterLimit: UInt(afterLimit), nextBatch: nextBatch) { results in
            if results.isFailure {
                reject(nil, nil, results.error)
                return
            }

            if results.value == nil || results.value?.results == nil {
                resolve([
                    "count": 0,
                    "next_batch": nil,
                    "results": [],
                ])
                return
            }

            let events = results.value?.results.map({ (result: MXSearchResult) -> [String: Any] in
                let context = result.context
                let eventsBefore = context?.eventsBefore ?? []
                let eventsAfter = context?.eventsAfter ?? []

                return [
                    "event": convertMXEventToDictionary(event: result.result),
                    "context": [
                        "before": eventsBefore.map(convertMXEventToDictionary) as Any,
                        "after": eventsAfter.map(convertMXEventToDictionary) as Any,
                    ],
                    "token": [
                        "start": unNil(value: context?.start),
                        "end": unNil(value: context?.end),
                    ],
                ]
            })

            resolve([
                "next_batch": unNil(value: results.value?.nextBatch),
                "count": unNil(value: results.value?.count),
                "results": events,
            ])
        }
    }

    @objc(getMessages:from:direction:limit:resolver:rejecter:)
    func getMessages(roomId: String, from: String, direction: String, limit: NSNumber, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let roomEventFilter = MXRoomEventFilter()
        let timelimeDirection = direction == "backwards" ? MXTimelineDirection.backwards : MXTimelineDirection.forwards

        mxSession.matrixRestClient.messages(forRoom: roomId, from: from, direction: timelimeDirection, limit: UInt(limit), filter: roomEventFilter) { response in
            if response.error != nil {
                reject(nil, nil, response.error)
                return
            }

            let results = response.value?.chunk.map { convertMXEventToDictionary(event: $0 as? MXEvent) }

            resolve([
                "start": unNil(value: response.value?.start),
                "end": unNil(value: response.value?.end),
                "results": results,
            ])
        }
    }

    @objc(sendMessageToRoom:data:resolver:rejecter:)
    func sendMessageToRoom(roomId: String, data: [String: Any], resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        let room = mxSession.room(withRoomId: roomId)

        if room == nil {
            reject(nil, "Room not found", nil)
            return
        }

        _ = room?.sendMessage(withContent: data, localEcho: nil, success: { response in resolve(response) }, failure: { error in reject(nil, nil, error) })
    }

    @objc(sendReadReceipt:eventId:resolver:rejecter:)
    func sendReadReceipt(roomId: String, eventId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        if mxSession == nil {
            reject(nil, "client is not connected yet", nil)
            return
        }

        mxSession.matrixRestClient.sendReadReceipts(toRoom: roomId, forEvent: eventId) { response in
            if response.error != nil {
                reject(nil, nil, response.error)
                return
            }

            resolve(["success": response.value])
        }
    }
}

internal func unNil(value: Any?) -> Any? {
    guard let value = value else {
        return nil
    }
    return value
}

internal func convertMXEventToDictionary(event: MXEvent?) -> [String: Any] {
    return [
        "event_type": unNil(value: event?.type) as Any,
        "event_id": unNil(value: event?.eventId) as Any,
        "room_id": unNil(value: event?.roomId) as Any,
        "sender_id": unNil(value: event?.sender) as Any,
        "age": unNil(value: event?.age) as Any,
        "content": unNil(value: event?.content) as Any,
    ]
}
