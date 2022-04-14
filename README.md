# VIP Container Images

This repository is used to build Docker container images used, among others, by the [VIP Local Development Environment](https://docs.wpvip.com/technical-references/vip-local-development-environment/).

Images are built and published using GitHub Actions and GitHub Packages. All images in this repository are [multi-architechture images](https://docs.docker.com/desktop/multi-arch/), supporting `amd64` and `arm64`.

## Using the images

You can find the most up to date versions of the images and the command to pull them in the sidebar, under the _Packages_ section. TL;DR the pulling has to be prefixed with `ghcr.io/automattic/vip-container-images`. For instance:

```bash
docker pull ghcr.io/automattic/vip-container-images/alpine:3.14.1
```

### Using image locally in dev-env

The easiest way is to reconfigure lando file in specific `dev-env` to build image directly from this repository.
For example for `dev-tools` you could do something like this:

```
services:

  devtools:
    type: compose
    services:
      build:
        context: ~/git/automattic/vip-container-images
        dockerfile: ~/git/automattic/vip-container-images/dev-tools/Dockerfile
      command: sleep infinity
      volumes:
        - devtools:/dev-tools
    volumes:
      devtools: {}
```

Note: Lando will try to pull image from remote repository if you would use `image` instead of `build` which would probably fail if your image is only local one.

## Publishing the images

The image publishing process is performed by [a GitHub action](.github/workflows/) every time a commit is done to `master`. All workflows are triggered then, therefore, all images are built in parallel.

## Updating Docker images

This repository has Dependabot [set up](.github/dependabot.yml). Whenever a Docker base image has a new available version, the bot will open a Pull Request with the change.

## Adding, Updating and Deleting versions of WordPress

We have utility scripts to add and remove the versions of WordPress, based on the versions.json we kick off the image builds for every specified version. We use [official GitHub repo for WordPress](https://github.com/WordPress/WordPress). 

Basic syntax is as follows

`$> wordpress/add-version.sh <TAG> <REF> [cacheable=true] [locked=false] [prerelease=false]`

- `<TAG>` is Docker image tag, should be pointing to the major version, E.g. `5.8`
- `<REF>` is either git tag, e.g. `5.8.3` or git SHA, e.g. `e86b90cad6330eea636496f7317fac4c1a73e42b`

`$> wordpress/add-version.sh 6.0 2be90dc589a1c2e2bde5efa691eafe5407d0f753 true true true`
This will add a 6.0 (pre-release) and point to a specific commit

`$> wordpress/add-version.sh 5.9 5.9.3`
This will add a 5.9 and point to 5.9.3 tag.

`$> wordpress/delete-version.sh 5.9`
This can be used to delete tag.
Alternatively, this also can be done by removing the related entry from `wordpress/versions.json`
