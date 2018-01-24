*** Settings ***
Documentation  This test suite will verify the AIN driver. No testing on SC to VBAT is performed in this test suite.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspAinTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${REPETITIONS}  ${4}
${SUCCESS_PERIOD}  500
${FAILING_PERIOD}  50
@{ANTENNA_STATE}=  SC_GND  CON  NOT_CON


*** Keywords ***
SetWlan
  [Documentation]  Sets WLAN to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  WIFI  GND
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  WIFI  CON
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  WIFI  OC

SetGsm1
  [Documentation]  Sets GSM1 to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  GSM1  GND
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  GSM1  CON
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  GSM1  OC

SetGsm2
  [Documentation]  Sets GSM2 to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  GSM2  GND
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  GSM2  CON
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  GSM2  OC

SetGps
  [Documentation]  Sets GPS to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  GPS  GND
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  GPS  CON
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  GPS  OC

SetAudioLine
  [Documentation]  Sets AudioLine to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  Canoe Vt2516 Set Relay Bus Bar Active  Audio_Line_Out
  ...  ELSE IF  '${state}' == 'CON'
  ...  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  Canoe Vt2516 Set Relay Org Component Inactive  Audio_Line_Out

SetMic
  [Documentation]  Sets Mic to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  Canoe Vt2516 Set Relay Gnd Active  Microphone
  ...  ELSE IF  '${state}' == 'CON'
  ...  Canoe Vt2516 Set Relay Org Component Active  Microphone
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  Canoe Vt2516 Set Relay Org Component Inactive  Microphone

ResetWlan
  [Documentation]  Resets WLAN to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  WIFI  OC
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  WIFI  OC
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  WIFI  OC

ResetGsm1
  [Documentation]  Resets GSM1 to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  GSM1  OC
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  GSM1  OC
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  GSM1  OC

ResetGsm2
  [Documentation]  Resets GSM2 to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  GSM2  OC
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  GSM2  OC
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  GSM2  OC

ResetGps
  [Documentation]  Resets GPS to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  CANoe Set Antenna State  GPS  OC
  ...  ELSE IF  '${state}' == 'CON'
  ...  CANoe Set Antenna State  GPS  OC
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  CANoe Set Antenna State  GPS  OC

ResetAudioLine
  [Documentation]  Resets AudioLine to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  Canoe Vt2516 Set Relay Bus Bar Inactive  Audio_Line_Out
  ...  ELSE IF  '${state}' == 'CON'
  ...  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  Canoe Vt2516 Set Relay Org Component Inactive  Audio_Line_Out

ResetMic
  [Documentation]  Resets Mic to requested state.
  [Arguments]  ${state}
  Run Keyword If  '${state}' == 'SC_GND'
  ...  Canoe Vt2516 Set Relay Gnd Inactive  Microphone
  ...  ELSE IF  '${state}' == 'CON'
  ...  Canoe Vt2516 Set Relay Org Component Inactive  Microphone
  ...  ELSE IF  '${state}' == 'NOT_CON'
  ...  Canoe Vt2516 Set Relay Org Component Inactive  Microphone

SetAinAntennaState
  [Documentation]  Sets requested antenna to requested state.
  [Arguments]  ${ain}  ${state}
  LOG  ${ain}
  LOG  ${state}
  Run Keyword If  '${ain}' == 'WLAN_ANT_DETECT'
  ...  SetWlan  ${state}
  ...  ELSE IF  '${ain}' == 'AUDIO_LINE_OUT_DETECT'
  ...  SetAudioLine  ${state}
  ...  ELSE IF  '${ain}' == 'MICRO_DETECT'
  ...  SetMic  ${state}
  ...  ELSE IF  '${ain}' == 'GSM_ANT_DETECT_1'
  ...  SetGsm1  ${state}
  ...  ELSE IF  '${ain}' == 'GSM_ANT_DETECT_2'
  ...  SetGsm2  ${state}
  ...  ELSE IF  '${ain}' == 'GPS_DETECT'
  ...  SetGps  ${state}
  ...  ELSE
  ...  LOG  Voltage ranges are not tested for CTN_TEMP_ADC and VBAT_ADC.

ResetAinAntennaState
  [Documentation]  Resets requested antenna to default state.
  [Arguments]  ${ain}  ${state}
  LOG  ${ain}
  LOG  ${state}
  Run Keyword If  '${ain}' == 'WLAN_ANT_DETECT'
  ...  ResetWlan  ${state}
  ...  ELSE IF  '${ain}' == 'AUDIO_LINE_OUT_DETECT'
  ...  ResetAudioLine  ${state}
  ...  ELSE IF  '${ain}' == 'MICRO_DETECT'
  ...  ResetMic  ${state}
  ...  ELSE IF  '${ain}' == 'GSM_ANT_DETECT_1'
  ...  ResetGsm1  ${state}
  ...  ELSE IF  '${ain}' == 'GSM_ANT_DETECT_2'
  ...  ResetGsm2  ${state}
  ...  ELSE IF  '${ain}' == 'GPS_DETECT'
  ...  ResetGps  ${state}
  ...  ELSE
  ...  LOG  Voltage ranges are not tested for CTN_TEMP_ADC and VBAT_ADC.


AinReadTesting
  [Documentation]  Evaluates AIN Read result.
  [Arguments]  ${ain}
  : FOR  ${state}  IN  @{ANTENNA_STATE}
  \  SetAinAntennaState  ${ain}  ${state}
  \  Sleep  0.5s
  \  ${result}  Ain Read   ${TELNET_HANDLE}  ${ain}
  \  ${check}  Check String Content  ${result}  <${ain}>, status <STATUS_OK>
  \  Should be equal  ${check}  <${ain}>, status <STATUS_OK>
  \  ${voltage_result}=  Ain Check Read Voltage  ${result}  ${ain}  ${state}  ${TGW_VERSION}
  \  Should be equal  ${voltage_result}  SUCCESS
  \  ResetAinAntennaState  ${ain}  ${state}
  \  Sleep  0.5s

AinReadTempAndVbatTesting
  [Documentation]  Evaluates AIN Read result for VBAT and TEMP.
  [Arguments]  ${ain}
  ${result}  Ain Read   ${TELNET_HANDLE}  ${ain}
  ${check}  Check String Content  ${result}  <${ain}>, status <STATUS_OK>
  Should be equal  ${check}  <${ain}>, status <STATUS_OK>

StartAndMonitorAinSuccess
  [Documentation]  Evaluates AIN Start result for success scenarios.
  [Arguments]  ${ain}
  ${result}  Ain Read   ${TELNET_HANDLE}  ${ain}
  : FOR  ${state}  IN  @{ANTENNA_STATE}
  \  SetAinAntennaState  ${ain}  ${state}
  \  Sleep  0.5s
  \  ${result}  Ain Start  ${SERIAL_HANDLE}  ${TELNET_HANDLE}  ${ain}  ${SUCCESS_PERIOD}  ${REPETITIONS}
  \  ${check}  Ain Check Monitor Result For Each Repetition  ${result}  ${ain}  ${state}  ${REPETITIONS}  ${TGW_VERSION}
  \  Should be equal  ${check}  SUCCESS
  \  ResetAinAntennaState  ${ain}  ${state}
  \  Sleep  0.5s

StartAndMonitorAinFail
  [Documentation]  Evaluates AIN Start result for failing scenarios.
  [Arguments]  ${ain}
  ${result}  Ain Start Fail  ${TELNET_HANDLE}  ${ain}  ${FAILING_PERIOD}  ${REPETITIONS}
  ${check}  Check String Content  ${result}  Error: Failed starting monitoring <${ain}>, status <STATUS_WRONG_PARAM>
  Should be equal  ${check}  Error: Failed starting monitoring <${ain}>, status <STATUS_WRONG_PARAM>

*** Test Cases ***

#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Setup TFTP Boot

#*************************************************************************************************
# AIN_READ_CHANNEL
#*************************************************************************************************
Ain Read Channels
  [Documentation]  To verify that the AIN driver reads the proper ADC for selected channels.
  [Tags]  TGW2.0  TGW2.1  IssueTGWIISP-504

  BSP TestCase Setup

  ${result}  Boot And Load Tst  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Ain Open  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  LOG  AUDIO_LINE_OUT_DETECT is only checked against 0V .. 3,3V
  AinReadTesting  AUDIO_LINE_OUT_DETECT

  AinReadTesting  MICRO_DETECT

  AinReadTesting  GSM_ANT_DETECT_1

  AinReadTesting  GSM_ANT_DETECT_2

  Run Keyword If  '${TGW_VERSION}' == 'TGW2.1'
  ...  AinReadTesting  GPS_DETECT

  AinReadTempAndVbatTesting  CTN_TEMP_ADC

  AinReadTempAndVbatTesting  VBAT_ADC

  ${result}  Ain Close  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

#*************************************************************************************************
# AIN_READ_CHANNEL_WLAN
#*************************************************************************************************
Ain Read Channels WLAN
  [Documentation]  To verify that the AIN WLAN driver reads the proper ADC for selected channels.
  [Tags]  TGW2.0  TGW2.1  EXCLUDE_IF_NO_WLAN

  BSP TestCase Setup

  ${result}  Boot And Load Tst  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Ain Open  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  AinReadTesting  WLAN_ANT_DETECT

  ${result}  Ain Close  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

#*************************************************************************************************
# AIN_MONITOR_CHANNELS
#*************************************************************************************************
Ain Monitor Channel
  [Documentation]  To verify that the AIN driver filters the proper ADC for selected channels.
  ...              To verify that the driver does not accept polling period less than 100ms.
  [Tags]  TGW2.0  TGW2.1

  Flush Serial Input  ${SERIAL_HANDLE}
  Ain Close  ${TELNET_HANDLE}
  ${result}  Ain Open  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  LOG  AUDIO_LINE_OUT_DETECT is only checked against 0V .. 3,3V
  StartAndMonitorAinSuccess  AUDIO_LINE_OUT_DETECT

  StartAndMonitorAinSuccess  MICRO_DETECT

  StartAndMonitorAinSuccess  GSM_ANT_DETECT_1

  StartAndMonitorAinSuccess  GSM_ANT_DETECT_2

  Run Keyword If  '${TGW_VERSION}' == 'TGW2.1'
  ...  StartAndMonitorAinSuccess  GPS_DETECT

  ${result}  Ain Close  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  # Polling period < 100 ms shall fail
  ${result}  Ain Open  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  StartAndMonitorAinFail  AUDIO_LINE_OUT_DETECT

  StartAndMonitorAinFail  MICRO_DETECT

  StartAndMonitorAinFail  GSM_ANT_DETECT_1

  StartAndMonitorAinFail  GSM_ANT_DETECT_2

  Run Keyword If  '${TGW_VERSION}' == 'TGW2.1'
  ...  StartAndMonitorAinFail  GPS_DETECT

  StartAndMonitorAinFail  CTN_TEMP_ADC

  StartAndMonitorAinFail  VBAT_ADC

  ${result}  Ain Close  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

#*************************************************************************************************
# AIN_MONITOR_CHANNELS_WLAN
#*************************************************************************************************
Ain Monitor Channel WLAN
  [Documentation]  To verify that the AIN WLAN driver filters the proper ADC for selected channels.
  ...              To verify that the driver does not accept polling period less than 100ms.
  [Tags]  TGW2.0  TGW2.1  EXCLUDE_IF_NO_WLAN

  Flush Serial Input  ${SERIAL_HANDLE}
  Ain Close  ${TELNET_HANDLE}
  ${result}  Ain Open  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  StartAndMonitorAinSuccess  WLAN_ANT_DETECT

  ${result}  Ain Close  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  # Polling period < 100 ms shall fail
  ${result}  Ain Open  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

  StartAndMonitorAinFail  WLAN_ANT_DETECT

  ${result}  Ain Close  ${TELNET_HANDLE}
  Should be equal  ${result}  SUCCESS

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown
