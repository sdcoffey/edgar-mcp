// Entry point for the build script in your package.json
import { Application } from "@hotwired/stimulus";
import "@hotwired/turbo-rails";
import "dayjs-init";

window.Stimulus = Application.start();
