#!/usr/bin/env bash

# test_bashu_main.bash
#
# Unit testing for bashu

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

### Constant variables

testcase_self() {
  local expected=$rootdir/bashu

  [ "$bashu_self" == "$expected" ]
}

testcase_rootdir() {
  local expected=$rootdir

  [ "$bashu_rootdir" == "$expected" ]
}

testcase_specfile() {
  local expected=$rootdir/tests/test_bashu_main.bash

  [ "$bashu_specfile" == "$expected" ]
}

### Initialize

# Set random values to mock variables to be uninitialized.
_testcase_initialize_setup() {
  bashu_is_running=$RANDOM
  bashu_all_testcases=("testcase_dummy")
  bashu_performed_testcases=("testcase_dummy")
  bashu_passed_testcases=("testcase_dummy")
  bashu_failed_testcases=("testcase_dummy")
}

testcase_initialize() {
  # Given that randome values are substituted,
  _testcase_initialize_setup
  # When `bashu_initialize` is called,
  bashu_initialize
  # Then variables are initilized.
  [ $bashu_is_running -eq 0 ]
  [ ${#bashu_all_testcases[@]} -eq 0 ]
  [ ${#bashu_performed_testcases[@]} -eq 0 ]
  [ ${#bashu_passed_testcases[@]} -eq 0 ]
  [ ${#bashu_failed_testcases[@]} -eq 0 ]

  # File descriptor for test results is also opened.
  : >&$bashu_fd_result
}

bashu_main "$@"
