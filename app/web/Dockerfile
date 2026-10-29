# Update the digest by running: docker pull nginxinc/nginx-unprivileged:1.27-alpine
# and copying "Digest: sha256:..." from the output.
FROM nginxinc/nginx-unprivileged:1.27-alpine@sha256:a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

USER nginx

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

EXPOSE 8080
