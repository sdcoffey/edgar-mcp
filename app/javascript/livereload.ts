/* eslint-disable */
(() => (new EventSource("http://localhost:8082").onmessage = (): void => location.reload()))();
