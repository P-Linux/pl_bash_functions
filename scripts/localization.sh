#******************************************************************************************************************************
#
#   <localization.sh> **peter1000** see license at: [pl_bash_functions](https://github.com/P-Linux/pl_bash_functions)
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
#                   GETTEXT LOCALIZATION RELATED FUNCTIONS
#
#=============================================================================================================================#

#******************************************************************************************************************************
# Generate a corresponding `pot` file from '_in_srcfile', it will be written to the `_outdir`
#
#   ARGUMENTS:
#       `_in_srcfile`: path to a bash source file
#       `_outdir`: path to the output directory for `po` files
#       `_pkgname`: Package name
#       `_copyright`: Copyright holder
#       `_copyright_start`: The year when the copyright started
#
#   ARGUMENTS Optional:
#       `_url`: e.g. documentation url or source code url
#       `_bugs_url`: Optional: url e.g. "https://github.com/P-Linux/pl_bash_functions/issues"
#******************************************************************************************************************************
l_generate_pot_file() {
    (( ${#} < 5 )) && m_exit "l_generate_pot_file" "$(_g "FUNCTION Requires AT LEAST '5' arguments. Got '%s'")" "${#}"
    local _in_srcfile=$(readlink -f "${1}")
    local _outdir=$(readlink -f "${2}")
    local _pkgname=${3}
    local _copyright=${4}
    local _copyright_start=${5}
    local _url=${6:-""}
    local _bugs_url=${7:-""}
    local _src_name; u_basename _src_name "${_in_srcfile}"
    local _src_dir; u_dirname _src_dir "${_in_srcfile}"
    local _pot_file="${_outdir}/${_src_name}.pot"
    local _current_year="$(date +%Y)"
    if [[ -n ${_url} ]]; then
        local _first_author_txt="${_copyright} <${_url}>. ${_current_year}."
    else
        local _first_author_txt="${_copyright}. ${_current_year}."
    fi
    declare -i _ret

    m_msg "$(_g "Generating original 'pot' file. Output-Dir: <%s>")" "${_outdir}"
    m_more_i "$(_g "Processing source-file: <%s>")" "${_in_srcfile}"

    mkdir -p "${_outdir}"
    # remove any existing pot file
    rm -f "${_pot_file}"

    pushd "${_src_dir}" &> /dev/null
    if [[ -n ${_bugs_url} ]]; then
        xgettext --output "${_pot_file}" --language=Shell --package-name="${_pkgname}" --copyright-holder="${_copyright}" \
            --msgid-bugs-address="${_bugs_url}" --from-code=UTF-8 --force-po --no-wrap "${_src_name}"
    else
        xgettext --output "${_pot_file}" --language=Shell --package-name="${_pkgname}" --copyright-holder="${_copyright}" \
            --from-code=UTF-8 --force-po --no-wrap "${_src_name}"
    fi
    _ret=${?}
    (( ${_ret} )) &&  m_exit "l_generate_pot_file" "$(_g "Could not generate .pot' file. xgettext Error: '%s'")" "${_ret}"

    # update the pot header
    sed -i.bak "
            s|^\# SOME DESCRIPTIVE TITLE.|\# Package: <${_pkgname}> autogenerated from source-file: <${_src_name}>|;
            s|^\# Copyright (C) YEAR|\# Copyright (C) ${_copyright_start} - ${_current_year}|;
            s|^\# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.|\# ${_first_author_txt}|;
            s|LL@li.org|${_url}|;
            s|charset=CHARSET|charset=UTF-8|;
    " "${_pot_file}"

    rm -f "${_pot_file}.bak"
    popd &> /dev/null
}


#******************************************************************************************************************************
# Generate all .pot files and corresponding 'po' files for all defind locale.
#
#   ARGUMENTS:
#       `_in_srcfiles`: a reference var: an indexed array of source files
#       `_in_utf8_languages`: a reference var: an indexed array of UTF-8 locale
#       `_outdir`: path to the output directory for `po` files
#       `_pkgname`: Package name
#       `_copyright`: Copyright holder
#       `_copyright_start`: The year when the copyright started
#
#   ARGUMENTS Optional:
#       `_url`: e.g. documentation url or source code url
#       `_bugs_url`: Optional: url e.g. "https://github.com/P-Linux/pl_bash_functions/issues"
#******************************************************************************************************************************
l_generate_po_files() {
    local _fn="l_generate_pot_file"
    (( ${#} < 6 )) && m_exit "${_fn}" "$(_g "FUNCTION Requires AT LEAST '6' arguments. Got '%s'")" "${#}"
    local -n _in_srcfiles=${1}
    local -n _in_utf8_languages=${2}
    local _outdir=$(readlink -f "${3}")
    local _pkgname=${4}
    local _copyright=${5}
    local _copyright_start=${6}
    local _url=${7:-""}
    local _bugs_url=${8:-""}
    local  _f _src_name _pot_file _locale _only_locale
    declare -i _ret

    m_msg "$(_g "Generating 'pot' file and corresponding 'po' files. Output-Dir: <%s>")" "${_outdir}"

    for _f in "${_in_srcfiles[@]}"; do
        u_basename _src_name "${_f}"
        _pot_file="${_outdir}/${_src_name}.pot"
        l_generate_pot_file "${_f}" "${_outdir}" "${_pkgname}" "${_copyright}" "${_copyright_start}" "${_url}" \
            "${_bugs_url}"

        for _locale in "${_in_utf8_languages[@]}"; do
            [[ ${_locale} == *".UTF-8" ]] || m_exit "${_fn}" "$(_g "Only UTF-8 locale are supported: '%s'")" \
                "${_locale}"

            _locale_po_dir="${_outdir}/${_locale}/LC_MESSAGES"
            mkdir -p "${_locale_po_dir}"

            m_msg_i "$(_g "Proccessing locale '%s'")" "${_locale}"

            _empty_po_path="${_locale_po_dir}/${_src_name}_empty.po"
            _final_po_path="${_locale_po_dir}/${_src_name}.po"

            if [[ -f ${_final_po_path} ]]; then
                msgmerge --update --backup=simple --no-wrap  "${_final_po_path}" "${_pot_file}"
                _ret=${?}
                (( ${_ret} )) &&  m_exit "${_fn}" "$(_g "Could not update .po' file. 'msgmerge' Error: '%s'")" "${_ret}"
            else
                rm -f "${_empty_po_path}"
                msginit  --no-wrap --no-translator --locale="${_locale}" --input="${_pot_file}"  \
                    --output-file="${_empty_po_path}"
                _ret=${?}
                (( ${_ret} )) && m_exit "${_fn}" "$(_g "Could not generate .po' file. 'msginit' Error: '%s'")" "${_ret}"

                # update the po header: use the whole defined local: e.g. de_DE
                u_prefix_longest_all _only_locale "${_locale}" ".UTF-8"
                sed -i.bak "
                        s|^\"Last-Translator: Automatically generated|\"Last-Translator: ${_copyright} <${_url}>|;
                        s|^\"Language-Team: none|\"Language-Team: LANGUAGE <${_url}>|;
                        s|^\"Language:.*|\"Language: ${_only_locale}\\\n\"|;
                " "${_empty_po_path}"
                rm -f "${_empty_po_path}.bak"
            fi
        done
    done
}


#******************************************************************************************************************************
# End of file
#******************************************************************************************************************************
