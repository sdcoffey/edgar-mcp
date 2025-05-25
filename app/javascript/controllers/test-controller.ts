import { Controller } from "@hotwired/stimulus";
import { stimulusController } from "controllers/decorator";

@stimulusController("test-controller")
export default class TestController extends Controller {
  connect(): void {
    super.connect();

    // biome-ignore lint/suspicious/noConsole: example component
    console.log("connected");
  }
}
