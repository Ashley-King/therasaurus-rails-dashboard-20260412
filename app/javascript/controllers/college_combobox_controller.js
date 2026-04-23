import { Controller } from "@hotwired/stimulus"

// Autocomplete combobox for picking a college, with an inline option to
// submit a brand-new college (which will be stored as pending-review).
//
// Submits two hidden inputs: college_id (when an existing college is picked)
// or college_name (when a new one is proposed). The server's resolver treats
// them as mutually exclusive.
export default class extends Controller {
  static targets = [
    "input",
    "listbox",
    "collegeId",
    "collegeName",
    "selected",
    "selectedName",
    "selectedBadge"
  ]
  static values = { searchUrl: String, index: Number }

  connect() {
    this.activeIndex = -1
    this.options = []
    this.hasAddNew = false
    this.currentQuery = ""
    this.debounceTimer = null
    this.listboxId = `college-combobox-listbox-${this.indexValue}`
    this.listboxTarget.id = this.listboxId
    this.inputTarget.setAttribute("aria-controls", this.listboxId)
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
    // Delay so a mousedown on an option can resolve before blur closes the list.
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

  renderOptions(colleges, query) {
    this.options = colleges
    this.currentQuery = query

    const items = colleges.map((c, i) => {
      const badge = c.status === "pending"
        ? `<span class="ml-2 inline-flex items-center rounded-full bg-amber-100 text-amber-800 px-2 py-0.5 text-xs font-medium">Pending review</span>`
        : ""
      return `<li id="${this.listboxId}-opt-${i}" role="option" aria-selected="false"
                  data-action="mousedown->college-combobox#selectOption mouseenter->college-combobox#hoverOption"
                  data-index="${i}"
                  class="cursor-pointer px-3 py-2 text-sm text-text-primary hover:bg-gray-50 flex items-center">
                <span>${this.escape(c.name)}</span>${badge}
              </li>`
    }).join("")

    const exactMatch = colleges.some(c => c.name.toLowerCase() === query.toLowerCase())
    const addNewIdx = colleges.length
    let addNewHtml = ""
    if (!exactMatch) {
      addNewHtml = `<li id="${this.listboxId}-opt-${addNewIdx}" role="option" aria-selected="false"
                       data-action="mousedown->college-combobox#selectOption mouseenter->college-combobox#hoverOption"
                       data-index="${addNewIdx}"
                       data-new="true"
                       class="cursor-pointer px-3 py-2 text-sm font-medium text-plum border-t border-gray-100 hover:bg-gray-50">
                     + Add “${this.escape(query)}” <span class="text-text-muted font-normal">(pending review)</span>
                   </li>`
      this.hasAddNew = true
    } else {
      this.hasAddNew = false
    }

    if (colleges.length === 0 && !this.hasAddNew) {
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
      this.selectNew(this.currentQuery)
    } else {
      this.select(this.options[this.activeIndex])
    }
  }

  selectOption(event) {
    event.preventDefault()
    if (event.currentTarget.dataset.new === "true") {
      this.selectNew(this.currentQuery)
    } else {
      const idx = parseInt(event.currentTarget.dataset.index, 10)
      this.select(this.options[idx])
    }
  }

  hoverOption(event) {
    const idx = parseInt(event.currentTarget.dataset.index, 10)
    this.activeIndex = idx
    this.highlightActive()
  }

  select(college) {
    this.collegeIdTarget.value = college.id
    this.collegeNameTarget.value = ""
    this.showSelected(college.name, college.status)
  }

  selectNew(name) {
    this.collegeIdTarget.value = ""
    this.collegeNameTarget.value = name
    this.showSelected(name, "pending")
  }

  showSelected(name, status) {
    this.selectedNameTarget.textContent = name
    this.selectedBadgeTarget.hidden = status !== "pending"
    this.selectedTarget.hidden = false
    this.inputTarget.hidden = true
    this.inputTarget.value = ""
    this.hideListbox()
  }

  clear(event) {
    event?.preventDefault()
    this.collegeIdTarget.value = ""
    this.collegeNameTarget.value = ""
    this.selectedTarget.hidden = true
    this.inputTarget.hidden = false
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
