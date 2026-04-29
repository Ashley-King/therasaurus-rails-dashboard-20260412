import { Controller } from "@hotwired/stimulus"

// Add/remove FAQ rows with a hard cap. Persisted rows toggle their
// hidden _destroy flag and stay in the DOM (hidden) so the form
// submits the destruction; new rows are removed outright.
export default class extends Controller {
  static targets = ["rows", "row", "template", "addButton"]
  static values = { max: Number }

  connect() {
    this.updateAddButton()
  }

  add(event) {
    event.preventDefault()
    if (this.visibleRows().length >= this.maxValue) return

    const html = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, Date.now())
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
    this.updateAddButton()
  }

  remove(event) {
    event.preventDefault()
    const row = event.currentTarget.closest("[data-faqs-target='row']")
    if (!row) return

    const idInput = row.querySelector("input[name*='[id]']")
    if (idInput && idInput.value) {
      const destroyInput = row.querySelector("input[name*='[_destroy]']")
      if (destroyInput) destroyInput.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }
    this.updateAddButton()
  }

  visibleRows() {
    return this.rowTargets.filter(r => !r.hidden)
  }

  updateAddButton() {
    this.addButtonTarget.hidden = this.visibleRows().length >= this.maxValue
  }
}
