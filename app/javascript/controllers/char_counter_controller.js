import { Controller } from "@hotwired/stimulus"

// Shows a live character count for a text field, e.g. "42 / 300".
// Reads the max from the input's maxlength attribute.
//
// Usage:
//   <div data-controller="char-counter">
//     <textarea maxlength="300"
//               data-char-counter-target="field"
//               data-action="input->char-counter#update"></textarea>
//     <span data-char-counter-target="output"></span>
//   </div>
export default class extends Controller {
  static targets = ["field", "output"]

  connect() {
    this.update()
  }

  update() {
    const max = parseInt(this.fieldTarget.getAttribute("maxlength"), 10)
    const count = this.fieldTarget.value.length
    this.outputTarget.textContent = Number.isFinite(max) ? `${count} / ${max}` : `${count}`
  }
}
