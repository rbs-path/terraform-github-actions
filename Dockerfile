FROM amazonlinux:2

RUN ["/bin/sh", "-c", "yum install -y --update --no-cache python3 python3-pip bash ca-certificates curl git jq openssh gcc build-base libffi-devel"]
# gcc and build is required to build python packages on the fly

COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
