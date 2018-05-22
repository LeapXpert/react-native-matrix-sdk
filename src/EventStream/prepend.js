// @flow
import type {MatrixEvent, MatrixEventSection} from '../types'

export default function prependEventsToSections<
  M: Array<MatrixEvent>,
  S: Array<MatrixEventSection>
>(messages: M, sections: S): S {
  if (!messages.length) {
    return sections
  }

  return messages.reduce((result: S, message: MatrixEvent) => {
    const lastSection = result[result.length - 1]
    const timestamp = new Date(message.created_at).valueOf()

    if (lastSection == null) {
      return result.concat({data: [message], key: timestamp})
    }

    const lastMessage = lastSection.data[lastSection.data.length - 1]

    const isWithinDebounceDuration = this._isWithinDebounceDuration(
      lastMessage.created_at,
      message.created_at
    )

    const isTheSameMessageType = this._isTheSameMessageType(
      lastMessage.content.msgtype,
      message.content.msgtype
    )

    if (isWithinDebounceDuration && isTheSameMessageType) {
      result[result.length - 1] = {
        data: lastSection.data.concat(message),
        key: timestamp
      }
    } else {
      result.push({data: [message], key: timestamp})
    }

    return result
  }, sections)
}
