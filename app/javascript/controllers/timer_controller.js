import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { seconds: Number }

  connect() {
    this.time = this.secondsValue
    this.timerSpan = document.querySelector("#timer")
    this.update()
  }

  update() {
    if (!this.timerSpan) return

    const min = Math.floor(this.time / 60)
    const sec = this.time % 60

    this.timerSpan.textContent =
      `${min.toString().padStart(2, "0")}:${sec.toString().padStart(2, "0")}`

    if (this.time > 0) {
      this.time--
      setTimeout(() => this.update(), 1000)
    }
  }
}
