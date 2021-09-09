#!/bin/bash

# Vars.
REPO_SRC="${1}"
REPO_DST="${2}"
USER="${3}"
EMAIL="${4}"
TOKEN="${5}"

# Apps.
debuild="$( command -v debuild )"
mv="$( command -v mv )"
git="$( command -v git )"
date="$( command -v date )"

# Dirs.
d_src="/root/git/repo_src"
d_dst="/root/git/repo_dst"

# Git config.
${git} config --global user.email "${EMAIL}"
${git} config --global user.name "${USER}"
${git} config --global init.defaultBranch 'main'

_timestamp() {
  ${date} -u '+%Y-%m-%d %T'
}

# Get repos.
get() {
  SRC="https://${USER}:${TOKEN}@${REPO_SRC#https://}"
  DST="https://${USER}:${TOKEN}@${REPO_DST#https://}"

  ${git} clone "${SRC}" "${d_src}" \
    && ${git} clone "${DST}" "${d_dst}"
}

build() {
  cd "${d_src}" || exit 1
  ${debuild} -us -uc -i -d -S && cd .. || exit 1
}

move() {
  for i in _service *.tar.* *.dsc *.build *.buildinfo *.changes; do
    ${mv} "${i}" "${d_dst}" || exit 1
  done
}

push() {
  ts="$( _timestamp )"

  cd "${d_dst}" || exit 1
  ${git} add . && ${git} commit -a -m "BUILD: ${ts}" && ${git} push
}

get && build && move && push

exit 0
