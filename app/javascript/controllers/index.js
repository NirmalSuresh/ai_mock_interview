import { application } from "./application"

// Load all controllers
import TimerController from "./timer_controller"

application.register("timer", TimerController)
