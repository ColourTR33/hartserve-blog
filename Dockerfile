# ---------- Build stage ----------
FROM alpine:3.20 AS builder

# Build arguments passed from GitHub Actions or locally
ARG HUGO_VERSION=0.151.0
ARG HUGO_BASEURL="https://mark.thehartleys.uk/blog/"
ARG TARGETARCH
ARG BUILD_REV=dev  # cache buster to force rebuilds

# Install dependencies (libc6-compat & libstdc++ for Hugo binary compatibility)
RUN apk add --no-cache ca-certificates curl tar git libc6-compat libstdc++

# Download the correct Hugo extended binary for this architecture
RUN curl -fsSL -o /tmp/hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
    && chmod +x /usr/local/bin/hugo \
    && /usr/local/bin/hugo version

# Set working directory
WORKDIR /src

# Copy repo contents into the build container
COPY . .

# Initialize Hugo theme submodules if using PaperMod or others
RUN git submodule update --init --recursive || true

# Build the static site with the correct baseURL
RUN /usr/local/bin/hugo --baseURL="${HUGO_BASEURL}" --minify

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