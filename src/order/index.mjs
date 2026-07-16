export const handler = async (event) => ({
  statusCode: 200,
  headers: { "content-type": "application/json" },
  body: JSON.stringify({
    service: "order",
    path: event.rawPath,
    method: event.requestContext.http.method,
  }),
});
