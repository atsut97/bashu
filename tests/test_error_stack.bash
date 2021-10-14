#!/usr/bin/env bash

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

### Utility functions

random_int() {
  local lo hi
  local n=${3:-1}
  case $# in
    0)
      lo=0
      hi=100
      ;;
    1)
      lo=0
      hi=$1
      ;;
    *)
      lo=$1
      hi=$2
      ;;
  esac
  shuf -i "${lo}-${hi}" -n "$n"
}

random_word() {
  local dict=/usr/share/dict/words
  local word="'"
  until [[ "$word" != *"'"* ]]; do
    word=$(shuf -n 1 "$dict")
  done
  echo "$word"
}

getlineno() {
  local filename=$1; shift
  local pattern="$*"'$'

  grep -ne "$pattern" "$filename" | cut -d':' -f1
}

failure1() {
  _bashu_errtrap "$1"
}

failure2() {
  failure1 "$1"
}

failure3() {
  failure2 "$1"
}

failure4() {
  failure3 "$1"
}

setup() {
  bashu_err_trace_stack=()
  bashu_err_trace_stack_aux=()
  bashu_err_status_stack=()
}

testcase_error_stack() {
  local n r i s

  setup
  n=$(random_int 2 5)
  for ((i=0; i<n; i++)); do
    r=$(random_int 1 4)
    s=$(random_int 1 10)
    failure"$r" "$s"
    bashu_postprocess "$s"
  done

  [ "${#bashu_err_trace_stack_aux[@]}" -eq "$n" ]
  [ "${#bashu_err_status_stack[@]}" -eq "$n" ]
  s=0
  for ((i=0; i<n; i++)); do
    s=$(( s + ${bashu_err_trace_stack_aux[$i]} ))
  done
  [ "${#bashu_err_trace_stack[@]}" -eq "$s" ]
}

bashu_main "$@"
