import { Controller } from "@hotwired/stimulus"

// Strips non-digit characters from an input on every keystroke and paste.
// Respects the input's own maxlength attribute if set.
export default class extends Controller {
  filter(event) {
    const input = event.target
    const cleaned = input.value.replace(/\D/g, "")
    const max = parseInt(input.getAttribute("maxlength"), 10)
    input.value = Number.isFinite(max) ? cleaned.slice(0, max) : cleaned
  }
}
