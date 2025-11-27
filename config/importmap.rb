pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# Load all Stimulus controllers automatically
pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap JS support
pin "@popperjs/core", to: "popper.js"
pin "bootstrap", to: "bootstrap.min.js"
