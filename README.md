# :basketball: bashu :athletic_shoe:

`bashu` ([bǽʃuː]) is a micro unit testing framework for bash scripts.

## Motives

This library provides a simple unit testing framework for bash
scripts. Although basic ideas are stolen from [Bash Automated Testing
System](https://github.com/sstephenson/bats)(, which is now maintained
by the [community](https://github.com/bats-core/bats-core)), this
framework is implemented so that it does not require an extended
syntax nor an interface description language (IDL) to write test cases
and a special interpreter or a binary is not needed to execute test
suites. Thus, you can write and run a test script as if it is a normal
bash script.

## Usage

Unlike traditional unit testing framworks such as xUnit, this
framework provides no assertion methods. Instead, it harnesses bash's
`errexit` (`set -e`) option to detect that each test case fails. A
test case consists of standard shell commands. If every command in the
test case exits with a `0` status code, then the test passes. If any
of the commands in the test case exits with a non-zero status, then
the test case is marked as a fail.

### Installation

`bashu` expects that you should source this library at the head in
your test script, define test cases as bash functions whose names
start with `testcase_` and call `bashu_main` at the end.

You have several options to install the library. The most
straightforward way is just to download it and put it in your project
directory.

```
$ cd your-project
$ curl -sSLO https://raw.githubusercontent.com/atsut97/bashu/main/bashu
```

If your project is managed under the Git, you can choose options to
have `bashu` in you project. One is to use `git submodule` by the
following commands:

```
$ cd your-project
$ git submodule add https://github.com/atsut97/bashu.git tests/bashu
```

Other way is to use `git subtree` by the following commands:

```
cd your-project
git remote add bashu https://github.com/atsut97/bashu.git
git subtree add --prefix=tests/bashu --squash bashu main
```

### Definition of a test case

You can write a test script as a standard bash script. Let's say we
create a file `test_sample.bash` in the directory
`your-project/tests`. First, a shebang should be put to the head of
the script:

``` shell
#!/bin/bash
```

Then the script `bashu` should be sourced.

``` shell
source bashu/bashu
```

`bashu` searches the `test_sample.bash` for functions whose names
start with `testcase_`, and treat them as test cases. A test case
consists of standard shell commands. If every command returns `0`
status, the test case is counted as passed. An example test case is
shown as follows:

``` shell
testcase_add() {
  result=$(echo 2+2 | bc)
  [ "$result" -eq 4 ]
}
```

### Running tests

To run the tests and show the results, you need to run `bashu_main` at
the end of the script.

``` shell
bashu_main "$@"
```

You can execute the test script just after execute permission is added
to it.

```
$ chmod +x test_sample.bash
$ ./test_sample.bash
.
1 passed in 0.02s
```

## License

[MIT](https://choosealicense.com/licenses/mit/)
