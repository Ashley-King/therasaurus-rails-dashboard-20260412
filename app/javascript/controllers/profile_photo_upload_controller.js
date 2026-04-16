import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

const OUTPUT_SIZE = 400
const MAX_FILE_SIZE = 5 * 1024 * 1024 // 5 MB
const ALLOWED_TYPES = ["image/jpeg", "image/png"]

export default class extends Controller {
  static targets = ["input", "image", "initials", "status", "dialog", "cropImage"]

  pick() {
    this.inputTarget.click()
  }

  // File selected → validate, then open crop modal
  openCropper() {
    const file = this.inputTarget.files[0]
    if (!file) return

    if (!ALLOWED_TYPES.includes(file.type)) {
      this.showStatus("Please use a JPEG or PNG image.", true)
      return
    }

    if (file.size > MAX_FILE_SIZE) {
      this.showStatus("Image must be under 5 MB.", true)
      return
    }

    // Load image into the crop dialog
    const url = URL.createObjectURL(file)
    this.cropImageTarget.src = url
    this.cropImageTarget.onload = () => {
      this.dialogTarget.showModal()
      this.initCropper()
    }
  }

  initCropper() {
    this.destroyCropper()
    this.cropper = new Cropper(this.cropImageTarget, {
      aspectRatio: 1,
      viewMode: 1,
      dragMode: "move",
      autoCropArea: 0.9,
      cropBoxResizable: true,
      cropBoxMovable: true,
      background: false,
      modal: true,
      guides: false,
      center: true,
      highlight: false,
      responsive: true,
      restore: false
    })
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  cancelCrop() {
    this.dialogTarget.close()
    this.destroyCropper()
    this.inputTarget.value = ""
  }

  async confirmCrop() {
    if (!this.cropper) return

    this.showStatus("Processing…")
    this.dialogTarget.close()

    try {
      const canvas = this.cropper.getCroppedCanvas({
        width: OUTPUT_SIZE,
        height: OUTPUT_SIZE,
        imageSmoothingEnabled: true,
        imageSmoothingQuality: "high"
      })

      this.destroyCropper()

      const blob = await new Promise((resolve, reject) => {
        canvas.toBlob(
          (b) => b ? resolve(b) : reject(new Error("Canvas export failed")),
          "image/jpeg",
          0.85
        )
      })

      await this.uploadBlob(blob)
    } catch (e) {
      console.error("Crop failed", e)
      this.showStatus("Something went wrong. Please try again.", true)
    }
  }

  async uploadBlob(blob) {
    this.showStatus("Uploading…")

    // 1. Get presigned URL
    const presignResponse = await this.request("/account-settings/presigned-upload", "POST", {
      content_type: blob.type,
      file_size: blob.size
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
      headers: { "Content-Type": blob.type },
      body: blob
    })

    if (!uploadResponse.ok) {
      this.showStatus("Upload to storage failed.", true)
      return
    }

    // 3. Save URL to therapist record
    const saveResponse = await this.request("/account-settings/account", "PATCH", {
      practice_image_url: public_url
    })

    if (!saveResponse.ok) {
      const error = await saveResponse.json()
      this.showStatus(error.error || "Failed to save.", true)
      return
    }

    // 4. Update UI
    this.imageTarget.src = public_url
    this.imageTarget.classList.remove("hidden")
    if (this.hasInitialsTarget) {
      this.initialsTarget.classList.add("hidden")
    }
    this.showStatus("Photo updated!", false)
    setTimeout(() => this.clearStatus(), 3000)
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

  disconnect() {
    this.destroyCropper()
  }
}
