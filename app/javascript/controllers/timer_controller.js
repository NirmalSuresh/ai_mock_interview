import { Controller } from "@hotwired/stimulus"

// <span data-controller="timer" data-timer-remaining-value="3600"></span>
export default class extends Controller {
  static values = { remaining: Number }

  connect() {
    this.update()
    this.timer = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  tick() {
    if (this.remainingValue <= 0) return

    this.remainingValue -= 1
    this.update()
  }

  update() {
    const minutes = Math.floor(this.remainingValue / 60)
    const seconds = this.remainingValue % 60
    this.element.textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`
  }
}
