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


### Gnu Gettext 0.19.7


### Ncurses 6.0.20150808

* tput


### Coreutils 8.24


### Gnu Findutils 4.4.2


### Grep 2.23


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

To see the *help*, run in the top-level-directory: `make`


## General Settings Requirements

These are general required settings and they are set in each file of the `pl_bash_functions package`. 
See function `t_general_opt()`.

!!! warning

    Individual function might not need all of them but some
    function might silently misbehave or fail without them.


### Variable GREP_OPTIONS

The variable *GREP_OPTIONS* MUST be *unset*: `unset GREP_OPTIONS`

This is done in each file of the `pl_bash_functions package`.

This variable specifies default options to be placed in front of any explicit options. As this causes problems when writing
portable scripts, this feature will be removed in a future release of grep, and grep warns if it is used.


### BASH shopt Options

* `shopt -s extglob`
* `shopt -s dotglob`
* `shopt -s expand_aliases`: e.g. used for the gettext alias.


### BASH Options

`set +o noclobber` is required by some functions: this is done in each file of the `pl_bash_functions package`.


## Usage

In your bash script: source the `pl_bash_functions files` you want to use.

!!! note

    Some functions require functions from other files in this package, there is some dependency order


### Common Example

Usually one wants to source first `trap_opt.sh` set the traps, source `msg.sh` and call function *m_format*, source `util.sh`
and after that anything else.

```bash
customary_cleanup_function() {
   echo "Missing code for the customary_cleanup_function"
}

declare -r _PL_BASH_FUNCTIONS_DIR="/usr/lib/pl_bash_functions/scripts"

source "${_PL_BASH_FUNCTIONS_DIR}/trap_opt.sh"
for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\" \"customary_cleanup_function\"" "${_signal}"; done
trap "t_trap_i \"customary_cleanup_function\"" INT
trap "t_trap_u \"customary_cleanup_function\"" ERR

source "${_PL_BASH_FUNCTIONS_DIR}/msg.sh"
m_format

#_M_VERBOSE="yes"       NOTE: This defaults to: yes
#_M_VERBOSE_I="yes"     NOTE: This defaults to: yes

m_header "${_M_GREEN}" "$(_g "Just Testing...")"

m_ask_continue "root"

m_has_tested_version "0.1.1"

source "${_PL_BASH_FUNCTIONS_DIR}/util.sh"

u_source_safe_exit "anything_else......"

d_got_download_prog_exit      # if the related files where sourced
e_got_extract_prog_exit       # if the related files where sourced
```

#### 01. Optional Cleanup Function

If needed add a cleanup function to be passed to the traps.

```bash
customary_cleanup_function() {
   echo "Missing code for the customary_cleanup_function"
}
```


#### 02. Get PL_BASH_FUNCTIONS_DIR

Specify where the *pl_bash_functions package is installed*: needs the *scripts directory*.

```bash
declare -r _PL_BASH_FUNCTIONS_DIR="/usr/lib/pl_bash_functions/scripts"
```


#### 03. Set Trap

Generally it is a good thing to set `traps`.

```bash
source "${_PL_BASH_FUNCTIONS_DIR}/trap_opt.sh"
for _signal in TERM HUP QUIT; do trap "t_trap_s \"${_signal}\" \"customary_cleanup_function\"" "${_signal}"; done
trap "t_trap_i \"customary_cleanup_function\"" INT
trap "t_trap_u \"customary_cleanup_function\"" ERR
```

SOURCING `trap_opt.sh"`: Sets also the required bash options. 

```
unset GREP_OPTIONS
shopt -s extglob dotglob expand_aliases
set +o noclobber
```

* It also checks for some required commands: e.g. gettext, tput
* And sets aliases: e.g. _g an alias for gettext

For mor info see function: *t_general_opt*


#### 04. Source 'msg.sh'

This is usually done first because other *pl_bash_functions package* files may use them. Run function: `m_format` which
sets important global variables for  the *pl_bash_functions package* message system.

```bash
source "${_PL_BASH_FUNCTIONS_DIR}/msg.sh"
m_format
```

#### 05. Optional Set Message Verbosity

**GENERAL LEVEL**

The Variable `_M_VERBOSE="yes" ` is set in the function: *m_format*
Optionally one can set it to `_M_VERBOSE="no" ` to skip some general messages.

* `_M_VERBOSE="yes" `: all general messages are printed
* `_M_VERBOSE="no" `: general are silenced

**ADDITIONAL INFO LEVEL**

The Variable `_M_VERBOSE_I="yes" ` is set in the function `m_format()`.
Optionally one can set it to `_M_VERBOSE_I="no" ` to skip such  additional messages.

* `_M_VERBOSE_I="yes" `: enables such additional messages
* `_M_VERBOSE_I="no" `: silences such additional messages

!!! note

    The Verbosity Levels work independently to silence both one needs to set BOTH levles to `no`


#### 06. Optional Print A Main Header

```bash
m_header "${_M_GREEN}" "$(_g "Just Testing...")"
```


#### 07. Optional Request User Confirmation

It is recommendet that in end-user scripts a request for user action is set.

The function `m_ask_continue` can be used for that: there is an optional user/account argument under which the script must
run.

```bash
m_ask_continue
```

Abort if the script is not executed under user/account *root*.

```bash
m_ask_continue "root"
```


#### 08. Optional Test 'pl_bash_functions' Version

Test if the users system has the same `pl_bash_functions version` which your script was tested with.

```bash
m_has_tested_version "0.1.1"
```


#### 09. Source 'util.sh'

```bash
source ""${_PL_BASH_FUNCTIONS_DIR}/util.sh"
```

!!! hint

    Afterwards use function: `u_source_safe_exit` to source any other files.


#### 10. Source Other Files

After that source (*u_source_safe_exit*) any needed other files.

```text
u_source_safe_exit "anything_else......"
```

#### 11. Optional Check Needed Programs

This only checks for the main programs.

```bash
d_got_download_prog_exit
e_got_extract_prog_exit
```

With setting the file download program to curl: (default is 'wget').

```bash
d_got_download_prog_exit "curl"
e_got_extract_prog_exit
```
