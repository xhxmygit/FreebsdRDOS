I. Summary
---------------------------------
This project aimed at establish a complete work flow to automate RDOS testing (both feature and stress)
in a Linux-on-Azure test cycle.

II. Main Component
---------------------------------
1. Feature Test
2. XStore Disk Stress Test
3. Local Disk Stress Test
4. Reboot Stress Test
5. Network Stress Test

III. file list
---------------------------------
- auto_rdos
   \
    - auto_rdos.ps1                 # single entry of this project
    - Feature.*                     # feature test
    - LocalDisk.*                   # local disk stress test
    - XStoreDisk.*                  # XStore disk stress test
    - NetworkStress.*               # Network stress test
    - config-*.xml                  # sample configure files
    - vhdnew.cmd                    # script used to create VHDs
    - vmnew.cmd                     # script used to create VMs
    - ReportTestResult.ps1          # report test result
    - ToJUnitResult.xsl             # xsl template transform test result to JUnit format

- lisablue
   \
    - bin
    - remote-scripts\ica\
       \
        - auto_rdos_LocalDisk.sh    # script run in VMs in LocalDisk Stress Test
        - auto_rdos_XStore.sh       # script run in VMs in XStore Stress Test
        - auto_rdos_Network.sh      # script run in VMs in Network Stress Test
        - auto_rdos_Reboot.sh       # script run in VMs in Reboot Stress Test
        - AUTO_Reboot.sh            # script run in VMs in Reboot Stress Test
    - mimicArp.ps1                  # mimicArp related functions
    - stateEngine.ps1               # our version of stateEngine in Lisa
    - utiFunctions.ps1              # our version of utilFunctions in Lisa

- DeployIOZone.sh                   # used to automate install IOZone
- DeployIperf.sh                    # used to automate install Iperf
- report_ip.sh                      # the script run on Linux VM to report IP to the mimicArp server while boot

IV. Usage
---------------------------------
1. preparation works
    - Customize your own configure file, your can refer to sample configure files Named config-*.xml in auto_rdos fold.
    - Prepare hvServers with a virtual switch installed.
    - Put VHD files to hvServers in the path which is determined by value of vmVhdRoot in your configure file.
    - Copy the codes to your sever machine with Lisa installed and replace the duplicates.
2. Command: auto_rdos.ps1 config-*.xml [-dbgLevel <integer>]

