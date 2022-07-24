export default function internalError() {
  return new Response("Something went wrong", { status: 500 });
}
