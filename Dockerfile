# ---------- Build stage ----------
FROM alpine:3.20 AS builder

ARG HUGO_VERSION=0.151.0
ARG HUGO_BASEURL="https://mark.thehartleys.uk/blog/"
ARG TARGETARCH

# Hugo extended is linked against glibc; these keep it happy on Alpine
RUN apk add --no-cache ca-certificates curl tar git libc6-compat libstdc++

# Install the correct Hugo (extended) binary for the platform
RUN curl -fsSL -o /tmp/hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
    && chmod +x /usr/local/bin/hugo \
    && /usr/local/bin/hugo version

WORKDIR /site
COPY . .

# If PaperMod (or any theme) is a submodule, make sure it’s there
RUN git submodule update --init --recursive || true

# Build the site with the correct baseURL
# (no --debug; Hugo doesn’t have it)
RUN HUGO_ENV=production /usr/local/bin/hugo \
    --baseURL="${HUGO_BASEURL}" \
    --minify

# ---------- Runtime stage ----------
FROM nginx:alpine

# Use your nginx vhost; remove default
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/blog.conf

# Copy the built site
COPY --from=builder /site/public /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ || exit 1