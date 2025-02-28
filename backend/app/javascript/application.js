// Configure your import map in config/importmap.rb

// Import Turbo and Stimulus
import "@hotwired/turbo-rails"
import { Turbo } from "@hotwired/turbo-rails"

// Import controllers
import "controllers"

// Configure Turbo
Turbo.session.drive = true

// Debug logging for development
console.log("Application JavaScript loaded")