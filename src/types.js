/* @flow */
export type MatrixCredentials = {
  homeServer: string,
  userId: string,
  accessToken: string
}

export type MatrixUser = {
  id: string,
  accessToken: string,
  avatar: string,
  displayname: ?string,
  last_active: number,
  status: ?string
}

export type MatrixRoom = {
  highlight_count: number,
  is_direct: boolean,
  last_message: MatrixEvent,
  room_id: string,
  name: ?string
}

export type MatrixEvent = {
  age: number,
  created_at: number,
  content: {
    [key: string]: any,
    msgtype: string,
    body: string
  },
  event_id: string,
  event_type: string,
  room_id: string,
  sender_id: string
}

export type MatrixRoomListener = (event: MatrixEvent) => void
export type MatrixRoomListenerRemover = {remove: () => void}
export type Direction = 'backwards' | 'forwards'
export type Timestamp = Date | number | string
export type MatrixEventSection = {data: Array<MatrixEvent>, key: number}
