*** Settings ***
Documentation  Robot Framework test start
Resource  Robot/Libs/Bsp/BspResources.robot
Library  Robot/Libs/Bsp/BspGsmTester.py
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspPwrMgmtTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py

*** Variables ***
${DEBUG}  ${1}
@{START_DELAYS} =  0.5  0.7  0.9  1.1  1.3  1.5  1.7  1.9  2.1
${RLD_OPTION_P0}
${RLD_OPTION_P1}  -p 1
${RLD_OPTION_P2}  -p 2

*** Keywords ***

RunPowerFailAtBoot
  [Documentation]  Keword used for cutting the power while OSE is booting.
  [Arguments]  ${delay}

  LOG  ${delay}
  CANoe Set Power Supply Off  VBAT
  Sleep  2.0
  CANoe Set Power Supply On  VBAT
  Sleep  ${delay}
  CANoe Set Power Supply Off  VBAT
  Sleep  2.0
  CANoe Set Power Supply On  VBAT

  ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  ${result}  check_ram_log_for_flash_state  ${SERIAL_HANDLE}  ${RLD_OPTION_P0}
  Should be equal  ${result}  FLASH_STATE_OK

  Sleep  2.0

  ${result}  check_ram_log_for_flash_state  ${SERIAL_HANDLE}  ${RLD_OPTION_P1}
  Should be equal  ${result}  FLASH_STATE_OK

  Sleep  2.0

  ${result}  check_ram_log_for_flash_state  ${SERIAL_HANDLE}  ${RLD_OPTION_P2}
  Should be equal  ${result}  FLASH_STATE_OK


*** Test Cases ***

TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Setup TFTP Boot

  ## Download OSE with test application built in
  ${result}  Write OSE TST To TGW And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK

#*************************************************************************************************
# POWER_FAIL
#*************************************************************************************************
Power Fail At OSE Boot
  [Documentation]  Verify that the TGW can handle sudden power loss when booting OSE (To verify that on power failure the flash access is cut)
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1  DevTrack_11514

  BSP TestCase Setup

  RunPowerFailAtBoot  0.4
  RunPowerFailAtBoot  0.5
  RunPowerFailAtBoot  0.6
  RunPowerFailAtBoot  0.7
  RunPowerFailAtBoot  0.8
  RunPowerFailAtBoot  0.9
  RunPowerFailAtBoot  1.0
  RunPowerFailAtBoot  1.1
  RunPowerFailAtBoot  1.3
  RunPowerFailAtBoot  1.5
  RunPowerFailAtBoot  1.7
  RunPowerFailAtBoot  1.9
  RunPowerFailAtBoot  2.1

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


