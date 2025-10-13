# ---------- Build stage ----------
FROM alpine:3.20 AS builder

ARG HUGO_VERSION=0.151.0
ARG TARGETARCH

# + libc6-compat and libstdc++ so the glibc-linked Hugo can run on Alpine (musl)
RUN apk add --no-cache ca-certificates curl tar git libc6-compat libstdc++

# Download platform-specific Hugo extended binary and install
RUN curl -fsSL -o /tmp/hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
    && chmod +x /usr/local/bin/hugo \
    && /usr/local/bin/hugo version

WORKDIR /src
COPY . .
# If you use PaperMod as a submodule, init recursively; otherwise safe to ignore failures
RUN git submodule update --init --recursive || true

# Build the site
RUN /usr/local/bin/hugo --minify

# ---------- Runtime ----------
FROM nginx:alpine
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/blog.conf
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ || exit 1