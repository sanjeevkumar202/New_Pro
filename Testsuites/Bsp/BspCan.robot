*** Settings ***
Documentation  This test suite will verify the CAN driver.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspCanTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${DEBUG}  ${1}

*** Keywords ***

*** Test Cases ***
#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Setup TFTP Boot

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}=  Check POLO Or OS Running  ${SERIAL_HANDLE}
  Should be equal  ${result}  OS is running

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

#*************************************************************************************************
# CAN_125KBPS_COMM
#*************************************************************************************************
CAN 125KBPS Communication
  [Documentation]  To verify that the CAN driver is able to send and receive both standard and
  ...              extended messages on CAN interface at 125kbps.
  [Tags]  TGW2.0  TGW2.1

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  125  False
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  125  True
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# CAN_250KBPS_COMM
#*************************************************************************************************
CAN 250KBPS Communication
  [Documentation]  To verify that the CAN driver is able to send and receive both standard and
  ...              extended messages on CAN interface at 250kbps.
  [Tags]  TGW2.0  TGW2.1

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  250  False
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  250  True
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# CAN_500KBPS_COMM
#*************************************************************************************************
CAN 500KBPS Communication
  [Documentation]  To verify that the CAN driver is able to send and receive both standard and
  ...              extended messages on CAN interface at 500kbsp.
  [Tags]  TGW2.0  TGW2.1

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  500  False
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  500  True
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# CAN_1MBPS_COMM
#*************************************************************************************************
CAN 1MBPS Communication
  [Documentation]  To verify that the CAN driver is able to send and receive both standard and
  ...              extended messages on CAN interface at 1Mbps.
  [Tags]  TGW2.0  TGW2.1

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  1000  False
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Run Enea Can Test  ${SERIAL_HANDLE}  1000  True
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# CAN_FILTER
#*************************************************************************************************
CAN Filter
  [Documentation]  To verify that the CAN driver is able to filter messages on CAN2 both standard
  ...              and extended.
  [Tags]  TGW2.0  TGW2.1

  ${result}  Run Enea Filter Can Test  ${SERIAL_HANDLE}  False
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  Run Enea Filter Can Test  ${SERIAL_HANDLE}  True
  Should be equal  ${result}  TGW_TEST_SUCCESS

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown
