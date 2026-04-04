# Build openclaw from source to avoid npm packaging gaps (some dist files are not shipped).
FROM node:22-bookworm AS openclaw-build

# Dependencies needed for openclaw build
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

# Install Bun (openclaw build uses it)
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /openclaw

# OpenClaw version control:
# - Set OPENCLAW_VERSION Railway variable to use a specific tag (e.g., v2026.2.15)
# - If not set, defaults to main branch (original behavior)
# - Can also override locally with --build-arg OPENCLAW_VERSION=<tag>
ARG OPENCLAW_VERSION
RUN set -eu; \
  if [ -n "${OPENCLAW_VERSION:-}" ]; then \
    REF="${OPENCLAW_VERSION}"; \
    echo "✓ Using OpenClaw ${REF}"; \
  else \
    REF="main"; \
    echo "⚠ OPENCLAW_VERSION not set, using main branch (may be unstable)"; \
  fi; \
  git clone --depth 1 --branch "${REF}" https://github.com/openclaw/openclaw.git .

# Patch: relax version requirements for packages that may reference unpublished versions.
# Apply to all extension package.json files to handle workspace protocol (workspace:*).
RUN set -eux; \
  find ./extensions -name 'package.json' -type f | while read -r f; do \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*">=[^"]+"/"openclaw": "*"/g' "$f"; \
    sed -i -E 's/"openclaw"[[:space:]]*:[[:space:]]*"workspace:[^"]+"/"openclaw": "*"/g' "$f"; \
  done

RUN pnpm install --no-frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:install && pnpm ui:build


# Runtime image
FROM node:22-bookworm
ENV NODE_ENV=production

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    build-essential \
    gcc \
    g++ \
    make \
    procps \
    file \
    git \
    python3 \
    pkg-config \
    sudo \
    jq \
    vim \
    nano \
    tree \
    fd-find \
    ripgrep \
  && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update \
  && apt-get install -y gh \
  && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package runner — used by trader agent for pyotp etc.)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install Homebrew (must run as non-root user)
# Create a user for Homebrew installation, install it, then make it accessible to all users
RUN useradd -m -s /bin/bash linuxbrew \
  && echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER linuxbrew
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

USER root
RUN chown -R root:root /home/linuxbrew/.linuxbrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Install gogcli (Google Suite CLI: Gmail, GCal, GDrive, etc.)
RUN set -eux; \
  GOGCLI_URL=$(curl -sL https://api.github.com/repos/steipete/gogcli/releases/latest \
    | jq -r '.assets[] | select(.name | test("linux.*amd64")) | .browser_download_url'); \
  curl -sL "$GOGCLI_URL" -o /tmp/gogcli.tar.gz; \
  tar -xzf /tmp/gogcli.tar.gz -C /tmp; \
  mv /tmp/gog /usr/local/bin/gog; \
  chmod +x /usr/local/bin/gog; \
  rm /tmp/gogcli.tar.gz

# Symlink entire .config from /data (persistent volume) to root's home
# This covers gog and any other tools that use ~/.config/
RUN ln -sf /data/.config /root/.config

WORKDIR /app

# Wrapper deps
RUN corepack enable
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile && pnpm store prune

# Copy built openclaw
COPY --from=openclaw-build /openclaw /openclaw

# Provide a openclaw executable
RUN printf '%s\n' '#!/usr/bin/env bash' 'exec node /openclaw/dist/entry.js "$@"' > /usr/local/bin/openclaw \
  && chmod +x /usr/local/bin/openclaw

COPY src ./src

ENV PORT=8080
EXPOSE 8080

CMD ["node", "src/server.js"]

# Install Claude Code CLI for OpenClaw CLI backend fallback
# Allows OpenClaw to shell out to Claude Code CLI instead of Anthropic API
# Claude Code CLI uses ANTHROPIC_API_KEY env var automatically, bypassing harness restriction
RUN npm install -g @anthropic-ai/claude-code@latest
ENV PATH="/usr/local/bin:${PATH}"
