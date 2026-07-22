import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "label"]

  toggle() {
    const showing = this.fieldTargets[0]?.type === "text"
    this.fieldTargets.forEach((field) => { field.type = showing ? "password" : "text" })
    this.labelTarget.textContent = showing ? "Show passwords" : "Hide passwords"
  }
}
