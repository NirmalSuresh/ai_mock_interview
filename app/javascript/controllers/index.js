import { application } from "controllers/application"

import autoscrollController from "./autoscroll_controller"
application.register("autoscroll", autoscrollController)

import timerController from "./timer_controller"
application.register("timer", timerController)
