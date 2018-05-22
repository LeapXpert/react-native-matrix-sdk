// @flow
import {NativeModules} from 'react-native'
import invariant from 'invariant'

import type {MatrixEvent, MatrixRoom, Direction} from '../types'

const {MatrixManager} = NativeModules

type SearchResult = {
  result: Array<MatrixEvent>,
  token: {start: string, end: string}
}

type MXPaginatedSearchResult = {
  count: number,
  nextBatch: string,
  results: Array<SearchResult>
}

type SearchContext = {
  searchTerm: string,
  currentBatch: string
}

class RoomEventSearcher {
  static create(room: MatrixRoom) {
    return new RoomEventSearcher(room)
  }

  _room: MatrixRoom

  _context: SearchContext

  _count: number

  constructor(room: MatrixRoom) {
    invariant(room != null, 'Event searcher was created with a null room')
    this._context = {searchTerm: '', currentBatch: ''}
    this._room = room
  }

  get count(): number {
    return this._count || 0
  }

  async search(pattern: string, limit: number = 15): Promise<*> {
    invariant(
      !this._context.searchTerm,
      'Searcher has been initialized with term %s',
      this._context.searchTerm
    )

    this._context.searchTerm = pattern

    const {results, nextBatch, count} = await this._searchMessageInRoom(
      this._room.room_id,
      this._context.searchTerm,
      this._context.currentBatch,
      limit
    )

    this._context.currentBatch = nextBatch
    this._count = count

    return results
  }

  async next(limit: number = 15): Promise<*> {
    const {results, nextBatch} = await this._searchMessageInRoom(
      this._room.room_id,
      this._context.searchTerm,
      this._context.currentBatch,
      limit
    )

    this._context.currentBatch = nextBatch

    return results
  }

  async _searchMessageInRoom(
    roomId: string,
    searchTerm: string,
    batch: string,
    limit: number
  ): Promise<MXPaginatedSearchResult> {
    const {
      results,
      count,
      next_batch: nextBatch
    } = await MatrixManager.searchMessagesInRoom(
      roomId,
      searchTerm,
      batch,
      limit,
      limit
    )

    if (!results || !results.length) {
      return {results: [], nextBatch: '', count: 0}
    }

    const actualResults = results.map(result => {
      // prettier-ignore
      const {event, context: {before, after}, token} = result

      const actualResult = [...after, {...event, match: true}, ...before].map(
        event => Object.assign(event, {created_at: Date.now() - event.age})
      )

      return {result: actualResult, token}
    })

    return {results: actualResults, count, nextBatch}
  }

  async getMessages(
    roomId: string,
    from: string,
    direction: Direction,
    limit: number = 15
  ): Promise<SearchResult> {
    const {results, start, end} = await MatrixManager.getMessages(
      roomId,
      from,
      direction,
      limit
    )

    const actualResults = results.map(event =>
      Object.assign(event, {created_at: Date.now() - event.age})
    )

    return {result: actualResults, token: {start, end}}
  }
}

export default RoomEventSearcher
