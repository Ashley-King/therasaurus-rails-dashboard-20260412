import { Controller } from "@hotwired/stimulus"

// Multi-select picker with category filters + text search.
// Checkboxes in the main list are the source of truth; the chip area
// at the top is a mirror rebuilt whenever selection changes. Category
// filters are OR-combined; search narrows by name. Both filters hide
// list rows but never hide selected chips at the top.
export default class extends Controller {
  static targets = [
    "search", "categorySelect", "service", "selectedChips",
    "selectedCount", "totalCount", "visibleCount", "empty"
  ]
  static values = { max: Number }

  connect() {
    this.activeCategories = new Set()
    this.renderChips()
    this.applyFilters()
  }

  onSearch() {
    this.applyFilters()
  }

  selectCategory(event) {
    const id = event.target.value
    this.activeCategories.clear()
    if (id) this.activeCategories.add(id)
    this.applyFilters()
  }

  clearFilters() {
    this.activeCategories.clear()
    if (this.hasSearchTarget) this.searchTarget.value = ""
    if (this.hasCategorySelectTarget) this.categorySelectTarget.value = ""
    this.applyFilters()
  }

  onServiceChange(event) {
    // If checking this would exceed the cap, undo it.
    const cb = event.currentTarget
    if (cb.checked && this.atCap()) {
      cb.checked = false
      return
    }
    this.renderChips()
  }

  atCap() {
    if (!this.hasMaxValue || this.maxValue <= 0) return false
    const count = this.serviceTargets
      .filter(r => r.querySelector("input[type='checkbox']").checked).length
    return count >= this.maxValue
  }

  applyCap() {
    if (!this.hasMaxValue || this.maxValue <= 0) return
    const atCap = this.atCap()
    this.serviceTargets.forEach(row => {
      const cb = row.querySelector("input[type='checkbox']")
      if (!cb) return
      const disable = atCap && !cb.checked
      cb.disabled = disable
      row.classList.toggle("opacity-50", disable)
      const label = row.querySelector("label")
      if (label) label.classList.toggle("cursor-not-allowed", disable)
    })
  }

  removeChip(event) {
    event.preventDefault()
    const id = event.currentTarget.dataset.serviceId
    const row = this.serviceTargets.find(r => r.dataset.serviceId === id)
    if (row) {
      const cb = row.querySelector("input[type='checkbox']")
      if (cb) cb.checked = false
    }
    this.renderChips()
  }

  applyFilters() {
    const query = this.hasSearchTarget ? this.searchTarget.value.trim().toLowerCase() : ""
    let visible = 0

    this.serviceTargets.forEach(row => {
      const name = row.dataset.serviceName.toLowerCase()
      const cats = row.dataset.categoryIds.split(" ").filter(Boolean)

      const matchesText = query === "" || name.includes(query)
      const matchesCats = this.activeCategories.size === 0 ||
        cats.some(c => this.activeCategories.has(c))

      const show = matchesText && matchesCats
      row.hidden = !show
      if (show) visible += 1
    })

    if (this.hasVisibleCountTarget) this.visibleCountTarget.textContent = visible
    if (this.hasEmptyTarget) this.emptyTarget.hidden = visible > 0
  }

  renderChips() {
    const selected = this.serviceTargets
      .filter(r => r.querySelector("input[type='checkbox']").checked)
      .map(r => ({ id: r.dataset.serviceId, name: r.dataset.serviceName }))

    if (this.hasSelectedCountTarget) this.selectedCountTarget.textContent = selected.length
    this.applyCap()

    if (!this.hasSelectedChipsTarget) return

    if (selected.length === 0) {
      this.selectedChipsTarget.innerHTML =
        `<p class="text-sm font-semibold text-text-primary">No services selected yet.</p>`
      return
    }

    this.selectedChipsTarget.innerHTML = selected.map(s => `
      <span class="inline-flex items-center gap-2 rounded-lg border border-plum-bg bg-plum-bg px-3 py-1.5">
        <span class="text-base text-text-primary">${this.escape(s.name)}</span>
        <button type="button"
                data-action="click->services-picker#removeChip"
                data-service-id="${this.escape(s.id)}"
                class="text-text-muted hover:text-text-primary cursor-pointer focus:outline-none focus:ring-2 focus:ring-plum focus:ring-offset-1 rounded"
                aria-label="Remove ${this.escape(s.name)}">
          <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </span>
    `).join("")
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = String(str)
    return div.innerHTML
  }
}
