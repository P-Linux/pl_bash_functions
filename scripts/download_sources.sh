#******************************************************************************************************************************
#
#   <download_sources.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
shopt -s extglob dotglob
set +o noclobber



#=============================================================================================================================#
#
#                   HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Aborts if the `_in_uri` is different than the folders `_origin_uri`
#
#   USAGE: do_abort_different_origin_uri "${_uri}" "${_origin_uri}" "${_destpath}" "${_entry}"
#******************************************************************************************************************************
do_abort_different_origin_uri() {
    local _fn="do_abort_different_origin_uri"
    if (( ${#} != 4 )); then
        ms_abort "do_abort_different_origin_uri" \
            "$(gettext "FUNCTION 'do_abort_different_origin_uri()': Requires EXACT '5' arguments. Got '%s'")" "${#}"
    fi
    # skip assignment:  _in_uri=${1}
    # skip assignment:  _origin_uri=${2}
    # skip assignment:  _destpath=${3}
    # skip assignment:  _entry=${4}
    local _abort_text=$(gettext "ABORTING....from:")
    local _msg1=$(gettext "Local repo folder: <%s> is not a clone of: <%s>")
    local _msg2=$(gettext "    Local folder origin_uri: <%s>")
    local _msg3=$(gettext "    ENTRY: <%s>")

    if [[ ${1} != ${2} ]]; then
        printf "${_MS_RED}    ->${_MS_ALL_OFF}${_MS_BOLD} ${_msg1}${_MS_ALL_OFF}\n" "${3}" "${1}" >&2
        printf "      ${_MS_ALL_OFF}${_MS_BOLD} ${_msg2}${_MS_ALL_OFF}\n\n" "${2}" >&2
        printf "      ${_MS_ALL_OFF}${_MS_BOLD} ${_msg3}${_MS_ALL_OFF}\n\n" "${4}" >&2
        exit 1
    fi
}


#******************************************************************************************************************************
# Call this once to check for the main commands used by the download functions: aborts if not found.
#
#   OPTIONAL ARGS:
#       `_download_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#******************************************************************************************************************************
do_got_download_programs_abort() {
    local _download_prog=${1:-"wget"}

    case "${_download_prog}" in
        curl) ut_no_command_abort "curl" ;;
        wget) ut_no_command_abort "wget" ;;
        *)  ms_abort "do_got_download_programs_abort" "$(gettext "Unsupported _download_prog: '%s'")" "${_download_prog}" ;;
    esac
    ut_no_command_abort "git"
    ut_no_command_abort "svn"
    ut_no_command_abort "hg"
    ut_no_command_abort "bzr"
}



#=============================================================================================================================#
#
#                   PKGFILE SOURCE DOWNLOAD RELATED FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Download downloadable sources by protocol filter.
#
#   ARGUMENTS
#       `_in_do_scrmtx`: reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   OPTIONAL ARGS:
#       `_verify`: yes/no if "yes" and a CHKSUM is specified for an entry the file will be checked: Default: "no"
#       `_in_dl_mirrors`: reference var: Array of mirror sites which will be checked first to download ftp|http|https sources
#       `_in_filter_protocols`: a reference var: An associative array with `PROTOCOL` names as keys.
#           Only these protocols sources will be deleted:
#           DEFAULTS TO: declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#       `_download_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#       `_download_prog_opts`:  Options to pass to the download agent: see function 'do_download_file()'
#
#   USAGE
#       declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#       do_downloadable_source SCRMTX
#       do_downloadable_source SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS FILTER
#       do_downloadable_source SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS FILTER "$DOWNLOAD_PROG" "$DOWNLOAD_PROG_OPTS"
#******************************************************************************************************************************
do_downloadable_source() {
    local -n _in_do_scrmtx=${1}
    local _verify=${2:-"no"}
    if [[ -n $3 ]]; then
        local -n _in_dl_mirrors=${3}
    else
        local _in_dl_mirrors=()
    fi
    if [[ -n $4 ]]; then
        local -n _in_filter_protocols=${4}
    else
        declare -A _in_filter_protocols=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
    fi
    local _download_prog=${5:-"wget"}
    local _download_prog_opts=${6:-""}
    declare -i _n
    local _in_filter_protocols_keys_string _protocol

    if [[ -v _in_filter_protocols["local"] ]]; then
        _in_filter_protocols_keys_string=${!_in_filter_protocols[@]}
        ms_abort "do_downloadable_source" \
            "$(gettext "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <%s>")" \
            "${_in_filter_protocols_keys_string}"
    fi

    if [[ ! -v _in_do_scrmtx[NUM_IDX] ]]; then
        ms_abort "do_downloadable_source" "\
            $(gettext "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_do_scrmtx[NUM_IDX]}; _n++ )); do
        _protocol=${_in_do_scrmtx[${_n}:PROTOCOL]}
        if [[ -v _in_filter_protocols[${_protocol}] ]]; then
            case "${_protocol}" in
                ftp|http|https) do_download_file ${_n} _in_do_scrmtx "${_verify}" _in_dl_mirrors "${_download_prog}" \
                                "${_download_prog_opts}" ;;
                git) do_download_git ${_n} _in_do_scrmtx ;;
                svn) do_download_svn ${_n} _in_do_scrmtx ;;
                hg)  do_download_hg ${_n} _in_do_scrmtx  ;;
                bzr) do_download_bzr ${_n} _in_do_scrmtx ;;
                *) _in_filter_protocols_keys_string=${!_in_filter_protocols[@]}
                    ms_abort "do_downloadable_source" \
                        "$(gettext "The protocol: '%s' is not in the '_in_filter_protocol array keys': <%s>")" \
                        "${_protocol}" "${_in_filter_protocols_keys_string}"
            esac
        fi
    done
}


#******************************************************************************************************************************
# Main download entry function:     IMPORTANT: for more info see the individual download functions and the tests folder.
#
#   ARGUMENTS
#       `_in_do_scrmtx`: reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   OPTIONAL ARGS:
#       `_verify`: yes/no if "yes" and a CHKSUM is specified for an entry the file will be checked: Default: "no"
#       `_in_dl_mirrors`: reference var: Array of mirror sites which will be checked first to download ftp|http|https sources
#       `_download_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#       `_download_prog_opts`:  Options to pass to the download agent: see function 'do_download_file()'
#
#   USAGE
#       do_download_source SCRMTX
#       do_download_source SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS "$DOWNLOAD_PROG" "$DOWNLOAD_PROG_OPTS"
#******************************************************************************************************************************
do_download_source() {
    local -n _in_do_scrmtx=${1}
    local _verify=${2:-"no"}
    if [[ -n $3 ]]; then
        local -n _in_dl_mirrors=${3}
    else
        local _in_dl_mirrors=()
    fi
    local _download_prog=${4:-"wget"}
    local _download_prog_opts=${5:-""}
    declare -i _n
    local _destpath _file_checksum

    if [[ ! -v _in_do_scrmtx[NUM_IDX] ]]; then
        ms_abort "do_download_source" \
            "$(gettext "Could not get the 'NUM_IDX' from the matrix - did you run 'so_prepare_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_do_scrmtx[NUM_IDX]}; _n++ )); do
        _destpath=${_in_do_scrmtx[${_n}:DESTPATH]}

        case "${_in_do_scrmtx[${_n}:PROTOCOL]}" in
            ftp|http|https) do_download_file ${_n} _in_do_scrmtx "${_verify}" _in_dl_mirrors "${_download_prog}" \
                            "${_download_prog_opts}" ;;
            local)
                if [[ -f ${_destpath} ]]; then
                    ms_bold "$(gettext "Found local source file: <%s>")" "${_destpath}"
                    [[ ${_verify} != "yes" || ${_in_do_scrmtx[${_idx}:CHKSUM]} == "SKIP" ]] && return 0
                    ut_get_file_md5sum _file_checksum "${_destpath}"
                    [[ ${_file_checksum} == ${_in_do_scrmtx[${_n}:CHKSUM]} ]] && return 0
                    ms_abort "do_download_source" "$(gettext "Failed verifying checksum: local source file: <%s>")" \
                        "${_destpath}"
                else
                    ms_abort "do_download_source" "$(gettext "Could not find local source file: <%s>")" "${_destpath}"
                fi
                ;;
            git) do_download_git ${_n} _in_do_scrmtx ;;
            svn) do_download_svn ${_n} _in_do_scrmtx ;;
            hg)  do_download_hg ${_n} _in_do_scrmtx  ;;
            bzr) do_download_bzr ${_n} _in_do_scrmtx ;;
        esac
    done
}


#******************************************************************************************************************************
# Handling the *download* of `File` sources.
#
#   IMPORTANT:
#
#       * If `_DOWNLOAD_PROG_OPTS` are set: only these options are used:
#
#           EXCEPTIONS: `_RESUME_OPTS` are handled internally - so do not set them in `_DOWNLOAD_PROG_OPTS`
#                      Also consider that FAILED COMMANDS are repeated internally.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_f'
#       `_in_do_scrmtx_f`: reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   OPTIONAL ARGS:
#       `_verify`: yes/no    if "yes" and a CHKSUM is specified for an entry the file will be checked: Default: "no"
#       `_in_dl_mirrors_f`: reference var: Array of mirror sites which will be checked first to download ftp|http|https sources.
#       `_download_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#       `_download_prog_opts`:  Options to pass to the download agent: see function 'do_download_file()'
#
#   USAGE
#       do_download_file $NUM_IDX SCRMTX "$VERIFY_CHKSUM"
#       do_download_file  $NUM_IDX SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS "$DOWNLOAD_PROG" "$DOWNLOAD_PROG_OPTS"
#******************************************************************************************************************************
do_download_file() {

    _download_move() {
        local __uri=${1}
        local __resume_opts=${2:-""}

        ${_download_prog} ${_download_opts} ${__resume_opts} "${__uri}" || return 1
        mv -f "${_download_tmp_path}" "${_destpath}"
    }

    _verify_checksum() {
        local __file_checksum

        [[ ${_verify} != "yes" || ${_chksum} == "SKIP" ]] && return 0

        ut_get_file_md5sum __file_checksum "${_destpath}"
        [[ ${__file_checksum} == ${_chksum} ]] && return 0
        ms_warn2 "$(gettext "Failed verifying checksum for existing ftp|http|https source file: <%s>")" "${_destpath}"
        ms_more_i "$(gettext "ORIG-CHECKSUM: '%s' Downloaded FILE-CHECKSUM: : <%s>")" "${_chksum}" "${__file_checksum}"

        ms_bold_i "$(gettext "Removing the file.")"
        rm -f -- "${_destpath}"
        return 1
    }

    if [[!  -n ${1} ]]; then
        ms_abort "do_download_file" "$(gettext "FUNCTION: 'do_download_file()' Argument '1': MUST NOT be empty")"
    fi
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_f=${2}
    local _verify=${3:-"no"}
    if [[ -n $4 ]]; then
        local -n _in_dl_mirrors_f=${4}
    else
        local _in_dl_mirrors_f=()
    fi
    local _download_prog=${5:-"wget"}
    local _download_prog_opts=${6:-""}
    local _resume_opts=""
    local _chksum=${_in_do_scrmtx_f[${1}:CHKSUM]}
    local _protocol=${_in_do_scrmtx_f[${1}:PROTOCOL]}
    local _uri=${_in_do_scrmtx_f[${1}:URI]}
    local _destpath=${_in_do_scrmtx_f[${1}:DESTPATH]}
    local _uri_basename; ut_basename _uri_basename "${_uri}"
    local _download_tmp_path="${_destpath}.partial"
    local _mirror

    if [[ -f ${_destpath} ]]; then
        ms_bold "$(gettext "Found ftp|http|https source file: <%s>")" "${_destpath}"
        _verify_checksum; (( ${?} )) || return 0
    fi

    case "${_protocol}" in
        ftp|http|https) ;;
        *)  ms_abort "do_download_file" "$(gettext "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_protocol}" \
                "${_in_do_scrmtx_f[${1}:ENTRY]}" ;;
    esac

    ms_msg "$(gettext "Downloading file URI: <%s>")" "${_uri}"
    ms_msg_i "$(gettext "destpath: <%s>")" "${_destpath}"

    case "${_download_prog}" in
        curl)
            _resume_opts="-C -"
            if [[ -z ${_download_prog_opts} ]]; then
                # NOTE: -q   Disable .curlrc (must be first parameter)
                _download_opts+=" -q"
                case "${_protocol}" in
                    ftp) _download_opts+=" --ftp-pasv" ;;
                    http|https) _download_opts+=" --location" ;;
                esac
                _download_opts+=" --fail --connect-timeout 6 --progress-bar --insecure"
            fi
            _download_opts+=" ${_download_prog_opts} -o ${_download_tmp_path}"
            ;;
        wget)
            _resume_opts="-c"
            if [[ -z ${_download_prog_opts} ]]; then
                case "${_protocol}" in
                    https) _download_opts+=" --no-check-certificate" ;;
                esac
                _download_opts+=" --timeout=6 --tries=1 --no-directories"
            fi
            _download_opts+=" ${_download_prog_opts} -O ${_download_tmp_path}"
            ;;
        *)  ms_abort "do_download_file" "$(gettext "Unsupported _download_prog: '%s'")" "${_download_prog}" ;;
    esac

    ut_got_internet || ms_abort "do_download_file" "$(gettext "Seems that there is no internet connection")"

    if [[ -n ${_in_dl_mirrors_f} ]]; then
        for _mirror in "${_in_dl_mirrors_f[@]}"; do
            ut_strip_trailing_slahes _mirror "${_mirror}"
            ms_more_i "$(gettext "Downloading WITH RESUME option - MIRROR URI: <%s>")" "${_mirror}/${_uri_basename}"
            ut_repeat_failed_command 2 2 _download_move "${_mirror}/${_uri_basename}" "${_resume_opts}"
            if (( ! ${?} )); then
                _verify_checksum; (( ${?} )) || return 0
            fi

            ms_more_i "$(gettext "Retrying WITHOUT RESUME option - MIRROR URI: <%s>")" "${_mirror}/${_uri_basename}"
            ut_repeat_failed_command 2 2 _download_move "${_mirror}/${_uri_basename}"
            if (( ! ${?} )); then
                _verify_checksum; (( ${?} )) || return 0
            fi
        done
    fi

    ms_more_i "$(gettext "Downloading WITH RESUME option - ORIGINAL URI: <%s>")" "${_uri}"
    ut_repeat_failed_command 2 3 _download_move "${_uri}" "${_resume_opts}"
    if (( ! ${?} )); then
        _verify_checksum; (( ${?} )) || return 0
    fi

    ms_bold "$(gettext "Retrying WITHOUT RESUME option - ORIGINAL URI: <%s>")" "${_uri}"
    rm -f -- "${_download_tmp_path}"
    ut_repeat_failed_command 2 3 _download_move "${_uri}"
    if (( ! ${?} )); then
        _verify_checksum; (( ${?} )) || return 0
    fi
    ms_abort "do_download_file" "$(gettext "Failure while downloading file. ENTRY: <%s>")" "${_in_do_scrmtx_f[${1}:ENTRY]}"
}


#******************************************************************************************************************************
# Handling the *download* of `Git` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_g'
#       `_in_do_scrmtx_g`: a reference var: Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   USAGE
#       do_download_git $NUM_IDX SCRMTX
#******************************************************************************************************************************
do_download_git() {
    [[ -n $1 ]] || ms_abort "do_download_git" "$(gettext "FUNCTION: 'do_download_git()' Argument '1': MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_g=${2}
    local _uri=${_in_do_scrmtx_g[${1}:URI]}
    local _destpath=${_in_do_scrmtx_g[${1}:DESTPATH]}
    local _destname=${_in_do_scrmtx_g[${1}:DESTNAME]}
    local _origin_uri=""

    if [[ ${_in_do_scrmtx_g[${1}:PROTOCOL]} != "git" ]]; then
        ms_abort "do_download_git" "$(gettext "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_in_do_scrmtx_g[${1}:PROTOCOL]}" \
            "${_in_do_scrmtx_g[${1}:ENTRY]}"
    fi

    ms_msg "$(gettext "Downloading git URI: <%s>")" "${_uri}"

    ut_is_git_uri_accessible "${_uri}" || ms_abort "do_download_git" "$(gettext "Failed to access the git URI: <%s>")" \
                                            "${_uri}"

    if ut_dir_has_content_abort "${_destpath}"; then
        ut_cd_safe_abort "${_destpath}"
        _origin_uri=$(git config --get remote.origin.url)
        do_abort_different_origin_uri "${_uri}" "${_origin_uri}" "${_destpath}" "${_in_do_scrmtx_g[${1}:ENTRY]}"

        ms_msg_i "$(gettext "Fetching (updating) git repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        git fetch --all --prune || ms_warn "$(gettext "Failed to update: '%s'")" "${_destname}"
    else
        ms_msg_i "$(gettext "Cloning git repo into destpath: <%s>")" "${_destpath}"
        git clone --mirror "${_uri}" "${_destpath}" || ms_abort "do_download_git" \
                                                        "$(gettext "Failed to clone git URI: <%s>")" "${_uri}"
    fi
}


#******************************************************************************************************************************
# Handling the *download* of `Subversion` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_s'
#       `_in_do_scrmtx_s`: a reference var:Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   USAGE
#       do_download_git $NUM_IDX SCRMTX
#******************************************************************************************************************************
do_download_svn() {
    [[ -n $1 ]] || ms_abort "do_download_svn" "$(gettext "FUNCTION: 'do_download_svn()' Argument '1': MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_s=${2}
    local _uri=${_in_do_scrmtx_s[${1}:URI]}
    local _fragment=${_in_do_scrmtx_s[${1}:FRAGMENT]}
    local _ref="HEAD"
    local _origin_uri=""
    local _tmp_var

    if [[ ${_in_do_scrmtx_s[${1}:PROTOCOL]} != "svn" ]]; then
        ms_abort "do_download_svn" "$(gettext "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_in_do_scrmtx_s[${1}:PROTOCOL]}" \
            "${_in_do_scrmtx_s[${1}:ENTRY]}"
    fi

    if [[ ${_in_do_scrmtx_s[${1}:PROTOCOL]} != "svn" ]]; then
        ms_abort "do_download_svn" "$(gettext "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_in_do_scrmtx_s[${1}:PROTOCOL]}" \
            "${_in_do_scrmtx_s[${1}:ENTRY]}"
    fi

    ms_msg "$(gettext "Downloading svn URI: <%s>")" "${_uri}"

    if [[ -n ${_fragment} ]]; then
        ut_get_prefix_shortest_all _tmp_var "${_fragment}" "="
        case "${_tmp_var}" in
            revision) ut_get_postfix_shortest_all _ref "${_fragment}" "=" ;;
            *) ms_abort "do_download_svn" "$(gettext "Unrecognized fragment: '%s'. ENTRY: '%s'")" "${_fragment}" \
                "${_in_do_scrmtx_s[${1}:ENTRY]}" ;;
        esac
    fi

    ut_is_svn_uri_accessible "${_uri}" || ms_abort "do_download_svn" "$(gettext "Failed to access the svn URI: <%s>")" \
                                            "${_uri}"
    if ut_dir_has_content_abort "${_destpath}"; then
        ut_cd_safe_abort "${_destpath}"
        ut_get_postfix_shortest_all _origin_uri "$(svn info | grep ^URL)" " "
        do_abort_different_origin_uri "${_uri}" "${_origin_uri}" "${_destpath}" "${_in_do_scrmtx_s[${1}:ENTRY]}"

        ms_msg_i "$(gettext "Updating svn repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        svn update --revision ${_ref} || ms_warn "$(gettext "Failed to update: '%s'")" "${_in_do_scrmtx_s[${1}:DESTNAME]}"
    else
        ms_msg_i "$(gettext "Checking-out svn repo into destpath: <%s>")" "${_destpath}"
        mkdir -p "${_destpath}/.svn_conf"
        if ! svn checkout --revision ${_ref} --config-dir "${_destpath}/.svn_conf" "${_uri}" "${_destpath}"; then
            ms_abort "do_download_svn" "$(gettext "Failed to checkout svn URI: <%s>")" "${_uri}"
        fi
    fi
}


#******************************************************************************************************************************
# Handling the *download* of `Mercurial` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_h'
#       `_in_do_scrmtx_h`: a reference var:Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   USAGE
#       do_download_hg $NUM_IDX SCRMTX
#******************************************************************************************************************************
do_download_hg() {
    [[ -n $1 ]] || ms_abort "do_download_hg" "$(gettext "FUNCTION: 'do_download_hg()' Argument '1': MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_h=${2}
    local _uri=${_in_do_scrmtx_h[${1}:URI]}
    local _destpath=${_in_do_scrmtx_h[${1}:DESTPATH]}
    local _origin_uri=""

    if [[ ${_in_do_scrmtx_h[${1}:PROTOCOL]} != "hg" ]]; then
        ms_abort "do_download_hg" "$(gettext "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_in_do_scrmtx_h[${1}:PROTOCOL]}" \
            "${_in_do_scrmtx_h[${1}:ENTRY]}"
    fi

    ms_msg "$(gettext "Downloading hg URI: <%s>")" "${_uri}"

    ut_is_hg_uri_accessible "${_uri}" || ms_abort "do_download_hg" "$(gettext "Failed to access the hg URI: <%s>")" "${_uri}"

    if ut_dir_has_content_abort "${_destpath}"; then
        ut_cd_safe_abort "${_destpath}"
        _origin_uri=$(hg paths default)
        do_abort_different_origin_uri "${_uri}" "${_origin_uri}" "${_destpath}" "${_in_do_scrmtx_h[${1}:ENTRY]}"

        ms_msg_i "$(gettext "Pulling (updating) hg repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        hg pull || ms_warn "$(gettext "Failed to update: '%s'")" "${_in_do_scrmtx_h[${1}:DESTNAME]}"
    else
        ms_msg_i "$(gettext "Cloning hg repo into destpath: <%s>")" "${_destpath}"
        hg clone -U "${_uri}" "${_destpath}" || ms_abort "do_download_hg" "$(gettext "Failed to clone hg URI: <%s>")" "${_uri}"
    fi
}


#******************************************************************************************************************************
# Handling the *download* of `Bazaar` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_b'
#       `_in_do_scrmtx_b`: a reference var:Source Matrix: see function 'so_prepare_src_matrix()' in file: <source_matrix.sh>
#
#   USAGE
#       do_download_bzr $NUM_IDX SCRMTX
#******************************************************************************************************************************
do_download_bzr() {
    [[ -n $1 ]] || ms_abort "do_download_bzr" "$(gettext "FUNCTION: 'do_download_bzr()' Argument '1': MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_b=${2}
    local _uri=${_in_do_scrmtx_b[${1}:URI]}
    local _destpath=${_in_do_scrmtx_b[${1}:DESTPATH]}
    local _origin_uri=""
    local _abort_text=$(gettext "ABORTING....from:")
    local _msg1=$(gettext "Local repo folder: <%s> is not a clone of: <%s>")
    local _msg2=$(gettext "    Local folder origin_uri: <%s>")
    local _msg3=$(gettext "    ENTRY: <%s>")

    # NOT WANTED any GREP_OPTIONS: This variable specifies default options to be placed in front of any explicit options.
    unset GREP_OPTIONS

    if [[ ${_in_do_scrmtx_b[${1}:PROTOCOL]} != "bzr" ]]; then
        ms_abort "do_download_bzr" "$(gettext "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_in_do_scrmtx_b[${1}:PROTOCOL]}" \
            "${_in_do_scrmtx_b[${1}:ENTRY]}"
    fi

    ms_msg "$(gettext "Downloading bzr URI: <%s>")" "${_uri}"

    ut_got_internet || ms_abort "do_download_bzr" "$(gettext "Seems that there is no internet connection")"

    if ut_dir_has_content_abort "${_destpath}"; then
        ut_cd_safe_abort "${_destpath}"
        ut_get_postfix_shortest_all _origin_uri "$(bzr info | grep "parent branch")" " "
        do_abort_different_origin_uri "${_uri}" "${_origin_uri}" "${_destpath}" "${_in_do_scrmtx_b[${1}:ENTRY]}"

        ms_msg_i "$(gettext "Pulling (updating) bzr repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        bzr pull "${_uri}" -Ossl.cert_reqs=none ||  ms_warn "$(gettext "Failed to update: '%s'")" \
                                                        "${_in_do_scrmtx_b[${1}:DESTNAME]}"
    else
        ms_msg_i "$(gettext "Branching bzr repo into destpath: <%s>")" "${_destpath}"
        if ! bzr branch "${_uri}" "${_destpath}" --no-tree --use-existing-dir -Ossl.cert_reqs=none; then
            ms_abort "do_download_bzr" "$(gettext "Failed to clone bzr URI: <%s>")" "${_uri}"
        fi
    fi
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
