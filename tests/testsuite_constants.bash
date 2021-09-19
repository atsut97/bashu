#!/bin/bash

rootdir="$(cd -- "$(dirname -- "$0")/.." && pwd)"

cd "$rootdir" || exit

./tests/test_constants.bash
./tests/test_constants2.bash

cd tests || exit

./test_constants.bash
./test_constants2.bash
