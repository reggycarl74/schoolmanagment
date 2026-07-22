import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "score", "total"]

  connect() {
    this.rowTargets.forEach((row) => this.updateRow(row))
  }

  update(event) {
    this.updateRow(event.target.closest("tr"))
  }

  updateRow(row) {
    const scores = this.scoreTargets.filter((input) => input.closest("tr") === row)
    const total = scores.reduce((sum, input) => sum + (Number.parseFloat(input.value) || 0), 0)
    const output = this.totalTargets.find((target) => target.closest("tr") === row)
    if (output) output.textContent = total.toFixed(2).replace(/\.00$/, "")
  }
}
