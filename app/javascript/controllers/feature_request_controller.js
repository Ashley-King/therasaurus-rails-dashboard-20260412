import { Controller } from "@hotwired/stimulus"

// Opens a per-link <dialog> for collecting a feature/specialty/service
// request. Native <dialog>.showModal() handles focus trap, ESC dismissal,
// and inert background — see _feature_request_link.html.erb.
export default class extends Controller {
  static targets = ["dialog"]

  open(event) {
    event.preventDefault()
    if (typeof this.dialogTarget.showModal === "function") {
      this.dialogTarget.showModal()
    } else {
      this.dialogTarget.setAttribute("open", "")
    }
  }

  close(event) {
    if (event) event.preventDefault()
    this.dialogTarget.close()
  }

  // Click on the flex wrapper outside the inner card closes the dialog.
  // currentTarget is the wrapper; target is whatever was clicked.
  // Equality means the click landed on the wrapper itself, not on the
  // card or its descendants.
  backdropClose(event) {
    if (event.target === event.currentTarget) {
      this.dialogTarget.close()
    }
  }
}
