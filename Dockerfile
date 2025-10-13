# ---------- Build stage: download the right Hugo for each arch ----------
FROM alpine:3.20 AS builder

ARG HUGO_VERSION=0.151.0
# Provided automatically by BuildKit/buildx for each platform:
# TARGETARCH ∈ { amd64, arm64 }
ARG TARGETARCH

RUN apk add --no-cache ca-certificates curl tar git

# Download platform-specific Hugo extended binary and install
# Example URL:
# https://github.com/gohugoio/hugo/releases/download/v0.151.0/hugo_extended_0.151.0_Linux-amd64.tar.gz
RUN curl -fsSL -o /tmp/hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
    && chmod +x /usr/local/bin/hugo \
    && hugo version

WORKDIR /src
# If you use PaperMod via git submodule, we need the .git dir to init it.
# If not using submodules, you can keep this COPY as-is.
COPY . .
# Try to init submodules if present; ignore if not a git checkout in CI
RUN git submodule update --init --recursive || true

# Build static site
RUN hugo --minify

# ---------- Runtime: Nginx serves static files ----------
FROM nginx:alpine
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/blog.conf
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ || exit 1