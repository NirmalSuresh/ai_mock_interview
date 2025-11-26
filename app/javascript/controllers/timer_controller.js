import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timer"
export default class extends Controller {
  static values = {
    seconds: Number
  }

  connect() {
    this.time = this.secondsValue
    this.timerElement = document.getElementById("timer")

    if (!this.timerElement) return

    this.update()
  }

  update() {
    const minutes = Math.floor(this.time / 60)
    const seconds = this.time % 60

    this.timerElement.textContent =
      `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`

    if (this.time > 0) {
      this.time--
      setTimeout(() => this.update(), 1000)
    }
  }
}
