import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.focus()
  }

  focus() {
    if (this.hasInputTarget) {
      // a small delay ensures Turbo rendered the form completely
      setTimeout(() => {
        this.inputTarget.focus()
      }, 40)
    }
  }
}
