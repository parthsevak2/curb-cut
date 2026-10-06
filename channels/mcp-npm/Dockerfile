# Curb Cut MCP server over stdio, for directory checks such as Glama's.
#
# It installs the published package, so it builds the same from any context:
#   docker build -t curb-cut-mcp channels/mcp-npm
#   docker run -i --rm curb-cut-mcp
#
# There is deliberately no Salesforce CLI and no org login in this image. The
# server still answers initialize and tools/list, and curbcut_cost_brief and
# curbcut_draft_request work. The tools that need an org return the setup
# steps as their result instead of failing.
FROM node:22-slim

ENV NODE_ENV=production
RUN npm install -g --no-fund --no-audit curb-cut-mcp@1.0.1 && npm cache clean --force

USER node
CMD ["curb-cut-mcp"]
