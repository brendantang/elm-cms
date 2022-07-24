export default function unauthorized() {
  const headers = new Headers();
  headers.set("WWW-AUTHENTICATE", 'Basic realm="Log in to the admin panel"');
  return new Response("Not authorized, try request again with credentials.", {
    headers: headers,
    status: 401,
  });
}
