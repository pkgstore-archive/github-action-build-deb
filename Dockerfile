FROM debian:bullseye-slim

LABEL "name"="Debian Build Package"
LABEL "description"=""
LABEL "maintainer"="Kitsune Solar <kitsune.solar@gmail.com>"
LABEL "repository"="https://github.com/pkgstore/github-action-build-deb.git"
LABEL "homepage"="https://pkgstore.github.io/"

COPY *.sh /
RUN apt update && apt install -y bash git git-lfs tar build-essential fakeroot devscripts

ENTRYPOINT ["/entrypoint.sh"]
