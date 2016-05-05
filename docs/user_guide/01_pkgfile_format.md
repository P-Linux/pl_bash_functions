# P-Linux Pkgfile Format

<p align="center">Some 'general' information about the 'Pkgfile Format'.</p>


---

!!! note

    Official Pkgfile variables start with a prefixed `pkg`


## Pkgfile-Header

A *Pkgfile* MUST have a *Pkgfile-Header* in the following format:

| Required | Variable Name | Description                                                                          | Type   |
|:--------:|:--------------|:-------------------------------------------------------------------------------------|:------:|
| YES      | `pkgpackager` | Name, pseudonym, e-mail address or web-link                                          | STRING |
| YES      | `pkgdesc`     | A short description of the package                                                   | STRING |
| YES      | `pkgurl`      | An URL that is associated with the software package or empty.                        | STRING |
| YES      | `pkgdeps`     | A list of dependencies needed to build or run the package or empty.                  | ARRAY  |
| NO       | `pkgdepsrun`  | A list of runtime dependencies or empty. If omitted it will be set to an empty array | ARRAY  |



Example Pkgfile-Header:

```bash
pkgpackager="peter1000 <https://github.com/peter1000>"
pkgdesc="Bash functions used by other P-Linux packages."
pkgurl="https://github.com/P-Linux/pl_bash_functions"
pkgdeps=(bash)
pkgdepsrun=(libarchive gzip bzip2 xz git subversion mercurial bzr)
```


## Pkgfile-Variables

Additionally to the *Pkgfile-Header*, following variables are REQUIRED:

| Required | Variable Name | Description                                                             | Type   |
|:--------:|:--------------|:------------------------------------------------------------------------|:------:|
| YES      | `pkgvers`     | The version of the package (typically the same as the upstream version. | STRING |
| YES      | `pkgrel`      | This is typically re-set to 1 for each new upstream release.            | STRING |
| YES      | `pkgsources`  | A list of source files required to build the package.                   | ARRAY  |
| YES      | `pkgmd5sum`   | A list of corresponding md5checksums (for file sources).                | ARRAY  |


Example Pkgfile-Variables:

```bash
pkgvers=0.1.0.r1.2f12e1a
pkgrel=1
pkgsources=($url/files/${CMK_NAME}-${pkgvers}.tar.xz)
pkgmd5sum=("SKIP")
```

Avoid introducing new variables, other names could be in conflict with internal variables.

!!! hint

    If other functions or variables are absolutely needed: prefix them with 2 underscores: e.g. `__pkgtag`


## Pkgfile Information

### pkgpackager

STRING - Name, pseudonym, e-mail address or web-link.


### pkgdesc

STRING - A short description of the package. It MUST have at least 10 and a maximum of 110 characters.


### pkgurl

STRING - An URL that is associated with the software package or empty.


### pkgdeps

INDEX ARRAY - A list of dependencies needed to build the package or empty. It can also contain other optional dependencies or
runtime dependencies: but see also `pkgdepsrun` for an optional separate runtime dependency array.

!!! note

    Dependencies which are listed in the `base collection` are not required to be included in the *pkgdeps* array.


### pkgdepsrun

INDEX ARRAY - A list of runtime dependencies, can also be empty or omitted.


### pkgvers

STRING - The version of the package (typically the same as the upstream source version). It MUST NOT be empty.
Valid characters for a pkgvers are alphanumeric and full stop.


### pkgrel

STRING - This is a release number specific to the P-Linux release. This is typically set to 1 for each new upstream software
release and incremented for intermediate *Pkgfile* updates or set to the actual date of the  *Pkgfile* update.

Valid characters for a pkgrel are digits and must be greater than 0 and less than 100000000.

Recommended date format: yyyymmdd: e.g. 20160329


### pkgsources

INDEX ARRAY - A list of sources required to build the package.
Local source files must reside in the same directory or a sub-directory of the Pkgfile location.
All other source entries must be fully-qualified URLs which can be used to download the sources.


### pkgmd5sums

INDEX ARRAY - A list of corresponding md5checksums used for source file validation.


## Pkgfile-Functions

There are a number of *Pkgfile functions* which are automatically executed by the build process.

| Required | Function Name                          | Description                                          |
|:--------:|:---------------------------------------|:-----------------------------------------------------|
| YES      | `build()`                              | The main function to build he package.               |
| NO       | `setpkgvers()`                         | Must return a package version: mostly useful for VCS |
| NO       | `CMK_GROUPS array defined functions`   | for more info see (CMK_GROUPS array functions)       |


Example Pkgfile-Functions:

```bash
build() {
    cd ${CMK_NAME}-${pkgvers}
    ./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info
    make
    make DESTDIR=${PKG} install
}
```


### CMK_GROUPS array functions

If the configuration variable `CMK_GROUPS` is set in the 'cmk.conf' file or in an individual Pkgfile, *cmk* will try to
split the produced package into additional groups defined in this array.
A default function is executed if a function with the same name is not found in the Pkgfile.
Supported default group functions are: lib() devel() doc() man() service()


## Pkgfile directory Name

The directory where the Pkgfile resides is used as the package name. It has a maximum length of 50 characters.

Valid characters for a Pkgfile directory are alphanumeric, and any of the following characters: hyphen-minus and underlines.
Additionally, the directory MUST start with an alphanumeric character.
