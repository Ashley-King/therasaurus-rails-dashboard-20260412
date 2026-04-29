import { Controller } from "@hotwired/stimulus"

// Multi-select autocomplete for insurance companies. Each selected item
// renders as a chip below the input. Chips carry a hidden input named
// `therapist[insurance_company_ids][]` for existing records or
// `therapist[insurance_company_names][]` for pending write-ins — the
// server resolver treats names as find-or-submit.
export default class extends Controller {
  static targets = ["input", "listbox", "chips"]
  static values = { searchUrl: String }

  connect() {
    this.activeIndex = -1
    this.options = []
    this.hasAddNew = false
    this.currentQuery = ""
    this.debounceTimer = null
    this.listboxTarget.id = `insurance-combobox-listbox`
    this.inputTarget.setAttribute("aria-controls", this.listboxTarget.id)
  }

  disconnect() {
    clearTimeout(this.debounceTimer)
  }

  onInput(event) {
    const value = event.target.value.trim()
    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => this.fetchResults(value), 150)
  }

  onFocus() {
    const value = this.inputTarget.value.trim()
    if (value.length >= 2) this.fetchResults(value)
  }

  onBlur() {
    setTimeout(() => this.hideListbox(), 150)
  }

  async fetchResults(query) {
    if (query.length < 2) {
      this.listboxTarget.innerHTML = `<li class="px-3 py-2 text-sm text-text-muted">Type at least 2 characters…</li>`
      this.showListbox()
      this.options = []
      this.hasAddNew = false
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

  renderOptions(companies, query) {
    const alreadySelectedIds = this.selectedIds()
    const visible = companies.filter(c => !alreadySelectedIds.has(c.id))
    this.options = visible
    this.currentQuery = query

    const items = visible.map((c, i) => {
      const badge = c.status === "pending"
        ? `<span class="ml-2 inline-flex items-center rounded-full bg-amber-100 text-amber-800 px-2 py-0.5 text-xs font-medium">Pending review</span>`
        : ""
      return `<li id="${this.listboxTarget.id}-opt-${i}" role="option" aria-selected="false"
                  data-action="mousedown->insurance-combobox#selectOption mouseenter->insurance-combobox#hoverOption"
                  data-index="${i}"
                  class="cursor-pointer px-3 py-2 text-sm text-text-primary hover:bg-gray-50 flex items-center">
                <span>${this.escape(c.name)}</span>${badge}
              </li>`
    }).join("")

    const normalizedQuery = query.toLowerCase()
    const exactInResults = companies.some(c => c.name.toLowerCase() === normalizedQuery)
    const exactInSelected = this.selectedNames().has(normalizedQuery)
    const addNewIdx = visible.length
    let addNewHtml = ""
    if (!exactInResults && !exactInSelected) {
      addNewHtml = `<li id="${this.listboxTarget.id}-opt-${addNewIdx}" role="option" aria-selected="false"
                       data-action="mousedown->insurance-combobox#selectOption mouseenter->insurance-combobox#hoverOption"
                       data-index="${addNewIdx}"
                       data-new="true"
                       class="cursor-pointer px-3 py-2 text-sm font-medium text-plum border-t border-gray-100 hover:bg-gray-50">
                     + Add “${this.escape(query)}” <span class="text-text-muted font-normal">(pending review)</span>
                   </li>`
      this.hasAddNew = true
    } else {
      this.hasAddNew = false
    }

    if (visible.length === 0 && !this.hasAddNew) {
      this.listboxTarget.innerHTML = `<li class="px-3 py-2 text-sm text-text-muted">No matches</li>`
    } else {
      this.listboxTarget.innerHTML = items + addNewHtml
    }
    this.showListbox()
    this.activeIndex = -1
  }

  showListbox() {
    this.listboxTarget.hidden = false
    this.inputTarget.setAttribute("aria-expanded", "true")
  }

  hideListbox() {
    this.listboxTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }

  navigate(event) {
    const count = this.options.length + (this.hasAddNew ? 1 : 0)
    if (event.key === "Escape") {
      this.hideListbox()
      return
    }
    if (event.key === "Backspace" && this.inputTarget.value === "") {
      const chips = this.chipsTarget.querySelectorAll("[data-insurance-chip]")
      if (chips.length > 0) chips[chips.length - 1].remove()
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
      this.commitActive()
    }
  }

  highlightActive() {
    const lis = this.listboxTarget.querySelectorAll("li[role='option']")
    lis.forEach((li, i) => {
      const isActive = i === this.activeIndex
      li.classList.toggle("bg-gray-100", isActive)
      li.setAttribute("aria-selected", isActive ? "true" : "false")
      if (isActive) this.inputTarget.setAttribute("aria-activedescendant", li.id)
    })
  }

  commitActive() {
    if (this.activeIndex < 0) return
    if (this.hasAddNew && this.activeIndex === this.options.length) {
      this.addNewChip(this.currentQuery)
    } else {
      this.addChip(this.options[this.activeIndex])
    }
  }

  selectOption(event) {
    event.preventDefault()
    if (event.currentTarget.dataset.new === "true") {
      this.addNewChip(this.currentQuery)
    } else {
      const idx = parseInt(event.currentTarget.dataset.index, 10)
      this.addChip(this.options[idx])
    }
  }

  hoverOption(event) {
    const idx = parseInt(event.currentTarget.dataset.index, 10)
    this.activeIndex = idx
    this.highlightActive()
  }

  addChip(company) {
    this.chipsTarget.insertAdjacentHTML("beforeend", this.chipHtml({
      id: company.id, name: company.name, status: company.status
    }))
    this.resetInput()
  }

  addNewChip(name) {
    const trimmed = name.trim().replace(/\s+/g, " ")
    if (!trimmed) return
    if (this.selectedNames().has(trimmed.toLowerCase())) { this.resetInput(); return }
    this.chipsTarget.insertAdjacentHTML("beforeend", this.chipHtml({
      id: null, name: trimmed, status: "pending"
    }))
    this.resetInput()
  }

  removeChip(event) {
    event.preventDefault()
    event.currentTarget.closest("[data-insurance-chip]").remove()
  }

  resetInput() {
    this.inputTarget.value = ""
    this.currentQuery = ""
    this.options = []
    this.hasAddNew = false
    this.hideListbox()
    this.inputTarget.focus()
  }

  chipHtml({ id, name, status }) {
    const hidden = id
      ? `<input type="hidden" name="therapist[insurance_company_ids][]" value="${this.escape(id)}">`
      : `<input type="hidden" name="therapist[insurance_company_names][]" value="${this.escape(name)}">`
    const badge = status === "pending"
      ? `<span class="inline-flex items-center rounded-full bg-amber-100 text-amber-800 px-2 py-0.5 text-xs font-medium">Pending review</span>`
      : ""
    return `<span data-insurance-chip
                  class="inline-flex items-center gap-2 rounded-lg border border-border-default bg-gray-50 px-3 py-1.5">
              ${hidden}
              <span class="text-sm text-text-primary">${this.escape(name)}</span>
              ${badge}
              <button type="button"
                      data-action="click->insurance-combobox#removeChip"
                      class="text-text-muted hover:text-text-primary cursor-pointer focus:outline-none focus:ring-2 focus:ring-plum focus:ring-offset-1 rounded"
                      aria-label="Remove ${this.escape(name)}">
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
                </svg>
              </button>
            </span>`
  }

  selectedIds() {
    const inputs = this.chipsTarget.querySelectorAll("input[name='therapist[insurance_company_ids][]']")
    return new Set(Array.from(inputs).map(i => i.value))
  }

  selectedNames() {
    const names = new Set()
    this.chipsTarget.querySelectorAll("[data-insurance-chip] .text-text-primary").forEach(el => {
      names.add(el.textContent.trim().toLowerCase())
    })
    return names
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = String(str)
    return div.innerHTML
  }
}
