FROM alpine:3.15

RUN apk update \
    && apk add nginx=1.20.2-r1 \
    && mkdir -p /data/www \
    && grep -q -E "^www-data:" /etc/group || addgroup --system www-data \
    && grep -q -E "^www-data:" /etc/passwd || adduser --system www-data www-data

COPY CV /data/CV
COPY nginx.conf /etc/nginx/

EXPOSE 80/tcp
EXPOSE 443/tcp

ENTRYPOINT ["nginx", "-g", "daemon off;"]
