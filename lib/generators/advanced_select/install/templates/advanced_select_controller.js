import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["hiddenFields", "trigger", "summary", "dropdown", "search", "options", "caret", "clear"]
  static values = {
    addMode: Boolean,
    delay: { type: Number, default: 200 },
    dependentFields: Object,
    errorText: String,
    inputId: String,
    loadingText: String,
    multiple: Boolean,
    name: String,
    placeholder: String,
    searchable: Boolean,
    selected: Array,
    targetId: String,
    url: String
  }

  connect() {
    this.timer = null
    this.requestSequence = 0
    this.activeIndex = -1
    this.selectedValue = this.selectedValue.map((option) => ({
      ...option,
      id: option.id.toString(),
      displayLabel: option.displayLabel || option.label
    }))
    this.close = this.close.bind(this)
  }

  disconnect() {
    window.clearTimeout(this.timer)
    document.removeEventListener("click", this.close)
  }

  toggle(event) {
    event.preventDefault()

    if (event.target === this.clearTarget) {
      return
    }

    this.expanded ? this.close() : this.open()
  }

  open() {
    this.dropdownTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.close)
    this.activate(-1)
    this.fetchOptions({ selected: true })

    if (this.searchableValue) {
      requestAnimationFrame(() => this.searchTarget.focus())
    }
  }

  close(event) {
    if (event && this.element.contains(event.target)) {
      return
    }

    this.dropdownTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.close)
    this.clearSearch()
    this.activate(-1)
  }

  search() {
    window.clearTimeout(this.timer)
    this.renderLoading()
    this.activate(-1)
    this.timer = window.setTimeout(() => this.fetchOptions(), this.delayValue)
  }

  choose(event) {
    event.preventDefault()
    this.selectOption(event.params.value, event.params.label, event.params.submitValue, { displayLabel: event.params.displayLabel })
  }

  add(event) {
    event.preventDefault()
    this.addOption(event.params.value, event.params.label, event.params.submitValue, event.params.displayLabel)
  }

  activateOption(event) {
    this.activate(this.optionElements.indexOf(event.currentTarget))
  }

  clear(event) {
    event.preventDefault()
    event.stopPropagation()
    this.selectedValue = []
    this.renderSelection()
    this.close()
  }

  keydown(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activate(this.activeIndex + 1)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activate(this.activeIndex < 0 ? this.optionElements.length - 1 : this.activeIndex - 1)
    } else if (event.key === "Enter" && this.activeOption) {
      event.preventDefault()
      this.chooseActiveOption()
    } else if (event.key === "Escape") {
      this.close()
    }
  }

  clearSearch() {
    if (this.searchableValue) {
      this.searchTarget.value = ""
    }
  }

  fetchOptions({ selected = false } = {}) {
    if (!this.urlValue) {
      return
    }

    const requestSequence = this.requestSequence + 1
    this.requestSequence = requestSequence
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("target", this.targetIdValue)
    url.searchParams.set("add_mode", this.addModeValue ? "1" : "0")
    this.selectedValue.forEach((option) => url.searchParams.append("selected_ids[]", option.id))

    if (selected && !this.multipleValue && this.selectedValue[0]) {
      url.searchParams.set("selected_id", this.selectedValue[0].id)
    } else if (this.searchableValue) {
      url.searchParams.set("query", this.searchTarget.value)
    }

    Object.entries(this.dependentFieldsValue).forEach(([name, selector]) => {
      const field = document.querySelector(selector)

      if (field) {
        url.searchParams.set(name, field.value)
      }
    })

    fetch(url, { headers: { Accept: "text/vnd.turbo-stream.html" } })
      .then((response) => {
        if (!response.ok) {
          throw new Error("Advanced select options request failed")
        }

        return response.text()
      })
      .then((html) => {
        if (!this.expanded || requestSequence !== this.requestSequence) {
          return
        }

        Turbo.renderStreamMessage(html)
        this.optionsTarget.setAttribute("aria-busy", "false")
        this.activate(-1)
      })
      .catch(() => {
        if (!this.expanded || requestSequence !== this.requestSequence) {
          return
        }

        this.renderError()
      })
  }

  renderLoading() {
    this.optionsTarget.setAttribute("aria-busy", "true")
    this.optionsTarget.replaceChildren(this.textElement("div", "ui-advanced-select-loading", this.loadingTextValue))
  }

  renderError() {
    this.optionsTarget.setAttribute("aria-busy", "false")
    this.optionsTarget.replaceChildren(this.textElement("div", "ui-advanced-select-error", this.errorTextValue))
  }

  addOption(value, label, submitValue = value, displayLabel = label) {
    this.selectOption(value, label, submitValue, { displayLabel, refreshOptions: false })

    if (this.multipleValue) {
      this.clearSearch()
      this.fetchOptions()
    }
  }

  selectOption(value, label, submitValue = value, { displayLabel = label, refreshOptions = this.multipleValue } = {}) {
    value = value.toString()
    submitValue = submitValue.toString()

    if (this.multipleValue) {
      if (this.selectedValue.some((option) => option.id === value)) {
        this.selectedValue = this.selectedValue.filter((option) => option.id !== value)
      } else {
        this.selectedValue = this.selectedValue.concat({ id: value, value: submitValue, label, displayLabel })
      }
    } else {
      this.selectedValue = [{ id: value, value: submitValue, label, displayLabel }]
    }

    this.renderSelection()
    if (refreshOptions) {
      this.fetchOptions()
    }

    if (!this.multipleValue) {
      this.close()
    }
  }

  renderSelection() {
    this.hiddenFieldsTarget.replaceChildren(...this.hiddenFieldElements)
    this.summaryTarget.replaceChildren(...this.selectionElements)
    this.renderOptionsState()
    this.caretTarget.classList.toggle("hidden", this.selectedValue.length > 0)
    this.clearTarget.classList.toggle("hidden", this.selectedValue.length === 0)
  }

  renderOptionsState() {
    const selectedIds = new Set(this.selectedValue.map((option) => option.id))

    this.optionElements.forEach((option) => {
      const selected = selectedIds.has(option.dataset.advancedSelectValueParam)
      option.setAttribute("aria-selected", selected.toString())

      const check = option.querySelector(".ui-advanced-select-option-check")
      if (check) {
        check.textContent = selected ? "\u2713" : ""
      }
    })
  }

  chooseActiveOption() {
    if (this.activeOption.classList.contains("ui-advanced-select-add-option")) {
      this.addOption(
        this.activeOption.dataset.advancedSelectValueParam,
        this.activeOption.dataset.advancedSelectLabelParam,
        this.activeOption.dataset.advancedSelectSubmitValueParam,
        this.activeOption.dataset.advancedSelectDisplayLabelParam
      )
    } else {
      this.selectOption(
        this.activeOption.dataset.advancedSelectValueParam,
        this.activeOption.dataset.advancedSelectLabelParam,
        this.activeOption.dataset.advancedSelectSubmitValueParam || this.activeOption.dataset.advancedSelectValueParam,
        { displayLabel: this.activeOption.dataset.advancedSelectDisplayLabelParam }
      )
    }
  }

  activate(index) {
    this.optionElements.forEach((option) => option.classList.remove("ui-advanced-select-option-active"))

    if (index < 0 || this.optionElements.length === 0) {
      this.activeIndex = -1
      return
    }

    this.activeIndex = (index + this.optionElements.length) % this.optionElements.length
    this.activeOption.classList.add("ui-advanced-select-option-active")
    this.activeOption.scrollIntoView({ block: "nearest" })
  }

  get optionElements() {
    return Array.from(this.optionsTarget.querySelectorAll("[role='option'], .ui-advanced-select-add-option")).filter((option) => !option.classList.contains("hidden"))
  }

  get activeOption() {
    return this.optionElements[this.activeIndex]
  }

  get hiddenFieldElements() {
    const options = this.multipleValue ? this.selectedValue : [this.selectedValue[0]]

    return options.map((option) => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = this.nameValue
      input.value = option ? option.value || option.id : ""

      if (!this.multipleValue) {
        input.id = this.inputIdValue
      }

      return input
    })
  }

  get selectionElements() {
    if (this.selectedValue.length === 0) {
      return [this.textElement("span", "ui-advanced-select-placeholder", this.placeholderValue)]
    }

    if (!this.multipleValue) {
      return [this.textElement("span", "ui-advanced-select-value", this.displayLabel(this.selectedValue[0]))]
    }

    const tokens = this.selectedValue.slice(0, 2).map((option) => this.textElement("span", "ui-advanced-select-token", this.displayLabel(option)))

    if (this.selectedValue.length > 2) {
      tokens.push(this.textElement("span", "ui-advanced-select-token", `& +${this.selectedValue.length - 2}`))
    }

    return tokens
  }

  displayLabel(option) {
    return option.displayLabel || option.label
  }

  textElement(tagName, className, text) {
    const element = document.createElement(tagName)
    element.className = className
    element.textContent = text

    return element
  }

  get expanded() {
    return this.triggerTarget.getAttribute("aria-expanded") === "true"
  }
}
