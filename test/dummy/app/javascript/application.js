import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import AdvancedSelectController from "advanced_select/advanced_select_controller"

window.Stimulus = Application.start()
window.Stimulus.register("advanced-select", AdvancedSelectController)
