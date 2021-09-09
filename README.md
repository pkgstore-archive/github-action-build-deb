# Debian Source Package Builder

**GitHub Action** for build Debian **source** package.

## Workflow Syntax

```yml
name: "Debian: Build Package"

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
          repo_dst: "https://github.com/PKG_REPO_NAME.git"
          user: "${{ secrets.BUILD_USER_NAME }}"
          email: "${{ secrets.BUILD_USER_EMAIL }}"
          token: "${{ secrets.BUILD_USER_TOKEN }}"
```

### Legend

- `repo_src` - source repository URL.
- `repo_dst` - destination repository URL.
- `user` - user name.
- `email` - user email.
- `token` - user token.

## openSUSE Build Service

In **openSUSE Build Service** add `_service` file:

```xml
<services>
  <service name="obs_scm">
    <param name="scm">git</param>
    <param name="url">https://github.com/PKG_REPO_NAME.git</param>
    <param name="revision">main</param>
    <param name="version">_none_</param>
    <param name="filename">PKG_NAME</param>
    <param name="extract">*</param>
  </service>
  <service name="tar" mode="buildtime"/>
  <service name="recompress" mode="buildtime">
    <param name="compression">xz</param>
    <param name="file">*.tar</param>
  </service>
</services>
```

### Legend

- `PKG_REPO_NAME` - repository with Debian source packages.
- `PKG_NAME` - package name.
