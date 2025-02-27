import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggleMenu() {
    this.menuTarget.classList.toggle("hidden")
  }

  // メニュー外をクリックした時に閉じる
  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  connect() {
    // documentのクリックイベントをリッスン
    this.clickHandler = this.hide.bind(this)
    document.addEventListener("click", this.clickHandler)
  }

  disconnect() {
    // コントローラーが削除される時にイベントリスナーを削除
    document.removeEventListener("click", this.clickHandler)
  }
}
