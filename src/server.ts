import Fastify from "fastify";
import cors from "@fastify/cors";
import env from "@fastify/env";
import sensible from "@fastify/sensible";
import { logger } from "./core/logger.js";
import { globalErrorHandler } from "./core/error-handler.js";

const server = Fastify({
  logger
});

await server.register(env, {
  schema: {
    type: "object",
    required: ["DB_URL", "JWT_SECRET", "REDIS_URL", "MIDTRANS_SERVER_KEY"],
    properties: {
      DB_URL: { type: "string" },
      JWT_SECRET: { type: "string" },
      REDIS_URL: { type: "string" },
      MIDTRANS_SERVER_KEY: { type: "string" }
    }
  },
  dotenv: true
});

await server.register(cors, { origin: true });
await server.register(sensible);

server.setErrorHandler(globalErrorHandler);

server.get("/health", async () => ({ status: "ok" }));

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "0.0.0.0";

try {
  await server.listen({ port, host });
} catch (err) {
  server.log.error(err);
  process.exit(1);
}
