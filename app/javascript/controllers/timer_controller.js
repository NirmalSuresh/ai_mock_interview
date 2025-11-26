import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { seconds: Number }

  connect() {
    this.time = this.secondsValue
    this.update()
  }

  update() {
    const el = document.getElementById("timer")
    if (!el) return

    let m = Math.floor(this.time / 60)
    let s = this.time % 60

    el.textContent =
      `${m.toString().padStart(2,'0')}:${s.toString().padStart(2,'0')}`

    if (this.time <= 0) return

    this.time--
    setTimeout(() => this.update(), 1000)
  }
}
