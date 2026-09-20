#!/bin/bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/5etools-mirror-3/5etools-src.git}"
REPO_DIR="${REPO_DIR:-/data/5etools-src}"
IMG_REPO_URL="${IMG_REPO_URL:-https://github.com/5etools-mirror-3/5etools-img.git}"
IMG_REPO_DIR="${IMG_REPO_DIR:-/data/5etools-img}"
GIT_TMPDIR="${GIT_TMPDIR:-/data/git-tmp}"

export TMPDIR="${GIT_TMPDIR}"
export GIT_TEMPDIR="${GIT_TMPDIR}"
mkdir -p /data
mkdir -p "${GIT_TMPDIR}"

update_repo() {
  local repo_url="$1"
  local repo_dir="$2"

  if [ ! -d "${repo_dir}/.git" ]; then
    echo "Cloning ${repo_url} into ${repo_dir}"
    git clone --depth 1 "${repo_url}" "${repo_dir}"
  else
    echo "Updating existing checkout at ${repo_dir}"
    git -C "${repo_dir}" remote set-url origin "${repo_url}"
    git -C "${repo_dir}" fetch --all --tags --prune

    if git -C "${repo_dir}" show-ref --verify --quiet refs/remotes/origin/main; then
      git -C "${repo_dir}" reset --hard origin/main
    elif git -C "${repo_dir}" show-ref --verify --quiet refs/remotes/origin/master; then
      git -C "${repo_dir}" reset --hard origin/master
    else
      git -C "${repo_dir}" pull --ff-only || true
    fi

    git -C "${repo_dir}" clean -fd
  fi
}

# Ensure the web root is ready before we serve it.
update_repo "${REPO_URL}" "${REPO_DIR}"

# Start nginx immediately so the site is available even while the large image repo is still syncing.
if [ -d "${REPO_DIR}" ] && [ ! -e "${REPO_DIR}/img" ]; then
  ln -sfn "${IMG_REPO_DIR}" "${REPO_DIR}/img"
fi

# If the repo is not at the root, keep the landing page available at the root.
if [ ! -f "${REPO_DIR}/index.html" ] && [ -d "${REPO_DIR}/src" ] && [ -f "${REPO_DIR}/src/index.html" ]; then
  ln -sfn "${REPO_DIR}/src" "${REPO_DIR}/site"
fi

nginx -g 'daemon off;' &
nginx_pid=$!

(
  update_repo "${IMG_REPO_URL}" "${IMG_REPO_DIR}"
  if [ -d "${IMG_REPO_DIR}" ]; then
    rm -rf "${REPO_DIR}/img"
    ln -sfn "${IMG_REPO_DIR}" "${REPO_DIR}/img"
  fi
) &

wait "$nginx_pid"
