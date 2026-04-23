import { Controller } from "@hotwired/stimulus"

// Shows or hides a panel based on a checkbox's checked state.
//
// Usage:
//   <div data-controller="toggle-visibility">
//     <input type="checkbox"
//            data-toggle-visibility-target="trigger"
//            data-action="change->toggle-visibility#toggle">
//     <div data-toggle-visibility-target="panel">...</div>
//   </div>
export default class extends Controller {
  static targets = ["trigger", "panel"]

  connect() {
    this.toggle()
  }

  toggle() {
    const show = this.triggerTarget.checked
    this.panelTarget.classList.toggle("hidden", !show)
  }
}
