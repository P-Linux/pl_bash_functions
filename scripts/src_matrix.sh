#******************************************************************************************************************************
#
#   <source_entries.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
#                   PKGFILE SOURCE ARRAY MATRIX RELATED FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Prepares a MATRIX (kind of) for all Source-Entries
#
#   ENTRY FORMAT:
#
#       The source ENTRY is divided into four components:
#
#           1. `NOEXTRACT` (optional): If the entry starts with `NOEXTRACT` it will not be extracted `::` is used as separator
#           2. `PREFIX`     (optional): A user specified destination name for the downloaded source. Useful for renaming.
#                                       `::` is used as separator.
#           3. `URI`        (required): MAY ONLY contain 1 (+) to prefixing the URL with a VCS type,
#                                       MAY ONLY contain 1 (#) to postfix the URL with a VCS fragment.
#               * Online FILES: A fully-qualified URL (supported are: ftp://, http://, https://)
#               * Local FILES:  A local file path: file must reside in the same directory as the Pkgfile `_pkgfile`
#                               A local source file path MUST NOT contain any slash `/`.
#                               e.g. (mylocal.patch)
#               * VCS SOURCES:  A Version control source: URL to the VCS repository (supported are: git, svn, hg, bzr)
#                               This must include the VCS type. If the protocol does not include the VCS name, it can be
#                               added by prefixing the URL with vcs+. e.g. ( git+https://...., svn://....)
#           4. `FRAGMENT`   (optional): Allows specifying a revision number or branch, commit, tag to checkout from the
#                                       VCS. `#` is used as separator.
#               The available fragments depends on the VCS being used:
#
#                   * `bzr`: revision (see 'bzr help revisionspec' for details)
#                   * `git`: tag, branch, commit
#                   * `hg`:  tag, branch, revision
#                   * `svn`: revision
#
#   ARGUMENTS: for test purpose: `_pkgfile` and `_srcdst_dir` do not need to point to existing paths.
#
#       `_retmatrix`: a reference var: an associative array which will be updated with the resulting data fields
#       `_in_entries`: a reference var: an indexed array of valid source entries
#       `_in_checksums`: a reference var: an indexed array of corresponding source checksums
#       `_pkgfile`: absolute path to the pkgfile: for test purpose it is not required that the path exists
#       `_srcdst_dir`:       Optional: absolute path to keep all downloaded sources in a central location.
#                                If not set: downloaded sources will be stored in the directory of the specified pkgfile
#
#   Individual elements can be accessed by: [INDEX:FIELD_NAME]: example: "${_SCRMTX[2:PROTOCOL]}"
#
#       SPECIAL FIELDS:
#
#           * `NUM_IDX`: "${_SCRMTX[NUM_IDX]}": the number of indexes in the MATRIX
#
#       `INDEX`: starts with: 1 and incremets with each SRC-ENTRY
#
#       'MAIN FIELD_NAME':
#               EXAMPLE: "NOEXTRACT::helper_scripts::git+https://github.com/P-Linux/pl_bash_functions.git#commit=2f12e1a"
#
#           * `ENTRY`:          The original ENTRY in the _in_entries array.
#           * `CHKSUM`:         The coresponding checksum or SKIP
#           * `NOEXTRACT`:      "NOEXTRACT" or EMPTY ""
#                   "${_SCRMTX[1:NOEXTRACT]}" has Value: "NOEXTRACT"
#           * `PREFIX`:         "The extracted prefix" or EMPTY ""
#                   "${_SCRMTX[1:PREFIX]}" has Value: "helper_scripts"
#           * `URI`:            "The extracted/prepared URI" exclusive any trailing fragments or leading protocol
#                   "${_SCRMTX[1:URI]}" has Value: "https://github.com/P-Linux/pl_bash_functions.git"
#           * `FRAGMENT`:       "The extracted fragment" or EMPTY ""
#                   "${_SCRMTX[1:FRAGMENT]}" has Value: "commit=2f12e1a"
#
#           * `PROTOCOL`:       "The extracted PROTOCOL": one of: 'ftp' 'http' 'https' 'git' 'svn' 'hg' 'bzr' 'local'"
#                   "${_SCRMTX[1:PROTOCOL]}" has Value: "git"
#           * `DESTNAME`:       The final download destination name: Only the name not a path
#
#       'ADDITIONAL FIELD_NAME':
#
#           * `DESTPATH`:       The final download destination absolute path.
#
#   USAGE: on purpose a longer example which shows most common source options: prefixes, fragments
#
#           declare -A _SCRMTX
#
#           _SOURCES=(
#               "NOEXTRACT::http://download.savannah.gnu.org/releases/acl/acl-2.2.52.src.tar.gz"
#               "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz"
#               "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.4.0.tar.xz"
#               "ftp://ftp.astron.com/pub/file/file-5.25.tar.gz"
#               "NOEXTRACT::renamed_zlib.tar.xz::http://www.zlib.net/zlib-1.2.8.tar.xz"
#               "renamed_xz.tar.xz::http://tukaani.org/xz/xz-5.2.2.tar.xz"
#               "mylocal.patch"
#               "mylocal2.patch"
#
#               "helper_scripts::git+https://github.com/P-Linux/pl_bash_functions.git"
#               "git+https://github.com/shazow/urllib3.git#tag=1.14"
#               "git+https://github.com/mate-desktop/mozo.git#branch=gtk3"
#               "git://github.com/HaxeFoundation/haxelib.git#commit=2f12e1a"
#
#               "svn://svn.code.sf.net/p/netpbm/code/advanced"
#               "svn://svn.code.sf.net/p/splix/code/splix#revision=315"
#               "vpnc::svn+http://svn.unix-ag.uni-kl.de/vpnc/trunk#revision=550"
#               "portsmf::svn+https://svn.code.sf.net/p/portmedia/code/portsmf/trunk#revision=228"
#
#               "hg+http://linuxtv.org/hg/dvb-apps/#revision=d40083fff895"
#               "hg+http://bitbucket.org/pypy/pypy#tag=release-4.0.1"
#               "hg+http://hg.nginx.org/nginx#branch=stable-1.8"
#               "hg_hello_example::hg+https://bitbucket.org/bos/hg-tutorial-hello"
#
#               "contractor::bzr+lp:~elementary-os/contractor/elementary-contracts"
#               "bzr+http://bzr.linuxfoundation.org/openprinting/foomatic/foomatic-db/#revision=1295"
#               "bzr+http://bazaar.launchpad.net/~system-settings-touch/gsettings-qt/trunk/#revision=75"
#           )
#
#           # Missing checksums will be added as SKIP: too short or too long once will be replaced with skip
#           _CHECKSUMS=(
#               "a61415312426e9c2212bd7dc7929abda"
#               "50f97f4159805e374639a73e2636f22e"
#               "d762653ec3e1ab0d4a9689e169ca184f"
#               "e6a972d4e10d9e76407a432f4a63cd4c"
#               "28f1205d8dd2001f26fec1e8c2cebe37"
#               "xz_28f1205d8dd20_too_short"
#               "mylocal.patch_2d4e10d9e76407a432f8_too_long"
#               "SKIP"
#           )
#
#           _PKGFILE_FULLPATH="/var/cards_mk/ports/only_download/Pkgfile"
#           _SRCDEST_DIR="/home/dummy_sources"
#
#           s_get_src_matrix _SCRMTX _SOURCES _CHECKSUMS "${_PKGFILE_FULLPATH}" "${_SRCDEST_DIR}"
#
#           for (( _n=1; _n <= ${_SCRMTX[NUM_IDX]}; _n++ )); do
#               echo
#               echo ">>>>ENTRY: ${_n}"
#               echo "ENTRY: <${_SCRMTX[${_n}:ENTRY]}>"
#               echo "CHKSUM: <${_SCRMTX[${_n}:CHKSUM]}>"
#               echo "NOEXTRACT: <${_SCRMTX[${_n}:NOEXTRACT]}>"
#               echo "PREFIX: <${_SCRMTX[${_n}:PREFIX]}>"
#               echo "URI: <${_SCRMTX[${_n}:URI]}>"
#               echo "FRAGMENT: <${_SCRMTX[${_n}:FRAGMENT]}>"
#               echo "PROTOCOL: <${_SCRMTX[${_n}:PROTOCOL]}>"
#               echo "DESTNAME: <${_SCRMTX[${_n}:DESTNAME]}>"
#               echo "DESTPATH: <${_SCRMTX[${_n}:DESTPATH]}>"
#           done
#
#   HINT: if needed one can run multiple pkgfiles (source arrays etc..) on the same '_retmatrix' array which will add
#           them into one so that the final SRC-MATRIX will contain all entries.
#
#       s_get_src_matrix _SCRMTX _SOURCES_1 _CHECKSUMS_1 "${_PKGFILE_FULLPATH}_1"
#       s_get_src_matrix _SCRMTX _SOURCES_2 _CHECKSUMS_2 "${_PKGFILE_FULLPATH}_2" "${_SRCDEST_DIR}_2"
#       s_get_src_matrix _SCRMTX _SOURCES_3 _CHECKSUMS_3 "${_PKGFILE_FULLPATH}_3" "${_SRCDEST_DIR}_3"
#******************************************************************************************************************************
s_get_src_matrix() {
    i_min_args_exit ${LINENO} 4 ${#}
    local -n _retmatrix=${1}
    local -n _in_entries=${2}
    local -n _in_checksums=${3}
    local _pkgfile=${4}
    # use an associative array which is faster for lookups
    declare -A _supported_protocols=(["ftp"]=0 ["http"]=0 ["https"]=0 ["git"]=0 ["svn"]=0 ["hg"]=0 ["bzr"]=0 ["local"]=0)
    declare -A _supported_vclplus_schemes=(["http"]=0 ["https"]=0 ["lp"]=0)
    if (( ${#} > 4 )); then
        i_exit_empty_arg ${LINENO} "${5}" 5
        local _srcdst_dir=${5}
    else
        local _srcdst_dir; u_dirname _srcdst_dir "${_pkgfile}"
    fi
    declare -i _in_entries_size=${#_in_entries[@]}
    declare -i _in_checksums_size=${#_in_checksums[@]}
    local _ent _chksum _noextract _prefix _uri _fragment _protocol _destname _destpath
    local _total_prefix _num_prefix_sep _vclplus_schemes _tmp_uri
    declare -i _next_idx _n _diff

    u_ref_associative_array_exit "_retmatrix"

    # Validate _in_checksums array
    if (( ${_in_checksums_size} < ${_in_entries_size} )); then
        i_more_i "$(_g "SRC_CHECKSUMS array size: '%s' is less than SRC_ENTRIES Array size: '%s'")" "${_in_checksums_size}" \
            "${_in_entries_size}"
        i_more_i "$(_g "Added temporarily checksum entries SKIP.")"
        _diff=${_in_entries_size}-${_in_checksums_size}
        for (( _n=0; _n < ${_diff}; _n++ )); do

            _in_checksums+=("SKIP")
        done
        _in_checksums_size=${#_in_checksums[@]}
    elif (( ${_in_checksums_size} > ${_in_entries_size} )); then
        i_more_i "$(_g "SRC_CHECKSUMS array size: '%s' is greater than SRC_ENTRIES Array size: '%s'")" \
            "${_in_checksums_size}" "${_in_entries_size}"
    fi

    for (( _n=0; _n < ${_in_entries_size}; _n++ )); do
        _chksum=${_in_checksums[${_n}]}
        if [[ ! -n ${_chksum} ]]; then
            _in_checksums[${_n}]="SKIP"
        elif [[ (( ${#_chksum} != 32 )) && ${_chksum} != "SKIP" ]]; then
            i_more "$(_g "CHECKSUM [%s]: '%s' MUST be 'SKIP' or 32 chars. Got: '%s'. Pkgfile: <%s>")" $((_n + 1)) \
                "${_chksum}" ${#_chksum} "${_pkgfile}"
            _in_checksums[${_n}]="SKIP"
            i_more_i "$(_g "Replaced the checksum temporarily with SKIP.")"
        fi
    done
    if [[ -v _retmatrix[NUM_IDX] ]]; then
       _next_idx=${_retmatrix[NUM_IDX]}
    else
       _next_idx=0
    fi

    # need to start from 0: '_n=0'
    for (( _n=0; _n < ${_in_entries_size}; _n++ )); do
        _next_idx+=1

        _ent=${_in_entries[${_n}]}
        if (( $(u_count_substr ":::" "${_ent}") != 0 )); then
            i_exit 1 ${LINENO} "$(_g "Entry MUST NOT contain any triple colons (:::): <%s>")" "${_ent}"
        fi

        _num_prefix_sep=$(u_count_substr "::" "${_ent}")
        if (( ${_num_prefix_sep} > 2 )); then
            i_exit 1 ${LINENO} "$(_g "Entry MUST NOT contain more than 2 prefix_sep (::). Got:'%s': <%s>")" ${_num_prefix_sep} \
                "${_ent}"
        fi

        if (( $(u_count_substr "+" "${_ent}") > 1 )); then
            i_exit 1 ${LINENO} "$(_g "Entry MUST NOT contain more than 1 plus (+): <%s>")" "${_ent}"
        fi
        if (( $(u_count_substr "#" "${_ent}") > 1 )); then
            i_exit 1 ${LINENO} "$(_g "Entry MUST NOT contain more than 1 number sign (#): <%s>")" "${_ent}"
        fi

        u_postfix_shortest_empty _fragment "${_ent}" "#"

        ### DO URI
        u_prefix_shortest_all _tmp_uri "${_ent}" "#"
        if (( ${_num_prefix_sep} > 0 )); then
            u_postfix_shortest_empty _tmp_uri "${_tmp_uri}" "::"
        fi
        u_postfix_longest_all _uri "${_tmp_uri}" "+"
        if [[ ${_tmp_uri} == *"+"* ]]; then
            u_prefix_shortest_all _vclplus_schemes "${_uri}" ":"
            if [[ ! -v _supported_vclplus_schemes[${_vclplus_schemes}] ]]; then
                i_exit 1 ${LINENO} "$(_g "Supported vclplus_schemes: 'http' 'https' 'lp'. Got '%s': <%s>")" \
                    "${_vclplus_schemes}" "${_ent}"
            fi
        fi

        ### DO PROTOCOL
        u_prefix_shortest_all _protocol "${_tmp_uri}" "://"
        u_prefix_shortest_all _protocol "${_protocol}" "+"
        if [[ ${_protocol} == ${_tmp_uri} ]]; then
            _protocol="local"
        fi

        [[ -v _supported_protocols[${_protocol}] ]] || i_exit 1 ${LINENO} "$(_g "The protocol: '%s' is not supported: <%s>")" \
                                                        "${_protocol}" "${_ent}"
        ### DO NOEXTRACT/PREFIX
        _noextract=""
        _prefix=""
        if (( ${_num_prefix_sep} > 0 )); then
            u_prefix_longest_empty _total_prefix "${_ent}" "::"
            if [[ ${_total_prefix} == "NOEXTRACT" ]]; then
                _noextract="NOEXTRACT"
            else
                u_prefix_shortest_empty _noextract "${_total_prefix}" "::"
                u_postfix_shortest_all _prefix "${_total_prefix}" "::"
            fi
        fi

        # ASSIGN MAIN
        _retmatrix["${_next_idx}:ENTRY"]=${_ent}
        _retmatrix["${_next_idx}:CHKSUM"]=${_in_checksums[${_n}]}
        _retmatrix["${_next_idx}:NOEXTRACT"]=${_noextract}
        _retmatrix["${_next_idx}:PREFIX"]=${_prefix}
        _retmatrix["${_next_idx}:URI"]=${_uri}
        _retmatrix["${_next_idx}:FRAGMENT"]=${_fragment}
        _retmatrix["${_next_idx}:PROTOCOL"]=${_protocol}

        # Some Validations
        if ! [[ -z ${_noextract} || ${_noextract} == "NOEXTRACT" ]]; then
            i_exit 1 ${LINENO} "$(_g "'NOEXTRACT' MUST be empty or: NOEXTRACT. Got: '%s': <%s>")" "${_noextract}" "${_ent}"
        fi
        case "${_protocol}" in
            local)
                if [[ ${_ent} == *"/"* ]]; then
                    i_exit 1 ${LINENO} "$(_g "Local source MUST NOT contain any slash: <%s>")" "${_ent}"
                fi
                if [[ -n ${_noextract} ]]; then
                    i_exit 1 ${LINENO} "$(_g "Local source MUST NOT have a 'NOEXTRACT': <%s>")" "${_ent}"
                fi
                if [[ -n ${_prefix} ]]; then
                    i_exit 1 ${LINENO} "$(_g "Local source MUST NOT have a prefix: '%s': <%s>")" "${_prefix}" "${_ent}"
                fi
                if [[ -n ${_fragment} ]]; then
                    i_exit 1 ${LINENO} "$(_g "Local source MUST NOT have a fragment: '%s': <%s>")" "${_fragment}" "${_ent}"
                fi
                ;;
            ftp|http|https)
                if [[ -n ${_fragment} ]]; then
                    i_exit 1 ${LINENO} "$(_g "ftp|http|https source MUST NOT have a fragment: '%s': <%s>")" "${_fragment}" \
                        "${_ent}"
                    fi
                ;;
            git|svn|hg|bzr)
                if [[ -n ${_noextract} ]]; then
                    i_exit 1 ${LINENO} "$(_g "'git|svn|hg|bzr source MUST NOT have a NOEXTRACT: <%s>")" "${_ent}"
                fi
                if [[ ${_retmatrix[${_next_idx}:CHKSUM]} != "SKIP" ]]; then
                    i_exit 1 ${LINENO} "$(_g "'git|svn|hg|bzr source MUST NOT have a checksum: '%s': <%s>")" \
                        "${_retmatrix[${_next_idx}:CHKSUM]}" "${_ent}"
                fi
                ;;
        esac

        ### DO DESTNAME
        if [[ -n ${_prefix} ]]; then
            _destname=${_prefix}
        else
            case "${_protocol}" in
                ftp|http|https) u_basename _destname "${_ent}" ;;
                local)          _destname=${_ent} ;;                     # use the whole entry to allow for subfolders
                git|svn|hg|bzr)
                    u_prefix_longest_all _destname "${_ent}" "#"    # strip any fragment
                    u_strip_end_slahes _destname "${_destname}"
                    u_basename _destname "${_destname}"
                    if [[ ${_protocol} == "bzr" ]]; then
                        u_postfix_longest_all _destname "${_destname}" "lp:"
                    fi
                    if [[ ${_protocol} == "git" ]]; then
                        u_prefix_shortest_all _destname "${_destname}" ".git"
                    fi
                    ;;
            esac
        fi
        _retmatrix["${_next_idx}:DESTNAME"]=${_destname}

        ### DO DESTPATH
        case "${_protocol}" in
            ftp|http|https|git|svn|hg|bzr)
                u_strip_end_slahes _destpath "${_srcdst_dir}"
                _destpath="${_destpath}/${_destname}"
                ;;
            local)
                u_dirname _destpath "${_pkgfile}}"
                _destpath="${_destpath}/${_destname}"
                ;;
        esac
        _retmatrix["${_next_idx}:DESTPATH"]=${_destpath}
    done

    # Save the _next_idx
    _retmatrix[NUM_IDX]=${_next_idx}
}


#******************************************************************************************************************************
# TODO: UPDATE THIS if there are functions/variables added or removed.
#
# EXPORT:
#   helpful command to get function names: `declare -F` or `compgen -A function`
#******************************************************************************************************************************
s_export() {
    local _func_names _var_names

    _func_names=(
        s_export
        s_get_src_matrix
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
s_export


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
