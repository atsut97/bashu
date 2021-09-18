#!/bin/bash

rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

cd -- "$(dirname -- "$0")"

# shellcheck source=../bashu
source "../bashu"

testcase_self() {
  local expected=$rootdir/bashu

  [ "$bashu_self" == "$expected" ]
}

testcase_rootdir() {
  local expected=$rootdir

  [ "$bashu_rootdir" == "$expected" ]
}

testcase_specfile() {
  local expected=$rootdir/tests/test_constants.bash

  [ "$bashu_specfile" == "$expected" ]
}

bashu_main "$@"
