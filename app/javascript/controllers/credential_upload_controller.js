import { Controller } from "@hotwired/stimulus"

// Handles credential document upload via presigned URL.
// Targets: input (file input), filename (display), status (message), urlField (hidden input for URL),
//          originalNameField (hidden input for original filename)
export default class extends Controller {
  static targets = ["input", "filename", "status", "urlField", "originalNameField"]

  static values = { uploadUrl: String }

  pick() {
    this.inputTarget.click()
  }

  async upload() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const allowedTypes = [
      "application/pdf",
      "image/jpeg", "image/png", "image/webp",
      "image/heic", "image/heif"
    ]

    if (!allowedTypes.includes(file.type)) {
      this.showStatus("File type not allowed. Use PDF, JPEG, PNG, WebP, or HEIC.", true)
      return
    }

    if (file.size > 10 * 1024 * 1024) {
      this.showStatus("File must be under 10 MB.", true)
      return
    }

    this.showStatus("Uploading…")

    try {
      // 1. Get presigned URL
      const presignResponse = await this.request(this.uploadUrlValue, "POST", {
        content_type: file.type,
        file_size: file.size
      })

      if (!presignResponse.ok) {
        const error = await presignResponse.json()
        this.showStatus(error.error || "Upload failed.", true)
        return
      }

      const { presigned_url, public_url } = await presignResponse.json()

      // 2. Upload to R2
      const uploadResponse = await fetch(presigned_url, {
        method: "PUT",
        headers: { "Content-Type": file.type },
        body: file
      })

      if (!uploadResponse.ok) {
        this.showStatus("Upload to storage failed.", true)
        return
      }

      // 3. Set hidden fields so the form submits the URL
      this.urlFieldTarget.value = public_url
      this.originalNameFieldTarget.value = file.name

      // 4. Show filename
      this.filenameTarget.textContent = file.name
      this.filenameTarget.classList.remove("hidden")
      this.showStatus("Uploaded! Click Save to keep this document.", false)
      setTimeout(() => this.clearStatus(), 4000)
    } catch (e) {
      console.error("Credential upload failed", e)
      this.showStatus("Upload failed. Check your connection and try again.", true)
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
