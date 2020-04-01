FROM python:3-alpine

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh gcc"]

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
