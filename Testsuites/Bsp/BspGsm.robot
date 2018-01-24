*** Settings ***
Documentation  This test suite will verify the GSM driver.
Resource  Robot/Libs/Bsp/BspResources.robot
Library  Robot/Libs/Bsp/BspGsmTester.py
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspPwrMgmtTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py

*** Variables ***
${DEBUG}  ${1}
${TGW_20_MODEM_START_DELAY}  30.0
${TGW_21_MODEM_START_DELAY}  3.0

${POSITION_ACC}  0.00008

*** Keywords ***
Restore Audio State
  [Documentation]  Keword used for restoring the audio state.
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  0
  Canoe Vt2516 Set Relay Gnd Inactive  Audio_Line_Out
  Canoe Vt2516 Set Relay Vbat Inactive  Audio_Line_Out
  Canoe Vt2516 Set Relay Org Component Inactive  Audio_Line_Out
  Canoe Vt2516 Set Relay Bus Bar Inactive  Audio_Line_Out

  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  0
  Canoe Vt2516 Set Relay Gnd Inactive  Audio_Line_Gnd
  Canoe Vt2516 Set Relay Vbat Inactive  Audio_Line_Gnd
  Canoe Vt2516 Set Relay Org Component Inactive  Audio_Line_Gnd
  Canoe Vt2516 Set Relay Bus Bar Inactive  Audio_Line_Gnd

Get AC Buildning Reference Position
    ${ac_position}  Create Dictionary  latitude=57.7154018333  longitude=11.9191813333
    [return]     ${ac_position}

*** Test Cases ***

TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1
  ${result}  BSP TestSuite Setup TFTP Boot
  Should be equal  ${result}  SETUP_TFTP_BOOT_COMPLETED

#*************************************************************************************************
# GSM_MODEM_START
#*************************************************************************************************
GSM Modem Start
  [Documentation]  To verify that the GSM Modem Driver can be opened and that AT can be sent/received on AT channel
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  GSM Modem Start  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  CANoe Set Power Supply Voltage  VBAT_Sup  8.7
  Sleep  2s
  CANoe Set Power Supply Voltage  VBAT_Sup  24.0

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  GSM Modem Start  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  #BSP TestCase Teardown

#*************************************************************************************************
# GSM_MODEM_GET_TYPE
#*************************************************************************************************
GSM Modem Get Type
  [Documentation]  To verify that the correct GSM Modem is detected.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1  DevTrack_11764

  #BSP TestCase Setup

  #${result}  Boot And Load TST  ${SERIAL_HANDLE}
  #Should be equal  ${result}  BOOT_OSE_OK

  # We must sleep to let the USB connection between the modem and CPU to
  # connect and thus allowing the driver to detect the modem type.
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.1'
  ...  Sleep  ${TGW_21_MODEM_START_DELAY}
  ...  ELSE
  ...  Sleep  ${TGW_20_MODEM_START_DELAY}

  ${result}  GSM Get Modem Type  ${SERIAL_HANDLE}
  Run Keyword If  '${TGW_MODEM}' == 'AGS2-E'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:AGS2
  ...  ELSE IF  '${TGW_MODEM}' == 'AHS3-W'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:AHS3  
  ...  ELSE IF  '${TGW_MODEM}' == 'AHS3-US'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:AHS3  
  ...  ELSE IF  '${TGW_MODEM}' == 'ALS3-US'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:ALS3
  ...  ELSE IF  '${TGW_MODEM}' == 'H24'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:H24
  ...  ELSE IF  '${TGW_MODEM}' == 'G24'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:G24
  ...  ELSE
  ...  Fail  Get GSM Modem Type Failed
  #TODO add more device variants

  #BSP TestCase Teardown

GSM Modem Antenna
  [Documentation]  To verify that the GSM Modem Driver can detect different states on the GSM antennas
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  #BSP TestCase Setup

  #${result}  Boot And Load TST  ${SERIAL_HANDLE}
  #Should be equal  ${result}  BOOT_OSE_OK

  # We must sleep to let the USB connection between the modem and CPU to
  # connect and thus allowing the driver to detect the modem type.
  #Run Keyword If  '${TGW_VERSION}' == 'TGW2.1'
  #...  Sleep  ${TGW_21_MODEM_START_DELAY}
  #...  ELSE
  #...  Sleep  ${TGW_20_MODEM_START_DELAY}

  # -------------------------------------
  # Test GSM1 Input
  CANoe Set Antenna State  GSM1  CON
  CANoe Set Antenna State  GSM2  CON
  CANoe Set Antenna State  GPS   CON

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected:GPS_STAT=Connected

  CANoe Set Antenna State  GSM1  OC
  CANoe Set Antenna State  GSM2  CON
  CANoe Set Antenna State  GPS   CON

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Disconnected:GSM2_STAT=Connected
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Disconnected:GSM2_STAT=Connected:GPS_STAT=Connected

  CANoe Set Antenna State  GSM1  GND
  CANoe Set Antenna State  GSM2  CON
  CANoe Set Antenna State  GPS   CON

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=ShortToGround:GSM2_STAT=Connected
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=ShortToGround:GSM2_STAT=Connected:GPS_STAT=Connected

  # -------------------------------------
  # Test GSM2 Input
  CANoe Set Antenna State  GSM1  CON
  CANoe Set Antenna State  GSM2  OC
  CANoe Set Antenna State  GPS   CON

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Disconnected
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Disconnected:GPS_STAT=Connected

  CANoe Set Antenna State  GSM1  CON
  CANoe Set Antenna State  GSM2  GND
  CANoe Set Antenna State  GPS   CON

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=ShortToGround
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=ShortToGround:GPS_STAT=Connected

  # -------------------------------------
  # Test GPS Input
  CANoe Set Antenna State  GSM1  CON
  CANoe Set Antenna State  GSM2  CON
  CANoe Set Antenna State  GPS   OC

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected:GPS_STAT=Disconnected

  CANoe Set Antenna State  GSM1  CON
  CANoe Set Antenna State  GSM2  CON
  CANoe Set Antenna State  GPS   GND

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected:GPS_STAT=ShortToGround

  CANoe Set Antenna State  GSM1  CON
  CANoe Set Antenna State  GSM2  CON
  CANoe Set Antenna State  GPS   CON

  ${result}  GSM Modem Antenna  ${SERIAL_HANDLE}  1  ${TGW_VERSION}
  Run Keyword If  '${TGW_VERSION}' == 'TGW2.0'
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected
  ...  ELSE
  ...  Should be equal  ${result}  TGW_TEST_SUCCESS:GSM1_STAT=Connected:GSM2_STAT=Connected:GPS_STAT=Connected

  #BSP TestCase Teardown

GSM Modem Reset
  [Documentation]  To verify that the GSM Modem Driver can reset the Modem and restore communication with it.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  #BSP TestCase Setup

  #${result}  Boot And Load TST  ${SERIAL_HANDLE}
  #Should be equal  ${result}  BOOT_OSE_OK

  # We must sleep to let the USB connection between the modem and CPU to
  # connect and thus allowing the driver to detect the modem type.
  #Run Keyword If  '${TGW_VERSION}' == 'TGW2.1'
  #...  Sleep  ${TGW_21_MODEM_START_DELAY}
  #...  ELSE
  #...  Sleep  ${TGW_20_MODEM_START_DELAY}

  ${result}  GSM Modem Reset  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  BSP TestCase Teardown

GSM Modem Com
  [Documentation]  Test modem communication by sending 50 AT cmds on both AT and DATA channel.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  GSM Modem Com  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  #BSP TestCase Teardown

GSM Modem AT Close
  [Documentation]  Test close of AT subdevice
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  #BSP TestCase Setup

  #${result}  Boot And Load TST  ${SERIAL_HANDLE}
  #Should be equal  ${result}  BOOT_OSE_OK

  ${result}  GSM Modem AT Close  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  BSP TestCase Teardown

GSM Modem GNSS
  [Documentation]  Test GNSS subdevice
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  GSM Modem GNSS  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${meas_pos}  Get GNSS Position  ${SERIAL_HANDLE}
  LOG  ${meas_pos}

  ${ac_ref_pos}  Get AC Buildning Reference Position

  ${pos_result}  Check GPS Position  ${meas_pos}  ${ac_ref_pos}  ${POSITION_ACC}
  Should Be Equal  ${pos_result}  ${True}

  #BSP TestCase Teardown

#
# No need to run modem sleep as we have no SIM card installed.
#
#GSM Modem Sleep
#  [Documentation]  Test Sleep functionality in the modem. Shall not be possible due to absence of SIM card.
#  ...              Upon success of the testcase it is ensured that the driver will not allow sleep mode 
#  ...              when no SIM card.
#  ...              Priority:      1,
#  ...              Level:         Component,
#  ...              Type:          Functional
#  ...              Applicability: TGW2.0, TGW2.1
#  # Tag test case accoring to:  BSP  req  req  req  ...
#  [Tags]  TGW2.0  TGW2.1
#
#  # It shall not be possible to put the modem to sleep when no SIM card is present
#  ${result}  GSM Put Modem To Sleep  ${SERIAL_HANDLE}
#  Should be equal  ${result}  TGW_TEST_SUCCESS:MODEM_STATUS_FAILED_TO_PUT_MODEM_TO_SLEEP
#
#  BSP TestCase Teardown

GSM Modem Antenna Select
  [Documentation]  Test that the TGW can switch between the two GSM antennas
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]   TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  ${result}  GSM Modem Set Antenna Select  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  GSM Modem Get Antenna Select  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:1

  ${result}  GSM Modem Set Antenna Select  ${SERIAL_HANDLE}  2
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  GSM Modem Get Antenna Select  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:2

  ${result}  GSM Modem Set Antenna Select  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS

  ${result}  GSM Modem Get Antenna Select  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_TEST_SUCCESS:1

  BSP TestCase Teardown

GSM Modem Monitor MIC State
  [Documentation]  Monitor The Mic State and verify the different states
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load TST  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  #Connect correct load to Mic
  Canoe Vt2516 Set Relay Org Component Active  Microphone
  ${result}=  GSM Monitor Mic State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:MIC_STAT=GSM_AUDIO_CONNECTED
  #Default state
  Canoe Vt2516 Set Relay Org Component Inactive  Microphone

  Sleep  0.5

  #Shortcut GSM mic line to GND
  Canoe Vt2516 Set Relay Gnd Active  Microphone
  ${result}=  GSM Monitor Mic State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:MIC_STAT=GSM_AUDIO_SHORT_CUT_GND
  #Default state
  Canoe Vt2516 Set Relay Gnd Inactive  Microphone

  Sleep  0.5

  #Shortcut GSM mic line to VBAT
  Canoe Vt2516 Set Relay Vbat Active  Microphone
  ${result}=  GSM Monitor Mic State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:MIC_STAT=GSM_AUDIO_SHORT_CUT_VBAT
  #Default state
  Canoe Vt2516 Set Relay Vbat Inactive  Microphone

  Sleep  0.5

  #Disconnect the Mic
  Canoe Vt2516 Set Relay Org Component Inactive  Microphone
  ${result}=  GSM Monitor Mic State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:MIC_STAT=GSM_AUDIO_NOT_CONNECTED

  #BSP TestCase Teardown

GSM Modem Monitor Audio State TGW2.0  
  [Documentation]  Monitor The Audio State and verify the different states
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.0
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  RemainingWork

  # Already set up from previous test case

  # Connect speaker / load
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  0
  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  0
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_CONNECTED

  #SC to Audio GND
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  Canoe Vt2516 Set Relay Bus Bar Active  Audio_Line_Out
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_GND
  Restore Audio State

  #SC to ECU Gnd
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  Canoe Vt2516 Set Relay Gnd Active  Audio_Line_Out
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_GND
  Restore Audio State

  #SC to Vbat
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  Canoe Vt2516 Set Relay Vbat Active  Audio_Line_Out
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_VBAT
  Restore Audio State

  #Discconnect speaker
  # RemainingWork: TGW not able to detect if connected or disconnected... incorrect load ?
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  1
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_NOT_CONNECTED
  Restore Audio State

  BSP TestCase Teardown
  
GSM Modem Monitor Audio State TGW2.1
  [Documentation]  Monitor The Audio State and verify the different states
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional
  ...              Applicability: TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.1  JIRA_ISSUE  OBT-570

  # Already set up from previous test case

  #Connect AUDIO_OUT_N and AUDIO_OUT_P
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  0
  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  0
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_CONNECTED

  # RemainingWork: We cannot detect NOT_CONNECTED
  # Not connected P and Not connected N
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Inactive  Audio_Line_Out
  Canoe Vt2516 Set Relay Org Component Inactive  Audio_Line_Gnd
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_NOT_CONNECTED_OUT_P
  Restore Audio State

  #Shortcut AUDIO_OUT_P gsm audio line to GND
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  Canoe Vt2516 Set Relay Gnd Active  Audio_Line_Out
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_OUT_P_GND
  Restore Audio State

  #Shortcut AUDIO_OUT_N gsm audio line to GND
  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Gnd
  Canoe Vt2516 Set Relay Gnd Active  Audio_Line_Gnd
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_OUT_N_GND
  Restore Audio State

  #Shortcut AUDIO_OUT_P antenna to VBAT
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  Canoe Vt2516 Set Relay Vbat Active  Audio_Line_Out
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_OUT_P_VBAT
  Restore Audio State

  # RemainingWork: Cannot be shorted to VBAT, why ?
  #Shortcut AUDIO_OUT_N antenna to VBAT  (GSM_AUDIO_SHORT_CUT_OUT_N_VBAT)
  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Gnd
  Canoe Vt2516 Set Relay Vbat Active  Audio_Line_Gnd
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_OUT_N_VBAT
  Restore Audio State

  Canoe Set VTS Variable  AudioLine_GND_N_LOAD  Relay  1
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Gnd
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_CONNECTED

  #Shortcut between AUDIO_OUT_P and AUDIO_OUT_N
  Canoe Set VTS Variable  AudioLine_OUT_P_LOAD  Relay  1
  Canoe Vt2516 Set Relay Org Component Active  Audio_Line_Out
  Canoe Vt2516 Set Relay Bus Bar Active  Audio_Line_Out
  ${result}=  Gsm Monitor Audio State  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  TGW_TEST_SUCCESS:AUDIO_STAT=GSM_AUDIO_SHORT_CUT_TWO_LINES
  Restore Audio State

  BSP TestCase Teardown

#GSM Modem Setup Data Connection
#  [Documentation]  Setup a data connection to a server via the modem.
#  ...              Priority:      1,
#  ...              Level:         Component,
#  ...              Type:          Functional
#  ...              Applicability: TGW2.0, TGW2.1
#  # Tag test case accoring to:  BSP  req  req  req  ...
#  [Tags]  TGW2.0  TGW2.1
#
#  BSP TestCase Setup
#
#  ## Set GSM Audio lines in a defined state
#
#  ${result}  GSM Setup Data Connection  ${TELNET_HANDLE}
#  Should be equal  ${result}  TGW_TEST_SUCCESS
#
#  BSP TestCase Teardown

#*************************************************************************************************
# Test Suite End
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1

  Restore Audio State

  BSP TestSuite Teardown