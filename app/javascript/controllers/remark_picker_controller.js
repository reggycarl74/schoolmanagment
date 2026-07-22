import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "body", "kind"]

  choose() {
    const option = this.selectTarget.selectedOptions[0]
    if (!option?.dataset.body) return

    this.bodyTarget.value = option.dataset.body
    this.kindTarget.value = option.dataset.kind
    this.bodyTarget.focus()
  }
}
