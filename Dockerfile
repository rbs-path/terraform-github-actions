FROM python:3-alpine

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh py3-pip && pip3 install awscli"]

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
