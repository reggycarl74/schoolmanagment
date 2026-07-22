import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "item", "count"]

  connect() {
    this.update()
  }

  toggleAll() {
    this.itemTargets.forEach((checkbox) => {
      checkbox.checked = this.allTarget.checked
    })
    this.update()
  }

  update() {
    const selected = this.itemTargets.filter((checkbox) => checkbox.checked).length
    this.countTarget.textContent = selected
    this.allTarget.checked = selected > 0 && selected === this.itemTargets.length
    this.allTarget.indeterminate = selected > 0 && selected < this.itemTargets.length
  }
}
