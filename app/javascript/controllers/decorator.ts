import { ControllerConstructor } from "@hotwired/stimulus";

export function stimulusController(name: string) {
  return (target: ControllerConstructor): void => {
    window.Stimulus.register(name, target);
  };
}
