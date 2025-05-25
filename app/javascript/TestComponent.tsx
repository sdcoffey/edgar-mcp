import { VNode } from "preact";
import { useState } from "preact/hooks";

type Props = { title: string };

export default function TestComponent(props: Props): VNode {
  const [count, setCount] = useState(0);

  return (
    <div class="container prose mx-auto">
      <h1>This is a test component!</h1>
      <p>Here are the props: {JSON.stringify(props)}</p>
      <p>It is SSR-ed and hydrated on the client</p>
      <p>It's still interactive: {count}</p>
      <button class="rounded bg-slate-400 px-4 py-1" onClick={(): void => setCount((i) => i + 1)}>
        See?
      </button>
    </div>
  );
}
