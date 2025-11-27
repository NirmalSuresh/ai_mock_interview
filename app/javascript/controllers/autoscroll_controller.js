import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages"]

  connect() {
    this.scrollToBottom()
  }

  // Smooth scroll logic - scroll only if near bottom
  scrollToBottom(force = false) {
    const box = this.messagesTarget
    const distanceFromBottom = box.scrollHeight - box.scrollTop - box.clientHeight

    const isNearBottom = distanceFromBottom < 120

    if (force || isNearBottom) {
      box.scrollTop = box.scrollHeight
    }
  }

  // Called automatically after Turbo Stream updates
  messagesTargetConnected() {
    this.scrollToBottom()
  }
}
