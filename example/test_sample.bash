#!/bin/bash

# shellcheck source=bashu
source bashu

testcase_add() {
  result=$(echo 2+2 | bc)
  [ "$result" -eq 4 ]
}

bashu_main "$@"
