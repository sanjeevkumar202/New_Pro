*** Settings ***
Documentation  This test suite will verify the J1708 driver.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspJ1708Tester.py
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
# J1708_COMM
#*************************************************************************************************
J1708 Communication
  [Documentation]  To verify that the J1708 driver is able to setup serial communication and to
  ...              send a message on serial link at 9600, 57600, 38400, 19200, 14400 and 115200bps
  ...              speeds.
  [Tags]  TGW2.0  TGW2.1

  Canoe Vt2516 Set Relay Org Component Active  J1708A
  Canoe Vt2516 Set Relay Org Component Active  J1708B

  Sleep  5.0

  ${result}  J1708 Communication Test  ${SERIAL_HANDLE}  9600
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  J1708 Communication Test  ${SERIAL_HANDLE}  14400
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  J1708 Communication Test  ${SERIAL_HANDLE}  19200
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  J1708 Communication Test  ${SERIAL_HANDLE}  38400
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  J1708 Communication Test  ${SERIAL_HANDLE}  57600
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  J1708 Communication Test  ${SERIAL_HANDLE}  115200
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# J1708_NETCAP
#*************************************************************************************************
J1708 Network Capacity
  [Documentation]  To verify that the J1708 driver is able to setup serial communication and to
  ...              send a message on a serial link that is fully loaded.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Test Not Implemented  NotImplemented

#*************************************************************************************************
# J1708_BITTIME
#*************************************************************************************************
J1708 Bittime
  [Documentation]  To verify that the J1708 bit timing is according to SAE J1708/OCT93
  ...              (104.17 us +-0.5%) for both logical "1" and "0"
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest


#*************************************************************************************************
# J1708_BAUDRATE
#*************************************************************************************************
J1708 Baudrate
  [Documentation]  To verify that the J1708 data rate is 9600 bits per second +/-0.5%.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest


#*************************************************************************************************
# J1708_MSGLEN
#*************************************************************************************************
J1708 Msglen
  [Documentation]  To verify that the J1708 message length is according to specifications (a
  ...              character consists of 10 bits, 1 start bit, 8 data bits and 1 stop bit. The
  ...              length of time between each characters within a message shall not exceed 2 bit
  ...              times, (208 us), measured from the first start bit in the message to the last
  ...              "0" in the message)
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest


#*************************************************************************************************
# J1708_TX_LATENCY
#*************************************************************************************************
J1708 TX Latency
  [Documentation]  To verify that the J1708 transmit latency is according to specifications (a
  ...              device transmitting should detect that idle state continues to exist
  ...              immediately prior to initiating a transmission. (This is, within one-half bit
  ...              time) according to SAE J1708/OCT93-4.2.1 Bus access)
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest


#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown
