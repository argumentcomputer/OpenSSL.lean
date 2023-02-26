# OpenSSL bindings for lean (unfinished)

Build with `nix build .` or `nix develop --command lake build`.

The bindings are mostly imperative and low level.
See the [OpenSSL manpages](https://www.openssl.org/docs/man3.1/) for more details.

## Dev env

Load dependencies and env variables into your shell.

Automatically

```bash
direnv activate
```
or manually
```bash
nix develop
```
