*** Settings ***
Documentation  This test suite will verify the Flash memory handling of the TGW device.

Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py
Library  Robot/Libs/Bsp/BspFlashTester.py

Resource  Robot/Libs/Bsp/BspResources.robot


*** Variables ***
${FLASH_FILE_SIZE}  2
${FILE_WR_COMPLETE_TIMEOUT}  180.0
${FLASH_ERASE_WR_SECT}  32
${FLASH_ERASE_WR_TIMEOUT}  30.0

${RLD_OPTION_P0}


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

  ${result}  check_ram_log_for_flash_state  ${SERIAL_HANDLE}  ${RLD_OPTION_P0}
  Should be equal  ${result}  FLASH_STATE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  # Only used assciated with the file system
  ${result}  Set Flash Write Size  ${TELNET_HANDLE}  ${FLASH_FILE_SIZE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:FILE_SIZE_SET_OK

Run Power Fail At File Download
  [Documentation]  Keword used for starting download of a file and then cutting the power
  ...              while a file is written to flash. Checks that the flash state is ok after
  ...              reboot.
  [Arguments]  ${delay}

  LOG  ${delay}
  CANoe Set Power Supply Off  VBAT
  Sleep  2.0
  CANoe Set Power Supply On  VBAT

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  Remove File From TGW If Existing  ${SERIAL_HANDLE}  flash_test_file.bin  /flash/
  Should be equal  ${result}  FILE_REMOVED_OK

  ${result}  Download File To TGW From TFTP  ${SERIAL_HANDLE}  flash_test_file.bin  /flash/
  Should be equal  ${result}  FILE_DOWNLOAD_STARTED_OK

  Sleep  ${delay}

  CANoe Set Power Supply Off  VBAT
  Sleep  2.0
  CANoe Set Power Supply On  VBAT

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  check_ram_log_for_flash_state  ${SERIAL_HANDLE}
  Should be equal  ${result}  FLASH_STATE_OK

*** Test Cases ***
#*************************************************************************************************
# Test Suite Start
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Setup TFTP Boot

  ## Download OSE with test application built in
  ${result}  Write OSE TST To TGW And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

TestSuite Start Small FS
  [Documentation]  Set Up the test suite for the special TGW containing mostly Flash tests
  [Tags]  FLASH_SMALL_FS_TEST
  BSP TestSuite Setup TFTP Small FS Boot

  ## Download OSE with test application built in
  ${result}  Write OSE Small FS TST To TGW And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

Power Fail At File Download Via TFTP
  [Documentation]  Download a file from TFTP and cut power during file transfer to ensure that the Flash memory
  ...              is handled correctly.

  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  Run Power Fail At File Download  0.5
  Run Power Fail At File Download  1.0
  Run Power Fail At File Download  5.0

  CANoe Set Power Supply Off  VBAT

Power Fail At File Write
  [Documentation]  Cut the power when a file is written to flash. Content to the file will be appended when
  ...              writing is resumed after next boot.

  [Tags]  TGW2.0  TGW2.1  FLASH_SMALL_FS_TEST

  BSP TestCase Setup

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Remove File From TGW If Existing  ${SERIAL_HANDLE}  tst_flash.dat  /flash/
  Should be equal  ${result}  FILE_REMOVED_OK

  ${result}  Set Flash Write Size  ${TELNET_HANDLE}  ${FLASH_FILE_SIZE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:FILE_SIZE_SET_OK

  ${result}  Create File On Flash And Start Writing  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  Wait And Cycle Power And Restore Telnet  0.5

  ${result}  Open File And Continue Writing  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  Wait And Cycle Power And Restore Telnet  2.0

  ${result}  Open File And Continue Writing  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  Wait And Cycle Power And Restore Telnet  3.5

  ${result}  Open File And Continue Writing  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  Wait And Cycle Power And Restore Telnet  1.5

  ${result}  Open File And Continue Writing  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  Wait And Cycle Power And Restore Telnet  1.2

  # We have to kick the dog unless the TGW will restart due to the long time it takes to write the file
  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  ${result}  Open File And Continue Writing To End  ${TELNET_HANDLE}  ${FILE_WR_COMPLETE_TIMEOUT}
  Should be equal  ${result}  TGW_TEST_SUCCESS:FILE_WRITE_COMPLETE

  ${result}  Verify File On Flash  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  BSP TestCase Teardown

#*************************************************************************************************
# Test Suite End
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  Remove Z Flag From OSE TST Image  ${SERIAL_HANDLE}

  BSP TestSuite Teardown

  CANoe Close Application

TestSuite End Small FS
  [Documentation]  Cleanup the test suite
  [Tags]  FLASH_SMALL_FS_TEST

  Remove Z Flag From OSE Small FS TST Image  ${SERIAL_HANDLE}

  BSP TestSuite Teardown

  CANoe Close Application