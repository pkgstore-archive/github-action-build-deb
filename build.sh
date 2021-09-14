#!/bin/bash

init() {
  # Vars.
  GIT_REPO_SRC="${1}"
  GIT_REPO_DST="${2}"
  GIT_USER="${3}"
  GIT_EMAIL="${4}"
  GIT_TOKEN="${5}"
  OBS_USER="${6}"
  OBS_PASSWORD="${7}"
  OBS_TOKEN="${8}"
  OBS_PROJECT="${9}"
  OBS_PACKAGE="${10}"

  # Apps.
  curl="$( command -v curl )"
  date="$( command -v date )"
  debuild="$( command -v debuild )"
  git="$( command -v git )"
  mv="$( command -v mv )"
  rm="$( command -v rm )"
  sleep="$( command -v sleep )"
  tar="$( command -v tar )"

  # Dirs.
  d_src="/root/git/repo_src"
  d_dst="/root/git/repo_dst"

  # Git config.
  ${git} config --global user.name "${GIT_USER}"
  ${git} config --global user.email "${GIT_EMAIL}"
  ${git} config --global init.defaultBranch 'main'

  # Run.
  git_clone           \
    && pkg_orig_pack  \
    && pkg_src_build  \
    && pkg_src_move   \
    && git_push       \
    && obs_upload     \
    && obs_trigger
}

pushd() {
  command pushd "$@" > /dev/null || exit 1
}

popd() {
  command popd > /dev/null || exit 1
}

timestamp() {
  ${date} -u '+%Y-%m-%d %T'
}

# Get repos.
git_clone() {
  echo "--- [GIT] CLONE: ${GIT_REPO_SRC#https://} & ${GIT_REPO_DST#https://}"

  SRC="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_SRC#https://}"
  DST="https://${GIT_USER}:${GIT_TOKEN}@${GIT_REPO_DST#https://}"

  ${git} clone "${SRC}" "${d_src}" \
    && ${git} clone "${DST}" "${d_dst}"

  echo "--- [GIT] LIST: '${d_src}'"
  ls -1 "${d_src}"

  echo "--- [GIT] LIST: '${d_dst}'"
  ls -1 "${d_dst}"
}

pkg_orig_pack() {
  echo "--- [SYSTEM] PACK: '${OBS_PACKAGE}' (*.orig.tar.xz)"
  pushd "${d_src}" || exit 1

  PKG_VER="1.0.0"

  for i in "${OBS_PACKAGE}-"*; do
    PKG_VER=${i##*-}
    break
  done;

  for i in *.orig.tar.*; do
    if [[ ! -f "${i}" ]]; then
      SOURCE="${OBS_PACKAGE}-${PKG_VER}"
      TARGET="${OBS_PACKAGE}_${PKG_VER}.orig.tar.xz"
      ${tar} -cJf "${TARGET}" "${SOURCE}"
    else
      echo "'${TARGET}' exist!"
    fi
    break
  done

  popd || exit 1
}

# Build package.
pkg_src_build() {
  echo "--- [SYSTEM] BUILD: '${GIT_REPO_SRC#https://}'"
  pushd "${d_src}/_build" || exit 1

  ${debuild} -us -uc -i -d -S

  popd || exit 1
}

# Move package to Debian Package Store repository.
pkg_src_move() {
  echo "--- [SYSTEM] MOVE: '${d_src}' -> '${d_dst}'"

  for i in _service _meta README.md LICENSE *.tar.* *.dsc *.build *.buildinfo *.changes; do
    ${rm} -fv "${d_dst}"/${i}
    ${mv} -fv "${d_src}"/${i} "${d_dst}" || exit 1
  done
}

# Push package to Debian Package Store repository.
git_push() {
  echo "--- [GIT] PUSH: '${d_dst}' -> '${GIT_REPO_DST#https://}'"
  pushd "${d_dst}" || exit 1

  ts="$( timestamp )"
  ${git} add . && ${git} commit -a -m "BUILD: ${ts}" && ${git} push

  popd || exit 1
}

# Upload "_meta" & "_service" files to OBS.
obs_upload() {
  echo "--- [OBS] UPLOAD: '${OBS_PROJECT}/${OBS_PACKAGE}/_meta'"
  ${curl} -u "${OBS_USER}":"${OBS_PASSWORD}" -X PUT -T "${d_dst}/_meta" "https://api.opensuse.org/source/${OBS_PROJECT}/${OBS_PACKAGE}/_meta"

  echo "--- [OBS] UPLOAD: '${OBS_PROJECT}/${OBS_PACKAGE}/_service'"
  ${curl} -u "${OBS_USER}":"${OBS_PASSWORD}" -X PUT -T "${d_dst}/_service" "https://api.opensuse.org/source/${OBS_PROJECT}/${OBS_PACKAGE}/_service"

  ${sleep} 5
}

# Run build package in OBS.
obs_trigger() {
  echo "--- [OBS] TRIGGER: '${OBS_PROJECT}/${OBS_PACKAGE}'"
  ${curl} -H "Authorization: Token ${OBS_TOKEN}" -X POST "https://api.opensuse.org/trigger/runservice?project=${OBS_PROJECT}&package=${OBS_PACKAGE}"
}

init "$@"
exit 0
