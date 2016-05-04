#******************************************************************************************************************************
#
#   <extract_sources.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: SEE: the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   ADJUST REQUIRED SETTINGS: IMPORTANT keep these otherwise some function might misbehave or fail
#
#=============================================================================================================================#

unset GREP_OPTIONS
shopt -s extglob



#=============================================================================================================================#
#
#                   HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Call this once to check for the main commands used by the extract functions: aborts if not found
#******************************************************************************************************************************
do_got_extract_programs_abort() {
    ut_no_command_abort "bsdtar"
    ut_no_command_abort "gzip"
    ut_no_command_abort "bzip2"
    ut_no_command_abort "xz"
    ut_no_command_abort "git"
    ut_no_command_abort "hg"
    ut_no_command_abort "bzr"
}



#=============================================================================================================================#
#
#                   PKGFILE SOURCE DOWNLOAD RELATED FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Main extract entry function:     IMPORTANT: for more info see the individual extract functions and the tests folder.
#
#   ARGUMENTS
#       `_in_ex_scrmtx`: a reference var:Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#       `_build_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_remove_build_dir`: yes/no    if "yes" the '_build_srcdir' is removed in case of an error/aborting. Default: "yes"
#
#   USAGE
#       ex_extract_source SCRMTX "BUILD_SRCDIR"
#       ex_extract_source SCRMTX "BUILD_SRCDIR" "$KEEP_BUILD_SRCDIR"
#******************************************************************************************************************************
ex_extract_source() {
    local _fn="ex_extract_source"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '1': MUST NOT be empty")" "${_fn}"
    [[ -n $2 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '2': MUST NOT be empty")" "${_fn}"
    local -n _in_ex_scrmtx=${1}
    local _build_srcdir=${2}
    local _remove_build_dir=${3:-"yes"}
    declare -i _n
    local _entry _protocol _destpath


    if [[ ! -v _in_ex_scrmtx[NUM_IDX] ]]; then
        ms_abort "${_fn}" "$(gettext "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_ex_scrmtx[NUM_IDX]}; _n++ )); do
        _entry=${_in_ex_scrmtx[${_n}:ENTRY]}
        case "${_in_ex_scrmtx[${_n}:PROTOCOL]}" in
            ftp|http|https) ex_extract_file ${_n} _in_ex_scrmtx "${_build_srcdir}" "${_remove_build_dir}" ;;
            local) ex_extract_only_copy     ${_n} _in_ex_scrmtx "${_build_srcdir}" "${_remove_build_dir}" ;;
            git)   ex_extract_git           ${_n} _in_ex_scrmtx "${_build_srcdir}" "${_remove_build_dir}" ;;
            svn)   ex_extract_svn           ${_n} _in_ex_scrmtx "${_build_srcdir}" "${_remove_build_dir}" ;;
            hg)    ex_extract_hg            ${_n} _in_ex_scrmtx "${_build_srcdir}" "${_remove_build_dir}" ;;
            bzr)   ex_extract_bzr           ${_n} _in_ex_scrmtx "${_build_srcdir}" "${_remove_build_dir}" ;;
        esac
    done
}


#******************************************************************************************************************************
# Handling the *copying* of `File` sources.
#
#   ARGUMENTS
#       `_idx`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_c`: a reference var:Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#       `_build_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_remove_build_dir`: yes/no    if "yes" the '_build_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
ex_extract_only_copy() {
    local _fn="ex_extract_only_copy"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '1': MUST NOT be empty")" "${_fn}"
    declare -i _idx=${1}
    local -n _in_ex_scrmtx_c=${2}
    local _build_srcdir=${3}
    local _remove_build_dir=${4:-"yes"}
    local _destpath=${_in_ex_scrmtx_c[${_idx}:DESTPATH]}
    local _finalpath="${_build_srcdir}/${_in_ex_scrmtx_c[${_idx}:DESTNAME]}"

    if [[ ! -e ${_destpath} ]]; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "File copy source  not found: <%s>")" "${_destpath}"
    fi

    ms_msg "$(gettext "Copying file: <%s>")" "${_destpath}"
    ms_more "$(gettext "To work-path: <%s>")" "${_finalpath}"

    cp -f "${_destpath}" "${_finalpath}"
    if (( ${?} )); then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Failure while copying <%s> to <%s>")" "${_destpath}" "${_finalpath}"
    fi
}


#******************************************************************************************************************************
# Handling the *extract* of `File` sources.
#
#   ARGUMENTS
#       `_idx`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_f`: a reference var:Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#       `_build_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_remove_build_dir`: yes/no    if "yes" the '_build_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
ex_extract_file() {
    local _fn="ex_extract_file"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '1': MUST NOT be empty")" "${_fn}"
    declare -i _idx=${1}
    local -n _in_ex_scrmtx_f=${2}
    local _build_srcdir=${3}
    local _remove_build_dir=${4:-"yes"}
    local _destpath=${_in_ex_scrmtx_f[${_idx}:DESTPATH]}
    local _destname=${_in_ex_scrmtx_f[${_idx}:DESTNAME]}
    local _noextract=${_in_ex_scrmtx_f[${_idx}:NOEXTRACT]}
    local _destname_no_ext; ut_get_prefix_longest_all _destname_no_ext "${_destname}" "."
    local _extension; ut_get_postfix_shortest_empty _extension "${_destname}" "."
    local _cmd=""
    declare -i _ret
    if [[ -e ${_destpath} ]]; then
        local _file_type=$(file -bizL "${_destpath}")
    else
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" "$(gettext "File source  not found: <%s>")" \
            "${_destpath}"
    fi

    if [[ ${_noextract} == NOEXTRACT ]]; then
        ms_more "$(gettext "%s() only copy: noextract: '%s'")" "${_fn}" "${_noextract}"
        ex_extract_only_copy ${_idx}  _in_ex_scrmtx_f "${_build_srcdir}" "${_remove_build_dir}"
        return 0
    fi

    # do not rely on extension for file type
    case "${_file_type}" in
        *application/x-tar*|*application/zip*|*application/x-zip*| \
        *application/x-cpio*|*application/x-rpm*|*application/vnd.debian.binary-package*)
            _cmd="bsdtar"
            ;;
        *application/x-gzip*)
            case "${_extension}" in
                gz|z|Z) _cmd="gzip" ;;
                *)      return 0   ;;
            esac
            ;;
        *application/x-bzip*)
            case "${_extension}" in
                bz2|bz) _cmd="bzip2" ;;
                *)      return 0    ;;
            esac
            ;;
        *application/x-xz*)
            case "${_extension}" in
                xz) _cmd="xz" ;;
                *)  return 0 ;;
            esac
            ;;
        *)
            # See if bsdtar can recognize the file
            if bsdtar -tf "${_destpath}" -q '*' &> /dev/null; then
                _cmd="bsdtar"
            else
                ex_extract_only_copy ${_n} _in_ex_scrmtx_f "${_build_srcdir}" "${_remove_build_dir}"
                return 0
            fi
            ;;
    esac

    ms_msg "$(gettext "Using (%s) to extract file: <%s>")" "${_cmd} " "${_destpath}"
    ms_more "$(gettext "To build-dir: <%s>")" "${_build_srcdir}"

    _ret=0
    if [[ ${_cmd}  == bsdtar ]]; then
        ${_cmd}  -p -C "${_build_srcdir}" -xf "${_destpath}" || _ret=${?}
    else
        rm -f -- "${_build_srcdir}/${_destname_no_ext}"
        ${_cmd}  -dcf "${_destpath}" > "${_build_srcdir}/${_destname_no_ext}" || _ret=${?}
    fi

    if (( ${_ret} )); then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Failed to extract file <%s> to <%s>")" "${_destpath}" "${_build_srcdir}"
    fi

    if (( EUID == 0 )); then
        # change perms of all source files to root user & root group
        chown -R 0:0 "${_build_srcdir}"
    fi
}


#******************************************************************************************************************************
# Handling the *extract* of `Git` sources.
#
#   ARGUMENTS
#       `_idx`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_g`: a reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#       `_build_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_remove_build_dir`: yes/no    if "yes" the '_build_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
ex_extract_git() {
    local _fn="ex_extract_git"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '1': MUST NOT be empty")" "${_fn}"
    declare -i _idx=${1}
    local -n _in_ex_scrmtx_g=${2}
    local _build_srcdir=${3}
    local _remove_build_dir=${4:-"yes"}
    local _fragment=${_in_ex_scrmtx_g[${_idx}:FRAGMENT]}
    local _destname=${_in_ex_scrmtx_g[${_idx}:DESTNAME]}
    local _destpath=${_in_ex_scrmtx_g[${_idx}:DESTPATH]}
    local _uri_basename; ut_basename _uri_basename "${_in_ex_scrmtx_g[${_idx}:URI]}"
    local _repo; ut_get_prefix_longest_all _repo "${_uri_basename}" ".git"
    local _finalpath="${_build_srcdir}/${_destname}"
    local _ref="origin/HEAD"
    declare -i _updating
    local _tmp_var


    if [[ ! -e ${_destpath} ]]; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" "$(gettext "Git source  not found: <%s>")" \
            "${_destpath}"
    fi

    ms_msg "$(gettext "Creating working copy of git repo: '%s'")" "${_repo}"
    ms_more "$(gettext "Path: <%s>")" "${_finalpath}"

    pushd "${_build_srcdir}" &> /dev/null

    _updating=0
    if [[ -d ${_finalpath} ]]; then
        _updating=1
        ut_cd_safe_abort "${_finalpath}"
        if ! git fetch; then
            ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
                "$(gettext "Failure while updating working copy of git repo: '%s'")" "${_repo}"
        fi
    elif ! git clone "${_destpath}" "${_finalpath}"; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Failure while creating working copy of git repo: '%s'")" "${_repo}"
    fi

    ut_cd_safe_abort "${_finalpath}"

    if [[ -n ${_fragment} ]]; then
        ut_get_prefix_shortest_all _tmp_var "${_fragment}" "="
        case "${_tmp_var}" in
            commit|tag) ut_get_postfix_shortest_all _ref "${_fragment}" "=" ;;
            branch)
                ut_get_postfix_shortest_all _ref "${_fragment}" "="
                _ref=origin/${_ref}
                ;;
            *) ms_abort "${_fn}" "$(gettext "Unrecognized fragment (reference): '%s'. ENTRY: '%s'")" "${_fragment}" \
                "${_entry}" ;;
        esac
    fi

    if [[ ${_ref} != "origin/HEAD" ]] || (( _updating )); then
        if ! git checkout --force --no-track -B "p-linux-work-branch" "${_ref}"; then
            ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
                "$(gettext "Failure while creating working copy of git repo: '%s'")" "${_repo}"
        fi
    fi

    popd &> /dev/null
}


#******************************************************************************************************************************
# Handling the *extract* of `Subversion` sources.
#
#   ARGUMENTS
#       `_idx`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_c`: a reference var:Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#       `_build_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_remove_build_dir`: yes/no    if "yes" the '_build_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
ex_extract_svn() {
    local _fn="ex_extract_svn"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '1': MUST NOT be empty")" "${_fn}"
    declare -i _idx=${1}
    local -n _in_ex_scrmtx_s=${2}
    local _build_srcdir=${3}
    local _remove_build_dir=${4:-"yes"}
    local _destname=${_in_ex_scrmtx_s[${_idx}:DESTNAME]}
    local _destpath=${_in_ex_scrmtx_s[${_idx}:DESTPATH]}
    local _repol; ut_basename _repo "${_in_ex_scrmtx_s[${_idx}:URI]}"
    local _finalpath="${_build_srcdir}/${_destname}"

    if [[ ! -e ${_destpath} ]]; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Subversion source  not found: <%s>")" "${_destpath}"
    fi

    ms_msg "$(gettext "Creating working copy of svn repo: '%s'")" "${_repo}"
    ms_more "$(gettext "Path: <%s>")" "${_finalpath}"

    if ! cp -au "${_destpath}" "${_build_srcdir}"; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Failure while creating working copy of svn repo: '%s'")" "${_repo}"
    fi
}


#******************************************************************************************************************************
# Handling the *extract* of `Mercurial` sources.
#
#   ARGUMENTS
#       `_idx`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_h`: a reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#       `_build_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_remove_build_dir`: yes/no    if "yes" the '_build_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
ex_extract_hg() {
    local _fn="ex_extract_svn"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '1': MUST NOT be empty")" "${_fn}"
    declare -i _idx=${1}
    local -n _in_ex_scrmtx_h=${2}
    local _build_srcdir=${3}
    local _remove_build_dir=${4:-"yes"}
    local _destname=${_in_ex_scrmtx_h[${_idx}:DESTNAME]}
    local _destpath=${_in_ex_scrmtx_h[${_idx}:DESTPATH]}
    local _repo; ut_basename _repo "${_in_ex_scrmtx_h[${_idx}:URI]}"
    local _finalpath="${_build_srcdir}/${_destname}"
    local _ref="tip"

    if [[ ! -e ${_destpath} ]]; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Mercurial source  not found: <%s>")" "${_destpath}"
    fi

    ms_msg "$(gettext "Creating working copy of hg repo: '%s'")" "${_repo}"
    ms_more "$(gettext "Path: <%s>")" "${_finalpath}"

    pushd "${_build_srcdir}" &> /dev/null

    if [[ -n ${_fragment} ]]; then
        case "$(ut_get_prefix_shortest_all "${_fragment}" "=")" in
            branch|revision|tag) ut_get_postfix_shortest_all _ref "${_fragment}" "=" ;;
            *) ms_abort "${_fn}" "$(gettext "Unrecognized fragment (reference): '%s'. ENTRY: '%s'")" "${_fragment}" \
                "${_entry}" ;;
        esac
    fi

    if [[ -d ${_finalpath} ]]; then
        ut_cd_safe_abort "${_finalpath}"
        if ! (hg pull && hg update -C -r "${_ref}"); then
            ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
                "$(gettext "Failure while updating working copy of hg repo: '%s'")" "${_repo}"
        fi
    elif ! hg clone -u "${_ref}" "${_destpath}" "${_finalpath}"; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Failure while creating working copy of hg repo: '%s'")" "${_repo}"
    fi

    popd &> /dev/null
}


#******************************************************************************************************************************
# Handling the *extract* of `Bazaar` sources.
#
#   ARGUMENTS
#       `_idx`: the 'NUM_IDX' number in the '_in_ex_scrmtx_c'
#       `_in_ex_scrmtx_h`: a reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#       `_build_srcdir`: Path to a directory to copy/extract sources into.
#
#   OPTIONAL ARGS:
#       `_remove_build_dir`: yes/no    if "yes" the '_build_srcdir' is removed in case of an error/aborting. Default: "yes"
#******************************************************************************************************************************
ex_extract_bzr() {
    local _fn="ex_extract_svn"
    [[ -n $1 ]] || ms_abort "${_fn}" "$(gettext "FUNCTION: '%s()' Argument '1': MUST NOT be empty")" "${_fn}"
    declare -i _idx=${1}
    local -n _in_ex_scrmtx_h=${2}
    local _build_srcdir=${3}
    local _remove_build_dir=${4:-"yes"}
    local _destname=${_in_ex_scrmtx_h[${_idx}:DESTNAME]}
    local _destpath=${_in_ex_scrmtx_h[${_idx}:DESTPATH]}
    local _repo; ut_basename _repo "${_in_ex_scrmtx_h[${_idx}:URI]}"
    local _finalpath="${_build_srcdir}/${_destname}"
    local _ref="last:1"

    if [[ ! -e ${_destpath} ]]; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" "$(gettext "Bazaar source  not found: <%s>")" \
            "${_destpath}"
    fi

    ms_msg "$(gettext "Creating working copy of bzr repo: '%s'")" "${_repo}"
    ms_more "$(gettext "Path: <%s>")" "${_finalpath}"

    pushd "${_build_srcdir}" &> /dev/null

    if [[ -n ${_fragment} ]]; then
        case "$(ut_get_prefix_shortest_all "${_fragment}" "=")" in
            revision) ut_get_postfix_shortest_all _ref "${_fragment}" "=" ;;
            *) ms_abort "${_fn}" "$(gettext "Unrecognized fragment (reference): '%s'. ENTRY: '%s'")" "${_fragment}" \
                "${_entry}" ;;
        esac
    fi

    if [[ -d ${_finalpath} ]]; then
        ut_cd_safe_abort "${_finalpath}"
        if ! (bzr pull "${_destpath}" -q --overwrite -r "${_ref}" && bzr clean-tree -q --detritus --force); then
            ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
                "$(gettext "Failure while updating working copy of bzr repo: '%s'")" "${_repo}"
        fi
    elif ! bzr checkout "${_destpath}" -r "${_ref}"; then
        ms_abort_remove_path "${_fn}" "${_remove_build_dir}" "${_build_srcdir}" \
            "$(gettext "Failure while creating working copy of bzr repo: '%s'")" "${_repo}"
    fi

    popd &> /dev/null
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
