import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "icon"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
    this.iconTarget.textContent = this.panelTarget.classList.contains("hidden") ? "☰" : "×"
  }

  close(event) {
    if (event.target.closest("a")) this.panelTarget.classList.add("hidden")
  }
}
