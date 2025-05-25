import { render } from "@testing-library/preact";
import { describe, expect, it } from "bun:test";
import TestComponent from "./TestComponent";

describe("TestComponent", () => {
  it("renders", () => {
    const { container } = render(<TestComponent title={"test"} />);
    expect(container.textContent).toMatch("This is a test component");
  });
});
