*** Settings ***
Documentation  This test suite will verify the WIFI driver.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspPwrMgmtTester.py
Library  Robot/Libs/Bsp/BspWifiTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

Test Setup        Wlan Test Setup
Test Teardown     Wlan Test Teardown
Suite Setup       Wlan Suite Setup
Suite Teardown    Wlan TestSuite Teardown

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${DEBUG}  ${1}

*** Keywords ***

Wlan Test Setup
  BSP TestCase Setup

  ${response}  Boot And Download Ose And Set Z Flag  ${SERIAL_HANDLE}
  Should be equal  ${response}  BOOT_OS_OK

  ${response}    Download Wifi Firmware And Reset      ${SERIAL_HANDLE}
  Should be equal  ${response}  FIRMWARE_DOWNLOADED_OK
  #${response}  Connect To Serial
  #Should be equal  ${response}  CONNECT_TO_SERIAL_OK

Wlan Test Teardown
  ${result}=  Remove Z Flag From OSE Image  ${SERIAL_HANDLE}
  Should be equal  ${result}  FLAG_REMOVED_OK
  BSP TestCase Teardown
  #${response}    Close Target  ${TELNET_HANDLE}  ${SERIAL_HANDLE}
  #Should be equal  ${response}  0
  #${response}    Close Serial Connection Only     ${SERIAL_HANDLE}
  #Should Be Equal As Numbers   ${response}    0

Wlan Suite Setup
  BSP TestSuite Setup TFTP Boot
  #${response}    Close Target  ${TELNET_HANDLE}  ${SERIAL_HANDLE}
  #Should be equal  ${response}  0
  #${response}    Close Serial Connection Only     ${SERIAL_HANDLE}
  #Should Be Equal As Numbers   ${response}    0

Wlan TestSuite Teardown
  BSP TestSuite Teardown


*** Test Cases ***

#*************************************************************************************************
# WLAN_COMM_MANAGED
#*************************************************************************************************
WLAN Manages Mode
  [Documentation]  To verify that the WLAN driver is able to transfer packets over a wireless
  ...              network in managed mode (Infrastructure mode).
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_ADHOC_START
#*************************************************************************************************
WLAN Adhoc Start
  [Documentation]  To verify that the WLAN driver is able to transfer packets over a wireless
  ...              ad-hoc network started by the TGW2 device.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_ADHOC_JOIN
#*************************************************************************************************
WLAN Adhoc Join
  [Documentation]  To verify that the WLAN driver is able to transfer packets over a wireless
  ...              ad-hoc network joined by the TGW2 device.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_WEP
#*************************************************************************************************
WLAN WEP
  [Documentation]  To verify that the WLAN driver is able to transfer packets over a wireless
  ...              network using WEP encryption.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_WPAPSK
#*************************************************************************************************
WLAN WPAPSK
  [Documentation]  To verify that the WLAN driver is able to transfer packets over a wireless
  ...              network using WPA2 encryption.
  [Tags]  TGW2.0  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_WPATKIP
#*************************************************************************************************
WLAN WPARKIP
  [Documentation]  To verify that the WLAN driver and embedded supplicant (firmware) are able to
  ...              transfer packets over a wireless network using WPA encryption.
  [Tags]  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_WPA2
#*************************************************************************************************
WLAN WPA2
  [Documentation]  To verify that the WLAN driver and embedded supplicant (firmware) are able to
  ...              transfer packets over a wireless network using WPA2 encryption.
  [Tags]  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_SEC_MISFIT
#*************************************************************************************************
WLAN Wrong Security
  [Documentation]  To verify WLAN driver behavior when security parameters are wrong configured
  ...              with respect to AP setup (wireless network is always in Infrastructure mode).
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_CONN_STATUS
#*************************************************************************************************
WLAN Connection Status
  [Documentation]  To verify that the WLAN driver is able to get connection status including the
  ...              SSID, channel, band, mode BSSID, noise ratio and RX rate statistics.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_NET_CHG
#*************************************************************************************************
WLAN Change Network
  [Documentation]  To verify WLAN driver behavior when being successfully connected into a WIFI
  ...              network it is issued a new connection command into a different network without
  ...              de-authenticated from the first one.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_COMM_AP_OFF
#*************************************************************************************************
WLAN Access Point Power Off
  [Documentation]  To verify the WLAN driver robustness when access point "vanishes" during a
  ...              data transfer (Infrastructure mode).
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_CHIP_POWER_SUPPLY
#*************************************************************************************************
WLAN Chip Power On And Off
  [Documentation]  To verify that the WLAN driver is behaving correctly while the chip power
  ...              supply is turned OFF and afterwards ON, and the eth3 interface state is
  ...              changed from down to up for a few times in a loop.
  [Tags]  TGW2.0  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# WLAN_ANTENNA_STATUS
#*************************************************************************************************
Wlan Antenna Status
  [Documentation]  To verify that the wlan antenna status can be read.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1  EXCLUDE_IF_NO_WLAN

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #Disconnect the antenna
  CANoe Set Antenna State  WIFI  OC
  Sleep  1.0
  ${result}=  Pow Get Wlan Antenna  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  WLAN antenna is not connected.

  #Shortcut wlan antenna to GND
  CANoe Set Antenna State  WIFI  GND
  Sleep  1.0
  ${result}=  Pow Get Wlan Antenna  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  WLAN antenna is shortcut to GND.

  #Connect the antenna
  CANoe Set Antenna State  WIFI  CON
  Sleep  1.0
  ${result}=  Pow Get Wlan Antenna  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  WLAN antenna is connected.

  BSP TestCase Teardown


