#******************************************************************************************************************************
#
#   <download.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
#
#       For more info and example usage: SEE: the 'pl_bash_functions' package *documentation and the tests folder*.
#
#******************************************************************************************************************************

#=============================================================================================================================#
#
#                   ADJUST REQUIRED SETTINGS: IMPORTANT keep these otherwise some function might misbehave or fail
#
#=============================================================================================================================#

i_general_opt



#=============================================================================================================================#
#
#                   HELPER FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Aborts if the `_uri` is different than the folders `_origin_uri`
#
#   USAGE: d_exit_diff_origin "${URI}" "${ORIGIN_URI}" "${DESTPATH}" "${ENTRY}"
#******************************************************************************************************************************
d_exit_diff_origin() {
    i_exact_args_exit ${LINENO} 4 ${#}
    local _uri=${1}
    local _origin_uri=${2}
    local _dest=${3}
    local _entry=${4}
    local _m1=$(_g "Local repo folder: <%s> is not a clone of: <%s>")
    local _m2=$(_g "    Local folder origin_uri: <%s>")
    local _m3=$(_g "    ENTRY: <%s>")

    if [[ ${_uri} != ${_origin_uri} ]]; then
        printf "${_BF_RED}    ->${_BF_OFF}${_BF_BOLD} ${_m1}${_BF_OFF}\n" "${_dest}" "${_uri}" >&2
        printf "      ${_BF_OFF}${_BF_BOLD} ${_m2}${_BF_OFF}\n\n" "${_origin_uri}" >&2
        printf "      ${_BF_OFF}${_BF_BOLD} ${_m3}${_BF_OFF}\n\n" "${_entry}" >&2
        i_exit 1 ${LINENO} "$(_g "Local repo folder: <%s> is not a clone of: <%s>")" "${_dest}" "${_uri}"
    fi
}


#******************************************************************************************************************************
# Call this once to check for the main commands used by the download functions: aborts if not found.
#
#   OPTIONAL ARGS:
#       `_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#******************************************************************************************************************************
d_got_download_prog_exit() {
    local _prog=${1:-"wget"}

    case "${_prog}" in
        curl) u_no_command_exit "curl" ;;
        wget) u_no_command_exit "wget" ;;
        *)  i_exit 1 ${LINENO} "$(_g "Unsupported _download_prog: '%s'")" "${_prog}" ;;
    esac
    u_no_command_exit "git"
    u_no_command_exit "svn"
    u_no_command_exit "hg"
    u_no_command_exit "bzr"
}



#=============================================================================================================================#
#
#                   PKGFILE SOURCE DOWNLOAD RELATED FUNCTIONS
#
#=============================================================================================================================#


#******************************************************************************************************************************
# Main download entry function:     IMPORTANT: for more info see the individual download functions and the tests folder.
#
#   ARGUMENTS
#       `_in_do_scrmtx`: reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   OPTIONAL ARGS:
#       `_verify`: yes/no if "yes" and a CHKSUM is specified for an entry the file will be checked: Default: "no"
#       `_in_dl_mirrors`: reference var: Array of mirror sites which will be checked first to download ftp|http|https sources
#       `_dl_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#       `_dl_prog_opts`:  Options to pass to the download agent: see function 'd_download_file()'
#
#   USAGE
#       d_download_src SCRMTX
#       d_download_src SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS "$DOWNLOAD_PROG" "$DOWNLOAD_PROG_OPTS"
#******************************************************************************************************************************
d_download_src() {
    i_min_args_exit ${LINENO} 1 ${#}
    local -n _in_do_scrmtx=${1}
    local _verify=${2:-"no"}
    if (( ${#} > 3 )); then
        local -n _in_dl_mirrors=${3}
    else
        local _in_dl_mirrors=()
    fi
    local _dl_prog=${4:-"wget"}
    local _dl_prog_opts=${5:-""}
    declare -i _n
    local _destpath _file_checksum

    if [[ ! -v _in_do_scrmtx[NUM_IDX] ]]; then
        i_exit 1 ${LINENO} "$(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_do_scrmtx[NUM_IDX]}; _n++ )); do
        _destpath=${_in_do_scrmtx[${_n}:DESTPATH]}
        case "${_in_do_scrmtx[${_n}:PROTOCOL]}" in
            ftp|http|https) d_download_file ${_n} _in_do_scrmtx "${_verify}" _in_dl_mirrors "${_dl_prog}" "${_dl_prog_opts}" ;;
            local)
                if [[ -f ${_destpath} ]]; then
                    i_more_i "$(_g "Found local source file: <%s>")" "${_destpath}"
                    if [[ ${_verify} != "yes" || ${_in_do_scrmtx[${_n}:CHKSUM]} == "SKIP" ]]; then
                        return 0
                    fi
                    u_get_file_md5sum _file_checksum "${_destpath}"
                    if [[ ${_file_checksum} == ${_in_do_scrmtx[${_n}:CHKSUM]} ]]; then
                        return 0
                    fi
                    i_exit 1 ${LINENO} "$(_g "Failed verifying checksum: local source file: <%s>")" "${_destpath}"
                else
                    i_exit 1 ${LINENO} "$(_g "Could not find local source file: <%s>")" "${_destpath}"
                fi
                ;;
            git) d_download_git ${_n} _in_do_scrmtx ;;
            svn) d_download_svn ${_n} _in_do_scrmtx ;;
            hg)  d_download_hg ${_n} _in_do_scrmtx  ;;
            bzr) d_download_bzr ${_n} _in_do_scrmtx ;;
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
#       `_in_do_scrmtx_f`: reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   OPTIONAL ARGS:
#       `_verify`: yes/no  if "yes" and a CHKSUM is specified for an entry the file will be checked: Default: "no"
#       `_in_dl_mirrors_f`: reference var: Array of mirror sites which will be checked first to download ftp|http|https sources
#       `_dl_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#       `_dl_prog_opts`:  Options to pass to the download agent: see function 'd_download_file()'
#
#   USAGE
#       d_download_file $NUM_IDX SCRMTX "$VERIFY_CHKSUM"
#       d_download_file  $NUM_IDX SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS "$DOWNLOAD_PROG" "$DOWNLOAD_PROG_OPTS"
#******************************************************************************************************************************
d_download_file() {

    _download_move() {
        local __uri=${1}
        local __resume_opts=${2:-""}

        ${_dl_prog} ${_download_opts} ${__resume_opts} "${__uri}" || return 1
        mv -f "${_dl_tmp_path}" "${_destpath}"
    }

    _verify_checksum() {
        local __file_chksum

        if [[ ${_verify} != "yes" || ${_chksum} == "SKIP" ]]; then
            return 0
        fi

        u_get_file_md5sum __file_chksum "${_destpath}"
        if [[ ${__file_chksum} == ${_chksum} ]]; then
            return 0
        fi
        i_warn2 "$(_g "Failed verifying checksum for existing ftp|http|https source file: <%s>")" "${_destpath}"
        i_more_i "$(_g "ORIG-CHECKSUM: '%s' Downloaded FILE-CHECKSUM: : <%s>")" "${_chksum}" "${__file_chksum}"

        i_bold_i "$(_g "Removing the file.")"
        rm -f -- "${_destpath}"
        return 1
    }

    i_min_args_exit ${LINENO} 2 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_f=${2}
    local _verify=${3:-"no"}
    local _got_dl_mirrors="no"
    if (( ${#} > 3 )); then
        local -n _in_dl_mirrors_f=${4}
        if (( ${#_in_dl_mirrors_f[@]} > 0 )); then
            _got_dl_mirrors="yes"
        fi
    fi
    local _dl_prog=${5:-"wget"}
    local _dl_prog_opts=${6:-""}
    local _resume_opts=""
    local _chksum=${_in_do_scrmtx_f[${1}:CHKSUM]}
    local _proto=${_in_do_scrmtx_f[${1}:PROTOCOL]}
    local _uri=${_in_do_scrmtx_f[${1}:URI]}
    local _destpath=${_in_do_scrmtx_f[${1}:DESTPATH]}
    local _ent=${_in_do_scrmtx_f[${1}:ENTRY]}
    local _uri_name; u_basename _uri_name "${_uri}"
    local _dl_tmp_path="${_destpath}.partial"
    local _mirror
    declare -i _ret

    if [[ -f ${_destpath} ]]; then
        i_more_i "$(_g "Found ftp|http|https source file: <%s>")" "${_destpath}"
        _verify_checksum; (( ${?} )) || return 0
    fi

    case "${_proto}" in
        ftp|http|https) ;;
        *)  i_exit 1 ${LINENO} "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}" ;;
    esac

    i_msg "$(_g "Downloading file URI: <%s>\n      to destpath: <%s>\n")" "${_uri}" "${_destpath}"

    case "${_dl_prog}" in
        curl)
            _resume_opts="-C -"
            if [[ ! -n ${_dl_prog_opts} ]]; then
                # NOTE: -q   Disable .curlrc (must be first parameter)
                _download_opts+=" -q"
                case "${_proto}" in
                    ftp) _download_opts+=" --ftp-pasv" ;;
                    http|https) _download_opts+=" --location" ;;
                esac
                _download_opts+=" --fail --connect-timeout 6 --progress-bar --insecure"
            fi
            _download_opts+=" ${_dl_prog_opts} -o ${_dl_tmp_path}"
            ;;
        wget)
            _resume_opts="-c"
            if [[ ! -n ${_dl_prog_opts} ]]; then
                case "${_proto}" in
                    https) _download_opts+=" --no-check-certificate" ;;
                esac
                _download_opts+=" --timeout=6 --tries=1 --no-directories"
            fi
            _download_opts+=" ${_dl_prog_opts} -O ${_dl_tmp_path}"
            ;;
        *)  i_exit 1 ${LINENO} "$(_g "Unsupported _download_prog: '%s'")" "${_dl_prog}" ;;
    esac

    u_got_internet || i_exit 1 ${LINENO} "$(_g "Seems that there is no internet connection")"

    if [[ ${_got_dl_mirrors} == "yes" ]]; then
        for _mirror in "${_in_dl_mirrors_f[@]}"; do
            u_strip_end_slahes _mirror "${_mirror}"
            i_more_i "$(_g "Downloading WITH RESUME option - MIRROR URI: <%s>")" "${_mirror}/${_uri_name}"
            u_repeat_failed_command _ret 2 2 _download_move "${_mirror}/${_uri_name}" "${_resume_opts}"
            if (( ! ${_ret} )); then
                _verify_checksum; (( ${?} )) || return 0
            fi

            i_more_i "$(_g "Retrying WITHOUT RESUME option - MIRROR URI: <%s>")" "${_mirror}/${_uri_name}"
            u_repeat_failed_command _ret 2 2 _download_move "${_mirror}/${_uri_name}"
            if (( ! ${_ret} )); then
                _verify_checksum; (( ${?} )) || return 0
            fi
        done
    fi

    i_more_i "$(_g "Downloading WITH RESUME option - ORIGINAL URI: <%s>")" "${_uri}"
    u_repeat_failed_command _ret 2 3 _download_move "${_uri}" "${_resume_opts}"
    if (( ! ${_ret} )); then
        _verify_checksum; (( ${?} )) || return 0
    fi

    i_bold "$(_g "Retrying WITHOUT RESUME option - ORIGINAL URI: <%s>")" "${_uri}"
    rm -f -- "${_dl_tmp_path}"
    u_repeat_failed_command _ret 2 3 _download_move "${_uri}"
    if (( ! ${_ret} )); then
        _verify_checksum; (( ${?} )) || return 0
    fi
    i_exit 1 ${LINENO} "$(_g "Failure while downloading file. ENTRY: <%s>")" "${_ent}"
}


#******************************************************************************************************************************
# Handling the *download* of `Git` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_g'
#       `_in_do_scrmtx_g`: a reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   USAGE
#       d_download_git $NUM_IDX SCRMTX
#******************************************************************************************************************************
d_download_git() {
    i_exact_args_exit ${LINENO} 2 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_g=${2}
    local _uri=${_in_do_scrmtx_g[${1}:URI]}
    local _destpath=${_in_do_scrmtx_g[${1}:DESTPATH]}
    local _destname=${_in_do_scrmtx_g[${1}:DESTNAME]}
    local _proto=${_in_do_scrmtx_g[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_g[${1}:ENTRY]}
    local _origin_uri=""

    [[ ${_proto} == "git" ]] || i_exit 1 ${LINENO} "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    i_msg "$(_g "Downloading git URI: <%s>\n      to destpath: <%s>\n")" "${_uri}" "${_destpath}"

    u_is_git_uri_accessible "${_uri}" || i_exit 1 ${LINENO} "$(_g "Failed to access the git URI: <%s>")" "${_uri}"

    if u_has_dir_content "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        _origin_uri=$(git config --get remote.origin.url)
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        i_msg_i "$(_g "Fetching (updating) git repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        git fetch --all --prune || i_warn "$(_g "Failed to update: '%s'")" "${_destname}"
    else
        i_msg_i "$(_g "Cloning git repo into destpath: <%s>")" "${_destpath}"
        git clone --mirror "${_uri}" "${_destpath}" || i_exit 1 ${LINENO} "$(_g "Failed to clone git URI: <%s>")" "${_uri}"
    fi
}


#******************************************************************************************************************************
# Handling the *download* of `Subversion` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_s'
#       `_in_do_scrmtx_s`: a reference var:Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   USAGE
#       d_download_git $NUM_IDX SCRMTX
#******************************************************************************************************************************
d_download_svn() {
    i_exact_args_exit ${LINENO} 2 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_s=${2}
    local _uri=${_in_do_scrmtx_s[${1}:URI]}
    local _frag=${_in_do_scrmtx_s[${1}:FRAGMENT]}
    local _proto=${_in_do_scrmtx_s[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_s[${1}:ENTRY]}
    local _ref="HEAD"
    local _origin_uri=""
    local _var

    [[ ${_proto} == "svn" ]] || i_exit 1 ${LINENO} "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    i_msg "$(_g "Downloading svn URI: <%s>\n      to destpath: <%s>\n")" "${_uri}" "${_destpath}"

    if [[ -n ${_frag} ]]; then
        u_prefix_shortest_all _var "${_frag}" "="
        case "${_var}" in
            revision) u_postfix_shortest_all _ref "${_frag}" "=" ;;
            *) i_exit 1 ${LINENO} "$(_g "Unrecognized fragment: '%s'. ENTRY: '%s'")" "${_frag}" "${_ent}" ;;
        esac
    fi

    u_is_svn_uri_accessible "${_uri}" || i_exit 1 ${LINENO} "$(_g "Failed to access the svn URI: <%s>")" "${_uri}"
    if u_has_dir_content "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        u_postfix_shortest_all _origin_uri "$(svn info | grep ^URL)" " "
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        i_msg_i "$(_g "Updating svn repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        svn update --revision ${_ref} || i_warn "$(_g "Failed to update: '%s'")" "${_in_do_scrmtx_s[${1}:DESTNAME]}"
    else
        i_msg_i "$(_g "Checking-out svn repo into destpath: <%s>")" "${_destpath}"
        mkdir -p "${_destpath}/.svn_conf"
        if ! svn checkout --revision ${_ref} --config-dir "${_destpath}/.svn_conf" "${_uri}" "${_destpath}"; then
            i_exit 1 ${LINENO} "$(_g "Failed to checkout svn URI: <%s>")" "${_uri}"
        fi
    fi
}


#******************************************************************************************************************************
# Handling the *download* of `Mercurial` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_h'
#       `_in_do_scrmtx_h`: a reference var:Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   USAGE
#       d_download_hg $NUM_IDX SCRMTX
#******************************************************************************************************************************
d_download_hg() {
    i_exact_args_exit ${LINENO} 2 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_h=${2}
    local _uri=${_in_do_scrmtx_h[${1}:URI]}
    local _destpath=${_in_do_scrmtx_h[${1}:DESTPATH]}
    local _proto=${_in_do_scrmtx_h[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_h[${1}:ENTRY]}
    local _origin_uri=""

    [[ ${_proto} == "hg" ]] || i_exit 1 ${LINENO} "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    i_msg "$(_g "Downloading hg URI: <%s>\n      to destpath: <%s>\n")" "${_uri}" "${_destpath}"

    u_is_hg_uri_accessible "${_uri}" || i_exit 1 ${LINENO} "$(_g "Failed to access the hg URI: <%s>")" "${_uri}"

    if u_has_dir_content "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        _origin_uri=$(hg paths default)
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        i_msg_i "$(_g "Pulling (updating) hg repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        hg pull || i_warn "$(_g "Failed to update: '%s'")" "${_in_do_scrmtx_h[${1}:DESTNAME]}"
    else
        i_msg_i "$(_g "Cloning hg repo into destpath: <%s>")" "${_destpath}"
        hg clone -U "${_uri}" "${_destpath}" || i_exit 1 ${LINENO} "$(_g "Failed to clone hg URI: <%s>")" "${_uri}"
    fi
}


#******************************************************************************************************************************
# Handling the *download* of `Bazaar` sources.
#
#   ARGUMENTS
#       `$1 (_idx)`: the 'NUM_IDX' number in the '_in_do_scrmtx_b'
#       `_in_do_scrmtx_b`: a reference var:Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   USAGE
#       d_download_bzr $NUM_IDX SCRMTX
#******************************************************************************************************************************
d_download_bzr() {
    i_exact_args_exit ${LINENO} 2 ${#}
    i_exit_empty_arg ${LINENO} "${1}" 1
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_b=${2}
    local _uri=${_in_do_scrmtx_b[${1}:URI]}
    local _destpath=${_in_do_scrmtx_b[${1}:DESTPATH]}
    local _proto=${_in_do_scrmtx_b[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_b[${1}:ENTRY]}
    local _origin_uri=""

    [[ ${_proto} == "bzr" ]] || i_exit 1 ${LINENO} "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    i_msg "$(_g "Downloading bzr URI: <%s>\n      to destpath: <%s>\n")" "${_uri}" "${_destpath}"

    u_got_internet || i_exit 1 ${LINENO} "$(_g "Seems that there is no internet connection")"

    if u_has_dir_content "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        u_postfix_shortest_all _origin_uri "$(bzr info | grep "parent branch")" " "
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        i_msg_i "$(_g "Pulling (updating) bzr repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        bzr pull "${_uri}" -Ossl.cert_reqs=none ||  i_warn "$(_g "Failed to update: '%s'")" "${_in_do_scrmtx_b[${1}:DESTNAME]}"
    else
        i_msg_i "$(_g "Branching bzr repo into destpath: <%s>")" "${_destpath}"
        if ! bzr branch "${_uri}" "${_destpath}" --no-tree --use-existing-dir -Ossl.cert_reqs=none; then
            i_exit 1 ${LINENO} "$(_g "Failed to clone bzr URI: <%s>")" "${_uri}"
        fi
    fi
}


#******************************************************************************************************************************
# Download downloadable sources by protocol filter.
#
#   ARGUMENTS
#       `_in_do_scrmtx`: reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   OPTIONAL ARGS:
#       `_verify`: yes/no if "yes" and a CHKSUM is specified for an entry the file will be checked: Default: "no"
#       `_in_dl_mirrors`: reference var: Array of mirror sites which will be checked first to download ftp|http|https sources
#       `_in_proto_filter`: a reference var: An associative array with `PROTOCOL` names as keys.
#           Only these protocols sources will be deleted:
#           DEFAULTS TO: declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#       `_dl_prog`:       The download agent used to fetch ftp|http|https source files: `curl` or `wget`
#       `_dl_prog_opts`:  Options to pass to the download agent: see function 'd_download_file()'
#
#   USAGE
#       declare -A FILTER=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
#       d_downloadable_src SCRMTX
#       d_downloadable_src SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS FILTER
#       d_downloadable_src SCRMTX "$VERIFY_CHKSUM" DOWNLOAD_MIRRORS FILTER "$DOWNLOAD_PROG" "$DOWNLOAD_PROG_OPTS"
#******************************************************************************************************************************
d_downloadable_src() {
    i_min_args_exit ${LINENO} 1 ${#}
    local -n _in_do_scrmtx=${1}
    local _verify=${2:-"no"}
    if (( ${#} > 2 )); then
        local -n _in_dl_mirrors=${3}
    else
        local _in_dl_mirrors=()
    fi
    if (( ${#} > 3 )) && [[ -v ${4}[@] ]]; then         # Check var 4 is set and has elements
        local -n _in_proto_filter=${4}
    else
        declare -A _in_proto_filter=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0)
    fi
    local _dl_prog=${5:-"wget"}
    local _dl_prog_opts=${6:-""}
    declare -i _n
    local _tmp _proto

    if [[ -v _in_proto_filter[local] ]]; then
        _tmp=${!_in_proto_filter[@]}        # _in_proto_filter_keys_str
        i_exit 1 ${LINENO} "$(_g "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <%s>")" "${_tmp}"
    fi

    if [[ ! -v _in_do_scrmtx[NUM_IDX] ]]; then
        i_exit 1 ${LINENO} "$(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_do_scrmtx[NUM_IDX]}; _n++ )); do
        _proto=${_in_do_scrmtx[${_n}:PROTOCOL]}
        if [[ -v _in_proto_filter[${_proto}] ]]; then
            case "${_proto}" in
                ftp|http|https) d_download_file ${_n} _in_do_scrmtx "${_verify}" _in_dl_mirrors "${_dl_prog}" \
                                "${_dl_prog_opts}" ;;
                git) d_download_git ${_n} _in_do_scrmtx ;;
                svn) d_download_svn ${_n} _in_do_scrmtx ;;
                hg)  d_download_hg ${_n} _in_do_scrmtx  ;;
                bzr) d_download_bzr ${_n} _in_do_scrmtx ;;
                *) _tmp=${!_in_proto_filter[@]}
                    i_exit 1 ${LINENO} "$(_g "The protocol: '%s' is not in the '_in_filter_protocol array keys': <%s>")" \
                        "${_proto}" "${_tmp}"
            esac
        fi
    done
}


#******************************************************************************************************************************
# TODO: UPDATE THIS if there are functions/variables added or removed.
#
# EXPORT:
#   helpful command to get function names: `declare -F` or `compgen -A function`
#******************************************************************************************************************************
d_export() {
    local _func_names _var_names

    _func_names=(
        d_download_bzr
        d_download_file
        d_download_git
        d_download_hg
        d_download_src
        d_download_svn
        d_downloadable_src
        d_exit_diff_origin
        d_export
        d_got_download_prog_exit
    )

    [[ -v _BF_EXPORT_ALL ]] || i_exit 1 ${LINENO} "$(_g "Variable '_BF_EXPORT_ALL' MUST be set to: 'yes/no'.")"
    if [[ ${_BF_EXPORT_ALL} == "yes" ]]; then
        export -f "${_func_names[@]}"
    elif [[ ${_BF_EXPORT_ALL} == "no" ]]; then
        export -nf "${_func_names[@]}"
    else
        i_exit 1 ${LINENO} "$(_g "Variable '_BF_EXPORT_ALL' MUST be: 'yes/no'. Got: '%s'.")" "${_BF_EXPORT_ALL}"
    fi
}
d_export


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
