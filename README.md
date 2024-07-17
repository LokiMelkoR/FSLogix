# FSLogix

Introduction

FSLogix is a profile solution for non-persistent desktops. It is Microsoft’s recommended profile solution for AVD, and is used accross other VDI solutions as well. This is because it moves away from “roaming” profile solutions to a profile that is mounted and feels like a local profile. If you’ve worked with User Profile Disks (UPDs) or have an understanding about VHD/VHDX’s, FSLogix profile containers would not be hard to understand. 


FSLogix components.

Storage
  In common administrators use either a SMB file server or Azure files for storage. FSLogix profile containers will be stored here, therefore the high performance of the storage solution is highly important for FSLogix to avoid slow logons. Additionally permissions for users need to be setup as well. 

FSLogix Application.
  The FSLogix Application is installed on the session host users login to. The installation of the application is simple and what requires the attention is setting up the group policies to configure.

FSLogix containers
  The container holds the users profile. When a user logins for the first time, a profile container will be created in the storage location designated. The user’s profile will be a VHDX or VHD file (with VHDX being preferred configuration).  In default, this will include the user’s entire profile.  Which means all that would be in a user’s C:\User\<username>     folder and this will be stored in their FSLogix profile container. You can control what should be stored and captured by configuring redirection.
  At user logon, the FSLogix app will look at the storage location and mount that user’s profile container to the VDI.  When the user logs off, this is dismounted from that host.  This way the user can login to multiple VDI’s on a VDI pool everyday, but still feel like its the same VDI. This way administrators can do VDI pool related tasks without users losing   their data and settings.  


Prerequisits

  Supported OS:  Windows 10, 11 (as of 17.07.2024)
  Windows Server 2012 R2, 2016, 2019, 2022 (as of 17.07.2024)

  Licensing: 

    Microsoft 365 E3/E5
    Microsoft 365 A3/A5/ Student Use Benefits
    Microsoft 365 F1/F3
    Microsoft 365 Business
    Windows 10 Enterprise E3/E5
    Windows 10 Education A3/A5
    Windows 10 VDA per user
    Remote Desktop Services (RDS) Client Access License (CAL)
    Remote Desktop Services (RDS) Subscriber Access License (SAL)
    Azure Virtual Desktop per-user access license

  Identity and Authentication: 
    Make sure users can access the Storage location/provider with read/write permission.

  Storage consideration: 
    Make sure storage infra is setup based on your workload, user, and business requirements. Generally start with 30GB quota per user profile and a 15GB for ODFC
    https://learn.microsoft.com/en-us/fslogix/overview-prerequisites#storage-next-steps 

  Network Considerations: 
    FSLogix relies on mounting a container from a remote storage location(on-prem or cloud). Therefore network latency, bandwidth and proximity to the storage provider is highly important to the user's experience.

  Antivirus Exclusions: 
    Exclude following from your corportate AV. Otherwise there will be delays on user logon.

      %TEMP%\*\*.VHD
      %TEMP%\*\*.VHDX
      %Windir%\TEMP\*\*.VHD
      %Windir%\TEMP\*\*.VHDX
      \\server-name\share-name\*\*.VHD
      \\server-name\share-name\*\*.VHD.lock
      \\server-name\share-name\*\*.VHD.meta
      \\server-name\share-name\*\*.VHD.metadata
      \\server-name\share-name\*\*.VHDX
      \\server-name\share-name\*\*.VHDX.lock
      \\server-name\share-name\*\*.VHDX.meta
      \\server-name\share-name\*\*.VHDX.metadata
      Cloud Cache specific exclusions (Not configured in MED-EL as of 19-06-2024)
      %ProgramData%\FSLogix\Cache\* (folder and files)
      %ProgramData%\FSLogix\Proxy\* (folder and files)

Installation steps: 

  Download FSLogix at  : https://learn.microsoft.com/en-us/fslogix/how-to-install-fslogix#download-fslogix

  Release notes are at : https://learn.microsoft.com/en-us/fslogix/overview-release-notes
  
  Known issues are at  : https://learn.microsoft.com/en-us/fslogix/troubleshooting-known-issues 

  Always test, test, test the patches before release to production. 

  1. Installing FSLogixAppsSetup.exe to the image would be enough. This is valid for updating as well. it is a simple straight-forward installation. 
  2. Always reboot after installation/updating.
  3. You can use the appwiz.cpl (installed apps on windows) to verify the installation.
     Or from cmd/powershell go to C:\Program Files\FSLogix\Apps and .\frx.exe version

  
  Now use the FSLogix GPO to set your configurations to the environment. They should come with your download.

  
    

