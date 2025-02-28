# Pin npm packages by running ./bin/importmap

# Core libraries
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true

# Application
pin "application", preload: true

# Controllers
pin "controllers/application", to: "controllers/application.js", preload: true
pin "controllers/dropdown_controller", to: "controllers/dropdown_controller.js", preload: true
pin "controllers/folder_list_controller", to: "controllers/folder_list_controller.js", preload: true
pin "controllers/flash_controller", to: "controllers/flash_controller.js", preload: true
pin "controllers", to: "controllers/index.js", preload: true