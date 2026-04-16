import { Controller } from "@hotwired/stimulus"

// Warns users before navigating away from a form with unsaved changes.
// Attaches to the <form> element. Listens for input/change events to mark
// the form as dirty, and hooks into both beforeunload (hard navigation)
// and turbo:before-visit (Turbo navigation) to show a confirmation.
//
// Usage:
//   <form data-controller="form-guard">
export default class extends Controller {
  connect() {
    this.dirty = false
    this.boundBeforeUnload = this.beforeUnload.bind(this)
    this.boundTurboVisit = this.turboBeforeVisit.bind(this)

    this.element.addEventListener("input", this.markDirty)
    this.element.addEventListener("change", this.markDirty)
    this.element.addEventListener("submit", this.markClean)

    window.addEventListener("beforeunload", this.boundBeforeUnload)
    document.addEventListener("turbo:before-visit", this.boundTurboVisit)
  }

  disconnect() {
    this.element.removeEventListener("input", this.markDirty)
    this.element.removeEventListener("change", this.markDirty)
    this.element.removeEventListener("submit", this.markClean)

    window.removeEventListener("beforeunload", this.boundBeforeUnload)
    document.removeEventListener("turbo:before-visit", this.boundTurboVisit)
  }

  markDirty = () => {
    this.dirty = true
  }

  markClean = () => {
    this.dirty = false
  }

  beforeUnload(event) {
    if (!this.dirty) return
    event.preventDefault()
    event.returnValue = ""
  }

  turboBeforeVisit(event) {
    if (!this.dirty) return
    if (!confirm("You have unsaved changes. Leave without saving?")) {
      event.preventDefault()
    } else {
      this.dirty = false
    }
  }
}
