# Release Notes


---


## v0.9.6 (xxxx-xx-xx)

* adjust function: u_repeat_failed_command() do not trigger ERR traps on exit if command failed
    and retrieve the actual commands exit code
* adjust function: u_in_array: do not trigger ERR traps if the array is empty


## v0.9.5 (2016-05-30)

* util.sh improved error feedback for some functions
* small improvement to tests.sh: checks now if we have got the number of expected tests
* replaces command lists && with other code to allow ERR traps
* improvement error feedback for required function arguments
* improvement error feedback for reuired none empty function arguments
* Number of Tests: 700
* adds option to export all functions and global variables: 
    Note: arrays need some extra work in bash
* adds function: i_trap_exit
* removes function: pk_get_only_pkgvers_exit


## v0.9.4 (2016-05-26)

* adds more general stricter settings: shopt, set
* Code refactoring
* Fixes some errors


## v0.9.3 (2016-05-15)

* Complete refactoring to avoid: Error: Argument list too long
    * Shorten bashfile/function/variable names, strings etc.
    * gettext was aliased to `_g`


## v0.9.2 (2016-05-12)

* Some speed improvements
* Adds requirement for permission to overwrite files: `set +o noclobber`
* Adds requirement for: `shopt -s dotglob`
* Adds separate: pkgarchives.sh
* New functions and tests
* Changes to local source files from `Local source MUST NOT start with a slash.` to `Local source MUST NOT contain any slash.`
    * Reason: for Port-Repo-Files we do want to include all the local files but nothing in subdirectories.
* Run tests in subshells to isolate them a bit
* Argument was removed from function: ms_format()
* Function arguments assignment was reduced to avoid: Error: Argument list too long


## v0.9.1 (2016-05-05)

* some speed improvements
* new `process_ports` functions
* install scripts/tests in a *scripts/tests subfolder*
* code style adjustments: use braces for variables


## v0.9.0 (2016-05-02)

* Initial Release


## History

On 17. March 2016 **peter1000** <https://github.com/peter1000/> started work on the new package
[pl_bash_functions](https://github.com/P-Linux/pl_bash_functions).
