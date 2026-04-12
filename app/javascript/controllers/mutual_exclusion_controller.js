import { Controller } from "@hotwired/stimulus"

// Handles mutual exclusion between two checkboxes.
// When one is checked, the other is automatically unchecked.
// Both can be unchecked simultaneously.
//
// Usage:
//   <div data-controller="mutual-exclusion">
//     <input type="checkbox" data-mutual-exclusion-target="first" data-action="change->mutual-exclusion#uncheckSecond">
//     <input type="checkbox" data-mutual-exclusion-target="second" data-action="change->mutual-exclusion#uncheckFirst">
//   </div>
export default class extends Controller {
  static targets = ["first", "second"]

  uncheckSecond() {
    if (this.firstTarget.checked) {
      this.secondTarget.checked = false
    }
  }

  uncheckFirst() {
    if (this.secondTarget.checked) {
      this.firstTarget.checked = false
    }
  }
}
