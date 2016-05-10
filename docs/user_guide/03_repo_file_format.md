# P-Linux Repo-File Format

<p align="center">Some 'general' information about the 'Repo-File Format'.</p>


---


A *Repo-File* is a plain text file with selected information.


## Port-Repo-File

A *Port-Repo-File* has this structure:

**EXAMPLE WITH COMPRESSION**

```text
1462707691#.cards.tar.xz#2.2.52#1#Some Info#http://savannah.nongnu.org/projects/acl#peter1000
ff097cb276710374b3ef4ef551dc29ab#acl#x86_64
9140e3d8065533d61fa077e731602172#acl.fr#any
0029f3a21d21534b2031a539f0e04065#acl.man#any
239870fb9cd383e270e0b08ac773db1a#acl.sv#any
866cff7556c9dc9ea81224459d8c00db#acl.README
80eba83e7de06d46752f4158979ea3c2#dummy.patch
d03ad0a50693b85015f2d420e2ed7d6a#otherfile.txt
66b57281f54815208b199afabddfd05e#Pkgfile

```

**EXAMPLE WITHOUT COMPRESSION**

```text
1462707691#.cards.tar#2.2.52#1#Some Info#http://savannah.nongnu.org/projects/acl#peter1000
ff097cb276710374b3ef4ef551dc29ab#acl#x86_64
9140e3d8065533d61fa077e731602172#acl.fr#any
0029f3a21d21534b2031a539f0e04065#acl.man#any
239870fb9cd383e270e0b08ac773db1a#acl.sv#any
866cff7556c9dc9ea81224459d8c00db#acl.README
80eba83e7de06d46752f4158979ea3c2#dummy.patch
d03ad0a50693b85015f2d420e2ed7d6a#otherfile.txt
66b57281f54815208b199afabddfd05e#Pkgfile

```

**EXAMPLE WITH COMPRESSION BUT NO EXISTING PKGARCHIVE FILEs**

```text
66b57281f54815208b199afabddfd05e#Pkgfile

```


### First Line Syntax

Only included if any pkgarchive file exist. 

```text
buildversion#.extension and any .compression#pkgversion#pkgrelease#pkgdescription#pkgurl#pkgpackager
```


### Pkgarchive Line Syntax

Only included if any pkgarchive file exist. 
See also [pkgarchive-name-syntax](02_pkgarchive_format/#pkgarchive-name-syntax).

```text
md5sum#port-name and any .group#architecture
```


### Other File Line Syntax

Only included if any pkgarchive file exist.

All other files of the port are included here: The Pkgfile is always the last: see below *Last Line Syntax*.

```text
md5sum#other-file-basename
```

!!! note

    Subdirectories or files in subdirectories are never included in the *Port-Repo-File*.


### Last Line Syntax

In a *Port-Repo-File* the Pkgfile line is always present.

```text
md5sum#pkgfile-basename
```


## Collection-Repo-File

Will be only updated if a Port-Repo-File exists and contains archive file entries: information is extracted from the first 
line of the Port-Repo-File.

**EXAMPLE**

```text
733f214a972cba5c70921a1181a392ef#1462741466#cpio#2.11#3#A tool.#http://www.gnu.org/software/cpio/#peter1000#.cards.tar.xz
```


### Line Syntax

```text
Port-Repo-File md5sum#buildversion#portname#pkgversion#pkgrelease#pkgdescription#pkgurl#pkgpackager#.extension any .compression
```

