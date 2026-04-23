import { Controller } from "@hotwired/stimulus"

// Shows/hides credential field groups based on the selected credential type.
// Usage:
//   <div data-controller="credential-type">
//     <select data-action="change->credential-type#switch">…</select>
//     <div data-credential-type-target="group" data-key="state_license">…</div>
//   </div>
export default class extends Controller {
  static targets = ["group"]

  connect() {
    const select = this.element.querySelector("select[name='user_credential[credential_type]']")
    this.showGroup(select?.value || null)
  }

  switch(event) {
    this.showGroup(event.target.value)
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
