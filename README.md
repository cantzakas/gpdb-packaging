# Greenplum VM build script

Repeatable builds for Greenplum VMs

## Limitations

Greenplum database installation procedure has changed between versions 5.x and 6.x; previously was using the `gpseginstall` utility, or using system's package manager software, `yum install` for RHEL/CentOS systems, `apt install` for Ubuntu systems for version 6.x.

This tool, as of *Q1 2020*, **does not** support version 6.x installations but we are actively working on updating it.

## Dependencies

You will need
[Packer](https://www.packer.io/) and
[jq](https://stedolan.github.io/jq/), as well as at least one of:

* [VirtualBox](https://www.virtualbox.org/)
* [VMWare](https://www.vmware.com/) (requires **enterprise** license)

These can be installed using [Homebrew](https://brew.sh/):

```bash
brew install packer jq

brew cask install virtualbox
# or
brew cask install vmware-fusion
```

## Usage

1. You must have an account with [Pivotal Network](https://network.pivotal.io) to download the greenplum.zip file.
   These accounts can be created for free.

2. Using the web UI, add a "refresh token" in your
   [user settings](https://network.pivotal.io/users/dashboard/edit-profile) ("Request New Refresh Token").

3. Run the build script, specifying the generated refresh token:

   ```bash
   REFRESH_TOKEN='<token_here>' ./build.sh
   ```

4. If the script runs successfully, you will get a virtual image at `build/centos7-greenplum-<version>.ova`

### Options

You can specify extra options if needed:

`--keep-files`: optional, keeps greenplum setup files after a successful build for next run.

### Debugging

#### VirtualBox

If you try to build a new image while running an existing image in VirtualBox, it can corrupt the base OS image.
To resolve this, you must force a rebuild of the base OS image (answer "yes" to the "rebuild?" question).

#### VMWare

If you get an immediate error about networking issues,
you need to open the VMWare Fusion app and accept the license agreement.
