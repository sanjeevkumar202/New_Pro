*** Settings ***
Documentation  This test suite will verify the Flash memory handling of the TGW device.

Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py
Library  Robot/Libs/Bsp/BspFlashTester.py

Resource  Robot/Libs/Bsp/BspResources.robot


*** Variables ***
${FLASH_ERASE_WR_SECT}  32
${FLASH_ERASE_WR_TIMEOUT}  30.0
${RLD_OPTION_P0}
${RLD_OPTION_P1}  -p 1
${POWER_RESTORED_TELNET_CONNECTED}  POWER_RESTORED_TELNET_CONNECTED

*** Keywords ***
Wait And Cycle Power And Restore Telnet
  [Documentation]  Keword used for cutting the power while a file is written to flash.
  ...              Checks that the flash state is ok after reboot.
  [Arguments]  ${delay}

  Sleep  ${delay}

  LOG  ${delay}
  CANoe Set Power Supply Off  VBAT
  Sleep  2.0
  CANoe Set Power Supply On  VBAT

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  check_ram_log_for_flash_state  ${SERIAL_HANDLE}  ${RLD_OPTION_P1}
  Should be equal  ${result}  FLASH_STATE_OK

  ${result}  check_ram_log_for_flash_state  ${SERIAL_HANDLE}  ${RLD_OPTION_P0}
  Should be equal  ${result}  FLASH_STATE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  # Only used outside the file system
  ${result}  Set Num Erase WR Sectors  ${TELNET_HANDLE}  ${FLASH_ERASE_WR_SECT}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  [Return]  ${POWER_RESTORED_TELNET_CONNECTED}

*** Test Cases ***
#*************************************************************************************************
# Test Suite Start
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite for the special TGW containing mostly Flash tests
  [Tags]  FLASH_SMALL_FS_TEST
  BSP TestSuite Setup TFTP Small FS Boot

  ## Download OSE with test application built in
  ${result}  Write OSE Small FS TST To TGW And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

Flash Erase
  [Documentation]  Erase 32 sectors of the Flash outside the file system
  [Tags]  FLASH_SMALL_FS_TEST

  BSP TestCase Setup

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Set Num Erase WR Sectors  ${SERIAL_HANDLE}  ${FLASH_ERASE_WR_SECT}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Erase Raw Flash On TGW To End  ${SERIAL_HANDLE}  ${FLASH_ERASE_WR_TIMEOUT}
  Should be equal  ${result}  TGW_TEST_SUCCESS:FLASH_ERASE_COMPLETE

  BSP TestCase Teardown

Power Fail At Direct Flash Write
  [Documentation]  Cut the power when writing directly to flash. Content to the flash will be appended when
  ...              writing is resumed after next boot.
  [Tags]  FLASH_SMALL_FS_TEST

  BSP TestCase Setup

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Set Num Erase Wr Sectors  ${SERIAL_HANDLE}  ${FLASH_ERASE_WR_SECT}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Erase Raw Flash On TGW To End  ${SERIAL_HANDLE}  ${FLASH_ERASE_WR_TIMEOUT}
  Should be equal  ${result}  TGW_TEST_SUCCESS:FLASH_ERASE_COMPLETE

  ${result}  Write Raw Flash On TGW  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Wait And Cycle Power And Restore Telnet  0.5
  Should be equal  ${result}  POWER_RESTORED_TELNET_CONNECTED

  ${result}  Write Raw Flash On TGW  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Wait And Cycle Power And Restore Telnet  2.0
  Should be equal  ${result}  POWER_RESTORED_TELNET_CONNECTED

  ${result}  Write Raw Flash On TGW  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Wait And Cycle Power And Restore Telnet  3.5
  Should be equal  ${result}  POWER_RESTORED_TELNET_CONNECTED

  ${result}  Write Raw Flash On TGW  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Wait And Cycle Power And Restore Telnet  5.5
  Should be equal  ${result}  POWER_RESTORED_TELNET_CONNECTED

  # We have to kick the dog unless the TGW will restart due to the long time it takes to write the file
  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  ${result}  Write Raw Flash On TGW To End  ${SERIAL_HANDLE}  ${FLASH_ERASE_WR_TIMEOUT}
  Should be equal  ${result}  TGW_TEST_SUCCESS:FILE_WRITE_COMPLETE

  BSP TestCase Teardown

Power Fail When Flash Erase
  [Documentation]  Erase 32 sectors of the Flash outside the file system
  [Tags]  FLASH_SMALL_FS_TEST

  BSP TestCase Setup

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Set Num Erase WR Sectors  ${SERIAL_HANDLE}  ${FLASH_ERASE_WR_SECT}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Erase Raw Flash On TGW  ${SERIAL_HANDLE}
  Should be equal  ${result}  STATUS_FLASH_ERASE_STARTED_OK

  ${result}  Wait And Cycle Power And Restore Telnet  1.5
  Should be equal  ${result}  POWER_RESTORED_TELNET_CONNECTED

  ${result}  Erase Raw Flash On TGW  ${SERIAL_HANDLE}
  Should be equal  ${result}  STATUS_FLASH_ERASE_STARTED_OK

  ${result}  Wait And Cycle Power And Restore Telnet  2.5
  Should be equal  ${result}  POWER_RESTORED_TELNET_CONNECTED

  ${result}  Erase Raw Flash On TGW  ${SERIAL_HANDLE}
  Should be equal  ${result}  STATUS_FLASH_ERASE_STARTED_OK

  ${result}  Wait And Cycle Power And Restore Telnet  3.5
  Should be equal  ${result}  POWER_RESTORED_TELNET_CONNECTED

  ${result}  Erase Raw Flash On TGW To End  ${SERIAL_HANDLE}  ${FLASH_ERASE_WR_TIMEOUT}
  Should be equal  ${result}  TGW_TEST_SUCCESS:FLASH_ERASE_COMPLETE

  # Todo, verify that flash is erased ?

  BSP TestCase Teardown

#*************************************************************************************************
# Test Suite End
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  FLASH_SMALL_FS_TEST

  ${result}  Remove OSE Small FS TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  FILE_REMOVED_OK

  BSP TestSuite Teardown

  CANoe Close Application