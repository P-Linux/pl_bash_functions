# P-Linux Pkgarchive Format

<p align="center">Some 'general' information about the 'Pkgarchive Format'.</p>


---


A pkgarchive is an archive containing a set of files of various types (e.g. libraries, command line applications, graphical
user interfaces, commands, configuration information, etc.) and is the result of building a port.

Such pkgarchives can be handled (installed/removed etc.) by the *P-Linux package manager*.


## Pkgarchive Name Syntax

* `port-name`
* `.group-name`: (only if it is a group pkgarchive.)
* `buildversion`: 10 digits Unix-timestamp of the pkgarchive build time.
* `architecture`: any or system-architecture: e.g. ("$(uname -m)"  x86_64)
* `.extension`: the predefined pkgarchive reference extension without compression.
* `.xz`: only if it is a compressed pkgarchive.


### EXAMPLE: Pkgarchive Names Without Compression

| Pkgarchive Name                         | Description                                                                       |
|:----------------------------------------|:----------------------------------------------------------------------------------|
| `cards1462695664x86_64.cards.tar`       | name: cards, no group, buildvers: 1462695664, arch: x86_64, ext: cards.tar        |                                         |
| `cards.devel1462695664x86_64.cards.tar` | name: cards, group: devel, buildvers: 1462695664, arch: x86_64, ext: cards.tar    |
| `cards.man1462695664any.cards.tar`      | name: cards, group: man, buildvers: 1462695664, arch: any, ext: cards.tar         |


### EXAMPLE: Pkgarchive Names With Compression

| Pkgarchive Name                      | Description                                                                          |
|:-------------------------------------|:-------------------------------------------------------------------------------------|
| `acl.fr1462707691any.cards.tar.xz`   | name: acl, group: fr, buildvers: 1462707691, arch: any, ext: cards.tar, compressed   |                                         |
| `acl1462707691x86_64.cards.tar.xz`   | name: acl, no group, buildvers: 1462707691, arch: x86_64, ext: cards.tar, compressed |                                         |

