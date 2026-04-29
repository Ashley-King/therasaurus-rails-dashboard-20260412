import { Controller } from "@hotwired/stimulus"

// Formats a US phone number as the user types: (XXX) XXX-XXXX.
// Strips non-digits, caps at 10 digits, and reformats existing values on connect.
export default class extends Controller {
  connect() {
    if (this.element.value) {
      this.element.value = this.formatted(this.digitsOnly(this.element.value))
    }
  }

  format(event) {
    const input = event.target
    input.value = this.formatted(this.digitsOnly(input.value))
  }

  digitsOnly(value) {
    return value.replace(/\D/g, "").slice(0, 10)
  }

  formatted(digits) {
    if (digits.length === 0) return ""
    if (digits.length <= 3) return digits
    if (digits.length <= 6) return `(${digits.slice(0, 3)}) ${digits.slice(3)}`
    return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`
  }
}
