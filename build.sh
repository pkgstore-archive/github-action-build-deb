#!/bin/bash

# Vars.
REPO_SRC="${1}"
REPO_DST="${2}"
USER_NAME="${3}"
USER_EMAIL="${4}"
USER_TOKEN="${5}"
OBS_TOKEN="${6}"
OBS_PROJECT="${7}"
OBS_PACKAGE="${8}"

# Apps.
curl="$( command -v curl )"
date="$( command -v date )"
debuild="$( command -v debuild )"
git="$( command -v git )"
mv="$( command -v mv )"
rm="$( command -v rm )"

# Dirs.
d_src="/root/git/repo_src"
d_dst="/root/git/repo_dst"

# Git config.
${git} config --global user.name "${USER_NAME}"
${git} config --global user.email "${USER_EMAIL}"
${git} config --global init.defaultBranch 'main'

_timestamp() {
  ${date} -u '+%Y-%m-%d %T'
}

# Get repos.
git_clone() {
  echo "--- GIT: Clone source & destination repositories..."

  SRC="https://${USER_NAME}:${USER_TOKEN}@${REPO_SRC#https://}"
  DST="https://${USER_NAME}:${USER_TOKEN}@${REPO_DST#https://}"

  ${git} clone "${SRC}" "${d_src}" \
    && ${git} clone "${DST}" "${d_dst}"
}

pkg_build() {
  echo "--- BUILD: Package..."

  pushd "${d_src}/_build" || exit 1
  ${debuild} -us -uc -i -d -S && popd || exit 1
}

pkg_move() {
  echo "--- MOVE: Package..."

  for i in _service README.md LICENSE *.tar.* *.dsc *.build *.buildinfo *.changes; do
    ${rm} -fv "${d_dst}"/${i}
    ${mv} -fv "${d_src}"/${i} "${d_dst}" || exit 1
  done
}

git_push() {
  echo "--- GIT: Push destination repository..."

  ts="$( _timestamp )"

  pushd "${d_dst}" || exit 1
  ${git} add . && ${git} commit -a -m "BUILD: ${ts}" && ${git} push
}

obs_trigger(){
  echo "--- TRIGGER: openSUSE Build Service..."

  ${curl} -H "Authorization: Token ${OBS_TOKEN}" -X POST "https://build.opensuse.org/trigger/runservice?project=${OBS_PROJECT}&package=${OBS_PACKAGE}"
}

git_clone && pkg_build && pkg_move && git_push && obs_trigger

exit 0
