*** Settings ***
Documentation  

Library  String
Library  OperatingSystem
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspStressTester.py

Resource  Robot/Libs/Bsp/BspResources.robot


Suite Setup      Stress Test Suite Setup
Suite Teardown   Stress Test Suite Teardown
Test Setup       Stress Test Test Setup
Test Teardown    Stress Test Test Teardown

Force Tags       TGW_STRESS_TEST

*** Variables ***
${WRITE_TO_CONSOLE}     True
${STRESS_TEST_DURAION}  0.1

*** Test Cases ***
Boot Both TGWs And Check Serial Communication
    [Documentation]  Boot Both TGWs and verify that the serial communication is working
    [Tags]  TGW2.1
    
    LOG  ** Verify that the extra TGW test application is booted **   console=${WRITE_TO_CONSOLE}
    
    CANoe Set Power Supply On  VBAT_EXTRA_TGW
    ${result}  Boot Stress Test  ${SERIAL_HANDLE_EX_TGW}  EX_TGW
    Should be equal  ${result}  BOOT_OSE_OK    
    ${result}=  Wait Serial Sel String  ${SERIAL_HANDLE_EX_TGW}  DiskStress:  10.0
    Should be equal  ${result}  STRING_FOUND
    CANoe Set Power Supply Off  VBAT_EXTRA_TGW
    
    LOG  ** Verify that the BSP Rig TGW test application is booted **   console=${WRITE_TO_CONSOLE}
    CANoe Set Power Supply On  VBAT
    ${result}  Boot Stress Test  ${SERIAL_HANDLE}
    Should be equal  ${result}  BOOT_OSE_OK    
    ${result}=  Wait Serial Sel String  ${SERIAL_HANDLE}  DiskStress:  10.0
    Should be equal  ${result}  STRING_FOUND
    CANoe Set Power Supply Off  VBAT

    LOG  End Test  console=${WRITE_TO_CONSOLE}

BSP Stress Test
    [Documentation]  Test case that starts the stress test and monitors the output
    [Tags]  TGW2.1

    LOG  ** Start both TGWs used in the Stress Test **   console=${WRITE_TO_CONSOLE}
    CANoe Set Antenna State  GSM1  CON

    LOG  ** Start the BSP rig TGW **   console=${WRITE_TO_CONSOLE}
    CANoe Set Power Supply On  VBAT
    ${result}  Boot Stress Test  ${SERIAL_HANDLE}
    Should be equal  ${result}  BOOT_OSE_OK
    ${result}=  Wait Serial Sel String  ${SERIAL_HANDLE}  DiskStress:  10.0
    Should be equal  ${result}  STRING_FOUND

    LOG  ** Start the extra TGW **   console=${WRITE_TO_CONSOLE}
    CANoe Set Power Supply On  VBAT_EXTRA_TGW
    ${result}  Boot Stress Test  ${SERIAL_HANDLE_EX_TGW}  EX_TGW
    Should be equal  ${result}  BOOT_OSE_OK
    ${result}=  Wait Serial Sel String  ${SERIAL_HANDLE_EX_TGW}  DiskStress:  10.0
    Should be equal  ${result}  STRING_FOUND

    ${result}=  Monitor BSP Stress Test  ${SERIAL_HANDLE}  ${SERIAL_HANDLE_EX_TGW}  ${TEST_DURATION}  bsp_tgw.log  ext_tgw.log  ${WRITE_TO_CONSOLE}
    Should be equal  ${result}  STRESS_TEST_SUCCESS


BSP Stress Test Check GPRS Fail
    [Documentation]  Post processing log to check GPRS failures
    [Tags]  TGW2.1
    LOG  ** Check if GPRS fail on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_RESULT|TGW_TEST_ERROR|GprsStress|evDSGprsStressError|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}
    LOG  ** Check if GPRS fail on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_RESULT|TGW_TEST_ERROR|GprsStress|evDSGprsStressError|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}


BSP Stress Test Check GNSS Fail
    [Documentation]  Post processing log to check GNSS failures
    [Tags]  TGW2.1

    LOG  ** Check if GNSS fail on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_RESULT|TGW_TEST_ERROR|GprsStress|onGNSSNewPosition, time diff is outside accepted range|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_RESULT|TGW_TEST_ERROR|GprsStress|GNSSTimeoutError    encoding_errors=ignore
    Should Be Empty    ${ret}
    LOG  ** Check if GNSS fail on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_RESULT|TGW_TEST_ERROR|GprsStress|onGNSSNewPosition, time diff is outside accepted range|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_RESULT|TGW_TEST_ERROR|GprsStress|GNSSTimeoutError    encoding_errors=ignore
    Should Be Empty    ${ret}


BSP Stress Test Check J1708 Fail
    [Documentation]  Post processing log to check J1708 failures
    [Tags]  TGW2.1
    LOG  ** Check if GPRS fail on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_RESULT|TGW_TEST_ERROR|J1708Stress|responseTimeout*|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}
    LOG  ** Check if GPRS fail on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_RESULT|TGW_TEST_ERROR|J1708Stress|responseTimeout*|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}


BSP Stress Test Check CAN Fail
    [Documentation]  Post processing log to check CAN failures
    [Tags]  TGW2.1
    LOG  ** Check if CAN fail on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_RESULT|TGW_TEST_ERROR|DiskStress|evDSCanTimeoutError|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}
    LOG  ** Check if CAM fail on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_RESULT|TGW_TEST_ERROR|DiskStress|evDSCanTimeoutError|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}


BSP Stress Test Check Reboot Fail
    [Documentation]  Post processing log to check Reboot failures
    [Tags]  TGW2.1
    LOG  ** Check if REBOOT fail on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_RESULT|TGW_TEST_ERROR|J1708Stress|Peer reboot error.|1|END_RESULT    encoding_errors=ignore
    Should Be Empty    ${ret}


BSP Stress Test Check GPRS Activity
    [Documentation]  Post processing log to check GPRS activity
    [Tags]  TGW2.1
    LOG  ** Check GPRS activity on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File   ${StressTestLogFileBspTgw}    PPP connected    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    New GPRS-PPP state: CONNECTED    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_STATUS|GprsStress|Run::StartTransfer|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    GprsStress:StartTransfer    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    GprsStress: startFtpDownload    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    GprsStress: File transfer completed    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    LOG  ** Check GPRS activity on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    PPP connected    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    New GPRS-PPP state: CONNECTED    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_STATUS|GprsStress|Run::StartTransfer|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    GprsStress:StartTransfer    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    GprsStress: startFtpDownload    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    GprsStress: File transfer completed    encoding_errors=ignore
    Should Not Be Empty    ${ret}


BSP Stress Test Check GNSS Activity
    [Documentation]  Post processing log to check GNSS activity
    [Tags]  TGW2.1
    LOG  ** Check GNSS activity on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    Got GNSS position. Current update interval    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    onGNSSNewPosition. Long    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    LOG  ** Check GNSS activity on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    Got GNSS position. Current update interval    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    onGNSSNewPosition. Long    encoding_errors=ignore
    Should Not Be Empty    ${ret}


BSP Stress Test Check J1708 Activity
    [Documentation]  Post processing log to check J1708 activity
    [Tags]  TGW2.1
    LOG  ** Check J1708 activity on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_STATUS|J1708Stress|RunActiveMode::SendRequest|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_STATUS|J1708Stress|RunActiveMode::WaitForResponse|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    LOG  ** Check J1708 activity on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_STATUS|J1708Stress|RunPassiveMode::SendResponse|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    START_STATUS|J1708Stress|RunPassiveMode::waitForRequest|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}


BSP Stress Test Check RTC Activity
    [Documentation]  Post processing log to check RTC activity
    [Tags]  TGW2.1
    LOG  ** Check RTC activity on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    RTC time differs 0 s from the new location time    encoding_errors=ignore
    ${cnt}=    Get Line Count    ${ret}
    ${re2}=    Run Keyword If    ${cnt}==0    Grep File    ${StressTestLogFileBspTgw}    RTC time set succesfull    encoding_errors=ignore
    ${cn2}=    Get Line Count    $[re2}
    ${sum}=    Evaluate    ${cnt}+${cn2}
    Should Be True    ${sum}>0

    LOG  ** Check RTC activity on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    RTC time differs 0 s from the new location time    encoding_errors=ignore
    ${cnt}=    Get Line Count    ${ret}
    ${re2}=    Run Keyword If    ${cnt}==0    Grep File    ${StressTestLogFileExtTgw}    RTC time set succesfull    encoding_errors=ignore
    ${cn2}=    Get Line Count    $[re2}
    ${sum}=    Evaluate    ${cnt}+${cn2}
    Should Be True    ${sum}>0


BSP Stress Test Check CAN Activity
    [Documentation]  Post processing log to check CAN activity
    [Tags]  TGW2.1
    LOG  ** Check RTC activity on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    can_*Incoming OFFSET    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    Outgoing OFFSET ACK    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    Outgoing FILECOUNT    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    can_*Incoming FILECOUNT ACK    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    Outgoing DATA_LAST     encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    Outgoing SHORT_SLEEP    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    can_*Incoming SHORT_SLEEP    encoding_errors=ignore
    Should Not Be Empty    ${ret}


    LOG  ** Check RTC activity on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    can_*Incoming TIME    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    can_*Incoming SERVER_RANDOM    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    can_*Incoming OFFSET ACK    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    can_*Incoming FILECOUNT    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    Outgoing SHORT_SLEEP    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    can_*Incoming SHORT_SLEEP    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    Outgoing DATA_LAST     encoding_errors=ignore
    Should Not Be Empty    ${ret}


BSP Stress Test Check REBOOT Activity
    [Documentation]  Post processing log to check REBOOT activity
    [Tags]  TGW2.1
    LOG  ** Check REBOOT activity on BSP TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_STATUS|RebootHandler|RelaySwitchDelay|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ret}=    Grep File    ${StressTestLogFileBspTgw}    START_STATUS|RebootHandler|RelaySwitch|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${bsp_lines}=    Grep File    ${StressTestLogFileBspTgw}    START_STATUS|RebootHandler|Powered off other TGW|1|END_STATUS    encoding_errors=ignore
    Should Not Be Empty    ${bsp_lines}

    ${bsp_reboot_cnt}=    Get Line Count    ${bsp_lines}

    LOG  ** Check REBOOT activity on EXT TGW **    console=${WRITE_TO_CONSOLE}
    ${ret}=    Grep File    ${StressTestLogFileExtTgw}    Welcome to RTOSE; an OSE reference system    encoding_errors=ignore
    Should Not Be Empty    ${ret}

    ${ext_lines}=    Grep File    ${StressTestLogFileExtTgw}    System restart    encoding_errors=ignore
    Should Not Be Empty    ${ext_lines}

    ${ext_reboot_cnt}=    Get Line Count    ${ext_lines}

    Log To Console    Detected restarts on BSP TGW ${bsp_reboot_cnt}

    Log To Console    Detected restarts on EXT TGW ${ext_reboot_cnt}


*** Keywords ***
Stress Test Suite Setup
    [Documentation]  Suite setup sets Z flag and boots OSE with test application.
    LOG  **** Stress Test Suite Setup ****  console=${WRITE_TO_CONSOLE}

    # Load CANoe Config
    CANoe Load Configuration
    CANoe Start Simulation

    # Set up the Rig to use the selected TGW
    ${result}  CANoe Setup Test Rig  ${TGW_BOX_POS}
    Should be equal  ${result}  CANoe Setup Testrig Succeeded
    Sleep  1.0

    ${result}  CANoe Check Test Rig Settings  ${TGW_BOX_POS}
    # Try to setup test rig one more time
    Run Keyword If  '${result}' != 'SUCCESS'  Try Rig Setup One Last Time

    # Begin with configuring the extra TGW
    CANoe Set Power Supply Current  VBAT_Sup  1.0
    Sleep  0.5
    CANoe Set Power Supply Voltage  VBAT_Sup  24.0
    Sleep  0.5

    LOG  Power on Extra TGW, download OSE and set Z flag  console=${WRITE_TO_CONSOLE}
    ${result}  Boot Extra TGW Set Z Flag And Prevent Reset
    Should be equal  ${result}  SETUP_TFTP_BOOT_COMPLETED

    ${result}     Watchdog Teaser  ${SERIAL_HANDLE_EX_TGW}
    Should be equal  ${result}    TEASER_OK

    LOG  Install Stress Test on Extra TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Install Stress Test Application  ${SERIAL_HANDLE_EX_TGW}  rtose_ex_s.elf.manifest
    Should be equal  ${result}  STRESS_TEST_APPLICATION_INSTALLED

    LOG  Install Stress Test Settings Files on Extra TGW  console=${WRITE_TO_CONSOLE}
    ${result}=  Install Stress Test Settings Files  ${SERIAL_HANDLE_EX_TGW}  ext_tgw  False  True  False
    Should be equal  ${result}  STRESS_TEST_SETTINGS_INSTALLED

    Sleep  1.0
    LOG  Kill Power on Extra TGW  console=${WRITE_TO_CONSOLE}
    CANoe Set Power Supply Off  VBAT_EXTRA_TGW

    LOG  Power on BSP TGW, download OSE and set Z flag  console=${WRITE_TO_CONSOLE}
    ${result}  Boot BSP Rig TGW And Set Z Flag And Then Prevent Reset
    Should be equal  ${result}  SETUP_TFTP_BOOT_COMPLETED

    ${result}     Watchdog Teaser  ${SERIAL_HANDLE}
    Should be equal  ${result}    TEASER_OK

    LOG  Install Stress Test on BSP TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Install Stress Test Application  ${SERIAL_HANDLE}  rtose_s.elf.manifest
    Should be equal  ${result}  STRESS_TEST_APPLICATION_INSTALLED

    LOG  Install Stress Test Settings Files  console=${WRITE_TO_CONSOLE}
    ${result}=  Install Stress Test Settings Files  ${SERIAL_HANDLE}  bsp_tgw  True  False  True
    Should be equal  ${result}  STRESS_TEST_SETTINGS_INSTALLED

    Sleep  1.0
    CANoe Set Power Supply Off  VBAT

    # Connect J1708 and CAN
    LOG  Connect J1708 and CAN  console=${WRITE_TO_CONSOLE}
    Canoe Vt2516 Set Relay Org Component Active  J1708A
    Canoe Vt2516 Set Relay Org Component Active  J1708B
    Canoe Vt2516 Set Relay Org Component Active  Vehicle_CAN2_H
    Canoe Vt2516 Set Relay Org Component Active  Vehicle_CAN1_H
    Canoe Vt2516 Set Relay Org Component Active  Vehicle_CAN2_L
    Canoe Vt2516 Set Relay Org Component Active  Vehicle_CAN1_L

    # Enable TGW resetting via  HW Reset and
    Canoe Set Vts Variable  TGW_STRESS_TEST_EN   Relay  1
    Canoe Vt2516 Set Relay Org Component Active  HW_RESET

    # Location of test logs/build artifacts
    ${StressTestLogFileBspTgw}=    Set Variable    C://Jenkins_Slave//workspace//%{JOB_NAME}//TSP_VERIFICATION_VOB//PythonTesting//bsp_tgw.log
    Set Suite Variable    ${StressTestLogFileBspTgw}
    ${StressTestLogFileExtTgw}=    Set Variable    C://Jenkins_Slave//workspace//%{JOB_NAME}//TSP_VERIFICATION_VOB//PythonTesting//ext_tgw.log
    Set Suite Variable    ${StressTestLogFileExtTgw}

    LOG  **** Stress Test Suite Setup completed *****  console=${WRITE_TO_CONSOLE}


Stress Test Suite Teardown
    [Documentation]  Suite teardown will power on both TGWs and erase the flash
    LOG  **** Stress Test Suite Teardown ****  console=${WRITE_TO_CONSOLE}
    # Powers on and remove Z flag
    CANoe Set Power Supply On  VBAT
    Flush Serial Input  ${SERIAL_HANDLE}
    Sleep  1.0
    ${result}  Boot Stress Test  ${SERIAL_HANDLE}
    Should be equal  ${result}  BOOT_OSE_OK
    Sleep  0.5
    Flush Serial Input  ${SERIAL_HANDLE}
    ${result}  Erase TGW Flash Memory  ${SERIAL_HANDLE}  True
    Should be equal  ${result}  TGW_FLASH_ERASED_OK
    CANoe Set Power Supply Off  VBAT
    Sleep  1.0

    Close Serial Connection Only  ${SERIAL_HANDLE}

    CANoe Set Power Supply On  VBAT_EXTRA_TGW
    Flush Serial Input  ${SERIAL_HANDLE_EX_TGW}
    Sleep  1.0
    ${result}  Boot Stress Test  ${SERIAL_HANDLE_EX_TGW}  EX_TGW
    Should be equal  ${result}  BOOT_OSE_OK
    Sleep  0.5
    Flush Serial Input  ${SERIAL_HANDLE_EX_TGW}
    ${result}  Erase TGW Flash Memory  ${SERIAL_HANDLE_EX_TGW}  True
    Should be equal  ${result}  TGW_FLASH_ERASED_OK
    CANoe Set Power Supply Off  VBAT_EXTRA_TGW

    Close Serial Connection Only  ${SERIAL_HANDLE_EX_TGW}

    # Disconnect J1708 and CAN
    LOG  Disconnect J1708 and CAN  console=${WRITE_TO_CONSOLE}
    Canoe Vt2516 Set Relay Org Component Inactive  J1708A
    Canoe Vt2516 Set Relay Org Component Inactive  J1708B
    Canoe Vt2516 Set Relay Org Component Inactive  Vehicle_CAN2_H
    Canoe Vt2516 Set Relay Org Component Inactive  Vehicle_CAN1_H
    Canoe Vt2516 Set Relay Org Component Inactive  Vehicle_CAN2_L
    Canoe Vt2516 Set Relay Org Component Inactive  Vehicle_CAN1_L

    Canoe Set Vts Variable  TGW_STRESS_TEST_EN     Relay  0
    Canoe Vt2516 Set Relay Org Component Inactive  HW_RESET


    CANoe Stop Simulation

Stress Test Test Setup
    LOG  **** Stress Test Test Setup ****  console=${WRITE_TO_CONSOLE}

Stress Test Test Teardown
    LOG  **** Stress Test Test Teardown ****  console=${WRITE_TO_CONSOLE}

    CANoe Set Power Supply Off  VBAT
    CANoe Set Power Supply Off  VBAT_EXTRA_TGW
    
Boot Extra TGW Set Z Flag And Prevent Reset
    [Documentation]  Set up the Power to the extra TGW. The OSE is booted and downloaded to the TGW whereas the Z-flag is set. 

    # Make sure that the extra TGW is powered off completely and serial handle connected by waiting 2 seconds before restoring power.
    CANoe Set Power Supply Off  VBAT_EXTRA_TGW
    Sleep  1.0

    # The Connect To Serial keyword will register the SERIAL_HANDLE_EX_TGW variable.
    LOG  ...Connect to Serial Port for Extra TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Connect To Serial Ex TGW
    Should be equal  ${result}  CONNECT_TO_SERIAL_OK
    Flush Serial Input  ${SERIAL_HANDLE_EX_TGW}
    Sleep  1.0

    LOG  ...Power On for Extra TGW  console=${WRITE_TO_CONSOLE}
    CANoe Set Power Supply On  VBAT_EXTRA_TGW

    LOG  ...Boot OSE for Extra TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Boot OSE  ${SERIAL_HANDLE_EX_TGW}  EX_TGW
    Should be equal  ${result}  BOOT_OSE_OK

    Sleep  4.0
    Flush Serial Input  ${SERIAL_HANDLE_EX_TGW}

    LOG  ...Erase Flash for Extra TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Erase TGW Flash Memory  ${SERIAL_HANDLE_EX_TGW}  True
    Should be equal  ${result}  TGW_FLASH_ERASED_OK
    
    Sleep  2.0
    Flush Serial Input  ${SERIAL_HANDLE_EX_TGW}

    LOG  ...Setup TGW Flash File System for Extra TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Setup Tgw Flash File Structure  ${SERIAL_HANDLE_EX_TGW}  True
    Should be equal  ${result}  TGW_FLASH_SETUP_OK
    
    # Download OSE from TFTP and set Z flag
    LOG  ...Download OSE To Extra TGW And Set Z Flag  console=${WRITE_TO_CONSOLE}
    ${result}    Write OSE To TGW And Set Z Flag    ${SERIAL_HANDLE_EX_TGW}  EX_TGW
    Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

    ${SETUP_TFTP_BOOT_COMPLETED}=  Set Variable  SETUP_TFTP_BOOT_COMPLETED

    [Return]  SETUP_TFTP_BOOT_COMPLETED

Install Stress Test Application
    [Documentation]  Install all files nessesary to boot the stress test application
    [Arguments]  ${handle}  ${rtose_manifest}
    
    ${result}    Download File To TGW At Path And Wait  ${handle}  ${rtose_manifest}  /flash/Application/Bank1/OS/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${result}    Download File To TGW At Path And Wait  ${handle}  Dataset1.bin  /flash/Application/Bank1/DataFiles/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${result}    Download File To TGW At Path And Wait  ${handle}  Dataset1.bin.manifest  /flash/Application/Bank1/DataFiles/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${result}    Download File To TGW At Path And Wait  ${handle}  Dataset2.bin  /flash/Application/Bank1/DataFiles/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${result}    Download File To TGW At Path And Wait  ${handle}  Dataset2.bin.manifest  /flash/Application/Bank1/DataFiles/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${result}    Download File To TGW At Path And Wait  ${handle}  TGWOSE.elf  /flash/Application/Bank1/Autostart/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${result}    Download File To TGW At Path And Wait  ${handle}  TGWOSE.elf.manifest  /flash/Application/Bank1/Autostart/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${STRESS_TEST_APPLICATION_INSTALLED}=  Set Variable  STRESS_TEST_APPLICATION_INSTALLED

    [Return]  ${STRESS_TEST_APPLICATION_INSTALLED}

Install Stress Test Settings Files
    [Documentation]  Install all files nessesary to run the stress test application
    [Arguments]  ${serial_handle}  ${file_ext}  ${en_j1708}  ${no_reset}  ${can_server}

    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  FTP_FILENAME      /flash/tgw_root/diskstress/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  FTP_PASSWORD      /flash/tgw_root/diskstress/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  FTP_PORT          /flash/tgw_root/diskstress/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  FTP_SERVER        /flash/tgw_root/diskstress/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  FTP_USER_NAME     /flash/tgw_root/diskstress/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  FTP_FILENAME      /flash/tgw_root/diskstress/  True
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  GNSS_INTERVAL_MS.${file_ext}  /flash/tgw_root/diskstress/  True  GNSS_INTERVAL_MS
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    Run Keyword If  '${en_j1708}' == 'True'  Write J1708 MID Settings  ${serial_handle}  ${file_ext}

    Run Keyword If  '${no_reset}' == 'True'  Write noreset Setting  ${serial_handle}

    Run Keyword If  '${can_server}' == 'True'  Write Can Server Settings  ${serial_handle}

    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  SIM_HOST.${file_ext}          /flash/tgw_root/diskstress/  True  SIM_HOST
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  SIM_PASS.${file_ext}          /flash/tgw_root/diskstress/  True  SIM_PASS
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  SIM_USER.${file_ext}          /flash/tgw_root/diskstress/  True  SIM_USER
    Should be equal  ${result}  FILE_DOWNLOADED_OK

    ${STRESS_TEST_SETTINGS_INSTALLED}=  Set Variable  STRESS_TEST_SETTINGS_INSTALLED

    [Return]  ${STRESS_TEST_SETTINGS_INSTALLED}

Write J1708 MID Settings
    [Documentation]  Write the J1708 MID Settings file to TGW
    [Arguments]  ${serial_handle}  ${file_ext}
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  J1708_MID.${file_ext}         /flash/tgw_root/diskstress/  True  J1708_MID
    Should be equal  ${result}  FILE_DOWNLOADED_OK

Write noreset Setting
    [Documentation]  Write the noreset Settings file to TGW
    [Arguments]  ${serial_handle}
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  noreset         /flash/tgw_root/  True  noreset
    Should be equal  ${result}  FILE_DOWNLOADED_OK
    LOG  Write noreset Setting  console=${WRITE_TO_CONSOLE}

Write CAN Server Settings
    [Documentation]  Write the CAN Server Settings file to TGW
    [Arguments]  ${serial_handle}
    ${result}    Download File To TGW At Path And Wait  ${serial_handle}  CAN_SERVER         /flash/tgw_root/diskstress/  True  CAN_SERVER
    Should be equal  ${result}  FILE_DOWNLOADED_OK

Boot BSP Rig TGW And Set Z Flag And Then Prevent Reset
    [Documentation]  Set up the Power to the selected TGW. The OSE is booted whereas the Test Application is started.

    ${result}  CANoe Setup Test Rig  ${TGW_BOX_POS}
    Should be equal  ${result}  CANoe Setup Testrig Succeeded
    Sleep  1.0

    ${result}  CANoe Check Test Rig Settings  ${TGW_BOX_POS}
    # Try to setup test rig one more time
    Run Keyword If  '${result}' != 'SUCCESS'  Try Rig Setup One Last Time

    # Make sure that the TGW is powered off completely and serial handle connected by waiting 2 seconds before restoring power.
    CANoe Set Power Supply Off  VBAT

    # The Connect To Serial keyword will register the SERIAL_HANDLE variable.
    LOG  ...Connect to Serial Port for BSP Rig TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Connect To Serial
    Should be equal  ${result}  CONNECT_TO_SERIAL_OK
    Flush Serial Input  ${SERIAL_HANDLE}
    Sleep  1.0

    LOG  ...Power On for for BSP Rig TGW  console=${WRITE_TO_CONSOLE}
    CANoe Set Power Supply On  VBAT
    Sleep  0.5
    ${result}  CANoe Check Voltage And Current
    Run Keyword If  '${result}' != 'SUCCESS'  Try CANoe Set Power Supply One Last Time
    
    LOG  ...Boot OSE for BSP Rig TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Boot OSE  ${SERIAL_HANDLE}
    Should be equal  ${result}  BOOT_OSE_OK

    Sleep  4.0
    Flush Serial Input  ${SERIAL_HANDLE}
    
    LOG  ...Erase Flash for BSP Rig TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Erase TGW Flash Memory  ${SERIAL_HANDLE}  True
    Should be equal  ${result}  TGW_FLASH_ERASED_OK
    
    Sleep  2.0
    Flush Serial Input  ${SERIAL_HANDLE}
    
    LOG  ...Setup TGW Flash File System for BSP Rig TGW  console=${WRITE_TO_CONSOLE}
    ${result}  Setup Tgw Flash File Structure  ${SERIAL_HANDLE}  True
    Should be equal  ${result}  TGW_FLASH_SETUP_OK

    # Download OSE from TFTP and set Z flag
    LOG  ...Download OSE To BSP Rig TGW And Set Z Flag  console=${WRITE_TO_CONSOLE}
    ${result}    Write OSE To TGW And Set Z Flag    ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

    ${SETUP_TFTP_BOOT_COMPLETED}=  Set Variable  SETUP_TFTP_BOOT_COMPLETED

    [Return]  ${SETUP_TFTP_BOOT_COMPLETED}


