# How To

<p align="center">How to install & use the 'pl_bash_functions' package.</p>


---


## System Requirements

!!! hint

    There are related helper scripts to list intalled versions:
    [pl_helper_scripts](https://github.com/P-Linux/pl_helper_scripts)

    They might require additional software.


Following software should be installed, **earlier or later versions** of the listed software packages may also work.

!!! note

    If you use only some selected functions you may not need all the software installed.


### Bash 4.3.42(1)-release


### Gnu Gettext 0.19.7


### Ncurses 6.0.20150808

* tput


### Coreutils 8.25


### PROCPS-NG 3.3.11

* ps


### Gnu Findutils 4.6.0


### Grep 2.23


### Wget 1.17.1


### Curl 7.47.1     (Optional)

Required to pass some tests


### Git 2.8.2


### Subversion 1.9.3 (r1718519)

Required for source-entries which fetch there sources from subversion repos.


### Mercurial 3.7.1

Required for source-entries which fetch there sources from mercurial repos.


### Bazaar 2.6.0

Required for source-entries which fetch there sources from bazaar repos.


### Inetutils 1.9.4

* ping


### Gzip 1.6


### Bzip2 1.0.6


### Xz 5.2.2


### bsdtar 3.1.2 - libarchive 3.1.2


## Installation

The package contains only docs, examples, tests, *bash functions* and related Makefiles to install them.

To see the *help*, run in the top-level-directory: `make`


## General Settings Requirements

These are general required settings and **they are set in each file** of the `pl_bash_functions package`.

!!! warning

    Individual function might not need all of them but some
    function might silently misbehave or fail without them.

    See function `mc_general_opt()` for a complete list of general settings.


### Variable GREP_OPTIONS

The variable *GREP_OPTIONS* MUST be *unset*: `unset GREP_OPTIONS`

This is done in each file of the `pl_bash_functions package`.

This variable specifies default options to be placed in front of any explicit options. As this causes problems when writing
portable scripts, this feature will be removed in a future release of grep, and grep warns if it is used.


### BASH Options

* `set -o braceexpand`  -o: Brace expansion is a mechanism by which arbitrary strings may be generated.
* `set +o errexit`      +o: do not use this one.
* `set -o errtrace`     -o: needed for trap on ERR: e.g. proper `i_trap_u()` execution.
* `set +o histexpand`   +o: e.g. needed  to allow !! strings in double quotes.
* `set +o noclobber`    +o: is required by some functions.
* `set -o nounset`      -o: using this stricter setting for code robustness.
* `set -o pipefail`     -o: using this stricter setting for code robustness.
* `set +o posix`        +o: e.g. needed otherwise tests_all.sh aborts on: readonly variable


### BASH shopt Options

* `shopt -s dotglob`
* `shopt -s expand_aliases`: e.g. used for the gettext alias.
* `shopt -s extglob`
* `shopt -u nocasematch`
* `shopt -u nullglob`


## Usage

In your bash script: source the `pl_bash_functions files` you want to use.

See the `tests` folder for examples.

!!! note

    Some functions require functions from other files in this package, there is some dependency order
