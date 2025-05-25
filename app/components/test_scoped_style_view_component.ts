const buttons = document.querySelectorAll(
  ".test-scoped-style-view-component__button",
);
buttons.forEach((b: HTMLButtonElement) => {
  b.addEventListener("click", () => {
    // biome-ignore lint/suspicious/noConsole: example component
    console.log("clicked");
  });
});
