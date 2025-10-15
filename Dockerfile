# ---------- Build stage ----------
FROM alpine:3.20 AS builder

ARG HUGO_VERSION=0.151.0
ARG HUGO_BASEURL="https://mark.thehartleys.uk/blog/"
ARG TARGETARCH
ARG BUILD_REV=dev

RUN apk add --no-cache ca-certificates curl tar git libc6-compat libstdc++

RUN curl -fsSL -o /tmp/hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_Linux-${TARGETARCH}.tar.gz \
    && tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo \
    && chmod +x /usr/local/bin/hugo \
    && /usr/local/bin/hugo version

WORKDIR /src
COPY . .
RUN git submodule update --init --recursive || true

# Make Hugo errors obvious in the Action logs
ENV HUGO_ENV=production
RUN /usr/local/bin/hugo --baseURL="${HUGO_BASEURL}" --minify --log --verbose --logFile /tmp/hugo.log \
    || { echo "==== HUGO LOG (start) ===="; cat /tmp/hugo.log || true; echo "==== HUGO LOG (end) ===="; exit 1; }

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