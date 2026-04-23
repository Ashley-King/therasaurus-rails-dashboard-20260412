import { Controller } from "@hotwired/stimulus"

// Toggles visibility of the second education slot + the "Add another" button.
// The slot markup is always in the DOM (for consistent nested param indices),
// but hidden slots have their inputs cleared so they don't submit values.
export default class extends Controller {
  static targets = ["slot", "addButton"]

  add(event) {
    event.preventDefault()
    const next = this.slotTargets.find(s => s.hidden)
    if (next) {
      next.hidden = false
      const input = next.querySelector("[data-college-combobox-target='input']")
      input?.focus()
    }
    this.updateAddButton()
  }

  remove(event) {
    event.preventDefault()
    const slot = event.currentTarget.closest("[data-education-slots-target='slot']")
    if (!slot) return
    slot.hidden = true
    slot.querySelectorAll("input, select").forEach(field => { field.value = "" })
    const selected = slot.querySelector("[data-college-combobox-target='selected']")
    const input = slot.querySelector("[data-college-combobox-target='input']")
    if (selected) selected.hidden = true
    if (input) input.hidden = false
    this.updateAddButton()
  }

  updateAddButton() {
    const anyHidden = this.slotTargets.some(s => s.hidden)
    this.addButtonTarget.hidden = !anyHidden
  }
}
