export default function notFound() {
  return new Response("Backend route not found", { status: 404 });
}
