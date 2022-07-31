A little cms app built in Elm, backend in Deno.

**Work in progress.**

Development scripts:
- `build` compiles the Elm frontend. You can pass arguments to `elm make`, like `scripts/build --optimize`.
- `watch` watches for changes to your Elm source or the index html file and rebuilds the frontend in debug mode. You'll need `fswatch` installed.
- `dev` runs the `watch` script for the frontend, and serves the Deno application in watch mode.
