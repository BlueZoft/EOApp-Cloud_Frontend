FROM nginxinc/nginx-unprivileged:stable-alpine@sha256:f5116ed4606f3eb015dd4a8e28cb9b351476dc0ad4bc6e9f93b19cec130cdf03
COPY --chown=101:101 build/web/ /usr/share/nginx/html/
COPY --chown=101:101 deploy/nginx.conf /etc/nginx/nginx.conf
COPY --chown=101:101 deploy/default.conf.template /etc/nginx/templates/default.conf.template
COPY --chown=101:101 deploy/security-headers.conf /etc/nginx/security-headers.conf
COPY --chown=101:101 deploy/05-validate-env.sh /docker-entrypoint.d/05-validate-env.sh
RUN test -s /usr/share/nginx/html/main.dart.js \
    && grep -q '"apiMode":"same-origin"' /usr/share/nginx/html/deployment.json
ENV NGINX_ENVSUBST_FILTER="^(SERVER_NAME|PUBLIC_ORIGIN)$"
EXPOSE 8080 8443
