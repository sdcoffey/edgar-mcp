import Fastify from "fastify";
import { h } from "preact";
import { render } from "preact-render-to-string";

import * as Components from "../app/javascript";

const fastify = Fastify({
  logger: true,
});

// Declare a route

fastify.post("/", async (request, reply) => {
  const { component, props, url } = request.body;

  // @ts-expect-error - shim for window.location based on the URL provided
  global.window = { location: locationProxy(url) };

  const Component = Components[component];

  const app = h(Component, props, null);
  const rendered = render(app, { pretty: true });

  reply.header("Content-Type", "text/html; charset=utf-8");
  reply.send(rendered);
});

const locationProxy = (url) =>
  new Proxy(
    {},
    {
      get(target, prop) {
        const asUrlObj = new URL(url);
        switch (prop) {
          case "href":
            return url;
          case "protocol":
            return asUrlObj.protocol;
          case "host":
            return asUrlObj.host;
          case "hostname":
            return asUrlObj.hostname;
          case "port":
            return asUrlObj.port;
          case "pathname":
            return asUrlObj.pathname;
          case "search":
            return asUrlObj.search;
        }
      },
    },
  );

const port = process.env.PORT || 3400;
const host = process.env.HOST || "0.0.0.0";
console.log(`listening at ${host}:${port}`);
fastify.listen({ port, host });
