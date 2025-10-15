# ---------- Build stage ----------
FROM alpine:3.20 AS builder

ARG HUGO_VERSION=0.151.0
ARG HUGO_BASEURL="https://mark.thehartleys.uk/blog/"
ARG TARGETARCH
ARG BUILD_REV=dev

# deps (Hugo extended needs these on Alpine)
RUN apk add --no-cache ca-certificates curl tar git libc6-compat libstdc++

# Install the correct Hugo extended binary for the current arch
RUN curl -fsSL -o /tmp/hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
    && chmod +x /usr/local/bin/hugo

WORKDIR /src
COPY . .

# If the theme is a git submodule, this is harmless if it's not
RUN git submodule update --init --recursive || true

# ---- SUPER VERBOSE DIAGNOSTICS ----
RUN set -euxo pipefail; \
    echo "== uname ==" && uname -a; \
    echo "== hugo version ==" && /usr/local/bin/hugo version; \
    echo "== HUGO_BASEURL ==" && echo "${HUGO_BASEURL}"; \
    echo "== repo root ==" && ls -la; \
    echo "== hugo.toml ==" && (cat hugo.toml || true); \
    echo "== themes dir ==" && (ls -la themes || true); \
    echo "== content dir ==" && (ls -la content || true); \
    echo "== first few theme files ==" && (find themes -maxdepth 2 -type f | head -n 20 || true); \
    echo "== running hugo =="; \
    HUGO_ENV=production /usr/local/bin/hugo \
    --baseURL="${HUGO_BASEURL}" \
    --minify \
    --log --verbose \
    --printI18nWarnings --printPathWarnings

# ---------- Runtime ----------
FROM nginx:alpine
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/blog.conf
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ || exit 1
# ---------- Runtime stage ----------
FROM nginx:alpine

# Clean default Nginx config and replace with our site config
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/blog.conf

# Copy the built site from Hugo's public/ directory
COPY --from=builder /src/public /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Add a lightweight healthcheck for uptime monitoring
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ || exit 1