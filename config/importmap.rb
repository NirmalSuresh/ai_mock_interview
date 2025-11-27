pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap + PopperJS (correct fingerprinted asset)
pin "@popperjs/core", to: "popper-003a40d80fd205e1fa00da117d5bdc19720ba330706eaa17f9ba9513fa502304.js"
pin "bootstrap", to: "bootstrap.min.js"
