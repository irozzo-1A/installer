#!/bin/sh
if [ "$IS_CONTAINER" != "" ]; then
  TOP_DIR="${1:-.}"
  find "${TOP_DIR}" \
    -path "${TOP_DIR}/vendor" -prune \
    -o -path "${TOP_DIR}/.build" -prune \
    -o -type f -name '*.sh' -exec shellcheck --format=gcc {} \+
else
  docker run --rm \
    --env IS_CONTAINER=TRUE \
    --volume "${PWD}:/workdir:ro,z" \
    --entrypoint sh \
    quay.io/coreos/shellcheck-alpine:v0.5.0 \
    /workdir/hack/shellcheck.sh /workdir
fi;
