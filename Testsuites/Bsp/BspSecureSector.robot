*** Settings ***
Documentation  This test suite will verify that the BSP handles the secure sector correctly.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspSecureSectTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***

*** Keywords ***

*** Test Cases ***
#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1

  ${result}  BSP TestSuite Setup TFTP Boot
  Should be equal  ${result}  SETUP_TFTP_BOOT_COMPLETED

#*************************************************************************************************
# SECURE_SECTOR_READ
#*************************************************************************************************
Secure Sector Read
  [Documentation]  To verify that the BSP correctly reads data from secure sector. Tests that
  ...              erasing of secure sector is not allowed.
  [Tags]  TGW2.0  TGW2.1

  ${result}  Verify MAC Addr Between SS And Ifconfig  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Try To Erase Secure Sector  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Verify MAC Addr Between SS And Ifconfig  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# SECURE_SECTOR_MAC_USB_ID
#*************************************************************************************************
Secure Sector MAC And USB ID
  [Documentation]  To verify that the BSP correctly reads and uses the MAC address and USB IDs
  ...              from secure sector
  [Tags]  TGW2.0  TGW2.1

  ${result}  Verify MAC Addr Between SS And Ifconfig  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Read TGW USB Vendor ID  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:103A

  ${result}  Read TGW USB Product ID  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:F00F

#*************************************************************************************************
# Test Suite End
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Teardown