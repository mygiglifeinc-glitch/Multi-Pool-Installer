# Security Policy

## Supported Versions

Only the latest tagged release of this installer is supported with security
fixes. Older tags should be considered unmaintained.

## Reporting a Vulnerability

If you discover a security vulnerability in this repository (for example, in
`bootstrap.sh` or the release/update flow it drives), please report it
privately rather than opening a public issue:

* Preferred: open a [GitHub Security Advisory](../../security/advisories/new)
  for this repository.
* Alternatively, reach out through the project's Discord (linked in the
  README) and ask to be connected with a maintainer.

Please do not disclose the issue publicly until a fix has been released.

## Scope Note

This repository only contains the `bootstrap.sh` launcher. The actual pool
installer logic lives in a separate repository
([mygiglifeinc-glitch/multipool_setup](https://github.com/mygiglifeinc-glitch/multipool_setup))
that `bootstrap.sh` clones, which in turn installs
[multipool_yiimp_single](https://github.com/mygiglifeinc-glitch/multipool_yiimp_single) and
[multipool_yiimp_multi](https://github.com/mygiglifeinc-glitch/multipool_yiimp_multi). Vulnerabilities in that installer
itself should be reported to that repository.
