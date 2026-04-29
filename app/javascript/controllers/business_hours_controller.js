import { Controller } from "@hotwired/stimulus"

// Drives the business hours grid: a per-row "Closed" toggle hides time
// selects, "Copy down" copies a row's values into every row below it,
// and "Clear all hours" marks every day closed in one click.
export default class extends Controller {
  static targets = ["row", "closed", "times"]

  toggleClosed(event) {
    const row = event.target.closest("[data-business-hours-target='row']")
    if (!row) return
    this.applyClosedState(row, event.target.checked)
  }

  copyDown(event) {
    event.preventDefault()
    const button = event.currentTarget
    const sourceIndex = parseInt(button.dataset.rowIndex, 10)
    const source = this.rowTargets[sourceIndex]
    if (!source) return

    const sourceClosed = this.closedInput(source).checked
    const sourceOpen = this.openSelect(source)?.value
    const sourceClose = this.closeSelect(source)?.value

    for (let i = sourceIndex + 1; i < this.rowTargets.length; i++) {
      const target = this.rowTargets[i]
      const targetClosedInput = this.closedInput(target)
      targetClosedInput.checked = sourceClosed
      this.applyClosedState(target, sourceClosed)

      if (!sourceClosed) {
        const openSelect = this.openSelect(target)
        const closeSelect = this.closeSelect(target)
        if (openSelect && sourceOpen !== undefined) openSelect.value = sourceOpen
        if (closeSelect && sourceClose !== undefined) closeSelect.value = sourceClose
      }
    }
  }

  clearAll(event) {
    event.preventDefault()
    this.rowTargets.forEach((row) => {
      this.closedInput(row).checked = true
      this.applyClosedState(row, true)
    })
  }

  applyClosedState(row, isClosed) {
    const times = row.querySelector("[data-business-hours-target='times']")
    if (!times) return
    times.classList.toggle("hidden", isClosed)
    times.querySelectorAll("select").forEach((select) => {
      select.disabled = isClosed
    })
  }

  closedInput(row) {
    return row.querySelector("input[type='checkbox'][name*='[closed]']")
  }

  openSelect(row) {
    return row.querySelector("select[name*='[open]']")
  }

  closeSelect(row) {
    return row.querySelector("select[name*='[close]']")
  }
}
