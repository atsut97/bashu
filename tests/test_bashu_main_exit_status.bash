#!/bin/bash
# shellcheck disable=SC2154

# Find the root directory of the repository.
rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

# shellcheck source=../bashu
source "$rootdir/bashu"

r=$(( RANDOM % 3 + 1 ))
for ((i=0; i<r; i++)); do
  v="cmd${i}=false"
  eval "$v"
done
for ((i=r; i<6; i++)); do
  v="cmd${i}=true"
  eval "$v"
done

testcase_test00() {
  $cmd0
}

testcase_test01() {
  $cmd1
}

testcase_test02() {
  $cmd2
}

testcase_test03() {
  $cmd3
}

testcase_test04() {
  $cmd4
}

testcase_test05() {
  $cmd5
}

catch_exit_status() {
  s=$?
  echo "FUNCNAME[${#FUNCNAME[@]}]=${FUNCNAME[*]}"
  echo   [ $s -eq $r ]
  [ $s -eq $r ]
  exit $?
}

trap catch_exit_status EXIT

bashu_main "$@" &>/dev/null
