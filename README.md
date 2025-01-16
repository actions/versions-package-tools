# Common tools for generation of packages in the actions/*-versions repositories
This repository contains PowerShell modules that are used to generate packages for Actions. The packages are consumed by the images generated through [actions/runner-images](https://github.com/actions/runner-images) and some of the setup-* Actions

## Recommended permissions

When using the `versions-package-tools` in your GitHub Actions workflow, it is recommended to set the following permissions to ensure proper functionality:

```yaml
permissions:
  contents: read # access to read repository's content
  actions: read # access to reading actions 
```

## Contribution
Contributions are welcome! See [Contributor's Guide](./CONTRIBUTING.md) for more details about contribution process and code structure
