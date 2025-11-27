pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

# CORRECT POPPERJS FROM PUBLIC/ASSETS
pin "@popperjs/core", to: "popper-003a40d80fd205e1fa00da117d5bdc19720ba330706eaa17f9ba9513fa502304.js"

# CORRECT BOOTSTRAP FROM PUBLIC/ASSETS
pin "bootstrap", to: "bootstrap.min-4ecafa8f279d0b285b3d27ca02c7e5da187907efe2c38f83eb8b4c7d6aa151c4.js"
