import { Application } from "@hotwired/stimulus"
import { registerControllers } from "@hotwired/stimulus-loading"

const application = Application.start()

// Register all Stimulus controllers
import FolderListController from "./folder_list_controller"
import FlashController from "./flash_controller"

application.register("folder-list", FolderListController)
application.register("flash", FlashController)

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

export { application }