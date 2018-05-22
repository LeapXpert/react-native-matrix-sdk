// @flow
import type {MatrixEvent, MatrixEventSection} from '../types'

export default function appendEventsToSections<
  M: Array<MatrixEvent>,
  S: Array<MatrixEventSection>
>(messages: M, sections: S): S {
  if (!messages.length) {
    return sections
  }

  return messages.reduce((result, message) => {
    const lastSection = result[0]
    const timestamp = new Date(message.created_at).valueOf()

    if (lastSection != null) {
      const lastMessageType = lastSection.data[0].content.msgtype
      const newMessageType = message.content.msgtype

      if (
        this._isWithinDebounceDuration(timestamp, lastSection.key) &&
        this._isTheSameMessageType(newMessageType, lastMessageType)
      ) {
        const lastSectionWithNewData = {
          data: [message].concat(lastSection.data),
          key: timestamp
        }

        return [lastSectionWithNewData].concat(result.slice(1))
      }
    }

    const newSection = {data: [message], key: timestamp}

    return [newSection].concat(result)
  }, sections)
}
