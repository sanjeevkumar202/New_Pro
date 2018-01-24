*** Settings ***
Documentation  This test suite will verify the Power Management.
Resource  Robot/Libs/Bsp/BspResources.robot
Library  Robot/Libs/Bsp/BspPwrMgmtTester.py
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspGsmTester.py
Library  Robot/Libs/Bsp/BspFramTester.py
Library  Robot/Libs/Bsp/BspUsbTester.py
Library  Robot/Libs/Bsp/BspDinTester.py
Library  Robot/Libs/Bsp/BspGpsTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py
Library  XML

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${DEBUG}  ${1}
${RESOURCES}  ${EXECDIR}//Robot//Resources//Bsp
@{BOOT_DELAY}  1.1  1.5

*** Keywords ***
POW Polo Vbat Teardown
  [Documentation]  Teardown used for collecting VTS system setting when tearing down test case.
  Print VT System Parameters

*** Test Cases ***
#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Setup TFTP Boot

#*************************************************************************************************
# POW_READ_BATTERY
#*************************************************************************************************
POW Read Battery
  [Documentation]  To verify that the battery voltage is read correctly. Note that the thresholds
  ...              selected & used in this test case may change as the specification is also
  ...              updated.
  ...              Test case is for verifying that VBAT can be fetched. Not for accuracy.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  Flush Serial Input  ${SERIAL_HANDLE}
  Sleep  2.0
  ${result}  Pow Read Vbat  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check VBAT  ${result}  24000
  Should be equal  ${result}  VBAT_OK

  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Set Power Supply Voltage  VBAT_SUP  10.5
  Sleep  2.0
  ${result}  Pow Read Vbat  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check VBAT  ${result}  10500
  Should be equal  ${result}  VBAT_OK

  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Set Power Supply Voltage  VBAT_SUP  12
  Sleep  2.0
  ${result}  Pow Read Vbat  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check VBAT  ${result}  12000
  Should be equal  ${result}  VBAT_OK

  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Set Power Supply Voltage  VBAT_SUP  24
  Sleep  2.0
  ${result}  Pow Read Vbat  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check VBAT  ${result}  24000
  Should be equal  ${result}  VBAT_OK

  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Set Power Supply Voltage  VBAT_SUP  36
  Sleep  2.0
  ${result}  Pow Read Vbat  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check VBAT  ${result}  36000
  Should be equal  ${result}  VBAT_OK

  BSP TestCase Teardown

#*************************************************************************************************
# POW_BOARD_TEMPERATURE
#*************************************************************************************************
#POW Board Temperature
#  [Documentation]  To verify that the board temperature is read correctly.
#  ...              Priority:      1,
#  ...              Level:         Component,
#  ...              Type:          Functional,
#  ...              Applicability: TGW2.0, TGW2.1
#  # Tag test case according to:  BSP  req  req  req  ...
#  [Tags]  #TGW2.0  TGW2.1

#Not prioritized

#*************************************************************************************************
# POW_GET_FAIL_REASON
#*************************************************************************************************
POW Get Fail Reason
  [Documentation]  To verify that the failure is read correctly. Note that the thresholds
  ...              selected & used in this test case may change as the specification is also
  ...              updated.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1  DevTrack_11010

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  # Trigger low voltage failure
  CANoe Set Power Supply Voltage  VBAT_SUP  12.0
  Sleep  1s
  ${result}  Pow get fail reason  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Error: Failed retrieving power fail reason, status <PWR_STATUS_ERROR>.

  CANoe Set Power Supply Voltage  VBAT_SUP  10.5
  Sleep  1s
  ${result}  Pow get fail reason  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Error: Failed retrieving power fail reason, status <PWR_STATUS_ERROR>.

  CANoe Set Power Supply Voltage  VBAT_SUP  9.5
  Sleep  1s
  ${result}  Pow get fail reason  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check String Content  ${result}  PWR_FAIL_LOW_VOLTAGE
  Should be equal  ${result}  PWR_FAIL_LOW_VOLTAGE

  # Trigger high voltage failure
  CANoe Set Power Supply Voltage  VBAT_SUP  24.0
  Sleep  1s
  ${result}  Pow get fail reason  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Error: Failed retrieving power fail reason, status <PWR_STATUS_ERROR>.

  # Trigger high voltage failure
  CANoe Set Power Supply Voltage  VBAT_SUP  34.0
  Sleep  1s
  ${result}  Pow get fail reason  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check String Content  ${result}  PWR_FAIL_OVER32_VOLTAGE
  Should be equal  ${result}  PWR_FAIL_OVER32_VOLTAGE

  CANoe Set Power Supply Voltage  VBAT_SUP  24.0
  Sleep  1s
  ${result}  Pow get fail reason  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Error: Failed retrieving power fail reason, status <PWR_STATUS_ERROR>.

  BSP TestCase Teardown

#*************************************************************************************************
# POW_TEMPERATURE_MONITORING
#*************************************************************************************************
#POW Temperature Monitoring
#  [Documentation]  To verify that the temperature levels are triggered correctly for temperature
#  ...              monitoring.
#  ...              Priority:      1,
#  ...              Level:         Component,
#  ...              Type:          Functional,
#  ...              Applicability: TGW2.0, TGW2.1
#  # Tag test case according to:  BSP  req  req  req  ...
#  [Tags]  TGW2.0  TGW2.1

#Not prioritized

#*************************************************************************************************
# POW_POWER_MONITORING
#*************************************************************************************************
#POW Power Monitoring
#  [Documentation]  To verify that the start of power monitoring and FRAM saving is working
#  ...              properly. Also the save address for the FRAM dump is tested.
#  ...              Priority:      1,
#  ...              Level:         Component,
#  ...              Type:          Functional,
#  ...              Applicability: TGW2.0, TGW2.1
#  # Tag test case according to:  BSP  req  req  req  ...
#  [Tags]  TGW2.0  TGW2.1
#
# Not prioritized - Should maybe be moved to FRAM test suite

 #BSP TestCase Setup

 #${FramAllZeros}=  Get Element Text  ${RESOURCES}//FramAllZeros.xml  pdu
 #FRAM Write Allzeros  ${TELNET_HANDLE}  ${DEBUG}
 #${result}=  FRAM Read  ${TELNET_HANDLE}  ${DEBUG}
 #${result}=  Compare Strings  ${result}  ${FramAllZeros}
 #Should be equal  ${result}   Strings Equal

 #${deadbeef}=  Convert To String  -l 0x1010 0x800 0xdeadbeef

 #FRAM mfill  ${TELNET_HANDLE}  ${deadbeef}  ${DEBUG}
 #FRAM Emergency Save Set  ${TELNET_HANDLE}  4112  ${DEBUG}
 #FRAM Emergency Save  ${TELNET_HANDLE}  on  ${DEBUG}
 #Pow Monitor Pow  ${TELNET_HANDLE}  start  ${DEBUG}
 #CANoe Set Power Supply Voltage  VBAT_SUP  12

 #${FramDeadbeef}=  Get Element Text  ${RESOURCES}//FramDeadbeef.xml  pdu

 #${result}=  FRAM Read  ${TELNET_HANDLE}  ${DEBUG}
 #${result}=  Compare Strings  ${result}  ${FramDeadbeef}
 #Should be equal  ${result}   Strings Equal

 #CANoe Set Power Supply Off  VBAT
 #Sleep  2s
 #CANoe Set Power Supply On  VBAT
 #Boot And Load  ${SERIAL_HANDLE}
 #CANoe Set Power Supply Voltage  VBAT_SUP  24.0

 #${result}=  Connect To Telnet  ${DEBUG}
 #Should be equal  ${result}  CONNECT_TO_TELNET_OK

 #${result}=  FRAM Read  ${TELNET_HANDLE}  ${DEBUG}
 #${result}=  Compare Strings  ${result}  ${FramDeadbeef}
 #Should be equal  ${result}   Strings Equal

 #FRAM mfill  ${TELNET_HANDLE}  -l 0x1010 0x800 0x01020304  ${DEBUG}
 #FRAM Emergency Save Set  ${TELNET_HANDLE}  4112  ${DEBUG}
 #FRAM Emergency Save  ${TELNET_HANDLE}  on  ${DEBUG}
 #Pow Monitor Pow  ${TELNET_HANDLE}  start  ${DEBUG}
 #CANoe Set Power Supply Voltage  VBAT_SUP  12.0

 #CANoe Set Power Supply Off  VBAT
 #Sleep  2s
 #CANoe Set Power Supply On  VBAT
 #Boot And Load  ${SERIAL_HANDLE}
 #Canoe Set Power Supply Voltage  VBAT_SUP  24.0

 #${result}=  Connect To Telnet  ${DEBUG}
 #Should be equal  ${result}  CONNECT_TO_TELNET_OK

 #${result}=  FRAM Read  ${TELNET_HANDLE}  ${DEBUG}
 #${result}=  Compare Strings  ${result}  ${FramDeadbeef}
 #Should be equal  ${result}   Strings Equal

 #BSP TestCase Teardown

#*************************************************************************************************
# POW_WLAN_ANTENNA_STATUS
#*************************************************************************************************
#POW Wlan Antenna Status
#  [Documentation]  To verify that the wlan antenna status can be read.
#  ...              Priority:      1,
#  ...              Level:         Component,
#  ...              Type:          Functional,
#  ...              Applicability: TGW2.0, TGW2.1
#  # Tag test case according to:  BSP  req  req  req  ...
#  [Tags]  TGW2.0  TGW2.1
#
#  #This test is moved to BspWlan.robot

#*************************************************************************************************
# POW_GET_WAKEUP_SOURCES
#*************************************************************************************************
POW Get Wakeup Sources
  [Documentation]  To verify that the wakeup sources are read correctly.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  Pow off  ${SERIAL_HANDLE}  32  ${DEBUG}

  Sleep  1s
  CANoe Set Relay Active  WAKEUP_R_PM
  Sleep  1s
  CANoe Set Relay Inactive  WAKEUP_R_PM
  Sleep  1s

  ${result}=  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}=  Connect To Telnet  ${DEBUG}
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}=  Pow Get Wsrc  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Wakeup source <WAKEUP_R_CPU> active.

  BSP TestCase Teardown

  #TODO: Add more wakeup sources

#*************************************************************************************************
# POW_GET_RESET_REASONS
#*************************************************************************************************
POW Get Reset Reasons
  [Documentation]  To verify cpu reset is done correctly. The application should report if the
  ...              last reset was due to hardware watchdog or not.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  Test Watchdog  ${TELNET_HANDLE}
  Sleep  10s

  # Load RTOSE and TestApp, connect to telnet
  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}=  Pow Get Reset Reason  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Reset reason: CPU_WATCHDOG_RESET

  BSP TestCase Teardown

  #TODO: # Extend TC to also test other resets

#*************************************************************************************************
# POW_ETHERNET_POWERDOWN
#*************************************************************************************************
POW Ethernet Powerdown
  [Documentation]  To check that Ethernet power down function works properly.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  Pow Eth Powdown  ${SERIAL_HANDLE}  POWER_ALWAYS_UP  ${DEBUG}
  Ping Eth Interface  ${SERIAL_HANDLE}  192.168.10.2
  Sleep  5s
  ${result}  Check Ping Response  ${SERIAL_HANDLE}  POWER_ALWAYS_UP
  Should Be Equal  ${result}  POWER_ALWAYS_UP Success

  Pow Eth Powdown  ${SERIAL_HANDLE}  POWER_DOWN_GENERAL  ${DEBUG}
  Ping Eth Interface  ${SERIAL_HANDLE}  192.168.10.2
  Sleep  5s
  ${result}  Check Ping Response  ${SERIAL_HANDLE}  POWER_DOWN_GENERAL
  Should Be Equal  ${result}  POWER_DOWN_GENERAL Success

  Pow Eth Powdown  ${SERIAL_HANDLE}  POWER_DOWN_ENERGY_DETECT  ${DEBUG}
  Ping Eth Interface  ${SERIAL_HANDLE}  192.168.10.2
  Sleep  5s
  ${result}  Check Ping Response  ${SERIAL_HANDLE}  POWER_DOWN_ENERGY_DETECT
  Should Be Equal  ${result}  POWER_DOWN_ENERGY_DETECT Success

  BSP TestCase Teardown

#*************************************************************************************************
# POW_POLO_VBAT
#*************************************************************************************************
POW Polo Vbat
  [Documentation]  This test case reboots the TGW at low voltage.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1
  [Teardown]  POW Polo Vbat Teardown

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  Write OSE To TGW And Set Z Flag  ${SERIAL_HANDLE}

  LOG  Voltage < 9V ? POLO resets and stay in POLO indefinitely
  CANoe Set Power Supply Voltage  VBAT_SUP  8.5
  :FOR  ${INDEX}  IN RANGE  0  5
  \  LOG  ${INDEX}
  \  CANoe Set Power Supply Off  VBAT
  \  Sleep  1s
  \  CANoe Set Power Supply On  VBAT
  \  Sleep  2s
  \  ${result}=  Check POLO Or OS Running  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  Neither OS or POLO are running

  LOG  9V < voltage < 10.5V ? POLO does not boot OSE
  CANoe Set Power Supply Off  VBAT
  CANoe Set Power Supply Voltage  VBAT_SUP  10.0
  Sleep  1s
  :FOR  ${DELAY}  IN  @{BOOT_DELAY}
  \  LOG  ${DELAY}
  \  CANoe Set Power Supply Off  VBAT
  \  Sleep  1s
  \  CANoe Set Power Supply On  VBAT
  \  Sleep  ${DELAY}
  \  CANoe Set Power Supply Off  VBAT
  \  Sleep  1s
  \  CANoe Set Power Supply On  VBAT
  \  ${result}=  Wait Ose Boot And Prevent Reset  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  OSE_BOOT_FAILED
  \  ${result}=  Check POLO Or OS Running  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  Neither OS or POLO are running

  LOG  10.5 < Voltage ? POLO boots OSE
  CANoe Set Power Supply Voltage  VBAT_SUP  11.5
  ${result}=  Wait Ose Boot And Prevent Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  OSE_BOOT_OK

  :FOR  ${INDEX}  IN RANGE  0  5
  \  LOG  ${INDEX}
  \  CANoe Set Power Supply Off  VBAT
  \  Sleep  1s
  \  CANoe Set Power Supply On  VBAT
  \  ${result}=  Wait Ose Boot And Prevent Reset  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  OSE_BOOT_OK
  \  ${result}=  Check POLO Or OS Running  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  OS is running

  ${result}=  Remove Z Flag From OSE Image  ${SERIAL_HANDLE}
  Should be equal  ${result}  FLAG_REMOVED_OK
  Reset TGW  ${SERIAL_HANDLE}

  BSP TestCase Teardown

#*************************************************************************************************
# POW_MULTI_BOOT
#*************************************************************************************************
POW Multi Boot
  [Documentation]  This test will perform multipel boots at different voltage.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  CANoe Set Power Supply Voltage  VBAT_SUP  12
  :FOR  ${INDEX}  IN RANGE  0  5
  \  ${result}  Boot And Load  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  BOOT_OSE_OK
  \  CANoe Set Power Supply Off  VBAT
  \  Sleep  2.0s
  \  CANoe Set Power Supply Current  VBAT_Sup  1.0
  \  CANoe Set Power Supply Voltage  VBAT_Sup  24.0
  \  CANoe Set Power Supply On  VBAT

  CANoe Set Power Supply Voltage  VBAT_SUP  24
  :FOR  ${INDEX}  IN RANGE  0  5
  \  ${result}  Boot And Load  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  BOOT_OSE_OK
  \  CANoe Set Power Supply Off  VBAT
  \  Sleep  2.0s
  \  CANoe Set Power Supply Current  VBAT_Sup  1.0
  \  CANoe Set Power Supply Voltage  VBAT_Sup  24.0
  \  CANoe Set Power Supply On  VBAT


  CANoe Set Power Supply Voltage  VBAT_SUP  32
  :FOR  ${INDEX}  IN RANGE  0  5
  \  ${result}  Boot And Load  ${SERIAL_HANDLE}
  \  Should be equal  ${result}  BOOT_OSE_OK
  \  CANoe Set Power Supply Off  VBAT
  \  Sleep  2.0s
  \  CANoe Set Power Supply Current  VBAT_Sup  1.0
  \  CANoe Set Power Supply Voltage  VBAT_Sup  24.0
  \  CANoe Set Power Supply On  VBAT

  BSP TestCase Teardown

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Teardown


