import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timer"
export default class extends Controller {
  static values = { endTime: Number }
  static targets = ["output"]

  connect() {
    this.update()
    this.interval = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  update() {
    const now = Math.floor(Date.now() / 1000)
    const remaining = this.endTimeValue - now

    if (remaining <= 0) {
      this.outputTarget.textContent = "00:00"
      clearInterval(this.interval)
      return
    }

    const minutes = Math.floor(remaining / 60)
    const seconds = remaining % 60

    this.outputTarget.textContent =
      `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`
  }
}
