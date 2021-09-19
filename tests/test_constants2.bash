#!/bin/bash

rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

testcase_self() {
  local expected=$rootdir/bashu

  [ "$bashu_self" == "$expected" ]
}

testcase_rootdir() {
  local expected=$rootdir

  [ "$bashu_rootdir" == "$expected" ]
}

testcase_specfile() {
  local expected=$rootdir/tests/test_constants2.bash

  [ "$bashu_specfile" == "$expected" ]
}

bashu_main "$@"
