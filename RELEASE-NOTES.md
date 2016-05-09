# Release Notes


---


## v0.9.2 (xxxx-xx-xx)

* some speed improvements
* adds requirement for permission to overwrite files: `set +o noclobber`
* adds separate: pkgarchives.sh
* new functions and tests
* Changes to local source files from `Local source MUST NOT start with a slash.` to `Local source MUST NOT contain any slash.`
    * Reason for Port-Repo-Files we do want to include all the local files but nothing in subdirectories.
* Run tests in subshells to isolate them a bit

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
