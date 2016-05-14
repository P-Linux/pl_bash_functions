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

t_general_opt



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
    (( ${#} != 4 )) && m_exit "d_exit_diff_origin" "$(_g "FUNCTION Requires EXACT '5' arguments. Got '%s'")" "${#}"
    local _uri=${1}
    local _origin_uri=${2}
    local _dest=${3}
    local _entry=${4}
    local _m1=$(_g "Local repo folder: <%s> is not a clone of: <%s>")
    local _m2=$(_g "    Local folder origin_uri: <%s>")
    local _m3=$(_g "    ENTRY: <%s>")

    if [[ ${_uri} != ${_origin_uri} ]]; then
        printf "${_M_RED}    ->${_M_OFF}${_M_BOLD} ${_m1}${_M_OFF}\n" "${_dest}" "${_uri}" >&2
        printf "      ${_M_OFF}${_M_BOLD} ${_m2}${_M_OFF}\n\n" "${_origin_uri}" >&2
        printf "      ${_M_OFF}${_M_BOLD} ${_m3}${_M_OFF}\n\n" "${_entry}" >&2
        exit 1
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
        *)  m_exit "d_got_download_prog_exit" "$(_g "Unsupported _download_prog: '%s'")" "${_prog}" ;;
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
# Download downloadable sources by protocol filter.
#
#   ARGUMENTS
#       `_in_do_scrmtx`: reference var: Source Matrix: see function 's_get_src_matrix()' in file: <src_matrix.sh>
#
#   OPTIONAL ARGS:
#       `_verify`: yes/no if "yes" and a CHKSUM is specified for an entry the file will be checked: Default: "no"
#       `_in_dl_mirrors`: reference var: Array of mirror sites which will be checked first to download ftp|http|https sources
#       `_in_filter_protocols`: a reference var: An associative array with `PROTOCOL` names as keys.
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
    local _dl_prog=${5:-"wget"}
    local _dl_prog_opts=${6:-""}
    declare -i _n
    local _in_filter_protocols_keys_str _proto

    if [[ -v _in_filter_protocols["local"] ]]; then
        _in_filter_protocols_keys_str=${!_in_filter_protocols[@]}
        m_exit "d_downloadable_src" "$(_g "Protocol 'local' MUST NOT be in the '_in_filter_protocol array keys': <%s>")" \
            "${_in_filter_protocols_keys_str}"
    fi

    if [[ ! -v _in_do_scrmtx[NUM_IDX] ]]; then
        m_exit "d_downloadable_src" "\
            $(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_do_scrmtx[NUM_IDX]}; _n++ )); do
        _proto=${_in_do_scrmtx[${_n}:PROTOCOL]}
        if [[ -v _in_filter_protocols[${_proto}] ]]; then
            case "${_proto}" in
                ftp|http|https) d_download_file ${_n} _in_do_scrmtx "${_verify}" _in_dl_mirrors "${_dl_prog}" \
                                "${_dl_prog_opts}" ;;
                git) d_download_git ${_n} _in_do_scrmtx ;;
                svn) d_download_svn ${_n} _in_do_scrmtx ;;
                hg)  d_download_hg ${_n} _in_do_scrmtx  ;;
                bzr) d_download_bzr ${_n} _in_do_scrmtx ;;
                *) _in_filter_protocols_keys_str=${!_in_filter_protocols[@]}
                    m_exit "d_downloadable_src" \
                        "$(_g "The protocol: '%s' is not in the '_in_filter_protocol array keys': <%s>")" "${_proto}" \
                        "${_in_filter_protocols_keys_str}"
            esac
        fi
    done
}


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
    local -n _in_do_scrmtx=${1}
    local _verify=${2:-"no"}
    if [[ -n $3 ]]; then
        local -n _in_dl_mirrors=${3}
    else
        local _in_dl_mirrors=()
    fi
    local _dl_prog=${4:-"wget"}
    local _dl_prog_opts=${5:-""}
    declare -i _n
    local _destpath _file_checksum

    if [[ ! -v _in_do_scrmtx[NUM_IDX] ]]; then
        m_exit "d_download_src" "$(_g "Could not get the 'NUM_IDX' from the matrix - did you run 's_get_src_matrix()'")"
    fi

    for (( _n=1; _n <= ${_in_do_scrmtx[NUM_IDX]}; _n++ )); do
        _destpath=${_in_do_scrmtx[${_n}:DESTPATH]}

        case "${_in_do_scrmtx[${_n}:PROTOCOL]}" in
            ftp|http|https) d_download_file ${_n} _in_do_scrmtx "${_verify}" _in_dl_mirrors "${_dl_prog}" "${_dl_prog_opts}" ;;
            local)
                if [[ -f ${_destpath} ]]; then
                    m_bold "$(_g "Found local source file: <%s>")" "${_destpath}"
                    [[ ${_verify} != "yes" || ${_in_do_scrmtx[${_idx}:CHKSUM]} == "SKIP" ]] && return 0
                    u_get_file_md5sum _file_checksum "${_destpath}"
                    [[ ${_file_checksum} == ${_in_do_scrmtx[${_n}:CHKSUM]} ]] && return 0
                    m_exit "d_download_src" "$(_g "Failed verifying checksum: local source file: <%s>")" "${_destpath}"
                else
                    m_exit "d_download_src" "$(_g "Could not find local source file: <%s>")" "${_destpath}"
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

        [[ ${_verify} != "yes" || ${_chksum} == "SKIP" ]] && return 0

        u_get_file_md5sum __file_chksum "${_destpath}"
        [[ ${__file_chksum} == ${_chksum} ]] && return 0
        m_warn2 "$(_g "Failed verifying checksum for existing ftp|http|https source file: <%s>")" "${_destpath}"
        m_more_i "$(_g "ORIG-CHECKSUM: '%s' Downloaded FILE-CHECKSUM: : <%s>")" "${_chksum}" "${__file_chksum}"

        m_bold_i "$(_g "Removing the file.")"
        rm -f -- "${_destpath}"
        return 1
    }

    [[ -n ${1} ]] ||  m_exit "d_download_file" "$(_g "FUNCTION Argument '1' MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_f=${2}
    local _verify=${3:-"no"}
    if [[ -n $4 ]]; then
        local -n _in_dl_mirrors_f=${4}
    else
        local _in_dl_mirrors_f=()
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

    if [[ -f ${_destpath} ]]; then
        m_bold "$(_g "Found ftp|http|https source file: <%s>")" "${_destpath}"
        _verify_checksum; (( ${?} )) || return 0
    fi

    case "${_proto}" in
        ftp|http|https) ;;
        *)  m_exit "d_download_file" "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}" ;;
    esac

    m_msg "$(_g "Downloading file URI: <%s>")" "${_uri}"
    m_msg_i "$(_g "destpath: <%s>")" "${_destpath}"

    case "${_dl_prog}" in
        curl)
            _resume_opts="-C -"
            if [[ -z ${_dl_prog_opts} ]]; then
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
            if [[ -z ${_dl_prog_opts} ]]; then
                case "${_proto}" in
                    https) _download_opts+=" --no-check-certificate" ;;
                esac
                _download_opts+=" --timeout=6 --tries=1 --no-directories"
            fi
            _download_opts+=" ${_dl_prog_opts} -O ${_dl_tmp_path}"
            ;;
        *)  m_exit "d_download_file" "$(_g "Unsupported _download_prog: '%s'")" "${_dl_prog}" ;;
    esac

    u_got_internet || m_exit "d_download_file" "$(_g "Seems that there is no internet connection")"

    if [[ -n ${_in_dl_mirrors_f} ]]; then
        for _mirror in "${_in_dl_mirrors_f[@]}"; do
            u_strip_end_slahes _mirror "${_mirror}"
            m_more_i "$(_g "Downloading WITH RESUME option - MIRROR URI: <%s>")" "${_mirror}/${_uri_name}"
            u_repeat_failed_command 2 2 _download_move "${_mirror}/${_uri_name}" "${_resume_opts}"
            if (( ! ${?} )); then
                _verify_checksum; (( ${?} )) || return 0
            fi

            m_more_i "$(_g "Retrying WITHOUT RESUME option - MIRROR URI: <%s>")" "${_mirror}/${_uri_name}"
            u_repeat_failed_command 2 2 _download_move "${_mirror}/${_uri_name}"
            if (( ! ${?} )); then
                _verify_checksum; (( ${?} )) || return 0
            fi
        done
    fi

    m_more_i "$(_g "Downloading WITH RESUME option - ORIGINAL URI: <%s>")" "${_uri}"
    u_repeat_failed_command 2 3 _download_move "${_uri}" "${_resume_opts}"
    if (( ! ${?} )); then
        _verify_checksum; (( ${?} )) || return 0
    fi

    m_bold "$(_g "Retrying WITHOUT RESUME option - ORIGINAL URI: <%s>")" "${_uri}"
    rm -f -- "${_dl_tmp_path}"
    u_repeat_failed_command 2 3 _download_move "${_uri}"
    if (( ! ${?} )); then
        _verify_checksum; (( ${?} )) || return 0
    fi
    m_exit "d_download_file" "$(_g "Failure while downloading file. ENTRY: <%s>")" "${_ent}"
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
    [[ -n $1 ]] || m_exit "d_download_git" "$(_g "FUNCTION Argument '1' MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_g=${2}
    local _uri=${_in_do_scrmtx_g[${1}:URI]}
    local _destpath=${_in_do_scrmtx_g[${1}:DESTPATH]}
    local _destname=${_in_do_scrmtx_g[${1}:DESTNAME]}
    local _proto=${_in_do_scrmtx_g[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_g[${1}:ENTRY]}
    local _origin_uri=""

    [[ ${_proto} != "git" ]] && m_exit "d_download_git" "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    m_msg "$(_g "Downloading git URI: <%s>")" "${_uri}"

    u_is_git_uri_accessible "${_uri}" || m_exit "d_download_git" "$(_g "Failed to access the git URI: <%s>")" "${_uri}"

    if u_dir_has_content_exit "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        _origin_uri=$(git config --get remote.origin.url)
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        m_msg_i "$(_g "Fetching (updating) git repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        git fetch --all --prune || m_warn "$(_g "Failed to update: '%s'")" "${_destname}"
    else
        m_msg_i "$(_g "Cloning git repo into destpath: <%s>")" "${_destpath}"
        git clone --mirror "${_uri}" "${_destpath}" || m_exit "d_download_git" "$(_g "Failed to clone git URI: <%s>")" \
                                                        "${_uri}"
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
    [[ -n $1 ]] || m_exit "d_download_svn" "$(_g "FUNCTION Argument '1' MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_s=${2}
    local _uri=${_in_do_scrmtx_s[${1}:URI]}
    local _frag=${_in_do_scrmtx_s[${1}:FRAGMENT]}
    local _proto=${_in_do_scrmtx_s[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_s[${1}:ENTRY]}
    local _ref="HEAD"
    local _origin_uri=""
    local _var

    [[ ${_proto} != "svn" ]] && m_exit "d_download_svn" "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    m_msg "$(_g "Downloading svn URI: <%s>")" "${_uri}"

    if [[ -n ${_frag} ]]; then
        u_prefix_shortest_all _var "${_frag}" "="
        case "${_var}" in
            revision) u_postfix_shortest_all _ref "${_frag}" "=" ;;
            *) m_exit "d_download_svn" "$(_g "Unrecognized fragment: '%s'. ENTRY: '%s'")" "${_frag}" "${_ent}" ;;
        esac
    fi

    u_is_svn_uri_accessible "${_uri}" || m_exit "d_download_svn" "$(_g "Failed to access the svn URI: <%s>")" "${_uri}"
    if u_dir_has_content_exit "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        u_postfix_shortest_all _origin_uri "$(svn info | grep ^URL)" " "
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        m_msg_i "$(_g "Updating svn repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        svn update --revision ${_ref} || m_warn "$(_g "Failed to update: '%s'")" "${_in_do_scrmtx_s[${1}:DESTNAME]}"
    else
        m_msg_i "$(_g "Checking-out svn repo into destpath: <%s>")" "${_destpath}"
        mkdir -p "${_destpath}/.svn_conf"
        if ! svn checkout --revision ${_ref} --config-dir "${_destpath}/.svn_conf" "${_uri}" "${_destpath}"; then
            m_exit "d_download_svn" "$(_g "Failed to checkout svn URI: <%s>")" "${_uri}"
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
    [[ -n $1 ]] || m_exit "d_download_hg" "$(_g "FUNCTION Argument '1' MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_h=${2}
    local _uri=${_in_do_scrmtx_h[${1}:URI]}
    local _destpath=${_in_do_scrmtx_h[${1}:DESTPATH]}
    local _proto=${_in_do_scrmtx_h[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_h[${1}:ENTRY]}
    local _origin_uri=""

    [[ ${_proto} != "hg" ]] && m_exit "d_download_hg" "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    m_msg "$(_g "Downloading hg URI: <%s>")" "${_uri}"

    u_is_hg_uri_accessible "${_uri}" || m_exit "d_download_hg" "$(_g "Failed to access the hg URI: <%s>")" "${_uri}"

    if u_dir_has_content_exit "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        _origin_uri=$(hg paths default)
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        m_msg_i "$(_g "Pulling (updating) hg repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        hg pull || m_warn "$(_g "Failed to update: '%s'")" "${_in_do_scrmtx_h[${1}:DESTNAME]}"
    else
        m_msg_i "$(_g "Cloning hg repo into destpath: <%s>")" "${_destpath}"
        hg clone -U "${_uri}" "${_destpath}" || m_exit "d_download_hg" "$(_g "Failed to clone hg URI: <%s>")" "${_uri}"
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
    [[ -n $1 ]] || m_exit "d_download_bzr" "$(_g "FUNCTION Argument '1' MUST NOT be empty")"
    # skip assignment: declare -i _idx=${1}
    local -n _in_do_scrmtx_b=${2}
    local _uri=${_in_do_scrmtx_b[${1}:URI]}
    local _destpath=${_in_do_scrmtx_b[${1}:DESTPATH]}
    local _proto=${_in_do_scrmtx_b[${1}:PROTOCOL]}
    local _ent=${_in_do_scrmtx_b[${1}:ENTRY]}
    local _origin_uri=""

    [[ ${_proto} != "bzr" ]] && m_exit "d_download_bzr" "$(_g "Unsupported protocol: '%s'. ENTRY: '%s'")" "${_proto}" "${_ent}"

    m_msg "$(_g "Downloading bzr URI: <%s>")" "${_uri}"

    u_got_internet || m_exit "d_download_bzr" "$(_g "Seems that there is no internet connection")"

    if u_dir_has_content_exit "${_destpath}"; then
        u_cd_safe_exit "${_destpath}"
        u_postfix_shortest_all _origin_uri "$(bzr info | grep "parent branch")" " "
        d_exit_diff_origin "${_uri}" "${_origin_uri}" "${_destpath}" "${_ent}"

        m_msg_i "$(_g "Pulling (updating) bzr repo at destpath: <%s>")" "${_destpath}"
        # only warn on failure to allow offline builds
        bzr pull "${_uri}" -Ossl.cert_reqs=none ||  m_warn "$(_g "Failed to update: '%s'")" "${_in_do_scrmtx_b[${1}:DESTNAME]}"
    else
        m_msg_i "$(_g "Branching bzr repo into destpath: <%s>")" "${_destpath}"
        if ! bzr branch "${_uri}" "${_destpath}" --no-tree --use-existing-dir -Ossl.cert_reqs=none; then
            m_exit "d_download_bzr" "$(_g "Failed to clone bzr URI: <%s>")" "${_uri}"
        fi
    fi
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
