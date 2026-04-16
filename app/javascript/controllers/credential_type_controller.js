import { Controller } from "@hotwired/stimulus"

// Shows/hides credential field groups based on the selected radio button.
// Usage:
//   <div data-controller="credential-type">
//     <input type="radio" data-action="change->credential-type#switch" data-credential-type-key-param="state_license">
//     <div data-credential-type-target="group" data-key="state_license">…</div>
//   </div>
export default class extends Controller {
  static targets = ["group"]

  connect() {
    // Show the group matching the currently checked radio, if any
    const checked = this.element.querySelector("input[type='radio']:checked")
    this.showGroup(checked?.dataset?.credentialTypeKeyParam || null)
  }

  switch(event) {
    this.showGroup(event.params.key)
  }

  showGroup(key) {
    this.groupTargets.forEach(group => {
      const match = group.dataset.key === key
      group.classList.toggle("hidden", !match)

      // Disable hidden inputs so they don't submit
      group.querySelectorAll("input, select, textarea").forEach(input => {
        input.disabled = !match
      })
    })
  }
}
