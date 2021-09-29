#!/bin/bash

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"


testcase_sample_function() {
  local i=0
  local j=1

  [ "$i" -eq "$j" ]
}

very_long_command() {
  : "$@"
}

testcase_including_long_command() {
  true
  true
  true
  true
  very_long_command "this" "is" "a" \
                    "very" "very" \
                    "long" \
                    "command"
}

testcase_including_long_command_with_comment() {
  true
  true
  true
  true
  very_long_command "this" "is" "a" \  # comment
                    "very" "very"   \
                    "long" \
                    "command"
}

testcase_including_long_command_with_comment_and_space() {
  true
  true
  true
  true
  very_long_command "this" "is" "a" \  # comment
# comment
                    "very" "very" \

                    "long" \


                    "command"
}
