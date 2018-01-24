*** Settings ***
Documentation  This test suite will verify the RTC driver.
Library  Robot/Libs/Bsp/BspRtcTester.py
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspPwrMgmtTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${DEBUG}  ${1}
${DELAY}  ${40}
${ADJUSTED_DELAY}  ${39.8}

*** Keywords ***

*** Test Cases ***
#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Setup TFTP Boot

  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  0
  Should Be Equal  ${result}  Clear alarm #0 succedded.
  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  1
  Should Be Equal  ${result}  Clear alarm #1 succedded.

#*************************************************************************************************
# RTC_DEMO
#*************************************************************************************************
RTC Demo
  [Documentation]  Test to verify the RTC driver. The sequence of operations this test does is:
  ...              RTC get time test, RTC set time test, RTC alarm 0 set test, clear first alarm,
  ...              set alarm 1, get alarm.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  RTC Demo  ${TELNET_HANDLE}
  Should Be Equal   ${result}  RTC test PASSED.

  BSP TestCase Teardown

#*************************************************************************************************
# RTC_TIME
#*************************************************************************************************
RTC Check Time
  [Documentation]  Test to verify the RTC timing.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  RTC Set Time  ${TELNET_HANDLE}  1:1:2009:1:0:02
  ${startTime}  RTC Get Time  ${TELNET_HANDLE}
  Sleep  ${ADJUSTED_DELAY}
  ${stopTime}  RTC Get Time  ${TELNET_HANDLE}

  ${result}  RTC Verify Time  ${startTime}  ${stopTime}  ${DELAY}
  Should Be Equal  ${result}  SUCCESS

  BSP TestCase Teardown

#*************************************************************************************************
# RTC_WAKEUP_BY_ALARM_0
#*************************************************************************************************
RTC Wakeup By Alarm 0
  [Documentation]  To verify that the RTC alarm 0 handling works properly.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  RTC Get Alarm  ${TELNET_HANDLE}  0
  Should Be Equal  ${result}  Error geting alarm.

  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  0
  Should Be Equal  ${result}  Clear alarm #0 succedded.
  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  1
  Should Be Equal  ${result}  Clear alarm #1 succedded.

  ${result}  RTC Set Time  ${TELNET_HANDLE}  1:1:2009:1:0:50
  Should Be Equal  ${result}  1:1:2009:1:0:50.

  ${result}  RTC Set Alarm  ${TELNET_HANDLE}  0  1:1:1:10
  Log  Alarm 0: day:hour:min:sec
  Should Be Equal  ${result}  1:1:1:10 alarm#0.

  Pow off  ${SERIAL_HANDLE}  8  ${DEBUG}

  Sleep  15s

  #The PLD should power down the board and wake up 10 sec later.

  # Load RTOSE and TestApp, connect to telnet
  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #After reloading rtose and test app run:
  ${result}=  Pow Get Wsrc  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Wakeup source <WAKEUP_RTC_IMU> active.

  BSP TestCase Teardown

#*************************************************************************************************
# RTC_WAKEUP_BY_ALARM_1
#*************************************************************************************************
RTC Wakeup By Alarm 1
  [Documentation]  To verify that the RTC alarm 1 handling works properly.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  RTC Get Alarm  ${TELNET_HANDLE}  1
  Should Be Equal  ${result}  Error geting alarm.

  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  0
  Should Be Equal  ${result}  Clear alarm #0 succedded.
  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  1
  Should Be Equal  ${result}  Clear alarm #1 succedded.

  ${result}  RTC Set Time  ${TELNET_HANDLE}  1:1:2009:1:0:45
  Should Be Equal  ${result}  1:1:2009:1:0:45.

  ${result}  RTC Set Alarm  ${TELNET_HANDLE}  1  1:1:1:10
  Log  Alarm 1: day:hour:min (sec set to 0)
  Should Be Equal  ${result}  1:1:1:0 alarm#1.

  Pow off  ${SERIAL_HANDLE}  8  ${DEBUG}

  #The PLD should power down the board and wake up 10 sec later.
  Sleep  15s

  # Load RTOSE and TestApp, connect to telnet
  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #After reloading rtose and test app run:
  ${result}=  Pow Get Wsrc  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Wakeup source <WAKEUP_RTC_IMU> active.

  BSP TestCase Teardown

#*************************************************************************************************
# RTC_GET_ERRORS
#*************************************************************************************************
RTC Get Errors
  [Documentation]  To verify that the RTC status handling works properly.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  RTC Get Status  ${TELNET_HANDLE}
  Should Be Equal  ${result}  RTC status OK.

  BSP TestCase Teardown

#*************************************************************************************************
# RTC_CANCEL_ALARM
#*************************************************************************************************
RTC Cancel Alarm
  [Documentation]  To verify that the RTC alarm canceling works properly.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  RTC Set Time  ${TELNET_HANDLE}  1:1:2009:1:1:1
  Should Be Equal  ${result}  1:1:2009:1:1:1.

  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  0
  Should Be Equal  ${result}  Clear alarm #0 succedded.

  ${result}  RTC Set Alarm  ${TELNET_HANDLE}  0  1:1:1:12
  Should Be Equal  ${result}  1:1:1:12 alarm#0.

  Sleep  3s

  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  0
  Should Be Equal  ${result}  Clear alarm #0 succedded.

  Sleep  1s

  ${result}  RTC Set Alarm  ${TELNET_HANDLE}  0  1:1:1:30
  Should Be Equal  ${result}  1:1:1:30 alarm#0.

  ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  0
  Should Be Equal  ${result}  Clear alarm #0 succedded.
    ${result}  RTC Clear Alarm  ${TELNET_HANDLE}  1
  Should Be Equal  ${result}  Clear alarm #1 succedded.

  BSP TestCase Teardown

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Teardown