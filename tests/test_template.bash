#!/bin/bash

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

testcase_test() {
  :
}

bashu_main "$@"
