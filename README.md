# GitHub Action: Debian Build DEB

GitHub Action for build Debian `.deb` packages.

## Workflow Syntax

```yml
name: "Build: DEB"

on:
  - push

jobs:
  mirror:
    runs-on: ubuntu-latest
    name: "Build"
    steps:
      - uses: pkgstore/github-action-build-deb@main
        with:
          repo_src: "https://github.com/${{ github.repository }}.git"
          repo_dst: "https://github.com/deb-store/"
          user: "${{ secrets.BUILD_USER_NAME }}"
          email: "${{ secrets.BUILD_USER_EMAIL }}"
          token: "${{ secrets.BUILD_USER_TOKEN }}"
```

## Legend

- `repo_src` - source repository URL.
- `repo_dst` - destination repository URL.
- `user` - user name.
- `email` - user email.
- `token` - user token.
