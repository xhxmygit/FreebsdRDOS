@rem
@rem e.g. vmnew VM-TEST-3 1 768 CorpNet f:\vm f:\vm\vhd f:\vm\snapshot f:\ccyVHD\oracle7b-base-rdssd.vhd
@rem 

cd %~dp0

set VM_NAME=%~1
set CPUS=%2
set MEM_SIZE=%3
set VM_SWITCH_NAME=%4
set VM_SWITCH_NAME_PLAIN=%~4
set VM_ROOT=%5
set VM_VHD_ROOT=%6
set VM_SNAPSHOOT_ROOT=%7
set VM_VHD_0=%8
set VM_VHD_1=%9

@rem setup switch
@echo setup switch
for /f "tokens=1,2 delims=:" %%i in ('vmadmin querynics ^| find "Name"') do (set NIC_NAME=%%j)
vmadmin queryswitch | findstr /R /C:"Name.*:%VM_SWITCH_NAME_PLAIN%$" 
if %errorlevel% EQU 0 (
    @echo %VM_SWITCH_NAME% already exists...
)else (
    @rem cmd /c vmadmin createswitch %VM_SWITCH_NAME%"  
	@rem cmd /c vmadmin setupswitch "%NIC_NAME%" "%VM_SWITCH_NAME%" EXTERNAL
	@echo Error: %VM_SWITCH_NAME% not exist...
	exit 10
)

@rem set root path of VM
@echo set root path of VM
cmd /c vmadmin setroot %VM_ROOT%
cmd /c vmadmin setvhdroot %VM_VHD_ROOT%


@rem create VM
@echo create VM
@vmadmin list | findstr "\<%VM_NAME%\>"
if %errorlevel% EQU 0 (
	@echo "VM: %VM_NAME% already exists  delete it..."
	cmd /c vmadmin delete %VM_NAME%
)else (
	@echo "VM: %VM_NAME% not exist creating VM ..."
)
cmd /c vmadmin create %VM_NAME% %CPUS% %MEM_SIZE% %VM_SWITCH_NAME% %VM_SNAPSHOOT_ROOT% %VM_VHD_0% %VM_VHD_1%

@rem Start and stop the VM to let the VM get a mac address
cmd /c vmadmin start %VM_NAME%
cmd /c vmadmin stop %VM_NAME%
