import type { FastifyError, FastifyReply, FastifyRequest } from "fastify";

export function globalErrorHandler(
  error: FastifyError,
  _request: FastifyRequest,
  reply: FastifyReply
): void {
  const statusCode = error.statusCode ?? 500;
  reply.status(statusCode).send({
    status: "error",
    code: statusCode,
    message: error.message ?? "Internal Server Error"
  });
}
