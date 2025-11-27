import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scroll()
  }

  scroll() {
    this.element.scrollTop = this.element.scrollHeight
  }

  // Automatically scroll when turbo-stream updates DOM
  update() {
    this.scroll()
  }
}
