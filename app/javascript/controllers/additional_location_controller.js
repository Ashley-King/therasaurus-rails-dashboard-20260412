import { Controller } from "@hotwired/stimulus"

// Toggles the additional-location form between its empty placeholder
// ("Add additional location" button) and the expanded form. The form
// stays in the DOM either way so the Stimulus ZIP combobox inside it
// initializes once on page load.
export default class extends Controller {
  static targets = ["empty", "form"]

  show(event) {
    event.preventDefault()
    this.emptyTarget.hidden = true
    this.formTarget.hidden = false
    const zipInput = this.formTarget.querySelector("[data-zip-combobox-target='zipInput']")
    zipInput?.focus()
  }
}
