import { Controller } from "@hotwired/stimulus"

// Use on the messages container to auto-scroll to bottom
export default class extends Controller {
  connect() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
