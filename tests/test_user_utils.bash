#!/usr/bin/env bash

# test_user_utils.bash
#
# Unit testing for user utilities

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

### User utility functions
#### Run

testcase_run_initialize_special_variables() {
  # [ "$status" -eq 0 ]
  # [ -z "$output" ]
  # [ "${#lines[@]}" -eq 0 ]
  echo "[status=$status]"
  hoge=0
  [ "$hoge" -eq 0 ]
}

bashu_main "$@"
