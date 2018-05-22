// @flow
import {NativeEventEmitter, NativeModules} from 'react-native'
import invariant from 'invariant'

const {MatrixManager} = NativeModules

import type {
  MatrixRoom,
  MatrixEvent,
  Direction,
  MatrixRoomListenerRemover,
  MatrixRoomListener
} from './types'

class RoomEventTimeline {
  static fromRoom(room: MatrixRoom): RoomEventTimeline {
    return new RoomEventTimeline(room)
  }

  _eventSubscribers: {[roomId: string]: Array<MatrixRoomListenerRemover>} = {}
  _matrixManagerEmitter = new NativeEventEmitter(MatrixManager)
  _room: MatrixRoom

  constructor(room: MatrixRoom) {
    invariant(room != null, 'Event timeline was created with a null room')
    this._room = room
  }

  _addRoomEventsListener(
    direction: Direction,
    listener: MatrixRoomListener
  ): MatrixRoomListenerRemover {
    const {room_id: roomId} = this._room

    if (
      this._eventSubscribers[roomId] == null ||
      this._eventSubscribers[roomId].length < 1
    ) {
      MatrixManager.listenToRoom(roomId)
    }

    const subscriber = this._matrixManagerEmitter.addListener(
      `matrix.room.${direction}`,
      message => {
        if (message.room_id !== roomId) {
          return
        }

        if (message.age != null) {
          message.created_at = Date.now() - message.age
        }

        listener(message)
      }
    )

    this._eventSubscribers[roomId] = this._eventSubscribers[roomId] || []
    this._eventSubscribers[roomId].push(subscriber)

    return {
      remove: () => {
        subscriber.remove()

        this._eventSubscribers[roomId] = this._eventSubscribers[roomId].filter(
          s => s !== subscriber
        )

        if (this._eventSubscribers[roomId].length < 1) {
          MatrixManager.unlistenToRoom(roomId)
        }
      }
    }
  }

  onReceiveNewMessage(listener: MatrixRoomListener) {
    this._addRoomEventsListener('forwards', listener)
  }

  // Load {perPage} message in a room. Enumerate the events to the attached listeners
  // Assuming each message comes after each other 250ms. Return promise but no need async/await
  async backwards(
    options: {perPage?: number, initial?: boolean} = {}
  ): Promise<Array<MatrixEvent>> {
    const {perPage = 15, initial = false} = options
    const messages = []

    const listener = this._addRoomEventsListener('backwards', message => {
      if (message.age != null) {
        message.created_at = -message.age + Date.now()
      }

      messages.push(message)
    })

    await MatrixManager.loadMessagesInRoom(this._room.room_id, perPage, initial)

    listener.remove()

    return messages
  }

  // Send message to a room. Only support text message for now.
  async sendMessageToRoom(payload: {
    body: string,
    msgtype: $Subtype<string>
  }): Promise<string> {
    return await MatrixManager.sendMessageToRoom(this._room.room_id, payload)
  }

  async sendReadReceipt(eventId: string): Promise<string> {
    return await MatrixManager.sendReadReceipt(this._room.room_id, eventId)
  }
}

export default RoomEventTimeline
