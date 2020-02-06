FROM python:3-alpine

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh && pip install awscli"]

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
