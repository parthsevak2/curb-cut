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
3. **Version.** 1.0.1, matching the `serverInfo` version inside
   `mcp-server.mjs`. 1.0.1 is the release that starts and answers
   `initialize` and `tools/list` with no Salesforce CLI and no org login, and
   that replies in newline-delimited JSON to clients that send it (every
   SDK-based client, Glama included). A version lives in four places:
   `package.json`, both `version` fields of `server.json`, and `VERSION` in
   `channels/mcp-server.mjs`.

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
On a machine without the CLI it should print one line first, `Curb Cut tools
need the Salesforce CLI and an org login: ...`, and then the same ready line,
and keep running: introspection works there, and the tools that need the org
answer with those setup steps instead of a stack trace. If you ever see "Permission denied", check for a stray global
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

Bump the version in `package.json`, in both `version` fields of
`server.json` and in `VERSION` in `channels/mcp-server.mjs`, repeat steps 1
and 3, then update the pinned version in the `Dockerfile`. The prepack copy
means a change to `channels/mcp-server.mjs` flows into the package with no
other work.

## Glama listing

The awesome-mcp-servers PR (punkpeye/awesome-mcp-servers#15294) waits on a
Glama listing, and Glama's only check is that the server starts in its
container and answers introspection. 1.0.1 does that with no CLI and no org,
which is exactly the container Glama builds.

1. Publish 1.0.1 to npm first (step 1 above). The `Dockerfile` installs
   `curb-cut-mcp@1.0.1` from npm, so Glama cannot build it before then.
2. Submit at https://glama.ai/mcp/servers, signed in with GitHub as
   **parthsevak2** (the account that owns the repo).
3. When it asks for a Dockerfile, paste the contents of `Dockerfile` in this
   folder. It runs `curb-cut-mcp` over stdio; no environment variables are
   needed for the check.
4. Once Glama shows the server at `parthsevak2/curb-cut`, add this badge line
   to the entry in PR #15294:

   ```markdown
   [![parthsevak2/curb-cut MCP server](https://glama.ai/mcp/servers/parthsevak2/curb-cut/badges/score.svg)](https://glama.ai/mcp/servers/parthsevak2/curb-cut)
   ```

   Check the path Glama actually assigns before pasting; if it differs, use
   that path in both URLs.

To check the container before submitting (needs Docker and 1.0.1 on npm):

```bash
docker build -t curb-cut-mcp channels/mcp-npm
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"check","version":"0"}}}' '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | docker run -i --rm curb-cut-mcp
```

It should print two JSON lines, the second listing 5 tools, plus the CLI
notice on stderr.
