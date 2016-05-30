@rem
@rem vhdgetas [host name] [VM name] [xStore sever add] [storage account name] [container] [access key]
@rem
@rem @@@ xDisk related parameter example @@@
@rem NETWORK_ADD=blob.core.test-cint.azure-test.net
@rem STORAGE_ACCOUNT_NAME=rdostestco2iaas1
@rem CONTAINER=ostc-shanghai
@rem ACCESS_KEY=ik37+x6DB9rvgIgwvJJf5yJ2bJhWlICHrQmmut19YJV7tNEXtlVDTESDPqClM83wvZSHfHT6raL0PSpvlx2hOA==
@rem

set HOST_NAME=%1
set VM_NAME=%~2
set NETWORK_ADD=%3
set STORAGE_ACCOUNT_NAME=%4
set CONTAINER=%5
set ACCESS_KEY=%6

@rem name of VHDs
set REMOTE_DATA_VHD_FILE_NAME=%HOST_NAME%.%VM_NAME%-data.vhd

set NSC=XDISK:%NETWORK_ADD%/%STORAGE_ACCOUNT_NAME%/%CONTAINER%

bin\vhdctrl -xdisk_getas %NSC%/%REMOTE_DATA_VHD_FILE_NAME%,%ACCESS_KEY%,0,%NETWORK_ADD%
