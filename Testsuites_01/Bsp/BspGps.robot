*** Settings ***
Documentation  Robot Framework test start
Resource  Robot/Libs/Bsp/BspResources.robot
Library  Robot/Libs/Bsp/BspGpsTester.py
Library  Robot/Libs/Bsp/BspGsmTester.py
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py

*** Variables ***
${DEBUG}  ${1}

${POSITION_ACC}  0.00008

*** Keywords ***
Get AC Buildning Reference Position
    ${ac_position}  Create Dictionary  latitude=57.7154018333  longitude=11.9191813333
    [return]     ${ac_position}

*** Test Cases ***

TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0
  BSP TestSuite Setup TFTP Boot

#*************************************************************************************************
# GPS_COMM
#*************************************************************************************************
GPS Communication Test
  [Documentation]  To verify that the GPS driver is able to setup serial communication
  ...              between Application and GPS device. The communication will take place at
  ...              4800bps, 8 data bits, 1 stop bit, no parity and no flow control.
  ...              The GPS device will be reset whereas NMEA data will be read and verified.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  GPS SW Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  # Wait until GPS has connection to sattelites before reding position
  Sleep  25s

  ${meas_pos}  Get NMEA Data  ${SERIAL_HANDLE}
  LOG  ${meas_pos}

  ${ac_ref_pos}  Get AC Buildning Reference Position

  ${pos_result}  Check GPS Position  ${meas_pos}  ${ac_ref_pos}  ${POSITION_ACC}
  Should Be Equal  ${pos_result}  ${True}

  BSP TestCase Teardown

#*************************************************************************************************
# GPS_RESET
#*************************************************************************************************
GPS Reset
  [Documentation]  To verify that the GPS driver is able to reset the GPS module for at least
  ...              100ms.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# GPS_TIMEPULSE
#*************************************************************************************************
GPS Get Timepulse
  [Documentation]  To verify that the GPS driver is able to issue a timepulse and that the inputs
  ...              driver can capture them. Count and verify the accuracy. For TGW2.1, the test
  ...              verify the timepulse issued from GNSS device on the AGS2 modem and it is covered
  ...              by the tst_gps –demo.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  IssueTGWIISP-506

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  GPS Generate Timepulse  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  BSP TestCase Teardown

#*************************************************************************************************
# Test Suite End
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0
  BSP TestSuite Teardown
