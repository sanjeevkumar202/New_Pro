*** Settings ***
Documentation  This test suite will verify the bootloader behaviour.
Library  Robot/Libs/Bsp/BspCommonTester.py

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

  BSP TestSuite Setup TFTP Boot

  ## Download OSE with test application built in
  ${result}  Write OSE To TGW And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

#*************************************************************************************************
# BOOTLDR_PBL_JEFF_READER
#*************************************************************************************************
Bootloader PBL JEFF Reader
  [Documentation]  To verify that the PBL can execute an elf file on the JEFF volume marked as
  ...              "startup file", using the JEFF Boot Reader support.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  CANoe Set Power Supply Off  VBAT
  Sleep  2.0
  CANoe Set Power Supply On  VBAT

  # OSE is written to flash in TestSuite Start
  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  Remove Z Flag From OSE Image  ${SERIAL_HANDLE}
  Should be equal  ${result}  FLAG_REMOVED_OK

  BSP TestCase Teardown

#*************************************************************************************************
# BOOTLDR_SBL_LOAD_AND_JEFF
#*************************************************************************************************
Bootloader SBL Load And JEFF Support
  [Documentation]  To verify that SBL can be executed by PBL and contains support for the JEFF
  ...              file system.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Wait For Polo Boot  ${SERIAL_HANDLE}
  Should be equal  ${result}  POLO_BOOT_OK

  ${result}  Load SBL  ${SERIAL_HANDLE}
  Should be equal  ${result}  LOAD_SBL_OK

  BSP TestCase Teardown

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown

