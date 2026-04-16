import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]

  static values = { copy: String }

  copy() {
    const text = this.hasCopyValue ? this.copyValue : this.sourceTarget.value
    navigator.clipboard.writeText(text).then(() => {
      const btn = this.buttonTarget
      const originalHTML = btn.innerHTML

      btn.innerHTML = `<svg class="h-3.5 w-3.5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" /></svg><span class="text-[9px] text-green-600 font-medium leading-none">Copied!</span>`

      setTimeout(() => {
        btn.innerHTML = originalHTML
      }, 2000)
    })
  }
}
