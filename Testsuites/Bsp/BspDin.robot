*** Settings ***
Documentation  This test suite will verify the digital input driver.
...            To be sure that the tests starts in a known state most of the test cases in this
...            suite starts with a test suite tear down followed by test suite setup.
Library  Robot/Libs/Bsp/BspDinTester.py
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${DEBUG}  ${1}
# Set default value
@{DIGITAL_INPUTS}=  DR_L  D_IN1_L  D_IN2_L  D_IN_CHARGER_L  D_IN3_L  D_IN_BAT_STAT_L  WAKEUP_R_PM  WAKEUP_ASSISTANCE_BUTTON_L
# Digital Inputs used for TGW2.0
@{DIGITAL_INPUTS_TGW_2_0}=  DR_L  D_IN1_L  D_IN2_L  D_IN_CHARGER_L  D_IN3_L  D_IN_BAT_STAT_L  WAKEUP_R_PM  WAKEUP_ASSISTANCE_BUTTON_L
# Digital Inputs used for TGW2.1, the rest are used for CAN2 strap
@{DIGITAL_INPUTS_TGW_2_1}=  DR_L  D_IN1_L  WAKEUP_R_PM  WAKEUP_ASSISTANCE_BUTTON_L


*** Keywords ***
evalOneActiveDigitalInput
  [Documentation]  Keword used for looping through all digital inputs and checking the status.
  ...              Only one digital input, ActiveInput, is expected to be enabled, all other
  ...              digital inputs is expected to be deactivated.
  [Arguments]  ${ActiveInput}
  :FOR  ${ELEMENT_2}  IN  @{DIGITAL_INPUTS}
  \  LOG  ${ELEMENT_2}
  \  ${result}  Din Read Current Value  ${TELNET_HANDLE}  ${ELEMENT_2}
  \  Run Keyword If  '${ELEMENT_2}' == '${ActiveInput}'
  \  ...  Should be equal  ${result}  Current value input ${ELEMENT_2} value ACTIVE DIN_PRINT_END
  \  ...  ELSE
  \  ...  Should be equal  ${result}  Current value input ${ELEMENT_2} value INACTIVE DIN_PRINT_END
  \  Sleep  0.2s


setAllDigitalInputRelays
  [Documentation]  Keword used for activating or deactivating all Digital Inputs.
  [Arguments]  ${status}
  :FOR  ${ELEMENT}  IN  @{DIGITAL_INPUTS}
  \  LOG  ${ELEMENT}
  \  Run Keyword If  'ON' == '${status}'
  \  ...  CANoe Set Relay Active  ${ELEMENT}
  \  ...  ELSE
  \  ...  CANoe Set Relay Inactive  ${ELEMENT}
  \  Sleep  0.2s

restartTgw
  [Documentation]  Keyword used to restart the TGW. This is needed to get a clean start in the DIN
   ...             test cases where WAKEUP_R_PM and WAKEUP_ASSISTANCE_BUTTON_L is tricky to read if
   ...             the previous test case failed.
  Reset TGW  ${SERIAL_HANDLE}
  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

testDinActivation
  [Documentation]  Keword used for testing the status messaging when activating input
  [Arguments]  ${ELEMENT}
  LOG  ${ELEMENT}
  CANoe Set Relay Active  ${ELEMENT}
  ${result}  Wait Serial String  ${SERIAL_HANDLE}  3
  Should be equal  ${result}  TGW_TEST_SUCCESS|${ELEMENT}|ACTIVE|END_DIN_RESULT
  Sleep  0.2s

*** Test Cases ***
#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite.
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Setup TFTP Boot

  # Set digital inputs depending on if it is TGW2.0 or TGW2.1
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Set Suite Variable  @{DIGITAL_INPUTS}  @{DIGITAL_INPUTS_TGW_2_0}
  ...  ELSE
  ...  Set Suite Variable  @{DIGITAL_INPUTS}  @{DIGITAL_INPUTS_TGW_2_1}


#*************************************************************************************************
# DIN_DRIVER_OPEN_CLOSE
#*************************************************************************************************
DIN Driver Open Close
  [Documentation]  To verify that the digital input driver open and close API functions work
  ...              properly.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}=  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_GET_CONFIG
#*************************************************************************************************
DIN Get Config
  [Documentation]  To verify that the digital input driver return correct configuration for
  ...              monitored input.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  # Start monitoring
  ${result}  Din Monitor  ${TELNET_HANDLE}  DR_L -nonotify -params:1,0,1,2
  Sleep  1s
  ${result}  Din Monitor  ${TELNET_HANDLE}  WAKEUP_R_PM -params:1,2,3,4
  Sleep  1s

  # Get DIN config and check result
  ${result}  Din Get Config  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Configuration input DR_L filter time: 0ms, notification time 0ms, suspend time 1ms DIN_PRINT_END
  Sleep  1s
  ${result}  Din Get Config  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Configuration input WAKEUP_R_PM filter time: 2ms, notification time 4ms, suspend time 3ms DIN_PRINT_END
  Sleep  1s

  # Stop monitoring
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  DR_L
  Sleep  1s
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  WAKEUP_R_PM
  Sleep  1s

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_INPUTS_ACTIVATION
#*************************************************************************************************
DIN Inputs Activation
  [Documentation]  To verify that the digital input driver monitors and reports events for inputs:
  ...              DR_L, D_IN1_L, D_IN2_L, D_IN3_L, D_IN_BAT_STAT_L, D_IN_CHARGER_L, WAKEUP_R_PM
  ...              and WAKEUP_ASSISTANCE_BUTTON_L. Digital inputs status for D_IN2,
  ...              D_IN3, D_IN_CHARGER and D_IN_BAT_STAT will not be available for TGW2.1 when
  ...              CAN2 strap HW option is mounted, signal value will be fixed to high level by HW.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  ${result}  Din Monitor  ${TELNET_HANDLE}  ALL_INPUTS -nonotify -params:1,0,0
  Sleep  1s

  # Check that all digital inputs are disabled.
  : FOR  ${ELEMENT}  IN  @{DIGITAL_INPUTS}
    \  LOG  ${ELEMENT}
    \  ${result}  Din Read Current Value  ${TELNET_HANDLE}  ${ELEMENT}
    \  Should be equal  ${result}  Current value input ${ELEMENT} value INACTIVE DIN_PRINT_END
    Sleep  2s

  # Enable one digital input at the time, check the current value of all digital inputs.
  : FOR  ${ELEMENT}  IN  @{DIGITAL_INPUTS}
    \  LOG  ${ELEMENT}
    \  CANoe Set Relay Active  ${ELEMENT}
    \  Sleep  0.5s
    \  evalOneActiveDigitalInput  ${ELEMENT}
    \  CANoe Set Relay Inactive  ${ELEMENT}
    \  Sleep  0.5s
    \  ${result}  Din Read Current Value  ${TELNET_HANDLE}  ${ELEMENT}
    \  Should be equal  ${result}  Current value input ${ELEMENT} value INACTIVE DIN_PRINT_END
    Sleep  1s

  # Enable all digital inputs, one at the time, check the status messages of the activated input.
  Flush Serial Input  ${SERIAL_HANDLE}
  : FOR  ${ELEMENT}  IN  @{DIGITAL_INPUTS}
    \  Run Keyword Unless  '${ELEMENT}' == 'WAKEUP_R_PM' or '${ELEMENT}' == 'WAKEUP_ASSISTANCE_BUTTON_L'
    \  ...  testDinActivation  ${ELEMENT}

  setAllDigitalInputRelays  OFF

  # Check that all digital inputs are disabled.
  : FOR  ${ELEMENT}  IN  @{DIGITAL_INPUTS}
    \  LOG  ${ELEMENT}
    \  ${result}  Din Read Current Value  ${TELNET_HANDLE}  ${ELEMENT}
    \  Should be equal  ${result}  Current value input ${ELEMENT} value INACTIVE DIN_PRINT_END
    Sleep  1s

  # Stop monitoring
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  ALL_INPUTS
  Sleep  1s
  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_FILTERING_SUSPEND
#*************************************************************************************************
DIN Filtering Suspend
  [Documentation]  To verify that the digital inputs filtering and suspend logic is working.
  ...              Test should be run for WAKEUP_R_PM and DR_L inputs (one input is direct and one
  ...              PLD controlled).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  # Start monitoring
  ${result}  Din Monitor  ${TELNET_HANDLE}  DR_L -nonotify -params:1,1000,2000
  ${result}  Din Monitor  ${TELNET_HANDLE}  WAKEUP_R_PM -nonotify -params:1,1000,2000

  # Check that digital inputs are inactive
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value INACTIVE DIN_PRINT_END
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  # Send an activation pulse for 2s, there should be a line status messages from both monitored inputs
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  DR_L  RelayBusBarA  1  0  2.0
  ${result}  Wait Serial String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  TGW_TEST_SUCCESS|DR_L|ACTIVE|END_DIN_RESULT
  ${result}  Wait Serial String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  TGW_TEST_SUCCESS|DR_L|INACTIVE|END_DIN_RESULT

  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  WAKEUP_R_PM  RelayBusBarA  1  0  2.0
  ${result}  Wait Serial String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  TGW_TEST_SUCCESS|WAKEUP_R_PM|ACTIVE|END_DIN_RESULT
  ${result}  Wait Serial String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  TGW_TEST_SUCCESS|WAKEUP_R_PM|INACTIVE|END_DIN_RESULT

  setAllDigitalInputRelays  OFF
  # Check that digital inputs are inactive
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value INACTIVE DIN_PRINT_END
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  # Send a activation pulse for 0,2s, there should not be a line status messages from either monitored inputs
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  DR_L  RelayBusBarA  1  0  0.2
  ${result}  Wait Serial String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  No string found!
  Sleep  3s
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  WAKEUP_R_PM  RelayBusBarA  1  0  0.2
  ${result}  Wait Serial String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  No string found!

  # Stop monitoring
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  DR_L
  Sleep  1s
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  WAKEUP_R_PM
  Sleep  1s

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_NOTIFICATION_TIME
#*************************************************************************************************
DIN Notification Time
  [Documentation]  To verify that the notification time for digital inputs driver is accurate.
  ...              Test should be run for WAKEUP_R_PM and DR_L inputs (one input is direct and one
  ...              PLD controlled).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  # Start monitoring
  ${result}  Din Monitor  ${TELNET_HANDLE}  DR_L -params:1,1000,2000,2000
  Sleep  1s
  ${result}  Din Monitor  ${TELNET_HANDLE}  WAKEUP_R_PM -params:1,1000,2000,2000
  Sleep  1s

  # Check that digital inputs are inactive
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value INACTIVE DIN_PRINT_END
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  # Send a activation puls to DR_L for 0,5s, there should be notification messages.
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  DR_L  RelayBusBarA  1  0  0.5
  ${result}  Din Wait Serial Status String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  Input DR_L triggered value ACTIVE, status STATUS_FILTER_ERROR.
  ${result}  Din Wait Serial Status String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  Input DR_L triggered value INACTIVE, status STATUS_OK.
  Sleep  2s

  # Send activation pulse to WAKEUP_R_PM for 0.5s, there shoule be notification messages.
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  WAKEUP_R_PM  RelayBusBarA  1  0  0.5
  ${result}  Din Wait Serial Status String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  Input WAKEUP_R_PM triggered value INACTIVE, status STATUS_FILTER_ERROR.
  ${result}  Din Wait Serial Status String  ${SERIAL_HANDLE}  2.5
  Should be equal  ${result}  Input WAKEUP_R_PM triggered value INACTIVE, status STATUS_OK.

  # Stop monitoring
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  DR_L
  Sleep  1s
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  WAKEUP_R_PM
  Sleep  1s

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_MONITOR_NOTIF_CLBK
#*************************************************************************************************
DIN Monitor Notif Clbk
  [Documentation]  To verify that the digital input driver can monitor a line with notification
  ...              messages and callback attached. Test should be run for WAKEUP_R_PM and DR_L
  ...              inputs (one input is direct and one PLD controlled).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  # Start monitoring
  ${result}  Din Monitor  ${TELNET_HANDLE}  DR_L -params:1,1000,2000,2000
  Sleep  1s
  ${result}  Din Monitor  ${TELNET_HANDLE}  WAKEUP_R_PM -params:1,1000,2000,2000
  Sleep  1s

  # Send one pulse shorter then 1s on digital input, starting Inactive: Active, Inactive.
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  DR_L  RelayBusBarA  1  0  0.2
  CANoe Pulse VTS Variable  WAKEUP_R_PM  RelayBusBarA  1  0  0.2
  sleep  4s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value INACTIVE DIN_PRINT_END
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  # Stop monitoring
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  WAKEUP_R_PM
  Sleep  1s
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  DR_L
  Sleep  1s

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_MONITOR_NO_CLBK
#*************************************************************************************************
DIN Monitor No Clbk
  [Documentation]  To verify that the digital input driver can monitor a line with notification
  ...              messages and without callback attached. Test should be run for WAKEUP_R_PM and
  ...              DR_L inputs (one input is direct and one PLD controlled).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF


  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  # Start monitoring
  ${result}  Din Monitor  ${TELNET_HANDLE}  DR_L -noclbk -params:1,1000,2000,2000
  Sleep  1s
  ${result}  Din Monitor  ${TELNET_HANDLE}  WAKEUP_R_PM -noclbk -params:1,1000,2000,2000
  Sleep  1s

  # Send one pulse shorter then 1s on digital input, starting Inactive: Active, Inactive.
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Pulse VTS Variable  DR_L  RelayBusBarA  1  0  0.2
  CANoe Pulse VTS Variable  WAKEUP_R_PM  RelayBusBarA  1  0  0.2
  Sleep  4s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value INACTIVE DIN_PRINT_END
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  # Stop monitoring
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  WAKEUP_R_PM
  Sleep  1s
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  DR_L
  Sleep  1s

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_LAST_FILTERED_VALUE
#*************************************************************************************************
DIN Last Filtered Value
  [Documentation]  To verify that the digital input can return correct filtered value. Test should
  ...              be run for WAKEUP_R_PM and DR_L inputs (one input is direct and one PLD
  ...              controlled).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  # Start monitoring
  ${result}  Din Monitor  ${TELNET_HANDLE}  DR_L -params:1,1000,2000,2000
  Sleep  1s
  ${result}  Din Monitor  ${TELNET_HANDLE}  WAKEUP_R_PM -params:1,1000,2000,2000
  Sleep  1s

  CANoe Set Relay Active  DR_L
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value ACTIVE DIN_PRINT_END
  CANoe Set Relay Active  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value ACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  DR_L
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value INACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  CANoe Set Relay Active  DR_L
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value ACTIVE DIN_PRINT_END
  CANoe Set Relay Active  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value ACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  DR_L
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value INACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  CANoe Set Relay Active  WAKEUP_R_PM
  CANoe Set Relay Active  DR_L
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value ACTIVE DIN_PRINT_END
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value ACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  WAKEUP_R_PM
  CANoe Set Relay Inactive  DR_L
  Sleep  2.0s
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Last filtered input WAKEUP_R_PM value INACTIVE DIN_PRINT_END
  ${result}  Din Read Last Filtered Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Last filtered input DR_L value INACTIVE DIN_PRINT_END

  # Stop monitoring
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  WAKEUP_R_PM
  Sleep  1s
  ${result}  Din Stop Monitoring  ${TELNET_HANDLE}  DR_L
  Sleep  1s

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# DIN_READ_VALUE
#*************************************************************************************************
DIN Read Value
  [Documentation]  To verify that the digital input driver can return unfiltered input values.
  ...              Test should be run for WAKEUP_R_PM and DR_L inputs (one input is direct and one
  ...              PLD controlled).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  restartTgw
  setAllDigitalInputRelays  OFF

  ${result}  Din Driver Open  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT
  Sleep  1s

  CANoe Set Relay Active  DR_L
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value ACTIVE DIN_PRINT_END
  CANoe Set Relay Active  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value ACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  DR_L
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value INACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  CANoe Set Relay Active  DR_L
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value ACTIVE DIN_PRINT_END
  CANoe Set Relay Active  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value ACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  DR_L
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value INACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  WAKEUP_R_PM
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value INACTIVE DIN_PRINT_END

  CANoe Set Relay Active  WAKEUP_R_PM
  CANoe Set Relay Active  DR_L
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value ACTIVE DIN_PRINT_END
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value ACTIVE DIN_PRINT_END
  CANoe Set Relay Inactive  WAKEUP_R_PM
  CANoe Set Relay Inactive  DR_L
  Sleep  2.0s
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  WAKEUP_R_PM
  Should be equal  ${result}  Current value input WAKEUP_R_PM value INACTIVE DIN_PRINT_END
  ${result}  Din Read Current Value  ${TELNET_HANDLE}  DR_L
  Should be equal  ${result}  Current value input DR_L value INACTIVE DIN_PRINT_END

  ${result}=  Din Driver Close  ${TELNET_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS|STATUS_OK|tst_din|0|END_RESULT

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite.
  [Tags]  TGW2.0  TGW2.1
  setAllDigitalInputRelays  OFF
  BSP TestSuite Teardown
