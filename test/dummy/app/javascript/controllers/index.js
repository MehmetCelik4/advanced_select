import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import AdvancedSelectController from "advanced_select/advanced_select_controller"

eagerLoadControllersFrom("controllers", application)
application.register("advanced-select", AdvancedSelectController)
