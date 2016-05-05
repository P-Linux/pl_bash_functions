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


### Bash 4.3.39


### Coreutils 8.24


### Gnu Findutils 4.4.2


### Grep 2.23


### Ncurses 6.0.20150808


### Wget 1.17.1


### Curl 7.47.1   (Optional)

Required to pass some tests


### Git 2.7.1


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

## Installation

Run in the top level dir `make` to see the *help*.


## General Settings Requirement

These are general required settings.

!!! warning

    Individual function might not need all of them but some
    function might silently misbehave or fail without them.


### Variable GREP_OPTIONS

The variable *GREP_OPTIONS* MUST be *unset*: `unset GREP_OPTIONS`

This is done in each file of the `pl_bash_functions package`.

This variable specifies default options to be placed in front of any explicit options. As this causes problems when writing
portable scripts, this feature will be removed in a future release of grep, and grep warns if it is used.


### BASH shopt Options

`shopt -s extglob` is required by some functions: this is done in each file of the `pl_bash_functions package`.


## Usage

In your bash script: source the `pl_bash_functions files` you want to use.

!!! note

    Some functions require functions from other files in this package, there is some dependency order


### Common Example

Usually one wants to source first `msg.sh` and after that anything else.

```bash
customary_cleanup_function() {
   echo "Missing code for the customary_cleanup_function"
}

unset GREP_OPTIONS
shopt -s extglob

declare -r _THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
declare -r _PL_BASH_FUNCTIONS_DIR="/usr/lib/pl_bash_functions/scripts"

source "${_PL_BASH_FUNCTIONS_DIR}/trap_exit.sh"
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"${_signal}\" \"customary_cleanup_function\"" "${_signal}"; done
trap "tr_trap_exit_interrupted \"customary_cleanup_function\"" INT
trap "tr_trap_exit_unknown_error \"customary_cleanup_function\"" ERR

source "${_PL_BASH_FUNCTIONS_DIR}/msg.sh"
ms_format "${_THIS_SCRIPT_PATH}"

#_MS_VERBOSE="yes"          NOTE: This defaults to: yes
#_MS_VERBOSE_MORE="yes"     NOTE: This defaults to: yes

ms_header "${_MS_GREEN}" "$(gettext "Just Testing...")"

ms_request_continue "root"

ms_has_tested_version "0.9.1"

source "${_PL_BASH_FUNCTIONS_DIR}/utilities.sh"

ut_source_safe_abort "anything_else......"

do_got_download_programs_abort      # if the related files where sourced
do_got_extract_programs_abort       # if the related files where sourced
```

#### 01. Optional Cleanup Function

If needed add a cleanup function to be passed to the traps.

```bash
customary_cleanup_function() {
   echo "Missing code for the customary_cleanup_function"
}
```

#### 02. Set/Unset Required Options

unset GREP_OPTIONS
shopt -s extglob


#### 03. Get Current Script Path

If the variable is not needed get it later as input argument for function `ms_format`.

```bash
declare -r _THIS_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
```


#### 04. Get PL_BASH_FUNCTIONS_DIR

Specify where the *pl_bash_functions package is installed*: need the *scripts ddirectory.

```bash
declare -r _PL_BASH_FUNCTIONS_DIR="/usr/lib/pl_bash_functions/scripts"
```


#### 05. Set Trap

Generally it is a good thing to set `traps`.

```bash
source "${_PL_BASH_FUNCTIONS_DIR}/trap_exit.sh"
for _signal in TERM HUP QUIT; do trap "tr_trap_exit \"${_signal}\" \"customary_cleanup_function\"" "${_signal}"; done
trap "tr_trap_exit_interrupted \"customary_cleanup_function\"" INT
trap "tr_trap_exit_unknown_error \"customary_cleanup_function\"" ERR
```


#### 06. Source 'msg.sh'

This is usually done first because other *pl_bash_functions package* files may use them. Run function: `ms_format` which
sets important global variables for  the *pl_bash_functions package* message system.

We pass the calling script PATH to the function in case of error messages.

```bash
source "${_PL_BASH_FUNCTIONS_DIR}/msg.sh"
ms_format "${_THIS_SCRIPT_PATH}"
```

#### 07. Optional Set Message Verbosity

**GENERAL LEVEL**

The Variable `_MS_VERBOSE="yes" ` is set in the function `ms_format()`.
Optionally one can set it to `_MS_VERBOSE="no" ` to skip some general messages.

* `_MS_VERBOSE="yes" `: all general messages are printed
* `_MS_VERBOSE="no" `: general are silenced

**ADDITIONAL INFO LEVEL**

The Variable `_MS_VERBOSE_MORE="yes" ` is set in the function `ms_format()`.
Optionally one can set it to `_MS_VERBOSE_MORE="no" ` to skip such  additional messages.

* `_MS_VERBOSE_MORE="yes" `: enables such additional messages
* `_MS_VERBOSE_MORE="no" `: silences such additional messages

!!! note

    The Verbosity Levels work independently to silence both one needs to set BOTH levles to `false`


#### 08. Optional Print A Main Header

```bash
ms_header "${_MS_GREEN}" "$(gettext "Just Testing...")"
```


#### 09. Optional Request User Confirmation

It is recommendet that in end-user scripts a request for user action is set.

The function `ms_request_continue` can be used for that: there is an optional user/account argument under which the script must
run.

```bash
ms_request_continue
```

Abort if the script is not executed under user/account *root*.

```bash
ms_request_continue "root"
```


#### 10. Optional Test 'pl_bash_functions' Version

Test if the `pl_bash_functions version` is the one which your script was tested with.

```bash
ms_has_tested_version "0.9.1"
```


#### 11. Source 'utilities.sh'

```bash
source ""${_PL_BASH_FUNCTIONS_DIR}/utilities.sh"
```

!!! hint

    Afterwards use function: `ut_source_safe_abort` to source any other files.


#### 12. Source Other Files

After that source any needed other files.

```bash
ut_source_safe_abort "anything_else......"
```

#### 13. Optional Check Needed Programs

This does only check for the main programs.

```bash
do_got_download_programs_abort
do_got_extract_programs_abort
```

With setting the file download program to curl: (default is 'wget').

```bash
do_got_download_programs_abort "curl"
do_got_extract_programs_abort
```
