#!/bin/bash

# Change the current working directory to where this script exists to
# source `bashu` correctly.
cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null || exit

source ../bashu

inner_func() {
  false
}

inner_func2() {
  inner_func
}

testcase_test01_fail() {
  # false
  # inner_func
  inner_func2
}

bashu_main "$@"
