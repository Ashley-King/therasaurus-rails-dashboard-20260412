import { Controller } from "@hotwired/stimulus"

// Reveals the next hidden training slot and hides the add button once all
// slots are visible. Slots stay in the DOM at stable indices so submitted
// params line up with the controller's expected shape.
export default class extends Controller {
  static targets = ["slot", "addButton"]

  add(event) {
    event.preventDefault()
    const next = this.slotTargets.find(s => s.hidden)
    if (next) {
      next.hidden = false
      next.querySelector("input, textarea")?.focus()
    }
    this.updateAddButton()
  }

  remove(event) {
    event.preventDefault()
    const slot = event.currentTarget.closest("[data-training-slots-target='slot']")
    if (!slot) return
    slot.hidden = true
    slot.querySelectorAll("input, textarea").forEach(field => { field.value = "" })
    this.updateAddButton()
  }

  updateAddButton() {
    const anyHidden = this.slotTargets.some(s => s.hidden)
    this.addButtonTarget.hidden = !anyHidden
  }
}
