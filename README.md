# OpenDevin PowerShell
Collection of PowerShell scripts for running [OpenDevin](https://github.com/OpenDevin/OpenDevin) geared towards Windows 10 and Windows 11

See [OpenDevin Requirements](https://github.com/OpenDevin/OpenDevin?tab=readme-ov-file#-get-started)

## Usage
- Run the **OpenDevinWindowsInstall.ps1** install script in a **Administration level** PowerShell terminal
- After install is complete, open two non-admin level PowerShell terminals
    - Run **OpenDevinStartBackend.ps1** in one terminal
    - Run **OpenDevinStartFrontend.ps1** in the other terminal

## Issues
### Major Stopping Issue (07/07/2024)

**Backend server will not start**

pexpect python library is [not supported on Windows](https://github.com/pexpect/pexpect/issues/339) and will need to be fixed on OpenDevin repo. 


### Current Known Issues (as of 4/6/2024)
- Workspace dir needs to be the full path. Pathlib doesn't work well with "./workspace" on Windows
- You will need to change directory manually back to where the PS scripts are if you CRTL-C the frontend or backend
- Working on a way to start both
- **Requires Admin Privledges to run the install script due to corepack and npm**

## Contribute
Feel free to open a PR or Issue to make this script better 🚀

## Links
[OpenDevin](https://github.com/OpenDevin/OpenDevin)

[OpenDevin discord](https://discord.gg/7md8tT6c)
