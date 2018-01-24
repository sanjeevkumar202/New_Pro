*** Settings ***
Documentation  This test suite will verify the serial driver is able to receive a message
 ...           from a tachometer.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspInfoIfTester.py

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

#*************************************************************************************************
# INFO_IF_COMM_DIGITAL_ACTI
#*************************************************************************************************
#INFO If Communication With Actia Digital Tacho
#  [Documentation]  To verify that the serial driver is able to receive a message on UART5 from a
#  ...              digital tachometer. The test uses a 10400bps 8N1 serial connection.
#  [Tags]  TGW2.0  TGW2.1
#
# NOTE:
# This Tacho is not prio according to Christoffer Nilsson.
#
#  BSP TestCase Setup
#
#  ${result}  Boot And Load  ${SERIAL_HANDLE}
#  Should be equal  ${result}  BOOT_OSE_OK
#
#  ${result}  Connect To Telnet  $(DEBUG)
#  Should be equal  ${result}  CONNECT_TO_TELNET_OK
#
#  ${result}=  Info If Comm Tacho  ${TELNET_HANDLE}  actia
#  ${string}=  Check String Content  ${result}  Received message:
#  #Should be equal  ${string}  Received message:
#  #${string}=  Check String Content  ${result}  INFOIF test PASSED
#  Should be equal  ${string}  INFOIF test PASSED
#
#  BSP TestCase Teardown

#*************************************************************************************************
# INFO_IF_COMM_ANALOG_VOLVO
#*************************************************************************************************
#INFO If Communication With Volvo Analog Tacho
#  [Documentation]  To verify that the serial driver is able to receive a message on UART5 from a
#  ...              VOLVO analog tachometer. The test puts the serial driver in ANALOG_TACHO mode,
#  ...              baud rate 10.66 Hz.
#  [Tags]  TGW2.0  TGW2.1
#
# NOTE:
# This Tacho is not prio according to Christoffer Nilsson
#
#  BSP TestCase Setup
#
#  ${result}  Boot And Load  ${SERIAL_HANDLE}
#  Should be equal  ${result}  BOOT_OSE_OK
#
#  ${result}  Connect To Telnet  $(DEBUG)
#  Should be equal  ${result}  CONNECT_TO_TELNET_OK
#
#  ${result}=  Info If Comm Tacho  ${TELNET_HANDLE}  volvo
#  #${string}=  Check String Content  ${result}  Received message:
#  #Should be equal  ${string}  Received message:
#  ${string}=  Check String Content  ${result}  INFOIF test PASSED
#  Should be equal  ${string}  INFOIF test PASSED
#
#  BSP TestCase Teardown

#*************************************************************************************************
# INFO_IF_COMM_DIGITAL_STONERIDGE
#*************************************************************************************************
INFO If Communication With Stoneridge Digital Tacho
  [Documentation]  To verify that the serial driver is able to receive a message on UART5 from a
  ...              digital tachometer. The test uses a baud rate of 1.200 bps.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #Connect the Stoneridge "pink cable"
  Canoe Set Vts Variable  TachoStoneridge  Relay  1
  ${result}=  Info If Comm Tacho  ${TELNET_HANDLE}  stoneridge  ${DEBUG}
  ${string}=  Check String Content  ${result}  Received message:
  Should be equal  ${string}  Received message:
  ${string}=  Check String Content  ${result}  INFOIF test PASSED
  Should be equal  ${string}  INFOIF test PASSED

  Canoe Set Vts Variable  TachoStoneridge  Relay  0

  BSP TestCase Teardown

#*************************************************************************************************
# INFO_IF_COMM_DIGITAL_SIEMENS_D7
#*************************************************************************************************
INFO If Communication With Siemens Digital Tacho D7
  [Documentation]  To verify that the serial driver is able to receive a message on UART5 from a
  ...              digital tachometer. The test uses a baud rate of X bps. #Todo: Check baudrate
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #Connect the TachoVolvoSiemensD7 "pink cable"
  Canoe Set Vts Variable  TachoVolvoSiemensD7  Relay  1
  ${result}=  Info If Comm Tacho  ${TELNET_HANDLE}  stoneridge  ${DEBUG}
  ${string}=  Check String Content  ${result}  Received message:
  Should be equal  ${string}  Received message:
  ${string}=  Check String Content  ${result}  INFOIF test PASSED
  Should be equal  ${string}  INFOIF test PASSED

  #Set Default
  Canoe Set Vts Variable  TachoVolvoSiemensD7  Relay  0

  BSP TestCase Teardown

#*************************************************************************************************
# INFO_IF_COMM_DIGITAL_SIEMENS_D8
#*************************************************************************************************
INFO If Communication With Siemens Digital Tacho D8
  [Documentation]  To verify that the serial driver is able to receive a message on UART5 from a
  ...              digital tachometer. The test uses a baud rate of X bps. #Todo: Check baudrate
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #Connect the TachoVolvoSiemensD8 "pink cable"
  Canoe Set Vts Variable  TachoVolvoSiemensD8  Relay  1
  ${result}=  Info If Comm Tacho  ${TELNET_HANDLE}  stoneridge  ${DEBUG}
  ${string}=  Check String Content  ${result}  Received message:
  Should be equal  ${string}  Received message:
  ${string}=  Check String Content  ${result}  INFOIF test PASSED
  Should be equal  ${string}  INFOIF test PASSED

  BSP TestCase Teardown

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown
