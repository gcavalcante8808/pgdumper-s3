FROM alpine:3.6
RUN apk add --no-cache postgresql bash
COPY docker-entrypoint.sh /entrypoint
ADD https://dl.minio.io/client/mc/release/linux-amd64/mc /usr/local/bin/mc
RUN chmod +x /usr/local/bin/mc
ENTRYPOINT ["bash","-x","/entrypoint"]
