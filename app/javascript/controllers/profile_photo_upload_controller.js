import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "image", "initials", "status"]

  pick() {
    this.inputTarget.click()
  }

  async upload() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const allowedTypes = ["image/jpeg", "image/png", "image/webp"]
    if (!allowedTypes.includes(file.type)) {
      this.showStatus("Please use a JPEG, PNG, or WebP image.", true)
      return
    }

    if (file.size > 10 * 1024 * 1024) {
      this.showStatus("Image must be under 10 MB.", true)
      return
    }

    this.showStatus("Uploading...")

    try {
      // 1. Get presigned URL from Rails
      const presignResponse = await this.request("/account-settings/presigned-upload", "POST", {
        content_type: file.type,
        file_size: file.size
      })

      if (!presignResponse.ok) {
        const error = await presignResponse.json()
        this.showStatus(error.error || "Upload failed.", true)
        return
      }

      const { presigned_url, public_url } = await presignResponse.json()

      // 2. Upload directly to R2
      const uploadResponse = await fetch(presigned_url, {
        method: "PUT",
        headers: { "Content-Type": file.type },
        body: file
      })

      if (!uploadResponse.ok) {
        this.showStatus("Upload to storage failed.", true)
        return
      }

      // 3. Save the URL to the therapist record
      const saveResponse = await this.request("/account-settings/account", "PATCH", {
        practice_image_url: public_url
      })

      if (!saveResponse.ok) {
        const error = await saveResponse.json()
        this.showStatus(error.error || "Failed to save.", true)
        return
      }

      // 4. Swap the displayed image
      this.imageTarget.src = public_url
      this.imageTarget.classList.remove("hidden")
      if (this.hasInitialsTarget) {
        this.initialsTarget.classList.add("hidden")
      }
      this.showStatus("Photo updated!", false)
      setTimeout(() => this.clearStatus(), 3000)
    } catch (e) {
      this.showStatus("Something went wrong. Please try again.", true)
    }
  }

  request(url, method, body) {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    return fetch(url, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify(body)
    })
  }

  showStatus(message, isError = false) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = message
    this.statusTarget.classList.remove("hidden", "text-red-600", "text-green-600", "text-text-muted")
    this.statusTarget.classList.add(isError ? "text-red-600" : "text-text-muted")
  }

  clearStatus() {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = ""
    this.statusTarget.classList.add("hidden")
  }
}
