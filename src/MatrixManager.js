/* @flow */
import {NativeModules} from 'react-native'
const {MatrixManager} = NativeModules

import type {MatrixCredentials, MatrixUser, MatrixRoom} from './types'

type ConnectOptions = {autoJoinInvitedRoom?: boolean}

class Matrix {
  login(
    url: string,
    username: string,
    password: string
  ): Promise<MatrixCredentials> {
    return MatrixManager.login(url, username, password)
  }

  async connect(
    credentials: MatrixCredentials,
    options: ConnectOptions = {}
  ): Promise<MatrixUser> {
    const user = await MatrixManager.connect(credentials)

    if (options.autoJoinInvitedRoom) {
      const invitedRooms = await MatrixManager.getInvitedRooms()
      await Promise.all(invitedRooms.map(room => room.room_id))
    }

    return user
  }

  createRoomWithUser(userId: string): Promise<MatrixRoom> {
    return MatrixManager.createRoom(userId)
  }

  getInvitedRooms(): Promise<MatrixRoom> {
    return MatrixManager.getInvitedRooms()
  }

  getJoinedRooms(): Promise<Array<MatrixRoom>> {
    return MatrixManager.getJoinedRooms()
  }
}

export default new Matrix()
