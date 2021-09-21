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

### Global initializer

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

### Arguments parser

### Test suite runner

testcase_collect_all_testcases() {
  bashu_all_testcases=()
  bashu_collect_all_testcases "${rootdir}/tests/test_collect_all_testcases.bash"
  [ ${#bashu_all_testcases[@]} -eq 10 ]
  [ "${bashu_all_testcases[0]}" = "testcase_test01" ]
  [ "${bashu_all_testcases[1]}" = "testcase_test02_with_underscore" ]
  [ "${bashu_all_testcases[2]}" = "testcase_test03-with-hyphen" ]
  [ "${bashu_all_testcases[3]}" = "testcase_test04:with:colon" ]
  [ "${bashu_all_testcases[4]}" = "testcase_test05_spaces" ]
  [ "${bashu_all_testcases[5]}" = "testcase_test06" ]
  [ "${bashu_all_testcases[6]}" = "testcase_test07_with_underscore" ]
  [ "${bashu_all_testcases[7]}" = "testcase_test08_spaces" ]
  [ "${bashu_all_testcases[8]}" = "testcase_test09_no_parens" ]
  [ "${bashu_all_testcases[9]}" = "testcase_main" ]
}

testcase_begin_test_suite() {
  bashu_initialize
  [ $bashu_is_running -eq 0 ]
  bashu_begin_test_suite
  [ $bashu_is_running -eq 1 ]
  : >&$bashu_fd_errtrap
}

testcase_finish_test_suite() {
  bashu_finish_test_suite
  [ $bashu_is_running -eq 0 ]
  ! (: >&$bashu_fd_errtrap) 2>/dev/null
}

bashu_main "$@"
