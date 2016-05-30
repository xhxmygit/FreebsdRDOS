@rem
@rem xstore_prepare [host name] [VM name] [source vhd file] [VM mode] [RDOS sever add] [storage account name] [container]
@rem                [access key] [mode] [data disk size, default:81920]
@rem
@rem @@@ xDisk related parameter example @@@
@rem NETWORK_ADD=blob.core.test-cint.azure-test.net
@rem STORAGE_ACCOUNT_NAME=rdostestco2iaas1
@rem CONTAINER=ostc-shanghai
@rem ACCESS_KEY=ik37+x6DB9rvgIgwvJJf5yJ2bJhWlICHrQmmut19YJV7tNEXtlVDTESDPqClM83wvZSHfHT6raL0PSpvlx2hOA==
@rem

set HOST_NAME=%1
set VM_NAME=%~2
set SRC_VHD_FILE=%~3
set VM_MODE=%4
set NETWORK_ADD=%5
set STORAGE_ACCOUNT_NAME=%6
set CONTAINER=%7
set ACCESS_KEY=%8
set RDOS_MODE=%9

@rem variables depend on input parameter
@shift /1
if {%9}=={} (set DATA_DISK_SIZE=81920) else (set DATA_DISK_SIZE=%9)

@rem name of VHDs
for %%F in ("%SRC_VHD_FILE%") do set SRC_VHD_FILE_NAME=%%~nxF
for %%F in ("%SRC_VHD_FILE%") do set SRC_VHD_PREFIX_PATH=%%~dpF
set TARGET_VHD_FILE=%SRC_VHD_FILE_NAME:~,-4%-rdssd.vhd
set REMOTE_VHD_COPY_FILE=%HOST_NAME%.%VM_NAME%-rdssd.vhd
set LOCAL_CACHE_VHD=%SRC_VHD_PREFIX_PATH%%VM_NAME%.vhd

set DATA_VHD_FIle_NAME=%VM_NAME%-data.vhd
set REMOTE_DATA_VHD_FILE_NAME=%HOST_NAME%.%VM_NAME%-data.vhd
set DATA_VHD_FIle=%SRC_VHD_PREFIX_PATH%%DATA_VHD_FIle_NAME%

set NSC=XDISK:%NETWORK_ADD%/%STORAGE_ACCOUNT_NAME%/%CONTAINER%

@if exist %LOCAL_CACHE_VHD% del %LOCAL_CACHE_VHD%
@if exist %DATA_VHD_FIle% del %DATA_VHD_FIle%

@rem Convert local VHD to XStore RDSSD VHD (no related RDSSD VHD exist)
@if "%VM_MODE%"=="L" goto :localOS
@echo Convert Local VHD to XStore RDSSD VHD...
vhdctrl -xdisk_lb %NSC%,%ACCESS_KEY%,0,%NETWORK_ADD% | find "- Blob = %TARGET_VHD_FILE% ,"
@if %errorlevel% EQU 0 (
    echo RDSSD VHD %TARGET_VHD_FILE% already exists
)else (
    echo vhdctrl -cv %SRC_VHD_FILE% %NSC%/%TARGET_VHD_FILE%,%ACCESS_KEY%,0,%NETWORK_ADD%
    vhdctrl -cv %SRC_VHD_FILE% %NSC%/%TARGET_VHD_FILE%,%ACCESS_KEY%,0,%NETWORK_ADD%
)

vhdctrl -xdisk_lb %NSC%,%ACCESS_KEY%,0,%NETWORK_ADD% | find "- Blob = %TARGET_VHD_FILE%" > temp1.txt
@rem temp1.txt example:
@rem "    - Blob = Ubuntu-12_04_4-LTS-amd64-server-20140717-en-us-30GB_dynamic-rdssd.vhd , Size = 31457280512 bytes , LeaseId = unlocked "
@for /f "tokens=2 delims=," %%i in (temp1.txt) do echo %%i > temp2.txt
@rem temp2.txt example:
@rem " Size = 31457280512 bytes "
@for /f "tokens=3" %%i in (temp2.txt) do set VHD_BYTE=%%i
set LARGE_VHD_SIZE=%VHD_BYTE:~0,-9%
set SMALL_VHD_SIZE=%VHD_BYTE:~-9%
@rem 1953125 = 5 ^ 9, want to calculate: VHD_SIZE = (VHD_BYTE - 512) / 1024 / 1024
@set /a "VHD_SIZE = (LARGE_VHD_SIZE * 1953125 + SMALL_VHD_SIZE / 512 - 1) / 2 / 1024"
@echo VHD_SIZE=%VHD_SIZE%

@rem Create a remote copy 
@echo Create a Remote Copy...
vhdctrl -xdisk_copyblob %NSC%/%REMOTE_VHD_COPY_FILE%,%ACCESS_KEY%,0,%NETWORK_ADD% http://%STORAGE_ACCOUNT_NAME%.%NETWORK_ADD%/%CONTAINER%/%TARGET_VHD_FILE%

@rem Create the local VHD cache to attach to VM
@echo Create the local VHD cache to attach to VM...
vhdctrl -c %LOCAL_CACHE_VHD% -s %VHD_SIZE% -rdssd %NSC%/%REMOTE_VHD_COPY_FILE%,%ACCESS_KEY%,2,%NETWORK_ADD% -t dynamic

@rem Create XStore Data Disk
@if "%VM_MODE%"=="X" goto :eof
@if "%VM_MODE%"=="XL" goto :localData

@echo Create Data Disk...
@if "%RDOS_MODE%"=="2" call :createData 2
@if "%RDOS_MODE%"=="1" call :createData 1
@if "%RDOS_MODE%"=="0" call :createData0
@goto :eof

:localOS
copy %SRC_VHD_FILE% %SRC_VHD_PREFIX_PATH%%VM_NAME%.vhd
@goto :eof

@rem Create normal Data Disk
:localData
vhdctrl -c %DATA_VHD_FIle% -s %DATA_DISK_SIZE% -t dynamic
@goto :eof

:createData
vhdctrl -xdisk_lb %NSC%,%ACCESS_KEY%,0,%NETWORK_ADD% | find "- Blob = %REMOTE_DATA_VHD_FILE_NAME% ,"
@if %errorlevel% EQU 0 (
    echo vhdctrl -xdisk_del %NSC%/%REMOTE_DATA_VHD_FILE_NAME%,%ACCESS_KEY%,%1,%NETWORK_ADD%
    vhdctrl -xdisk_del %NSC%/%REMOTE_DATA_VHD_FILE_NAME%,%ACCESS_KEY%,%1,%NETWORK_ADD%
)
vhdctrl -c %DATA_VHD_FIle% -s %DATA_DISK_SIZE% -rdssd %NSC%/%REMOTE_DATA_VHD_FILE_NAME%,%ACCESS_KEY%,%1,%NETWORK_ADD% -t dynamic
@goto :eof

:createData0
set DATA_LOCAL_VHD_FIle=%SRC_VHD_PREFIX_PATH%%VM_NAME%-data-local.vhd
@if exist %DATA_LOCAL_VHD_FIle% del %DATA_LOCAL_VHD_FIle%

vhdctrl -c %DATA_LOCAL_VHD_FIle% -s %DATA_DISK_SIZE% -t dynamic
vhdctrl -cv %DATA_LOCAL_VHD_FIle% %NSC%/%REMOTE_DATA_VHD_FILE_NAME%,%ACCESS_KEY%,0,%NETWORK_ADD%
vhdctrl -c %DATA_VHD_FIle% -s %DATA_DISK_SIZE% -pr %NSC%/%REMOTE_DATA_VHD_FILE_NAME%,%ACCESS_KEY%,0,%NETWORK_ADD% -awav
@goto :eof
