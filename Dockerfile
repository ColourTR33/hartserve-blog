# -------- Build stage: Hugo -> static site --------
FROM klakegg/hugo:ext-alpine AS builder
WORKDIR /src
COPY . .
# If the theme is a git submodule:
# RUN git submodule update --init --recursive
RUN hugo --minify

# -------- Runtime: Nginx serves static files --------
FROM nginx:alpine
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/blog.conf
COPY --from=builder /src/public /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ || exit 1