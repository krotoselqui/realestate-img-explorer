import { Application } from "@hotwired/stimulus"
import { registerControllers } from "@hotwired/stimulus-loading"

const application = Application.start()

// Register all Stimulus controllers
import DropdownController from "./dropdown_controller"
import FolderListController from "./folder_list_controller"
import FlashController from "./flash_controller"

application.register("dropdown", DropdownController)
application.register("folder-list", FolderListController)
application.register("flash", FlashController)

// Enable debugging in development
application.debug = process.env.NODE_ENV === "development"
window.Stimulus = application

// Log Stimulus initialization
console.log("Stimulus initialized with controllers:", {
  dropdown: DropdownController,
  folderList: FolderListController,
  flash: FlashController
})

export { application }