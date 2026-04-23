import { Controller } from "@hotwired/stimulus"
import "trix"

// Scoped Trix editor for the practice introduction.
// The view supplies a custom <trix-toolbar> with only bold, bullet list,
// numbered list, undo, and redo — so headings, italic, links, and quotes
// have no UI entry point. Server-side sanitize strips anything pasted in.
//
// The counter measures visible text (not HTML tags), matching the
// server-side Therapist#practice_description_within_limit check.
export default class extends Controller {
  static targets = ["counter"]
  static values = { max: Number }

  connect() {
    this.boundBlockFile = (event) => event.preventDefault()
    this.boundOnChange = () => {
      this.element.dispatchEvent(new Event("input", { bubbles: true }))
      this.updateCount()
    }
    this.boundOnReady = () => this.updateCount()

    this.element.addEventListener("trix-file-accept", this.boundBlockFile)
    this.element.addEventListener("trix-change", this.boundOnChange)
    this.element.addEventListener("trix-initialize", this.boundOnReady)
  }

  disconnect() {
    this.element.removeEventListener("trix-file-accept", this.boundBlockFile)
    this.element.removeEventListener("trix-change", this.boundOnChange)
    this.element.removeEventListener("trix-initialize", this.boundOnReady)
  }

  updateCount() {
    if (!this.hasCounterTarget) return
    const count = this.plainTextLength()
    const max = this.maxValue
    this.counterTarget.textContent = max ? `${count} / ${max}` : `${count}`
    this.counterTarget.classList.toggle("text-status-attention", max > 0 && count > max)
  }

  plainTextLength() {
    const editorEl = this.element.querySelector("trix-editor")
    if (!editorEl?.editor) return 0
    // Trix's getDocument().toString() always ends with a trailing newline.
    return editorEl.editor.getDocument().toString().replace(/\n$/, "").length
  }
}
