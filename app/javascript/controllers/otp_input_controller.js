import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.validate()
  }

  validate() {
    const valid = this.inputTarget.value.length === 8
    this.submitTarget.disabled = !valid
  }
}
