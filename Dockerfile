FROM alpine:3.15

RUN apk update \
    && apk add nginx \
    && mkdir -p /data/www \
    && grep -q -E "^www-data:" /etc/group || addgroup --system www-data \
    && grep -q -E "^www-data:" /etc/passwd || adduser --system www-data www-data

COPY index.html /data/www/
COPY nginx.conf /etc/nginx/

EXPOSE 80

ENTRYPOINT ["nginx", "-g", "daemon off;"]
