# Publishing curb-cut-mcp

Everything in this folder is prepared and checked, and nothing has been
published, committed or pushed. These are the exact commands, in order.
Publishing runs from this directory inside the repo checkout, because the
prepack script copies `../mcp-server.mjs` and `../../LICENSE` in at pack time.
The server file itself is untouched: the packaged copy is byte-identical to
`channels/mcp-server.mjs`, and the only new code is the launcher in
`bin/curb-cut-mcp.mjs`.

## Decide first

1. **Package name.** Prepared as unscoped `curb-cut-mcp`: no scope to create,
   public by default, and `npx -y curb-cut-mcp` reads cleanly in client
   configs. If you'd rather have `@parthsevak/curb-cut-mcp`, the scope must
   match your npm username, and the name changes in three places:
   `package.json` `name`, `server.json` `packages[0].identifier`, and the
   README's config snippet. Scoped also needs `npm publish --access public`.
2. **Registry namespace.** Prepared as `io.github.parthsevak2/curb-cut-mcp`,
   which matches where the repo lives. `mcp-publisher login github` must be
   done signed in as **parthsevak2**, not parthsevak-hash, because the
   namespace is the authenticated account's username. If you'd rather use a
   DNS namespace like Recordist did (`app.recordist`), that needs a domain,
   an Ed25519 key and a TXT record; the GitHub path is one browser login.
3. **Version.** 1.0.0, matching the `serverInfo` version inside
   `mcp-server.mjs`. If you want a more cautious 0.1.0 first release, change
   it in `package.json` and in both `version` fields of `server.json`; the
   server file stays as it is.

## 1. Publish to npm

```bash
cd path/to/your/clone/channels/mcp-npm

npm pack --dry-run        # look at the file list one last time
npm login                 # opens the browser; needs your npm 2FA, same as Recordist
npm publish               # prints an auth URL for 2FA again; unscoped packages are public
```

## 2. Verify from a clean cache (the Recordist lesson)

```bash
rm -rf ~/.npm/_npx
npx -y curb-cut-mcp
```

On this machine, with the CLI logged in, it should print
`curb-cut MCP server ready (org curbcut, 5 tools)` to stderr; Ctrl-C to stop.
On a machine without the CLI it should print the install instructions, not a
stack trace. If you ever see "Permission denied", check for a stray global
link shadowing npx, like the `npm link` leftover that bit Recordist.

## 3. Publish to the official MCP registry

npm must be done first: the registry validates that the published npm package
carries `"mcpName": "io.github.parthsevak2/curb-cut-mcp"`, which it does.

```bash
brew install mcp-publisher      # or the curl download from the registry releases page

cd path/to/your/clone/channels/mcp-npm
mcp-publisher login github      # browser OAuth; sign in as parthsevak2
mcp-publisher publish           # reads server.json in this directory
```

## 4. Confirm it landed

```bash
curl -s "https://registry.modelcontextprotocol.io/v0/servers?search=curb-cut" | python3 -m json.tool | head -40
```

## Later releases

Bump the version in `package.json` and in both `version` fields of
`server.json`, then repeat steps 1 and 3. The prepack copy means a change to
`channels/mcp-server.mjs` flows into the package with no other work.
