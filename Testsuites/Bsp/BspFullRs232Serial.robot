*** Settings ***
Documentation  This test suite will verify the serial driver.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspFullSerialTester.py

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
# SERIAL_COMM_MODEM_CTRL
#*************************************************************************************************
RS232 Serial Comm Modem Ctrl
  [Documentation]  To verify that the serial driver is able to get/set status of modem control lines.
  ...              The test connection will have the following parameters 8 data bits, 1 stop bit,
  ...              no parity and hardware flow control. Note: DTR is not checked.
  [Tags]  TGW2.0  TGW2.1  DevTrack_11874

  ${result}  Full Serial Port RTS CTS Test  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# SERIAL_COMM_HW_FLOW_CTRL
#*************************************************************************************************
RS232 Serial Comm Hw Flow Ctrl
  [Documentation]  To verify that the serial driver is able to set and use hardware flow control
  ...              in hardware. The test connection will have the following parameters 8 data
  ...              bits, 1 stop bit, no parity and hardware flow control.
  [Tags]  TGW2.0  TGW2.1  TGW2.1  DevTrack_11874

  ${result}  Full Serial Port HW Flow Control Test  ${SERIAL_HANDLE}  9600
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Full Serial Port HW Flow Control Test  ${SERIAL_HANDLE}  19200
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Full Serial Port HW Flow Control Test  ${SERIAL_HANDLE}  38400
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Full Serial Port HW Flow Control Test  ${SERIAL_HANDLE}  57600
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Full Serial Port HW Flow Control Test  ${SERIAL_HANDLE}  115200
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# SERIAL_COMM_PARAM_115K
#*************************************************************************************************
RS232 Serial Comm Param 115k
  [Documentation]  To verify that the serial driver is able to handle all parameters supported by
  ...              the full RS232 UART.
  [Tags]  TGW2.0  TGW2.1  TGW2.1  DevTrack_11874

  Fail  Test Not Implemented  NotImplemented


#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown