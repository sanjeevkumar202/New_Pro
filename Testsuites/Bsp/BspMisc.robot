*** Settings ***
Documentation  This test suite will perform miscellaneous testing.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspMiscTester.py
Library  Robot/Libs/Bsp/BspGsmTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${DEBUG}  ${1}
${TFTP_SPEED}  ${25000}
${BOOT_TIME}  ${8}

*** Keywords ***

*** Test Cases ***
#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Setup TFTP Boot

#*************************************************************************************************
# BSP_FUNCTION_INTERFACE
#*************************************************************************************************
Misc Bsp Function IF
  [Documentation]  To verify that the BSP API contains only function interfaces.
  [Tags]  TGW2.0  TGW2.1  ManualTest

    Fail  Manual test  ManualTest

#*************************************************************************************************
# CBKMGR_PRIO
#*************************************************************************************************
Misc Callback Manager Priority
  [Documentation]  To verify that the software system is able to run with fluctuating/high load
  ...              for a long time without unexpected consequences.
  [Tags]  TGW2.0  TGW2.1  ManualTest

    Fail  Manual test  ManualTest

#*************************************************************************************************
# WATCHDOG_TIM
#*************************************************************************************************
Misc Watchdog Timer
  [Documentation]  To verify that the watchdog timer API works as expected.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Misc Watchdog  ${SERIAL_HANDLE}
  Should be equal  ${result}  SUCCESS

  CANoe Set Power Supply Off  VBAT
  Sleep  1s
  CANoe Set Power Supply On  VBAT
  Sleep  2s

  # Load RTOSE and TestApp, connect to telnet
  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  BSP TestCase Teardown

#*************************************************************************************************
# BSP_VER
#*************************************************************************************************
Misc BSP Version
  [Documentation]  To verify that the BSP version is returned correctly.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Misc Get BSP Version  ${TELNET_HANDLE}
  Should be equal  ${result}  BSP version is ${BSP_VERSION} (major.minor)

  BSP TestCase Teardown

#*************************************************************************************************
# TGW_HW_VER
#*************************************************************************************************
Misc TGW HW Version
  [Documentation]  To verify that the TGW variant is returned correctly.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Misc Get TGW HW Version  ${TELNET_HANDLE}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.1'
  ...  Should be equal  ${result}  HW Product version is 2.1 (major.minor)
  ...  ELSE
  ...  Should be equal  ${result}  HW Product version is 2.0 (major.minor)

  BSP TestCase Teardown

#*************************************************************************************************
# GSM_ANTENNA_SEL
#*************************************************************************************************
Misc GSM Antenna Selection
  [Documentation]  To verify that the antenna selection is working correctly.
  ...              Note: The antenna cannot be selected on TGW2.1 with AGS2-E modem.

  [Tags]  TGW2.0  TGW2.1  ManualTest

  # Measurements inside TGW box
  Fail  Manual test  ManualTest

#*************************************************************************************************
# TFTP_TEST
#*************************************************************************************************
Misc TFTP
  [Documentation]  To verify that TFTP transfers work correctly.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}=  Check POLO Or OS Running  ${SERIAL_HANDLE}
  Should be equal  ${result}  OS is running

  ${result}  Remove File From TGW If Existing  ${SERIAL_HANDLE}  flash_test_file.bin  /flash/
  Should be equal  ${result}  FILE_REMOVED_OK

  ${result}  Misc TFTP  ${SERIAL_HANDLE}  flash_test_file.bin  /flash/  ${TFTP_SPEED}
  Should be equal  ${result}  SUCCESS

  ${result}  Remove File From TGW If Existing  ${SERIAL_HANDLE}  flash_test_file.bin  /flash/
  Should be equal  ${result}  FILE_REMOVED_OK

  BSP TestCase Teardown

#*************************************************************************************************
# OS_BOOT_TIME
#*************************************************************************************************
Misc OS Boot Time
  [Documentation]  To verify the time it takes the OS to start.
  [Tags]  TGW2.0  TGW2.1  RemainingWork

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ## Download OSE with test application built in
  ${result}  Write OSE TST To TGW And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

  LOG  RemainingWork: Reboot time measured from reset until string "Hit return to avoid" is measured.
  ${result}  Misc Reset and measure time  ${SERIAL_HANDLE}  ${BOOT_TIME}
  Should be equal  ${result}  SUCCESS

  ${result}=  Check POLO Or OS Running  ${SERIAL_HANDLE}
  Should be equal  ${result}  OS is running

  Remove Z Flag From OSE TST Image  ${SERIAL_HANDLE}

  BSP TestCase Teardown

#*************************************************************************************************
# CALLSTACK_TEST
#*************************************************************************************************
Misc Callstack
  [Documentation]  To verify that callstack backtrace is working.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  Sleep  1.0s

  ${result}  Install Callstack Test App  ${SERIAL_HANDLE}
  Should be equal  ${result}  CALLSTACK INSTALL SUCCESS

  Sleep  1.0s

  ${result}  Misc Callstack  ${SERIAL_HANDLE}  unmapped_w
  Should be equal  ${result}  SUCCESS

  ${result}  Wait For Polo Boot  ${SERIAL_HANDLE}
  Should be equal  ${result}  POLO_BOOT_OK

  ${result}  Check Callstack Unmapped Ram Log  ${SERIAL_HANDLE}
  Should be equal  ${result}  SUCCESS

  Reset TGW  ${SERIAL_HANDLE}
  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  Sleep  1.0s

  ${result}  Install Callstack Test App  ${SERIAL_HANDLE}
  Should be equal  ${result}  CALLSTACK INSTALL SUCCESS

  Sleep  1.0s

  ${result}  Misc Callstack  ${SERIAL_HANDLE}  user_error
  Should be equal  ${result}  SUCCESS

  ${result}  Wait For Polo Boot  ${SERIAL_HANDLE}
  Should be equal  ${result}  POLO_BOOT_OK

  ${result}  Check Callstack User Error Ram Log  ${SERIAL_HANDLE}
  Should be equal  ${result}  SUCCESS

#*************************************************************************************************
# WATCHDOG_STARTUP
#*************************************************************************************************
Misc Watchdog Startup
  [Documentation]  To verify that the BSP will configure WDOG with a 128s reset period as early as
  ...              possible at system startup.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Wait For Polo Boot  ${SERIAL_HANDLE}
  Should be equal  ${result}  POLO_BOOT_OK

  Flush Serial Input  ${SERIAL_HANDLE}

  ${result}  Misc Watchdog Startup Test  ${SERIAL_HANDLE}
  Should be equal  ${result}  SUCCESS

  ${result}  Wait For Polo Boot  ${SERIAL_HANDLE}
  Should be equal  ${result}  POLO_BOOT_OK

  BSP TestCase Teardown

#*************************************************************************************************
# RESET_TEST
#*************************************************************************************************
Misc Reset
  [Documentation]  To verify that latest modification from init_script_gcc.S is working.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ## Download OSE with test application built in and set Z flag
  ${result}  Write OSE TST To TGW And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

  CANoe Set Power Supply Off  VBAT
  Sleep  1s
  CANoe Set Power Supply On  VBAT

  ${result}  Misc Reset Test  ${SERIAL_HANDLE}
  Should be equal  ${result}  SUCCESS

  CANoe Set Power Supply Off  VBAT
  Sleep  1s
  CANoe Set Power Supply On  VBAT

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  Sleep  2s

  ${result}  Remove Z Flag From OSE TST Image  ${SERIAL_HANDLE}
  Should be equal  ${result}  FLAG_REMOVED_OK

  BSP TestCase Teardown

#*************************************************************************************************
# LOCK_UNLOCK
#*************************************************************************************************
Misc Lock And Unlock
  [Documentation]  To verify that lock/unlock mechanism added in fam_cfi.c works.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Wait For Polo Boot  ${SERIAL_HANDLE}
  Should be equal  ${result}  POLO_BOOT_OK

  Sleep  2s

  Flush Serial Input  ${SERIAL_HANDLE}

  ${result}  Misc Get Locked Sectors  ${SERIAL_HANDLE}  ${FLASH_SIZE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:['0xa0200000', '0xa0220000', '0xa0240000', '0xa0260000']

  ${result}  Misc Lock Sector  ${SERIAL_HANDLE}  0xa0000000
  Should be equal  ${result}  TGW_TEST_SUCCESS:SECTOR_LOCKED

  ${result}  Misc Lock Sector  ${SERIAL_HANDLE}  0xa0000000
  Should be equal  ${result}  TGW_TEST_SUCCESS:SECTOR_ALREADY_LOCKED

  ${result}  Misc Lock Sector  ${SERIAL_HANDLE}  0xa0200000
  Should be equal  ${result}  TGW_TEST_SUCCESS:SECTOR_ALREADY_LOCKED

  ${result}  Misc Get Locked Sectors  ${SERIAL_HANDLE}  ${FLASH_SIZE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:['0xa0000000', '0xa0200000', '0xa0220000', '0xa0240000', '0xa0260000']

  # Unlock
  ${result}  Misc Unlock Sector  ${SERIAL_HANDLE}  0xa0000000
  Should be equal  ${result}  TGW_TEST_SUCCESS:SECTOR_UNLOCKED

  # Check
  ${result}  Misc Get Locked Sectors  ${SERIAL_HANDLE}  ${FLASH_SIZE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:[]

  # Reset
  Reset TGW  ${SERIAL_HANDLE}

  # Wait Boot Polo
  ${result}  Wait For Polo Boot  ${SERIAL_HANDLE}
  Should be equal  ${result}  POLO_BOOT_OK

  # Check
  ${result}  Misc Get Locked Sectors  ${SERIAL_HANDLE}  ${FLASH_SIZE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:['0xa0200000', '0xa0220000', '0xa0240000', '0xa0260000']

  BSP TestCase Teardown

#*************************************************************************************************
# SIM_MIM_SWITCH
#*************************************************************************************************
Misc SIM or MIM Selection
  [Documentation]  To verify that the BSP supports the hardware capability to use either a SIM or
  ...              a MIM card along with the modems.
  [Tags]  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Misc Get Ram Log For Sim Or Mim  ${SERIAL_HANDLE}
  Should be equal  ${result}  SIM/MIM select: SIM.

  BSP TestCase Teardown

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown