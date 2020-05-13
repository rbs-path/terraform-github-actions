FROM python:3-alpine

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh gcc build-base libffi-dev"]
# gcc and build is required to build python packages on the fly

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
