import { Controller } from "@hotwired/stimulus"

// Three-state UX for ZIP entry:
//
//   empty    — ZIP combobox (the "finder") is visible with autocomplete;
//              a "Can't find your ZIP? Enter it manually" checkbox sits
//              below it.
//   selected — user picked a suggestion. Finder is replaced by a chip
//              ("02138 — Cambridge, MA ×"). Values live in hidden carriers
//              and submit with the form.
//   manual   — user checked the box. Finder is hidden. A plain ZIP + City
//              + State trio appears. Autocomplete is off; lat/lng/match
//              are cleared so the server falls back to
//              ZipLookup.geocode_with_fallback.
//
// Implementation detail: the form has TWO inputs named `<prefix>[zip]`,
// one in the finder and one in the manual section. Only the one matching
// the current state is enabled; the other has `disabled` so it never
// submits. That keeps a single form value for ZIP without needing to
// move inputs around in the DOM.
export default class extends Controller {
  static targets = [
    "finder",
    "finderZip",
    "listbox",
    "selected",
    "selectedZip",
    "selectedLocation",
    "manualToggle",
    "manualCheckbox",
    "manualFields",
    "manualZip",
    "cityInput",
    "stateInput",
    "latInput",
    "lngInput",
    "matchInput",
    "hint"
  ]
  static values = { searchUrl: String, index: Number }

  connect() {
    this.activeIndex = -1
    this.options = []
    this.currentQuery = ""
    this.debounceTimer = null
    this.listboxId = `zip-combobox-listbox-${this.indexValue}`
    this.listboxTarget.id = this.listboxId
    this.finderZipTarget.setAttribute("aria-controls", this.listboxId)

    this.form = this.element.closest("form")
    if (this.form) {
      this.submitHandler = this.onFormSubmit.bind(this)
      this.form.addEventListener("submit", this.submitHandler)
    }

    this.applyInitialState()
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
    if (this.form && this.submitHandler) {
      this.form.removeEventListener("submit", this.submitHandler)
    }
  }

  applyInitialState() {
    const hasZip = this.finderZipTarget.value.trim().length > 0
    const hasCity = this.cityInputTarget.value.trim().length > 0
    const hasLat = this.latInputTarget.value.trim().length > 0

    if (hasZip && hasCity && hasLat) {
      this.showSelected()
    } else if (hasZip || hasCity) {
      // Previously saved via manual entry — propagate zip to the manual input.
      this.manualZipTarget.value = this.finderZipTarget.value
      this.enterManual()
    } else {
      this.showEmpty()
    }
  }

  onFormSubmit(event) {
    // Block the "typed ZIP in the finder but never picked a suggestion"
    // case. Native `required` covers empty submits; this guard covers the
    // half-committed one.
    const finderZip = this.finderZipTarget.value.trim()
    const hasCity = this.cityInputTarget.value.trim().length > 0
    const isManual = this.manualCheckboxTarget.checked

    if (!isManual && finderZip && !hasCity) {
      event.preventDefault()
      this.showHint()
      this.finderZipTarget.focus()
    } else {
      this.hideHint()
    }
  }

  showHint() {
    if (this.hasHintTarget) this.hintTarget.hidden = false
  }

  hideHint() {
    if (this.hasHintTarget) this.hintTarget.hidden = true
  }

  // ── State transitions ──

  showEmpty() {
    this.selectedTarget.hidden = true
    this.finderTarget.hidden = false
    this.manualFieldsTarget.hidden = true
    this.manualToggleTarget.hidden = false
    this.manualCheckboxTarget.checked = false

    this.finderZipTarget.disabled = false
    this.manualZipTarget.disabled = true
    this.cityInputTarget.required = false
    this.stateInputTarget.required = false

    this.hideListbox()
    this.hideHint()
  }

  showSelected() {
    this.selectedZipTarget.textContent = this.finderZipTarget.value
    this.selectedLocationTarget.textContent =
      `${this.cityInputTarget.value}, ${this.stateInputTarget.value}`

    this.selectedTarget.hidden = false
    this.finderTarget.hidden = true
    this.manualFieldsTarget.hidden = true
    this.manualToggleTarget.hidden = true
    this.manualCheckboxTarget.checked = false

    this.finderZipTarget.disabled = false
    this.manualZipTarget.disabled = true
    this.cityInputTarget.required = false
    this.stateInputTarget.required = false

    this.hideListbox()
    this.hideHint()
  }

  enterManual() {
    this.selectedTarget.hidden = true
    this.finderTarget.hidden = true
    this.manualFieldsTarget.hidden = false
    this.manualToggleTarget.hidden = false
    this.manualCheckboxTarget.checked = true

    this.finderZipTarget.disabled = true
    this.manualZipTarget.disabled = false
    this.cityInputTarget.required = true
    this.stateInputTarget.required = true

    // Clear any prior autocomplete resolve.
    this.latInputTarget.value = ""
    this.lngInputTarget.value = ""
    this.matchInputTarget.value = "0"

    this.hideListbox()
    this.hideHint()
  }

  // ── Event handlers ──

  toggleManual(event) {
    if (event.currentTarget.checked) {
      // Preserve whatever ZIP the user has typed so far.
      this.manualZipTarget.value = this.finderZipTarget.value
      this.enterManual()
    } else {
      // Preserve their typed ZIP going back to the finder.
      this.finderZipTarget.value = this.manualZipTarget.value
      this.manualZipTarget.value = ""
      this.cityInputTarget.value = ""
      this.stateInputTarget.value = ""
      this.showEmpty()
    }
  }

  onInput(event) {
    // Any keystroke in the finder invalidates a prior autocomplete resolve.
    this.latInputTarget.value = ""
    this.lngInputTarget.value = ""
    this.matchInputTarget.value = "0"
    this.hideHint()

    const value = event.target.value.trim()
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.fetchResults(value), 150)
  }

  onFocus() {
    const value = this.finderZipTarget.value.trim()
    if (value.length >= 2) this.fetchResults(value)
  }

  onBlur() {
    setTimeout(() => this.hideListbox(), 150)
  }

  // ── Autocomplete ──

  async fetchResults(query) {
    if (query.length < 2) {
      this.hideListbox()
      this.options = []
      return
    }
    try {
      const response = await fetch(`${this.searchUrlValue}?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) throw new Error("search failed")
      const data = await response.json()
      this.renderOptions(data, query)
    } catch (_e) {
      this.hideListbox()
    }
  }

  renderOptions(zips, query) {
    this.options = zips
    this.currentQuery = query

    if (zips.length === 0) {
      this.listboxTarget.innerHTML = `<li class="px-3 py-2 text-base text-text-muted">No matches</li>`
      this.showListbox()
      this.activeIndex = -1
      return
    }

    const items = zips.map((z, i) => {
      const highlighted = this.highlightPrefix(z.zip, query)
      return `<li id="${this.listboxId}-opt-${i}" role="option" aria-selected="false"
                  data-action="mousedown->zip-combobox#selectOption mouseenter->zip-combobox#hoverOption"
                  data-index="${i}"
                  class="cursor-pointer px-3 py-2 text-base text-text-primary hover:bg-gray-50 flex items-center gap-2">
                <svg class="h-4 w-4 text-text-muted flex-none" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a2 2 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                </svg>
                <span><span class="font-medium">${highlighted}</span> — ${this.escape(z.city)}, ${this.escape(z.state)}</span>
              </li>`
    }).join("")

    this.listboxTarget.innerHTML = items
    this.showListbox()
    this.activeIndex = -1
  }

  highlightPrefix(zip, query) {
    const safeZip = this.escape(zip)
    if (!query || !zip.startsWith(query)) return safeZip
    const prefix = this.escape(query)
    const rest = this.escape(zip.slice(query.length))
    return `<mark class="bg-transparent font-semibold underline decoration-plum decoration-2 underline-offset-2">${prefix}</mark>${rest}`
  }

  showListbox() {
    this.listboxTarget.hidden = false
    this.finderZipTarget.setAttribute("aria-expanded", "true")
  }

  hideListbox() {
    this.listboxTarget.hidden = true
    this.finderZipTarget.setAttribute("aria-expanded", "false")
    this.finderZipTarget.removeAttribute("aria-activedescendant")
  }

  navigate(event) {
    const count = this.options.length
    if (event.key === "Escape") {
      this.hideListbox()
      return
    }
    if (event.key === "Tab") {
      this.hideListbox()
      return
    }
    if (count === 0) return
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activeIndex = (this.activeIndex + 1) % count
      this.highlightActive()
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activeIndex = (this.activeIndex - 1 + count) % count
      this.highlightActive()
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      this.select(this.options[this.activeIndex])
    }
  }

  highlightActive() {
    const lis = this.listboxTarget.querySelectorAll("li[role='option']")
    lis.forEach((li, i) => {
      const isActive = i === this.activeIndex
      li.classList.toggle("bg-gray-100", isActive)
      li.setAttribute("aria-selected", isActive ? "true" : "false")
      if (isActive) this.finderZipTarget.setAttribute("aria-activedescendant", li.id)
    })
  }

  selectOption(event) {
    event.preventDefault()
    const idx = parseInt(event.currentTarget.dataset.index, 10)
    this.select(this.options[idx])
  }

  hoverOption(event) {
    const idx = parseInt(event.currentTarget.dataset.index, 10)
    this.activeIndex = idx
    this.highlightActive()
  }

  select(zip) {
    this.finderZipTarget.value = zip.zip
    this.cityInputTarget.value = zip.city
    this.stateInputTarget.value = zip.state
    this.latInputTarget.value = zip.lat ?? ""
    this.lngInputTarget.value = zip.lng ?? ""
    this.matchInputTarget.value = "1"
    this.showSelected()
  }

  clear(event) {
    event?.preventDefault()
    this.finderZipTarget.value = ""
    this.manualZipTarget.value = ""
    this.cityInputTarget.value = ""
    this.stateInputTarget.value = ""
    this.latInputTarget.value = ""
    this.lngInputTarget.value = ""
    this.matchInputTarget.value = "0"
    this.showEmpty()
    this.finderZipTarget.focus()
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = str == null ? "" : String(str)
    return div.innerHTML
  }
}
