# 🏀 bashu 👟

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
`errexit` (`set -e`) option to detect each test case failed or not. A
test case consists of standard shell commands. If every command in the
test case exits with a `0` status code, then the test passes. If any
of the commands in the test case exits with a non-zero status, then
the test is considered as a fail.

### Installation

`bashu` expects that you should source this library at the
head in your test script, define test cases as bash functions whose
names start with `testcase_` and call `bashu_main` at the end.

You have several options to install the library. The most
straightforward way is just to download it and put it in your project
directory.

``` shell
cd your-project
curl -sSLO https://raw.githubusercontent.com/atsut97/bashu/main/bashu
```

If your project is managed under Git, you have some options to include
`bashu` in you project. One is to use `git submodule` by the
following commands:

``` shell
cd your-project
git submodule add https://github.com/atsut97/bashu.git bashu
```

Other way is to use `git subtree` by the following commands:

``` shell
cd your-project
git remote add bashu https://github.com/atsut97/bashu.git
git subtree add --prefix=bashu --squash bashu master
```

A test script can be written as a standard bash script, so you can put
a shebang to the head of a script:

``` shell
#!/bin/bash
```

In order to use this framework, sourcing the `unittsst.sh` is needed.

``` shell
source bashu
```

### Definition

## License

[MIT](https://choosealicense.com/licenses/mit/)
