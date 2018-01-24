*** Settings ***
Documentation  This test suite tests various performance aspects of the BSP.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspPerfTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${DEBUG}  ${1}
# 125 KB/s ->  1 Mb/s, 110 will be used since we don't know if the TGW is busy doing something else at the same time
${FS_THRESHOLD}   ${110}
# 7500 KB/s -> 60 Mb/s
${ETH_THRESHOLD}  ${7500}

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
# PERF_CAN
#*************************************************************************************************
Perf Can
  [Documentation]  To verify that the Can unit is able to receive 50 messages, 25ms apart of each
  ...              other and answer to each of them in the meanwhile.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# PERF_USB
#*************************************************************************************************
Perf USB
  [Documentation]  To measure the USB transfer performance on both device and host mode. This will
  ...              be done using RNDIS device/host since it is the only mode in which TGW2 can be
  ...              both device and host.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# PERF_FS
#*************************************************************************************************
Perf File System
  [Documentation]  To measure the FileSystem file access performance. This will measure normal
  ...              performance, using normal use-case. The numbers will be provided as a general
  ...              FS performance indication. The single specific performance requirement that
  ...              the BSP will satisfy is to ensure software download on CAN at 1Mbps support,
  ...              verified by the 6.21.2 SWPROG_CAN_SWDL.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  ${result}  Perf SW Prog Write  ${SERIAL_HANDLE}  ${FS_THRESHOLD}
  Should Be Equal  ${result}  SUCCESS

  Sleep  4.0s

  ${result}  Perf SW Prog Read  ${SERIAL_HANDLE}  ${FS_THRESHOLD}
  Should Be Equal  ${result}  SUCCESS

  BSP TestCase Teardown

#*************************************************************************************************
# PERF_ETH
#*************************************************************************************************
Perf Ethernet
  [Documentation]  To measure the Ethernet (FEC) performance.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  Sleep  0.5s

  ${result}  Perf Eth Transmit  ${SERIAL_HANDLE}  ${ETH_THRESHOLD}
  Should Be Equal  ${result}  SUCCESS

  ${result}  Perf Eth Receive  ${SERIAL_HANDLE}  ${ETH_THRESHOLD}
  Should Be Equal  ${result}  SUCCESS

  BSP TestCase Teardown

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown