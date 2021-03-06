# TODO List
- Get local IP address of the guest VM into a variable, to use further downstream: `hostname -I` (i.e. 10.0.2.15)
- Set Network Adapter to `NAT` (vs. `null`, `hostonly`, `natnetwork`, etc):  `VBoxManage controlvm <VM Name> nic1 nat` (i.e. 10.0.2.15)

# DONE List
- Update ~/.bashrc with Greenplum Database custom parameters
- Update ~/.bash_profile with Greenplum Database custom parameters
- Create ~/start_all.sh script to start Greenplum Database with parameters
- Create ~/stop_all.sh script to stop Greenplum Database with parameters
- REFRESH_TOKEN='**********' ./build.sh failed on first execution (see gpdb-packing-error shown below); investigate whether it was connection problem on downloading the GPDB binary file or need to update instructions to include _--force-download_)
  - turned out to be because `build` folder was not created before download begins; added explicit `mkdir`
- Enable Port Forwarding in Greenplum Database VM:
    - SSH: `VBoxManage controlvm <VM Name> natpf1 ssh,tcp,,2222,10.0.2.15,22` or `VBoxManage controlvm <VM Name> natpf1 ssh,tcp,,2222,,22` (need to check which works "best"
    - SQL: `VBoxManage controlvm <VM Name> natpf1 ssh,tcp,,5432,10.0.2.15,5432` or `VBoxManage controlvm <VM Name> natpf1 sql,tcp,,5432,,5432` (need to check which works "best"
    - `VBoxManage controlvm <VM Name> natpf1 sql ....` command is appropriate when the VM is running. Port-forwarding rules can also be set if the VM is not running with the `VBoxManage modifyvm <VM Name> --natpf1 ....` command.
- Update Greenplum Database VM parameters/settings:
    - Update VM Name to "GPDB-" + {Greenplum Database version major.minor} (extract from GPDB download file?), i.e. GPDB-5.16.0: `VBoxManage modifyvm <VM Name> <new VM Name>`
    - Update VM Description: `VBoxManage modifyvm <VM Name> --description <text>`
    - Update VM number of CPUS: `VBoxManage modifyvm <VM Name> --cpu <number>`
    - Update RAM Settings to i.e. 8192MB: `VBoxManage modifyvm <VM Name> --memory <memorysize in MB>` or `VBoxManage modifyvm <VM Name> --description <vram in MB>` (need to investigate what-is-what)
    - Update Video Memory to 24MB
    - Disable Remote Display
