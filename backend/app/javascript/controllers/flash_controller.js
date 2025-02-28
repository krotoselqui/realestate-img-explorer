import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss(event) {
    const flashMessage = event.target.closest("div.rounded-md")
    flashMessage.classList.add("opacity-0", "transition-opacity", "duration-300")
    setTimeout(() => {
      flashMessage.remove()
    }, 300)
  }

  connect() {
    // 5秒後に自動的に消える
    setTimeout(() => {
      const flashMessages = this.element.querySelectorAll("div.rounded-md")
      flashMessages.forEach(message => {
        message.classList.add("opacity-0", "transition-opacity", "duration-300")
        setTimeout(() => {
          message.remove()
        }, 300)
      })
    }, 5000)
  }
}