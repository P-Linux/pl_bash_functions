# Code Style

<p align="center">Some 'general' information on code style used in the 'pl_bash_functions' package.</p>


---

!!! note

    There might be some exceptions as I see fit.


## Line length

In general the line length used is maximum **127 chars** per line.


## Indentation

In general the indentation are **4 Spaces** per level.


## Naming Convention

### Function Name Prefix

In general Function Names are prefixed with the **First letter of the shell filename followed by one underscore**.

Example: if the 'pl_bash_functions' file is called: **msg.sh** - the prefix would be: **m_**

* `Function Name`: **m_abort**

* Sometimes the **Function Name** is prefixed with an underscore: e.g. function within function

* Exception: sometimes an additional letter is added to distinguish files which start with the same letter.
    * e.g. `testing.sh, trap_opt.sh`


### Function Exit/Abort

In general Function which abort on failure use following name syntax.

* `Exit if XXX`: **u_exit_sparse_array** -  Exit/Abort if it is a sparse array.
* `If XXX fails Exit`: **u_file_is_rw_exit** - If file is read/writeable fails, exit/abort.


### Variable Names

'pl_bash_functions' package own variable names follow following syntax.


#### Global Variable Names

Global variable names are prefixed with `_BF` (Bash Functions) and use uppercase letters, digits and underscores.

Example: `_BF_VERSION`


#### Local Variable Names

Local variable names are prefixed with `_` and use lowercase letters, digits and underscores.

Example: `_pkgfile_path`


## Backticks - Parenthesis

**Parenthesis** are prefered over *Backticks*.

```bash
# YES
_dir=$(dirname "/home/me/test/myscript.sh")

# NO
_dir=`dirname "/home/me/test/myscript.sh"`
```


## Square Brackets

**Double square brackets** are prefered over *Single square brackets*.

```bash
_a="yes exit"

# YES
if [[ ${_a} == "yes exit" ]]; then exit 1; fi

# NO
if [ "${_a}" == "yes exit" ]; then exit 1; fi

# ERROR: too many arguments
if [ ${_a} == "yes exit" ]; then exit 1; fi
```


## Shell Parameter Expansion

In general braces are used for parameter expansion. To be consistent braces are also used if a variable stands alone.

```bash
_a="test"

# YES
if [[ ${_a} == "yes exit" ]]; then exit 1; fi

# NO
if [[ $_a == "yes exit" ]]; then exit 1; fi
```


## Quotation Marks

**Double quotations marks** are prefered over *Single quotations marks*.

```bash
# YES
_a="A long text"

# NO
_a='A long text'

# EXCEPTION: literal text
echo '_lfs_target=$(uname -m)-lfs-linux-gnu' > .example.txt
```


### Variables Unquoted Within Double Square Brackets

In general simple variables within double square brackets are left unquoted.

```bash
_a="yes exit"
_b=${_a}

# YES
if [[ ${_a} == "yes exit" ]]; then exit 1; fi

if [[ ${_a} == ${_b} ]]; then exit 1; fi

# NO
if [[ "${_a}" == "yes exit" ]]; then exit 1; fi

if [[ "${_a}" == "${_b}" ]]; then exit 1; fi

```


### Variables Unquoted In Right Hand Assignment

In general variables in right hand assignment are left unquoted.

```bash
# YES
_a=$1

_dir=$(dirname "/home/me/test/myscript.sh")

# NO
_a="$1"

_dir="$(dirname "/home/me/test/myscript.sh")"
```


## Appending/Adding

In general this syntax is used.


### Append To A String

```bash
_a="STRING:"
_a+=" appended"
```


### Append/Add To An Integer

All integer variables should be declared as integer: `declare -i _myint=0`
Variables are also access through the $


```bash
# YES
declare -i _b=8
_b+=7
echo ${_b}

declare -i _b=5
declare -i _c=6
_b+=${_c}
echo ${_b}

declare -i _b=0
declare -i _c=0
_b+=${_c}
echo ${_b}

# NO: Reason it raises our `ERR trap` if both values are 0
declare -i _b=8
((_b+=7))

declare -i _b=0
declare -i _c=0
((_b+=_c))      # Raises `ERR trap`
```


### Append To An Index Array

```bash
_c=("ARRAY:")
_c+=("appended")
```


## Return Values

In general return statements will add always a return value: success (0), failure (1-255)

```bash
_V="yes"
if [[ ${_V} == "yes" ]]; then
    return 0
else
    do_something_else
fi
```


### Testing Return Values

In general this syntax is used: TEST if FAILED: `(( ${?} ))`

```bash
[[ "a" == "b" ]]
_ret=${?}
if (( ${_ret} )); then
    printf "%s\n" "COMMAND FAILED"
fi

```bash
_check_failed=${?}

# Return on success
(( ${_ret} )) || return 0

# OR Simple
(( ${?} )) || return 0
```


## Functions

In general functions in the *pl_bash_functions package* are self-contained: they do not use global variables and declare all
used variabled as: local

**Exceptions:**

* functions within function may use the outer function variables.
* functions will also use the msg variables declared by: `ms_format()`.
* some functions declare on purpose variables which are not set local: e.g.
    * some Pkgfile related function
    * some Port processing related function
* some functions relay on official Pkgfile variables: in such case a Pkgfile must first have been sourced or the required
    variables set globally.


### Function Arguments/Variables

In general:

* FIRST: Checks for valid function input arguments
* SECOND: most function arguments are assigned to local variables before they are used.
    * **Exception:** in small functions they are not re-assigned to local variables as arguments ar limited in bash:
        *Error: Argument list too long*
* THIRD: any other used variable are declared "local"
* Fourth: comes the rest of the code


## Speed

In some cases consideration for faster execution was given - could be in the future improved.

To avoid the creation of many subshell calls like:

```bash
local _result=$(function_1 "argument1")
```

The *pl_bash_functions package* uses for some function which return results **: a reference variables**.

Typically the first passed argument will hold the updated result. e.g.

```bash
local _result; function_1 _result "argument1"
```

!!! note

    This has also some costs - especially the usage is not always as easily to spot
    because natuarly one considers the first arg only as an other argument and not
    as the return variable.

    Only for demonstartion: this does not work: traditional usage

        _tmp_uri=$(u_prefix_shortest_all "${_entry}" "#")
        if (( ${_num_prefix_sep} > 0 )); then
            _tmp_uri=$(u_postfix_shortest_empty "${_tmp_uri}" "::")
        fi
        _uri=$(u_postfix_longest_all "${_tmp_uri}" "+")

    Speed improved usage

        u_prefix_shortest_all _tmp_uri "${_entry}" "#"
        if (( ${_num_prefix_sep} > 0 )); then
            u_postfix_shortest_empty _tmp_uri "${_tmp_uri}" "::"
        fi
        u_postfix_longest_all _uri "${_tmp_uri}" "+"


!!! warning

    The variable which is pass MUST NOT have the same name as used in the function,
    otherwise one might get (warning: circular name reference) and all breaks.

    It is also important that these variables are passed to the function only by name.


For examples see: `tests/example_usage__function_return_values.sh`


## Diverse


### String Empty/Not Empty Tests

In general it is prefered to use: `-n` to test for none empty as well as empty strings.

```bash
# YES
if [[ ! -n ${_dl_prog_opts} ]]; then
    

# NO
if [[ -z ${_dl_prog_opts} ]]; then
```

### Commands List AND/OR With ERR Trap

If one uses error traps: `i_trap_err` one must pay special attention if one uses *Commands Lists*.

EXAMPLE: 

```bash
CM_DOWNLOAD="no"

# This will trigger an ERR trap because the first part returns none 0.
[[ ${CM_DOWNLOAD} == "yes" ]] && echo "Do something"

# This works as expected: but double negation is not the best
[[ ${CM_DOWNLOAD} != "yes" ]] || echo "Do something"

# Best to use an if in this case
if [[ ${CM_DOWNLOAD} == "yes" ]]; then echo "Do something"; fi
```
 
!!! warning

    Do not use `commands lists with &&` together with `ERR trap`


