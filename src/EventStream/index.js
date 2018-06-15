// @flow
import type {Timestamp, MatrixEvent, MatrixEventSection} from '../types'

import append from './append'
import prepend from './prepend'

let DEBOUNCE_DURATION: number = 60000

class EventStream {
  static createEmpty(): EventStream {
    return new EventStream()
  }

  static setDebounceDuration(duration: number) {
    DEBOUNCE_DURATION = duration
  }

  _events: Array<MatrixEventSection> = []

  _isWithinDebounceDuration(newKey: Timestamp, sectionKey: Timestamp): boolean {
    return new Date(newKey) - new Date(sectionKey) <= DEBOUNCE_DURATION
  }

  _isTheSameEventType(str1: string, str2: string): boolean {
    return str1 === str2
  }

  append(...events: Array<MatrixEvent>) {
    return append.call(this, events, this._events)
  }

  prepend(...events: Array<MatrixEvent>) {
    return prepend.call(this, events, this._events)
  }

  toJSON() {
    return this._events
  }
}

export default EventStream
