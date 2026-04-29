import { Controller } from "@hotwired/stimulus"

// Multi-select picker with category filters, text search, and a
// focus-specialty star (capped at MAX_FOCUS). Checkboxes in the main
// list are the source of truth for "selected"; this controller keeps
// a Set of focus ids and rebuilds the top chip area on every change.
//
// Hidden inputs submitted:
//   therapist[specialty_ids][]        - one per checked checkbox
//   therapist[focus_specialty_ids][]  - one per starred chip
export default class extends Controller {
  static targets = [
    "search", "categorySelect", "specialty", "selectedChips",
    "selectedCount", "focusCount", "visibleCount", "empty"
  ]
  static values = { maxFocus: Number, initialFocus: Array }

  connect() {
    this.activeCategories = new Set()
    this.focusIds = new Set(this.initialFocusValue.map(String))
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

  onSpecialtyChange(event) {
    // Unchecking a focus specialty removes its focus too.
    const cb = event.currentTarget
    if (!cb.checked) this.focusIds.delete(cb.value)
    this.renderChips()
  }

  removeChip(event) {
    event.preventDefault()
    const id = event.currentTarget.dataset.specialtyId
    const row = this.specialtyTargets.find(r => r.dataset.specialtyId === id)
    if (row) {
      const cb = row.querySelector("input[type='checkbox']")
      if (cb) cb.checked = false
    }
    this.focusIds.delete(id)
    this.renderChips()
  }

  toggleFocus(event) {
    event.preventDefault()
    const btn = event.currentTarget
    if (btn.getAttribute("aria-disabled") === "true") return
    const id = btn.dataset.specialtyId
    if (this.focusIds.has(id)) {
      this.focusIds.delete(id)
    } else if (this.focusIds.size < this.maxFocusValue) {
      this.focusIds.add(id)
    }
    this.renderChips()
  }

  applyFilters() {
    const query = this.hasSearchTarget ? this.searchTarget.value.trim().toLowerCase() : ""
    let visible = 0

    this.specialtyTargets.forEach(row => {
      const name = row.dataset.specialtyName.toLowerCase()
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
    const selected = this.specialtyTargets
      .filter(r => r.querySelector("input[type='checkbox']").checked)
      .map(r => ({ id: r.dataset.specialtyId, name: r.dataset.specialtyName }))

    // Drop any stale focus ids whose checkbox is no longer checked.
    const selectedIds = new Set(selected.map(s => s.id))
    for (const id of this.focusIds) {
      if (!selectedIds.has(id)) this.focusIds.delete(id)
    }

    // Focus first, then alphabetical; name order already matches the
    // list because the server renders alphabetically and Array.filter
    // preserves order.
    const focus = selected.filter(s => this.focusIds.has(s.id))
    const rest = selected.filter(s => !this.focusIds.has(s.id))
    const ordered = [...focus, ...rest]

    if (this.hasSelectedCountTarget) this.selectedCountTarget.textContent = selected.length
    if (this.hasFocusCountTarget) this.focusCountTarget.textContent = focus.length
    if (!this.hasSelectedChipsTarget) return

    if (ordered.length === 0) {
      this.selectedChipsTarget.innerHTML =
        `<p class="text-sm font-semibold text-text-primary">No areas of expertise selected yet.</p>`
      return
    }

    const atCap = focus.length >= this.maxFocusValue
    this.selectedChipsTarget.innerHTML = ordered.map(s => {
      const isFocus = this.focusIds.has(s.id)
      const disabled = !isFocus && atCap
      const starFill = isFocus ? "currentColor" : "none"
      const starColor = isFocus ? "text-amber-500" : (disabled ? "text-gray-300" : "text-text-muted hover:text-amber-500")
      const chipBorder = isFocus ? "border-amber-400 bg-amber-50" : "border-plum-bg bg-plum-bg"
      const focusInput = isFocus
        ? `<input type="hidden" name="therapist[focus_specialty_ids][]" value="${this.escape(s.id)}">`
        : ""
      const starLabel = isFocus
        ? `Unstar ${this.escape(s.name)}`
        : (disabled ? `Specialty limit reached` : `Star ${this.escape(s.name)} as a specialty`)

      return `
        <span class="inline-flex items-center gap-2 rounded-lg border ${chipBorder} px-3 py-1.5">
          ${focusInput}
          <button type="button"
                  data-action="click->specialties-picker#toggleFocus"
                  data-specialty-id="${this.escape(s.id)}"
                  aria-pressed="${isFocus}"
                  aria-disabled="${disabled}"
                  aria-label="${starLabel}"
                  title="${starLabel}"
                  class="${starColor} cursor-pointer focus:outline-none focus:ring-2 focus:ring-plum focus:ring-offset-1 rounded ${disabled ? "cursor-not-allowed" : ""}">
            <svg class="h-4 w-4" fill="${starFill}" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M11.48 3.499a.562.562 0 0 1 1.04 0l2.125 5.111a.563.563 0 0 0 .475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 0 0-.182.557l1.285 5.385a.562.562 0 0 1-.84.61l-4.725-2.885a.562.562 0 0 0-.586 0L6.982 20.54a.562.562 0 0 1-.84-.61l1.285-5.386a.562.562 0 0 0-.182-.557l-4.204-3.602a.562.562 0 0 1 .321-.988l5.518-.442a.563.563 0 0 0 .475-.345L11.48 3.5Z"/>
            </svg>
          </button>
          <span class="text-base text-text-primary">${this.escape(s.name)}</span>
          <button type="button"
                  data-action="click->specialties-picker#removeChip"
                  data-specialty-id="${this.escape(s.id)}"
                  class="text-text-muted hover:text-text-primary cursor-pointer focus:outline-none focus:ring-2 focus:ring-plum focus:ring-offset-1 rounded"
                  aria-label="Remove ${this.escape(s.name)}">
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
            </svg>
          </button>
        </span>
      `
    }).join("")
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = String(str)
    return div.innerHTML
  }
}
