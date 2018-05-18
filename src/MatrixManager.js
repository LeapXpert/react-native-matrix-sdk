/* @flow */
import {NativeEventEmitter, NativeModules} from 'react-native'

const {MatrixManager} = NativeModules
const matrixManagerEmitter = new NativeEventEmitter(MatrixManager)

import type {
  MatrixCredentials,
  MatrixUser,
  MatrixRoom,
  MatrixEvent
} from './types'

type MatrixRoomListener = (event: MatrixEvent<*>) => void
type MatrixRoomListenerRemover = {remove: () => void}
type Direction = 'backwards' | 'forwards'

type MXPaginatedResult = {
  results: Array<MatrixEvent<*>>,
  token: ?{start: string, end: string}
}

class Matrix {
  _eventSubscribers: {[roomId: string]: Array<MatrixRoomListenerRemover>} = {}

  login(
    url: string,
    username: string,
    password: string
  ): Promise<MatrixCredentials> {
    return MatrixManager.login(url, username, password)
  }

  // Connect to Matrix
  async connect(credentials: MatrixCredentials): Promise<MatrixUser> {
    const user = await MatrixManager.connect(credentials)
    const invitedRooms = await MatrixManager.getInvitedRooms()

    // Auto connect to invited rooms
    for (let index = 0; index < invitedRooms.length; index++) {
      const roomId = invitedRooms[index].room_id
      await MatrixManager.joinRoom(roomId)
    }

    return user
  }

  createRoomWithUser(userId: string): Promise<MatrixRoom> {
    return MatrixManager.createRoom(userId)
  }

  // List all joined room of current user
  getJoinedRooms(): Promise<Array<MatrixRoom>> {
    return MatrixManager.getJoinedRooms()
  }

  // Listen to all the event types in a room with given id
  addRoomEventsListener(
    roomId: string,
    direction: Direction,
    listener: MatrixRoomListener
  ): MatrixRoomListenerRemover {
    if (
      this._eventSubscribers[roomId] == null ||
      this._eventSubscribers[roomId].length < 1
    ) {
      MatrixManager.listenToRoom(roomId)
    }

    const subscriber = matrixManagerEmitter.addListener(
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

  // Load {perPage} message in a room. Enumerate the events to the attached listeners
  // Assuming each message comes after each other 250ms. Return promise but no need async/await
  async loadMessagesInRoom(
    roomId: string,
    perPage: number = 15,
    initial: boolean = false
  ): Promise<Array<MatrixEvent<*>>> {
    const messages = []

    const listener = this.addRoomEventsListener(
      roomId,
      'backwards',
      message => {
        if (message.age != null) {
          message.created_at = -message.age + Date.now()
        }

        messages.push(message)
      }
    )

    await MatrixManager.loadMessagesInRoom(roomId, perPage, initial)

    listener.remove()

    return messages
  }

  async searchMessagesInRoom(
    roomId: string,
    searchTerm: string,
    currentBatch: string = '',
    limit: number = 15
  ): Promise<MXPaginatedResult> {
    const {results} = await MatrixManager.searchMessagesInRoom(
      roomId,
      searchTerm,
      currentBatch,
      limit,
      limit
    )

    if (!results || !results.length) {
      return {results: [], token: null}
    }

    const {
      event,
      context: {before, after},
      token
    } = results[0]

    const actualResults = [...after, event, ...before].map(event =>
      Object.assign(event, {created_at: Date.now() - event.age})
    )

    return {results: actualResults, token}
  }

  async getMessages(
    roomId: string,
    from: string,
    direction: Direction,
    limit: number = 15
  ): Promise<MXPaginatedResult> {
    const {results, start, end} = await MatrixManager.getMessages(
      roomId,
      from,
      direction,
      limit
    )

    const actualResults = results.map(event =>
      Object.assign(event, {created_at: Date.now() - event.age})
    )

    return {
      results: actualResults,
      token: {start, end}
    }
  }

  // Send message to a room. Only support text message for now.
  async sendMessageToRoom(
    roomId: string,
    payload: {body: string, msgtype: $Subtype<string>}
  ): Promise<string> {
    return await MatrixManager.sendMessageToRoom(roomId, payload)
  }

  async sendReadReceipt(roomId: string, eventId: string): Promise<string> {
    return await MatrixManager.sendReadReceipt(roomId, eventId)
  }
}

export default new Matrix()
