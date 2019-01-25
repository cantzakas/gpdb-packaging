# Greenplum VM build script

Repeatable builds for Greenplum VMs

## Dependencies

You will need
[Packer](https://www.packer.io/),
[VirtualBox](https://www.virtualbox.org/) and
[jq](https://stedolan.github.io/jq/).

These can be installed using [Homebrew](https://brew.sh/):

```bash
brew cask install virtualbox
brew install packer jq
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

   **Note**: If you see an error about accepting a EULA, open the printed URL in a browser to accept it manually.

4. If the script runs successfully, you will get a virtual image at `build/centos7-greenplum-<version>.ova`

### Options

You can specify extra options if needed:

`--force-download`: by default, greenplum will only be downloaded once.
If you need to re-download it (e.g. a new version), specify this flag

`--force-build-os`: by default, the base OS will only be built once.
If you need to re-build it (e.g. to use a later OS version), specify this flag.
