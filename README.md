# Packaging workspace

Local workspace for building Dockershelf `.deb` packages. Packaging repos are git submodules; clone with:

```bash
git clone --recurse-submodules https://github.com/Dockershelf/dockershelf-pipeline.git
```

Or initialize submodules in an existing checkout:

```bash
git submodule update --init --recursive
```

## Layout

```text
dockershelf-pipeline/
├── python-pipeline/   https://github.com/Dockershelf/python-pipeline
├── node-pipeline/     https://github.com/Dockershelf/node-pipeline
├── go-pipeline/       https://github.com/Dockershelf/go-pipeline
├── py3.10/ … py3.14/  Python packaging repos
├── node18/ … node26/  Node.js packaging repos
└── go1.22/ … go1.26/  Go repackaging repos
```

## Python

```bash
cd python-pipeline
cp config.env.example config.env
make bootstrap
make list-dists
```

See [python-pipeline/README.md](python-pipeline/README.md) and [docs/operations.md](python-pipeline/docs/operations.md).

Upstream `cpython/` submodules are large; initialize on demand:

```bash
../init-cpython-submodules.sh py3.14
```

## Node.js

```bash
cd node-pipeline
cp config.env.example config.env
make bootstrap
make list-dists
```

Upstream `node/` submodules are large; initialize on demand:

```bash
../init-node-submodules.sh node22
```

See [node-pipeline/README.md](node-pipeline/README.md) and [docs/operations.md](node-pipeline/docs/operations.md).

## Go

```bash
cd go-pipeline
cp config.env.example config.env
make bootstrap
make materialize GO=1.25 DIST=trixie
make build GO=1.25
```

See [go-pipeline/README.md](go-pipeline/README.md) and [docs/operations.md](go-pipeline/docs/operations.md).

## Convenience delegates

```bash
make -C python-pipeline list-dists
make -C node-pipeline list-dists
make -C go-pipeline list-dists
```
