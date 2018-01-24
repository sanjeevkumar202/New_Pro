*** Settings ***
Documentation    BSP low level testing. The goal is to verify the board support package (BSP) used together with
...              RTOSE at a low level. Low level in this case means that measurements are performed at a hardware
...              level by attaching small wires to specific locations on the PCB.

Resource         Robot/Libs/Bsp/BspResources.robot
Library          Robot/Libs/Bsp/BspGsmTester.py
Library          Robot/Libs/Bsp/BspCommonTester.py
Library          Robot/Libs/Bsp/BspMiscTester.py
Library          Robot/Libs/Bsp/BspSaleaeInterface.py
Library          Robot/Libs/Bsp/BspSaleaeOutputParser.py
Library          Robot/Libs/Bsp/BspSaleaeChannelMap.py
Library          Robot/Libs/Bsp/BspAcronameUsbHubTester.py
Library          Robot/Libs/Bsp/BspPwrMgmtTester.py
Library          Robot/Libs/Bsp/BspFlashTester.py
Library          Robot/Libs/Bsp/BspPldTester.py
Library          Robot/Libs/Bsp/BspDinTester.py
Library          Robot/Libs/Bsp/BspWifiTester.py
Library          Robot/Libs/Bsp/BspFramTester.py
Library          Collections
Library          String

Suite Setup      Low Level Suite Setup
Suite Teardown   Low Level Suite Teardown

Test Setup       Low Level Test Setup
Test Teardown    Low Level Test Teardown

Force Tags       LOW_LEVEL

*** Variables ***
${t0}=  0.0

${DigitalChannels}=  [0]
${AnalogChannels} =  [0]

# Test case to signal mapping
${TC_AHS3_ALS3_POWER}=        [PGSM_ON, GSM_CTR, USB_GSM_VBUS_5V, GSM_PWR_IND, EMERG_OFF]
${TC_AGS2_POWER_ON}=          [PGSM_ON, GSM_CTR, GSM_PWR_IND]
${TC_AGS2_POWER_OFF}=         [PGSM_ON, P1V80_GSM, GSM_PWR_IND, EMERG_OFF]
${TC_POWER_FAIL}=             [SPI_SCLK, SPI_MOSI, POWER_FAIL, NOR_FLASH_WE_B]
${TC_POWER_FAIL_AN}=          [VBAT_ADC]
${TC_ANTENNA_SELECT}=         [PGSM_ON, GSM_ANTENNA_SELECT]
${TC_AHS3_EMERGENCY_OFF}=     [PGSM_ON, GSM_PWR_IND, GSM_CTR, EMERG_OFF]
@{TC_HW_WATCHDOG}=            PGSM_ON  HW_WATCHDOG  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS1
@{TC_ACTIVITY_REGISTER}=      PGSM_ON  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS1
${TC_WIFI_POWER_ON_OFF}=      [WIFI_PWR_ON_B, RESET_B_WLAN, WLAN_EN, SLEEP]
@{TC_FRAM_WRITE_READ}=        SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS0

${LOGIC_HIGH}=                ${1}
${LOGIC_LOW}=                 ${0}

*** Test Cases ***
AHS3 ALS3 Power On
    [Documentation]  To power on the AHS3 or ALS3 module shall the power be applied to the module before ignition signal
    ...              is toggled. To be able to communicate with the module must power to the USB interface be applied.
    ...              Timings used in this TC:
    ...              t0: PGSM_ON goes high
    ...              t1: GSM_CTR goes high
    ...              t2: GSM_PWR_IND goes low
    ...              t3: GSM_CTR goes low (pulse width)
    ...              t4: USB_GSM_VBUS_5V goes high
    [Tags]  TGW2.1  LOW_LEVEL_AHS3_ALS3

    ${active_device}  Get Device From Name List  ${TC_AHS3_ALS3_POWER}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_AHS3_ALS3_POWER}
    LOG  ${DigitalChannels}
    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  0.5

    # Set trigger from where the measurements shall start
    Set Trigger One Channel  ${active_device}  PGSM_ON  Posedge
    Capture Start

    # Make PGSM_ON go high by starting the TGW
    CANoe Set Power Supply On  VBAT

    Wait Until Processing Done  ${120.0}

    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${power_on_capture}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY
    Wait Until Processing Done  ${120.0}

    ${resulting_list}  CSV Read To List  ${power_on_capture}

    # Set timing requirements, low and high values for each timing.
    ${t0t1_reqL}=  Set Variable  ${0.090}
    ${t0t1_reqH}=  Set Variable  ${0.150}

    ${t1t2_reqL}=  Set Variable If  '${TGW_MODEM}' == 'ALS3-US'  ${0.050}  ${0.020}
    ${t1t2_reqH}=  Set Variable If  '${TGW_MODEM}' == 'ALS3-US'  ${0.070}  ${0.040}

    ${t1t3_reqL}=  Set Variable  ${0.100}
    ${t1t3_reqH}=  Set Variable  ${0.200}

    ${t3t4_reqL}=  Set Variable  ${0.010}
    ${t3t4_reqH}=  Set Variable  ${0.120}

    # Check timings
    # t0 -> t1
    ${t1}  Find Digital Channel Transition  ${resulting_list}  GSM_CTR  ${t0}  True
    ${t0t1}  Get Time Difference  ${t0}  ${t1}
    LOG  ${t0t1}
    Should Be True  ${t0t1} > ${t0t1_reqL}
    Should Be True  ${t0t1} < ${t0t1_reqH}

    # t1 -> t2
    ${t2}  Find Digital Channel Transition  ${resulting_list}  GSM_PWR_IND  ${t1}  False
    ${t1t2}  Get Time Difference  ${t1}  ${t2}
    LOG  ${t1t2}
    Should Be True  ${t1t2} > ${t1t2_reqL}
    Should Be True  ${t1t2} < ${t1t2_reqH}

    # t1 -> t3
    ${t3}  Find Digital Channel Transition  ${resulting_list}  GSM_CTR  ${t1}  False
    ${t1t3}  Get Time Difference  ${t1}  ${t3}
    LOG  ${t1t3}
    Should Be True  ${t1t3} > ${t1t3_reqL}
    Should Be True  ${t1t3} < ${t1t3_reqH}

    # t3 -> t4
    ${t4}  Find Digital Channel Transition  ${resulting_list}  USB_GSM_VBUS_5V  ${t1}  True
    ${t3t4}  Get Time Difference  ${t3}  ${t4}
    LOG  ${t3t4}
    Should Be True  ${t3t4} > ${t3t4_reqL}
    Should Be True  ${t3t4} < ${t3t4_reqH}

    # Check that USB_GSM_VBUS_5V doesn't go low again.
    ${t0t4}  Get Time Difference  ${t0}  ${t4}
    ${noTransition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list}  USB_GSM_VBUS_5V  ${t0t4}  False
    ${items}  Get From List   ${noTransition}  1
    Should Contain  ${items}  ACTestException: Transition not found


AHS3 ALS3 Power Off
    [Documentation]  To power off the AHS3 or ALS3 module an AT command shall be sent and the power indicator should go
    ...              inactive afterwards and the power to the module should not be turned off before t0 + t2 + 100ms
    ...              after that the AT command is sent. I.e. t3 - t2 > 100 ms
    ...              Timings used in this TC:
    ...              t0-: Power off is sent, AT^SMSO
    ...              t0: GSM_PWR_IND goes high
    ...              t1: -
    ...              t2: USB_GSM_VBUS_5V goes low
    ...              t3: PGSM_ON goes low
    ...              t4: EMERG_OFF goes low
    [Tags]  TGW2.1  LOW_LEVEL_AHS3_ALS3

    ${active_device}  Get Device From Name List  ${TC_AHS3_ALS3_POWER}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_AHS3_ALS3_POWER}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  2.0

    # Make PGSM_ON go high by starting the TGW
    CANoe Set Power Supply On  VBAT

    ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    Set Trigger One Channel  ${active_device}  GSM_PWR_IND  Posedge
    Capture Start

    ${result}  GSM Modem Power Off  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS

    Wait Until Processing Done  ${120.0}

    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${power_off_capture}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY
    Wait Until Processing Done  ${120.0}

    ${resulting_list}  CSV Read To List  ${power_off_capture}

    # Set timing requirements.
    ${t2t3_req}=  Set Variable  ${0.100}

    # Check timings
    # t2 -> t3
    ${t2}  Find Digital Channel Transition  ${resulting_list}  USB_GSM_VBUS_5V  ${t0}  False
    ${t3}  Find Digital Channel Transition  ${resulting_list}  PGSM_ON  ${t0}  False
    ${t4}  Find Digital Channel Transition  ${resulting_list}  EMERG_OFF  ${t0}  False
    ${t2t3}  Get Time Difference  ${t2}  ${t3}
    ${t3t4}  Get Time Difference  ${t3}  ${t4}
    LOG  ${t2t3}
    Should Be True  ${t2t3} > ${t2t3_req}
    Should Be True  ${t3t4} > ${0.0}

    # USB_GSM_VBUS_5V might toggel, add short time to remove toggling problems.
    ${t0t2}  Get Time Difference  ${t0}  ${t2}
    ${t0t2}  evaluate  ${t0t2} + ${0.005}

    ${noTransition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list}  USB_GSM_VBUS_5V  ${t0t2}  True
    ${items}  Get From List   ${noTransition}  1
    Should Contain  ${items}  ACTestException: Transition not found

    ${t0t3}  Get Time Difference  ${t0}  ${t3}
    ${noTransition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list}  PGSM_ON  ${t0t3}  True
    ${items}  Get From List   ${noTransition}  1
    Should Contain  ${items}  ACTestException: Transition not found

AGS2 Power On
    [Documentation]  To power on the AGS2 module shall the power be applied to the module before ignition signal is toggled.
    ...              Timings used in this TC:
    ...              t0: PGSM_ON goes high
    ...              t1: GSM_CTR goes high
    ...              t2: GSM_PWR_IND goes low the first time after t1
    ...              t3: GSM_CTR goes low (pulse width)
    [Tags]  TGW2.1  LOW_LEVEL_AGS2

    ${active_device}  Get Device From Name List  ${TC_AGS2_POWER_ON}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_AGS2_POWER_ON}
    LOG  ${DigitalChannels}
    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  3.2

    # Set trigger from where the measurements shall start
    Set Trigger One Channel  ${active_device}  PGSM_ON  Posedge
    Capture Start

    # Make PGSM_ON go high by starting the TGW
    CANoe Set Power Supply On  VBAT

    Wait Until Processing Done  ${120.0}

    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${ags2_power_on_capture}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY
    Wait Until Processing Done  ${120.0}

    ${resulting_list}  CSV Read To List  ${ags2_power_on_capture}

    # Set timing requirements, low and high values for each timing.
    ${t0t1_reqL}=  Set Variable  ${0.100}
    ${t0t1_reqH}=  Set Variable  ${3.000}

    ${t1t2_reqL}=  Set Variable  ${0.0005}
    ${t1t2_reqH}=  Set Variable  ${0.020}

    ${t1t3_reqL}=  Set Variable  ${0.000001}
    ${t1t3_reqH}=  Set Variable  ${0.02}

    # Check timings
    # t0 -> t1
    ${t1}  Find Digital Channel Transition  ${resulting_list}  GSM_CTR  ${t0}  True
    ${t0t1}  Get Time Difference  ${t0}  ${t1}
    LOG  ${t0t1}
    Should Be True  ${t0t1} > ${t0t1_reqL}
    Should Be True  ${t0t1} < ${t0t1_reqH}

    # t1 -> t2
    ${t2}  Find Digital Channel Transition  ${resulting_list}  GSM_PWR_IND  ${t1}  False
    ${t1t2}  Get Time Difference  ${t1}  ${t2}
    LOG  ${t1t2}
    Should Be True  ${t1t2} > ${t1t2_reqL}
    Should Be True  ${t1t2} < ${t1t2_reqH}

    # t1 -> t3
    ${t3}  Find Digital Channel Transition  ${resulting_list}  GSM_CTR  ${t1}  False
    ${t1t3}  Get Time Difference  ${t1}  ${t3}
    LOG  ${t1t3}
    Should Be True  ${t1t3} > ${t1t3_reqL}
    Should Be True  ${t1t3} < ${t1t3_reqH}


AGS2 Power Off
    [Documentation]  To power off the AGS2 module an AT command shall be sent and the power indicator should go inactive
    ...              afterwards and the power to the module should not be turned off before t3 > t1 and
    ...              0 ms > (t4 - t3) > 300 ms after that the AT command is sent.
    ...              Timings used in this TC:
    ...              t0: Power off is sent, AT^SMSO
    ...              t1: GSM_PWR_IND goes high
    ...              t2: EMERG_OFF goes low
    ...              t3: P1V80_GSM goes low
    ...              t4: PGSM_ON goes low

    [Tags]  TGW2.1  LOW_LEVEL_AGS2  JIRA_ISSUE  OBT-5937

    ${active_device}  Get Device From Name List  ${TC_AGS2_POWER_OFF}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_AGS2_POWER_OFF}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  1.0

    # Make PGSM_ON go high by starting the TGW
    CANoe Set Power Supply On  VBAT

    ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    Set Trigger One Channel  ${active_device}  GSM_PWR_IND  Posedge
    Capture Start

    ${result}  GSM Modem Power Off  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS

    Wait Until Processing Done  ${120.0}

    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${ags2_power_off_capture}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY
    Wait Until Processing Done  ${120.0}

    ${resulting_list}  CSV Read To List  ${ags2_power_off_capture}

    # Set timing requirements.
    ${t3t4_reqL}=  Set Variable  ${0.0}
    ${t3t4_reqH}=  Set Variable  ${0.300}

    # Check timings
    ${t1}  Find Digital Channel Transition  ${resulting_list}  GSM_PWR_IND  ${t0}  True
    ${t2}  Find Digital Channel Transition  ${resulting_list}  EMERG_OFF  ${t0}  False
    ${t3}  Find Digital Channel Transition  ${resulting_list}  P1V80_GSM  ${t0}  False
    ${t4}  Find Digital Channel Transition  ${resulting_list}  PGSM_ON  ${t0}  False


    ${t3t4}  Get Time Difference  ${t3}  ${t4}
    ${t1t2}  Get Time Difference  ${t1}  ${t2}
    LOG  ${t3t4}
    Should Be True  ${t3t4} > ${t3t4_reqL}
    Should Be True  ${t3t4} < ${t3t4_reqH}

    # Check tat emergency off does not move until mode is power off.
    Should Be True  ${t1t2} > ${0.0}

    # Check that PGSM_ON doesn't change state
    ${noTransition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list}  PGSM_ON  ${t4}  True
    ${items}  Get From List   ${noTransition}  1
    Should Contain  ${items}  ACTestException: Transition not found

Power Fail Flash
    [Documentation]  When the battery level turns to low (<10 V, ~0.7V on VBAT) power fail mode shall be activated.
    ...              HW shall provide at least 2 ms of autonomy to manage ongoing flash operations. This can be verified
    ...              by checking the SPI_SCLK signal.
    [Tags]  TGW2.1  LOW_LEVEL_POWER_FAIL_FLASH

    ${active_device}  Get Device From Name List  ${TC_POWER_FAIL}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_POWER_FAIL}
    LOG  ${DigitalChannels}

    ${AnalogChannels}  Map Names To Channels  ${active_device}  ${TC_POWER_FAIL_AN}
    LOG  ${AnalogChannels}

    Set Active Channels  ${DigitalChannels}  ${AnalogChannels}
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  6250000  781250
    Set Capture Duration In Seconds  0.3

    # Start the TGW
    CANoe Set Power Supply On  VBAT

    ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    Sleep  5.0

    PWR Enable Emergency Save  ${SERIAL_HANDLE}

    Set Trigger One Channel  ${active_device}  POWER_FAIL  Posedge

    Capture Start

    ${result}  Create File On Flash And Start Writing  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS

    Sleep  0.5s

    Canoe Set Power Supply Voltage  VBAT_Sup  5.0

    # Wait for trigger
    Wait Until Processing Done  ${120.0}

    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    # Export data
    ${power_fail_capture}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY  SPECIFIC_CHANNELS
    Wait Until Processing Done  ${120.0}
    ${resulting_list}  CSV Read To List  ${power_fail_capture}

    ${power_fail_capture_an}  Export Data  ${TEST_NAME}  No_Digital  ${AnalogChannels}  ANALOG_ONLY
    Wait Until Processing Done  ${120.0}
    ${resulting_list_an}  CSV Read To List  ${power_fail_capture_an}  ${1}

    ${tPowerFailFall}=  Set Variable  ${0.005}
    ${tTestEndTimeDict}=  Find Digital Channel Transition  ${resulting_list}  POWER_FAIL  ${tPowerFailFall}  False
    ${tTestEndTime}=  Get From Dictionary  ${tTestEndTimeDict}  time
    ${tTestEndTime}=  Evaluate  ${tTestEndTime}-${0.001}

    # Check that NOR_FLASH_WE_B doesn't change state after power fail
    ${tFlashWeDisable}=  Set Variable  ${0.001}
    ${noTransition}=  Find Digital Channel Transition  ${resulting_list}  NOR_FLASH_WE_B  ${tFlashWeDisable}  False
    ${tFlashWeFalling}=  Get From Dictionary  ${noTransition}  time
    Should Be True  ${tFlashWeFalling}>${tTestEndTime}

    ${vbat_value_at_trigger}  Get Sample Value  ${resulting_list_an}  VBAT_ADC  0.0
    LOG  VBAT value at trigger point is ${vbat_value_at_trigger}V  console=true
    Should Be True  ${vbat_value_at_trigger}>${0.65}
    Should Be True  ${vbat_value_at_trigger}<${0.9}

    # Check That SPI_SCLK toggles up to 2 ms after power fail
    ${tSpiClkStart}=  Set Variable  ${0.002}
    ${Transition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list}  SPI_SCLK  ${tSpiClkStart}  True
    ${items}  Get From List   ${Transition}  1
    Should Not Contain  ${items}  ACTestException: Transition not found
    # Check that no SPI_SCLK toggling 10 ms after Power Fail
    ${tSpiClkSilent}=  Set Variable  ${0.010}
    ${Transition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list}  SPI_SCLK  ${tSpiClkSilent}  True
    ${items}  Get From List   ${Transition}  1
    Should Contain  ${items}  ACTestException: Transition not found

Antenna Select Antenna 2
    [Documentation]  Testing GSM_ANTENNA_SEL when setting antenna 2
    ...              Triggers used in this TC:
    ...              t0: GSM_ANTENNA_SEL goes high
    [Tags]    TGW2.1    LOW_LEVEL_ANT_SEL

    ${active_device}  Get Device From Name List  ${TC_ANTENNA_SELECT}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_ANTENNA_SELECT}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  2

    # Power on the TGW
    CANoe Set Power Supply On  VBAT

    ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
    Should be equal  ${result}  TEASER_OK

    Set Trigger One Channel  ${active_device}  GSM_ANTENNA_SELECT  Posedge
    Capture Start

    # Set antenna 2
    ${result}  GSM Modem Set Antenna Select  ${SERIAL_HANDLE}  2
    Should be equal  ${result}  TGW_TEST_SUCCESS

    ${result}  GSM Modem Get Antenna Select  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS:2

    Wait Until Processing Done  ${120.0}

    Save measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${antenna_select_pos}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY
    Wait Until Processing Done  ${120.0}

    ${resulting_list_pos}  CSV Read To List  ${antenna_select_pos}

    # Check that GSM_ANTENNA_SELECT goes high when enabling antenna 2
    ${t1}  Find Digital Channel Transition  ${resulting_list_pos}  GSM_ANTENNA_SELECT  ${t0}  True
    # Check that GSM_ANTENNA_SELECT doesn't change state
    ${noTransition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list_pos}  GSM_ANTENNA_SELECT  ${t1}  False
    ${items}  Get From List   ${noTransition}  1
    Should Contain  ${items}  ACTestException: Transition not found

Antenna Select Antenna 1
    [Documentation]  Testing GSM_ANTENNA_SEL when setting antenna 1
    ...              Triggers used in this TC:
    ...              t0: GSM_ANTENNA_SEL goes low
    [Tags]    TGW2.1    LOW_LEVEL_ANT_SEL

    ${active_device}  Get Device From Name List  ${TC_ANTENNA_SELECT}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_ANTENNA_SELECT}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  2

    # Power on the TGW
    CANoe Set Power Supply On  VBAT

    ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
    Should be equal  ${result}  TEASER_OK

    Set Trigger One Channel  ${active_device}  GSM_ANTENNA_SELECT  Negedge
    Capture Start

    # Set antenna 2
    ${result}  GSM Modem Set Antenna Select  ${SERIAL_HANDLE}  2
    Should be equal  ${result}  TGW_TEST_SUCCESS

    ${result}  GSM Modem Get Antenna Select  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS:2

    # Set antenna 1
    ${result}  GSM Modem Set Antenna Select  ${SERIAL_HANDLE}  1
    Should be equal  ${result}  TGW_TEST_SUCCESS

    ${result}  GSM Modem Get Antenna Select  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS:1

    Wait Until Processing Done  ${120.0}

    Save measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${antenna_select_neg}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY
    Wait Until Processing Done  ${120.0}

    ${resulting_list_neg}  CSV Read To List  ${antenna_select_neg}

    # Check that GSM_ANTENNA_SELECT goes low when enabling antenna 1
    ${t1}  Find Digital Channel Transition  ${resulting_list_neg}  GSM_ANTENNA_SELECT  ${t0}  False
    # Check that GSM_ANTENNA_SELECT doesn't change state
    ${noTransition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list_neg}  GSM_ANTENNA_SELECT  ${t1}  True
    ${items}  Get From List   ${noTransition}  1
    Should Contain  ${items}  ACTestException: Transition not found

AHS3 ALS3 Emergency Off
    [Documentation]  Verify that the Emergency Off sequence is correct. The EMERG_OFF signal must be
    ...              grounded for more than 40ms. Verify also that the power indicator is set to active
    ...              after >540ms measured from the falling edge of EMERG_OFF. It is important that the
    ...              PGSM_ON is high until the power indicator has gone high.
    ...              Timings used in this TC:
    ...              t0: Falling edge of EMERG_OFF
    ...              t1: Rising edge of EMERG_OFF
    ...              t2: Rising edge of GSM_PWR_IND
    ...              t3: Falling edge of PGSM_ON
    [Tags]    TGW2.1    LOW_LEVEL_AHS3_ALS3

    ${active_device}  Get Device From Name List  ${TC_AHS3_EMERGENCY_OFF}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_AHS3_EMERGENCY_OFF}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}

    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  6.0

    # Power on the TGW
    CANoe Set Power Supply On  VBAT

    ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
    Should be equal  ${result}  TEASER_OK

    ${result}  GSM Modem Start  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS

    Sleep  5s

    # Disable all triggers PGSM_ON, GSM_PWR_IND, GSM_CTR
    Set Trigger One Channel  ${active_device}  PGSM_ON  NoTrigger
    Set Trigger One Channel  ${active_device}  GSM_PWR_IND  NoTrigger
    Set Trigger One Channel  ${active_device}  GSM_CTR  NoTrigger

    Capture Start

    ${async}   GSM Modem Simulate Emergency Off  ${SERIAL_HANDLE}
    ${result}  Wait Until Emergency Off Is Done  ${async}

    Wait Until Processing Done  ${120.0}

    Save measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${result}=  Dump Ramlog To File  ${SERIAL_HANDLE}  ${TEST_NAME}_rld.log
    Should Be Equal  ${result}  RLD_DUMP_OK

    ${ahs3_emergency_off}=  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY  csv_density=ROW_PER_CHANGE
    Wait Until Processing Done  ${120.0}
    ${resulting_list}  CSV Read To List  ${ahs3_emergency_off}

    ${t0}=     Find Digital Channel Transition  ${resulting_list}  EMERG_OFF  ${0.0}  ${False}
    ${t1}=     Find Digital Channel Transition  ${resulting_list}  EMERG_OFF  ${t0}  ${True}
    ${t1_t0}=  Get Time Difference  ${t0}  ${t1}
    Should Be True  ${t1_t0}>${0.040}
    Should Be True  ${t1_t0}<${0.100}

    ${t2}  Find Digital Channel Transition  ${resulting_list}  GSM_PWR_IND  ${t1}  True
    ${t3}  Find Digital Channel Transition  ${resulting_list}  PGSM_ON  ${t1}  False

    ${t2t0_reqL}=  Set Variable If  '${TGW_MODEM}' == 'ALS3-US'  ${0.530}  ${0.540}
    ${t2t0_reqH}=  Set Variable If  '${TGW_MODEM}' == 'ALS3-US'  ${0.600}  ${0.600}

    ${t2_t0}=  Get Time Difference  ${t0}  ${t2}
    Should Be True  ${t2_t0}>${t2t0_reqL}
    Should Be True  ${t2_t0}<${t2t0_reqH}

    ${t3_t2}=  Get Time Difference  ${t2}  ${t3}
    Should Be True  ${t3_t2}>${0.0}

HW Watchdog RTOSE
    [Documentation]  Verify that the hardware watchdog is disabled before 64 s has passed from
    ...              power on with RTOSE booting. The watchdog is disabled when accessing a register
    ...              in the FPGA. Verify that the status register is read at least twice at startup.
    [Tags]    TGW2.1  LOW_LEVEL_WATCHDOG

    ${active_device}=  Get Device From Name List  ${TC_HW_WATCHDOG}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}=  Map Names To Channels  ${active_device}  ${TC_HW_WATCHDOG}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}=  Get Active Channels

    ${AllSamplerates}=  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  70.0

    Disable All Triggers  ${active_device}  @{TC_HW_WATCHDOG}

    LOG To Console  Start recording signals
    Capture Start

    # Power on the TGW
    CANoe Set Power Supply On  VBAT

    ${result}=  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    Wait Until Processing Done  ${75.0}

    Save measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${hw_watchdog}=  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY  csv_density=ROW_PER_CHANGE
    Wait Until Processing Done  ${120.0}
    ${resulting_list}=  CSV Read To List  ${hw_watchdog}

    ${t_spi_on}=  Find Digital Channel Transition  ${resulting_list}  SPI_SS1  ${0.0}  True
    LOG  SPI start @ ${t_spi_on}

    @{all_spi_data}=  Get All FPGA SPI Data After Timestamp  ${resulting_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS1  ${t_spi_on}

    ${num_acceses}=  Count Number Of Read Acceses On SPI Before TimeStamp  ${64.0}  @{all_spi_data}
    LOG To Console  Number of Read Accesses to FPGA is ${num_acceses}
    Should Be True  ${num_acceses}>${2}

    ${noTransition}  Run Keyword And Ignore Error  Find Digital Channel Transition  ${resulting_list}  HW_WATCHDOG  ${0.5}  True
    ${items}  Get From List   ${noTransition}  1
    Should Contain  ${items}  ACTestException: Transition not found

Read FPGA Activity Register
    [Documentation]  Read FPGA Wakeup Source Activity (WSA) Register and verify that the SPI transfer is according to specification.
    [Tags]    TGW2.1

    ${active_device}=  Get Device From Name List  ${TC_ACTIVITY_REGISTER}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}=  Map Names To Channels  ${active_device}  ${TC_ACTIVITY_REGISTER}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}=  Get Active Channels

    ${AllSamplerates}=  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  20.0

    LOG To Console  Start recording signals
    ${time_stamp_0}  Get Time  epoch
    Capture Start
    
    # Power on the TGW
    CANoe Set Power Supply On  VBAT

    ${result}=  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    # ##################  WAKEUP_R_PM
    ${time_stamp_r_pm_1}  Get Time  epoch
    ${result}  PLD Read WSA Register  ${SERIAL_HANDLE}
    ${wsa_r_pm}  Get From Dictionary  ${result}  R_PM
    LOG  ${wsa_r_pm}
    Should Be Equal  ${wsa_r_pm}  ${LOGIC_HIGH}

    Sleep  0.5s

    CANoe Set Relay Active  WAKEUP_R_PM
    Sleep  0.5s
    ${time_stamp_r_pm_2}  Get Time  epoch
    ${result}  PLD Read WSA Register  ${SERIAL_HANDLE}
    ${wsa_r_pm}  Get From Dictionary  ${result}  R_PM
    LOG  ${wsa_r_pm}
    Should Be Equal  ${wsa_r_pm}  ${LOGIC_LOW}
    CANoe Set Relay Inactive  WAKEUP_R_PM
    Sleep  1.5s

    ${time_stamp_r_pm_3}  Get Time  epoch
    ${result}  PLD Read WSA Register  ${SERIAL_HANDLE}
    ${wsa_r_pm}  Get From Dictionary  ${result}  R_PM
    LOG  ${wsa_r_pm}
    Should Be Equal  ${wsa_r_pm}  ${LOGIC_HIGH}

    Sleep  0.5s

    # ##################  WAKEUP_ASSISTANCE_BUTTON
    ${time_stamp_asst_1}  Get Time  epoch
    ${result}  PLD Read WSA Register  ${SERIAL_HANDLE}
    LOG  ${result}
    ${wsa_asst_btn}  Get From Dictionary  ${result}  ASSIST_BTN
    LOG  ${wsa_asst_btn}
    Should Be Equal  ${wsa_asst_btn}  ${LOGIC_LOW}

    Sleep  0.5s

    CANoe Set Relay Active  WAKEUP_ASSISTANCE_BUTTON_L
    Sleep  0.5s
    ${time_stamp_asst_2}  Get Time  epoch
    ${result}  PLD Read WSA Register  ${SERIAL_HANDLE}
    ${wsa_asst_btn}  Get From Dictionary  ${result}  ASSIST_BTN
    LOG  ${wsa_asst_btn}
    Should Be Equal  ${wsa_asst_btn}  ${LOGIC_HIGH}

    CANoe Set Relay Inactive  WAKEUP_ASSISTANCE_BUTTON_L
    Sleep  0.5s

    ${time_stamp_asst_3}  Get Time  epoch
    ${result}  PLD Read WSA Register  ${SERIAL_HANDLE}
    ${wsa_asst_btn}  Get From Dictionary  ${result}  ASSIST_BTN
    LOG  ${wsa_asst_btn}
    Should Be Equal  ${wsa_asst_btn}  ${LOGIC_LOW}

    Sleep  5.0s

    Wait Until Processing Done  ${120.0}

    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${pld_read}=  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY  csv_density=ROW_PER_CHANGE
    Wait Until Processing Done  ${120.0}
    ${resulting_list}=  CSV Read To List  ${pld_read}

    ${spi_time_start}=   Evaluate  float(${time_stamp_r_pm_1}-${time_stamp_0}-${1.0})
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp  ${resulting_list}  ${spi_time_start}   WSA  ${0}  ${1}  # WAKEUP_R_PM shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp  ${resulting_list}  ${next_spi_access}  WSA  ${0}  ${0}  # WAKEUP_R_PM shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp  ${resulting_list}  ${next_spi_access}  WSA  ${0}  ${1}  # WAKEUP_R_PM shall be 1

    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp  ${resulting_list}  ${next_spi_access}  WSA  ${1}  ${0}  # WAKEUP_ASSISTANCE_BUTTON shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp  ${resulting_list}  ${next_spi_access}  WSA  ${1}  ${1}  # WAKEUP_ASSISTANCE_BUTTON shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp  ${resulting_list}  ${next_spi_access}  WSA  ${1}  ${0}  # WAKEUP_ASSISTANCE_BUTTON shall be 0

Read Write FPGA Registers
    [Documentation]  Read FPGA Latched Register (WSL) and verify that the SPI transfer is according to specification.
    ...              The Wakeup Source Mask register (WSM) is also verified as part of the WSL register verification.
    ...              The PGCR register is also verified for all bits during the antenna switch in the end of the test case.
    ...              The test case verifies:
    ...                 That the clock frequency on SPI is not over 1MHz
    ...                 That the idle time between SPI reads is more than 3us
    ...                 That the DIR and SEL bits is set correctly
    ...                 Some of the selected register bits
    [Tags]    TGW2.1  LOW_LEVEL_RW_FPGA_REG

    ${active_device}=  Get Device From Name List  ${TC_ACTIVITY_REGISTER}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}=  Map Names To Channels  ${active_device}  ${TC_ACTIVITY_REGISTER}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}=  Get Active Channels

    ${AllSamplerates}=  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  60.0

    LOG To Console  Start recording signals
    ${time_stamp_0}  Get Time  epoch
    Capture Start

    # Power on the TGW
    CANoe Set Power Supply On  VBAT

    ${result}=  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    ${time_stamp_boot_1}  Get Time  epoch
    ${result}  PLD Read WSL Register  ${SERIAL_HANDLE}
    LOG  ${result}
    ${wsl_asst_btn}  Get From Dictionary  ${result}  ASSIST_BTN
    ${wsl_r_pm}      Get From Dictionary  ${result}  R_PM
    Should Be Equal  ${wsl_asst_btn}  ${LOGIC_LOW}
    Should Be Equal  ${wsl_r_pm}      ${LOGIC_LOW}

    # ---------------------------- WAKEUP_R_PM --------------------------
    Pow off  ${SERIAL_HANDLE}  0  # WAKEUP_R_PM always enabled

    Sleep  1s
    CANoe Set Relay Active  WAKEUP_R_PM
    Sleep  1s
    CANoe Set Relay Inactive  WAKEUP_R_PM
    Sleep  1s

    ${result}=  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    ${time_stamp_boot_2}  Get Time  epoch
    ${result}=  Pow Get Wsrc  ${SERIAL_HANDLE}
    Should be equal  ${result}  Wakeup source <WAKEUP_R_CPU> active.

    ${result}  PLD Read WSL Register  ${SERIAL_HANDLE}
    LOG  ${result}
    ${wsl_asst_btn}  Get From Dictionary  ${result}  ASSIST_BTN
    ${wsl_r_pm}      Get From Dictionary  ${result}  R_PM
    Should Be Equal  ${wsl_asst_btn}  ${LOGIC_LOW}
    Should Be Equal  ${wsl_r_pm}      ${LOGIC_HIGH}

    Sleep  5s

    # ---------------------------- WAKEUP_ASSISTANCE_BUTTON_L --------------------------
    Pow off  ${SERIAL_HANDLE}  2

    Sleep  1s
    CANoe Set Relay Active  WAKEUP_ASSISTANCE_BUTTON_L
    Sleep  1s
    CANoe Set Relay Inactive  WAKEUP_ASSISTANCE_BUTTON_L
    Sleep  1s

    ${result}=  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    ${time_stamp_boot_3}  Get Time  epoch
    ${result}=  Pow Get Wsrc  ${SERIAL_HANDLE}
    Should be equal  ${result}  Wakeup source <WAKEUP_ASSISTANCE_BUTTON> active.

    ${result}  PLD Read WSL Register  ${SERIAL_HANDLE}
    LOG  ${result}
    ${wsl_asst_btn}  Get From Dictionary  ${result}  ASSIST_BTN
    ${wsl_r_pm}      Get From Dictionary  ${result}  R_PM
    ${wsl_ant_sel}   Get From Dictionary  ${result}  GSM_ANT_SEL
    Should Be Equal  ${wsl_asst_btn}  ${LOGIC_HIGH}
    Should Be Equal  ${wsl_r_pm}      ${LOGIC_LOW}
    Should Be Equal  ${wsl_ant_sel}   ${LOGIC_LOW}

    ${result}  GSM Modem Set Antenna Select  ${SERIAL_HANDLE}  2
    Should be equal  ${result}  TGW_TEST_SUCCESS

    ${result}  GSM Modem Get Antenna Select  ${SERIAL_HANDLE}
    Should be equal  ${result}  TGW_TEST_SUCCESS:2

    ${result}  PLD Read WSL Register  ${SERIAL_HANDLE}
    LOG  ${result}
    ${wsl_asst_btn}  Get From Dictionary  ${result}  ASSIST_BTN
    ${wsl_r_pm}      Get From Dictionary  ${result}  R_PM
    ${wsl_ant_sel}   Get From Dictionary  ${result}  GSM_ANT_SEL
    Should Be Equal  ${wsl_asst_btn}  ${LOGIC_HIGH}
    Should Be Equal  ${wsl_r_pm}      ${LOGIC_LOW}
    Should Be Equal  ${wsl_ant_sel}   ${LOGIC_HIGH}

    Wait Until Processing Done  ${60.0}

    Save measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${pld_read}=  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY  csv_density=ROW_PER_CHANGE
    Wait Until Processing Done  ${120.0}
    ${resulting_list}=  CSV Read To List  ${pld_read}

    ${result}=           Get All FPGA SPI Data After Timestamp  ${resulting_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS1  ${0.0}
    LOG  ${result}

    ${t_spi_on}=  Find Digital Channel Transition  ${resulting_list}  SPI_SS1  ${0.0}  True
    LOG  SPI start @ ${t_spi_on}
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${t_spi_on}          WSL    ${0}  ${0}  # WAKEUP_R_PM shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${t_spi_on}          WSL    ${1}  ${0}  # WAKEUP_ASSISTANCE_BUTTON shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${t_spi_on}          WSL    ${6}  ${0}  # GSM power state shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${t_spi_on}          WSL    ${7}  ${0}  # GSM Antenna selected state shall be 0

    ${spi_time_start}=   Evaluate  float(${time_stamp_boot_1}-${time_stamp_0}-${1.0})
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${0}  ${0}  # WAKEUP_R_PM shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${1}  ${0}  # WAKEUP_ASSISTANCE_BUTTON shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${6}  ${1}  # GSM power state shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${7}  ${0}  # GSM Antenna selected state shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${next_spi_access}   WSM    ${0}  ${0}  # WAKEUP_R_PM set to 0 (Dummy write, always active)
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${next_spi_access}   PGCR   ${0}  ${1}  # OFF_CPU set to 1 to reboot the CPU

    ${spi_time_start}=   Evaluate  float(${time_stamp_boot_2}-${time_stamp_0}-${1.0})
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${0}  ${1}  # WAKEUP_R_PM shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${1}  ${0}  # WAKEUP_ASSISTANCE_BUTTON shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${6}  ${1}  # GSM power state shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${7}  ${0}  # GSM Antenna selected state shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${next_spi_access}   WSM    ${1}  ${1}  # WAKEUP_ASSISTANCE_BUTTON set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${next_spi_access}   PGCR   ${0}  ${1}  # OFF_CPU set to 1 to reboot the CPU

    ${spi_time_start}=   Evaluate  float(${time_stamp_boot_3}-${time_stamp_0}-${1.0})
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${0}  ${0}  # WAKEUP_R_PM shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${1}  ${1}  # WAKEUP_ASSISTANCE_BUTTON shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${6}  ${1}  # GSM power state shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${7}  ${0}  # GSM Antenna selected state shall be 0

    ${spi_time_start}=   Set Variable  ${next_spi_access}
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${0}  ${0}  # CPU_OFF shall be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${1}  ${1}  # PGSM_ON shall still be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${4}  ${0}  # GSM_VBUS_ON shall be set to 0

    ${spi_time_start}=   Set Variable  ${next_spi_access}
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${0}  ${0}  # CPU_OFF shall be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${1}  ${0}  # PGSM_ON shall be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${2}  ${0}  # ANT_SEL shall still be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${4}  ${0}  # GSM_VBUS_ON shall be set to 0

    ${spi_time_start}=   Set Variable  ${next_spi_access}
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${0}  ${0}  # CPU_OFF shall be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${1}  ${0}  # PGSM_ON shall be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${2}  ${1}  # ANT_SEL shall be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${3}  ${1}  # GSM_READY shall be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${4}  ${0}  # GSM_VBUS_ON shall be set to 0

    ${spi_time_start}=   Set Variable  ${next_spi_access}
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${0}  ${0}  # CPU_OFF shall be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${1}  ${1}  # PGSM_ON shall be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${2}  ${1}  # ANT_SEL shall still be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${3}  ${1}  # GSM_READY shall be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${4}  ${0}  # GSM_VBUS_ON shall be set to 0

    Run Keyword If  '${TGW_MODEM}' == 'AHS3-W'
    ...  ${next_spi_access}=  Check PGCR GSM VBUS ON  ${resulting_list}  ${spi_time_start}  ${next_spi_access}

    ${spi_time_start}=   Set Variable  ${next_spi_access}
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${0}  ${0}  # WAKEUP_R_PM shall be 0
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${1}  ${1}  # WAKEUP_ASSISTANCE_BUTTON shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${6}  ${1}  # GSM power state shall be 1
    ${next_spi_access}=  Verify Bit Value For A SPI Read Access After Timestamp   ${resulting_list}  ${spi_time_start}    WSL    ${7}  ${1}  # GSM Antenna selected state shall be 1

Wifi Power On Off
    [Documentation]  Verify that signals have correct timing. To enable the WIFI-chip these three signals
    ...              needed to be controlled WIFI_PWR_ON_B, RESET_B_WLAN and WLAN_EN.
    ...              Functionality is not available when SLEEP signal low, inactive to reduce power consumption.
    ...              The Sleep signal is monitored to be able to verify that the Wifi chip is enabled when requested
    ...              ---
    ...              Timings used in this TC for WiFi Power ON:
    ...              t0_On: WIFI_PWR_ON_B goes low,
    ...                     RESET_B_WLAN goes high
    ...              t1_On: Edge of WLAN_EN is raised
    ...              t2_On: Rising edge of SLEEP
    ...              ---
    ...              Timings used in this TC for WiFi Power OFF:
    ...              t0_Off: Edge of WLAN_EN goes low
    ...                      Lowering edge of SLEEP to low
    ...              t1_Off: WIFI_PWR_ON_B goes high,
    ...                      RESET_B_WLAN goes low

    [Tags]    TGW2.1    LOW_LEVEL_WIFI_POWER

    ${active_device}  Get Device From Name List  ${TC_WIFI_POWER_ON_OFF}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${TC_WIFI_POWER_ON_OFF}
    LOG  ${DigitalChannels}
    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  30.0
    Capture Start

    CANoe Set Power Supply On  VBAT
    ${result}=  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    # Do Test
    WiFi Pow                    ${SERIAL_HANDLE}          on        ACTIVE
    Sleep   5.0s
    WiFi Pow                    ${SERIAL_HANDLE}          off        ACTIVE
    Sleep   5.0s
    CANoe Set Power Supply Off  VBAT
    Wait Until Processing Done  ${120.0}

    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${wifi_power_on_capture}  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY   csv_density=ROW_PER_CHANGE
    Wait Until Processing Done  ${120.0}

    ${resulting_list}  CSV Read To List  ${wifi_power_on_capture}

    # -------------- Check Wifi Oon  --------------------
    # Set timing requirements, low and high values for each timing.
    ${t0t1_reqH}=       Set Variable  ${0.001}
    ${t1t2_On_Sleep}=   Set Variable  ${0.005}   # after firmware download

    # Check timings
    ${startOfTest}  Find Digital Channel Transition  ${resulting_list}  WIFI_PWR_ON_B  ${t0}           True  # TGW ON
    #t0
    ${t0_On}        Find Digital Channel Transition  ${resulting_list}  WIFI_PWR_ON_B  ${startOfTest}  False
    ${t0_On_Reset}  Find Digital Channel Transition  ${resulting_list}  RESET_B_WLAN   ${startOfTest}  True
    ${t0_On_t0_On_Reset}      Get Time Difference    ${t0_On}     ${t0_On_Reset}
    Should Be True  ${t0_On_t0_On_Reset} < ${0.00001}   # WIFI_PWR_ON_B and RESET_B_WLAN almost active at the same time
    # t0 -> t1
    ${t1_On}        Find Digital Channel Transition  ${resulting_list}  WLAN_EN        ${startOfTest}  True
    ${t0t1_On}      Get Time Difference  ${t0_On}  ${t1_On}
    LOG  ${t0t1_On}
    Should Be True  ${t0t1_On} > ${t0t1_reqH}
    #t1 -> t2
    ${t2_On}        Find Digital Channel Transition  ${resulting_list}  SLEEP          ${startOfTest}  True
    Should Be True  ${t2_On} > ${t1_On}
    ${t1t2_On}      Get Time Difference  ${t1_On}  ${t2_On}
    LOG  ${t1t2_On}
    Should Be True  ${t1t2_On} < ${t1t2_On_Sleep}

    # -------------- Check Wifi Off  --------------------
    # ${t2_On} end of start Wifi power On and start of Wifi power Off test.
    # Set timing requirements, low and high values for each timing.
    ${t0t1_Off_reqH}=  Set Variable  ${0.001}

    # Check timings
    # t0
    ${t0_Off}        Find Digital Channel Transition  ${resulting_list}  WLAN_EN        ${t2_On}      False
    ${t0_Off_Sleep}  Find Digital Channel Transition  ${resulting_list}  SLEEP          ${t2_On}      False
    Should be equal   ${t0_Off}   ${t0_Off_Sleep}   # WLAN_EN and SLEEP inactive at the same time(sample)
    # t1
    ${t1_Off}        Find Digital Channel Transition  ${resulting_list}  RESET_B_WLAN   ${t0_Off}     False
    ${t1_Off_pwr}    Find Digital Channel Transition  ${resulting_list}  WIFI_PWR_ON_B  ${t0_Off}     True
    ${t0_Off_t1_Off_pwr}      Get Time Difference   ${t1_Off_pwr}   ${t0_Off}
    Should Be True  ${t0_Off_t1_Off_pwr} < ${0.00001}
    # t0 -> t1
    ${t0t1_Off}  Get Time Difference  ${t0_Off}  ${t1_Off}
    LOG  ${t0t1_Off}
    Should Be True  ${t0t1_Off} > ${t0t1_Off_reqH}
    Should Be True  ${t1_Off} > ${t0_Off}

FRAM Write Read
    [Documentation]  Writes and reads chunks (0-512 bytes) of the FRAM and verifies the SPI data-
    ...              (time, opcode, address, frequency and data) returned from the logic analyzer.
    [Tags]    TGW2.1

    ${DEBUG}=  Set Variable  ${0}
    ${start_time}=  Set Variable  ${-0.01}
    ${expected_value}=  Set Variable  0x55
    ${addr}=  Set Variable  ${-1}

    ${active_device}=  Get Device From Name List  ${TC_FRAM_WRITE_READ}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}=  Map Names To Channels  ${active_device}  ${TC_FRAM_WRITE_READ}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}=  Get Active Channels

    ${AllSamplerates}=  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  50000000  0
    Set Capture Duration In Seconds  0.2

    # Power on the TGW
    CANoe Set Power Supply On  VBAT

    ${result}=  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK

    LOG To Console  Start recording signals
    ${time_stamp}=  Get Time  epoch

    Set Trigger One Channel  ${active_device}  SPI_SS0  Negedge
    Sleep  2s
    Capture Start
    Sleep  2s

    FRAM Write  ${SERIAL_HANDLE}  ${DEBUG}
    FRAM Read  ${SERIAL_HANDLE}  ${DEBUG}

    Wait Until Processing Done  ${120.0}
    Save Measurement  ${TEST_NAME}
    Wait Until Processing Done  ${120.0}

    ${fram_write_read}=  Export Data  ${TEST_NAME}  ${DigitalChannels}  No_Analog  DIGITAL_ONLY  csv_density=ROW_PER_CHANGE
    Wait Until Processing Done  ${120.0}
    ${resulting_list}=  CSV Read To List  ${fram_write_read}

    :FOR  ${i}  IN RANGE  5
    \  ${start_time}  ${addr}=  Verify FRAM write sequence  ${resulting_list}  ${start_time}  ${expected_value}  ${addr}
    \  LOG  found write sequence ${i+1} / 5 at address: ${addr}, time: ${start_time}s  console=true

    ${addr}=  Set Variable  ${-1}

    :FOR  ${i}  IN RANGE  5
    \  ${start_time}  ${addr}=  Verify FRAM read sequence  ${resulting_list}  ${start_time}  ${expected_value}  ${addr}
    \  LOG  found read sequence ${i+1} / 5 at address: ${addr}, time: ${start_time}s  console=true

*** Keywords ***

Check PGCR GSM VBUS ON
    [Documentation]  Checks that VBUS is enabled via PGCR
    [Arguments]      ${resulting_list}  ${next_spi_access}
    [Return]         ${next_spi_access}

    ${spi_time_start}=   Set Variable  ${next_spi_access}
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${0}  ${0}  # CPU_OFF shall be set to 0
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${1}  ${1}  # PGSM_ON shall be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${2}  ${1}  # ANT_SEL shall still be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${3}  ${1}  # GSM_READY shall still be set to 1
    ${next_spi_access}=  Verify Bit Value For A SPI Write Access After Timestamp  ${resulting_list}  ${spi_time_start}    PGCR   ${4}  ${1}  # GSM_VBUS_ON shall still be set to 1

Verify FRAM read sequence
    [Documentation]  Reads one chunk (0-512 bytes) SPI data and verifies the content.
    [Arguments]      ${resulting_list}  ${start_time}  ${expected_value}  ${prev_addr}
    [Return]         ${end_time}  ${addr}

    # Read data
    ${spi_data_result_1}=  Get FRAM SPI Data After Timestamp  ${resulting_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS0  ${start_time}
    ${end_time}=  Verify FRAM Transaction  ${spi_data_result_1}  ${expected_value}  ${prev_addr}  0x03
    ${addr}=  Get From Dictionary  ${spi_data_result_1}  addr

Verify FRAM write sequence
    [Documentation]  Reads one chunk (0-512 bytes) SPI data and verifies the content.
    [Arguments]      ${resulting_list}  ${start_time}  ${expected_value}  ${prev_addr}
    [Return]         ${end_time}  ${addr}

    # Enable FRAM Write
    ${fram_write_enable_result_1}=  Get FRAM SPI Data Byte At Timestamp  ${resulting_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS0  ${start_time}  ${True}
    ${next_time}=  Get From Dictionary  ${fram_write_enable_result_1}  end_time

    # Read data
    ${spi_data_result_1}=  Get FRAM SPI Data After Timestamp  ${resulting_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS0  ${next_time}
    ${end_time}=  Verify FRAM Transaction  ${spi_data_result_1}  ${expected_value}  ${prev_addr}  0x02
    ${addr}=  Get From Dictionary  ${spi_data_result_1}  addr

Verify FRAM Transaction
    [Documentation]  Verifies SPI data (time, opcode, address, frequency and data) returned from the logic analyzer.
    [Arguments]      ${result}  ${expected_value}  ${prev_addr}  ${expected_opcode}
    [Return]         ${end_time}

    ${start_time}=  Get From Dictionary  ${result}  start_time
    ${end_time}=    Get From Dictionary  ${result}  end_time
    ${opcode}=      Get From Dictionary  ${result}  opcode
    ${addr}=        Get From Dictionary  ${result}  addr
    ${freq}=        Get From Dictionary  ${result}  freq
    ${data}=        Get From Dictionary  ${result}  data

    # Verify time
    Should Be True  ${start_time} < ${end_time}

    # Verify opcode
    Should Be Equal  ${expected_opcode}  ${opcode}

    # Verify address
    ${addr}=  Convert To Integer  ${addr}
    ${old_addr}=  Convert To Integer  ${prev_addr}
    Should Be True  ${prev_addr} < ${addr}

    # Verify freq 12,5 MHz
    ${spi_freq}  Convert To Number  ${freq}
    Should Be True  ${12400000.0} < ${spi_freq}
    Should Be True  ${spi_freq} < ${12600000.0}

    # Verify data
    Should Not Be Empty  ${data}
    :FOR  ${value}  IN  @{data}
    \  Should Be Equal  ${value}  ${expected_value}

Verify Bit Value For A SPI Read Access After Timestamp
    [Documentation]  Verify a bit value for a SPI read sequence, 2 reads must be done by the CPU so both read accesses
    ...              are analyzed and miso data are feteched from the second read in the sequence.
    ...              The keyword also checks requirement on idle time between SPI reads clock frequency.
    [Arguments]  ${spi_list}  ${time_spi_access}  ${spi_reg}  ${bit_num}  ${expected_bit_val}
    [Return]     ${next_spi_access}

    ${spi_data_1}=  Get FPGA SPI Data After Timestamp  ${spi_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS1  ${time_spi_access}
    ${spi_time_1}=  Get From Dictionary  ${spi_data_1}  end_time
    ${spi_reg_1}=   Get From Dictionary  ${spi_data_1}  spi_reg
    ${spi_freq_1}=  Get From Dictionary  ${spi_data_1}  spi_freq

    ${spi_data_2}=  Get FPGA SPI Data After Timestamp  ${spi_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS1  ${spi_time_1}
    ${spi_reg_2}=   Get From Dictionary  ${spi_data_2}  spi_reg
    ${spi_time_2}=  Get From Dictionary  ${spi_data_2}  start_time
    ${spi_freq_2}=  Get From Dictionary  ${spi_data_2}  spi_freq

    # Check that space between SPI reads is within range
    ${time_diff}=   Evaluate  float(${spi_time_2})-float(${spi_time_1})
    Should Be True  ${time_diff}>${0.000030}
    Should Be True  ${time_diff}<${0.000100}

    Should Be Equal  ${spi_reg_1}  ${spi_reg}
    Should Be Equal  ${spi_reg_2}  ${spi_reg}

    # Check requirement Spec-SW-HW_265 (SPI clock speed shall be limited to 1MHz)
    Should Be True  ${spi_freq_1}<${1000000.0}
    Should Be True  ${spi_freq_2}<${1000000.0}

    ${spi_miso}=      Get From Dictionary  ${spi_data_2}  spi_miso
    ${spi_miso_i}=    Convert To Integer  ${spi_miso}

    ${result}=  Check Bit Value  ${spi_miso_i}  ${bit_num}  1  ${expected_bit_val}
    Should Be True  ${result}
    LOG  ${result}

    ${next_spi_access}=  Get From Dictionary  ${spi_data_2}  end_time

Verify Bit Value For A SPI Write Access After Timestamp
    [Documentation]  Verify a bit value for a SPI write sequence
    ...              The keyword also checks requirement on clock frequency.
    [Arguments]  ${spi_list}  ${time_spi_access}  ${spi_reg}  ${bit_num}  ${expected_bit_val}
    [Return]     ${next_spi_access}

    ${spi_data_1}=  Get FPGA SPI Data After Timestamp  ${spi_list}  SPI_SCLK  SPI_MOSI  SPI_MISO  SPI_SS1  ${time_spi_access}
    ${spi_reg_1}=   Get From Dictionary  ${spi_data_1}  spi_reg
    ${spi_freq_1}=  Get From Dictionary  ${spi_data_1}  spi_freq

    Should Be Equal  ${spi_reg_1}  ${spi_reg}

    # Check requirement Spec-SW-HW_265 (SPI clock speed shall be limited to 1MHz)
    Should Be True  ${spi_freq_1}<${1000000.0}

    ${spi_mosi}=      Get From Dictionary  ${spi_data_1}  spi_mosi
    ${spi_mosi_i}=    Convert To Integer  ${spi_mosi}

    ${result}=  Check Bit Value  ${spi_mosi_i}  ${bit_num}  1  ${expected_bit_val}
    Should Be True  ${result}
    LOG  ${result}

    ${next_spi_access}=  Get From Dictionary  ${spi_data_1}  end_time

Count Number Of Read Acceses On SPI Before TimeStamp
    [Documentation]  Count Number Of Read Acceses On SPI with 0x40
    [Arguments]  ${timestamp}  @{spi_list}
    [Return]     ${num_spi_reads}

    ${num_spi_reads}=  Set Variable  ${0}
    :FOR  ${spi_item}  IN  @{spi_list}
    \   ${spi_reg}=   Get From Dictionary  ${spi_item}  spi_reg
    \   ${spi_time}=  Get From Dictionary  ${spi_item}  end_time
    \   Run Keyword If  ${spi_time}>${timestamp}  Exit For Loop
    \   ${num_spi_reads}  Set Variable If  '${spi_reg}'=='WSL'  ${num_spi_reads+1}  ${num_spi_reads}
    \   Run Keyword If  '${spi_reg}'!='WSL'  Exit For Loop

Disable All Triggers
    [Documentation]  Disable all triggers for the channels in the supplied list
    [Arguments]  ${active_device}  @{channel_list}

    :FOR  ${channel}  IN  @{channel_list}
    \  Set Trigger One Channel  ${active_device}  ${channel}  NoTrigger

Select Saleae Device and Wait Enum
    [Documentation]  Enable selected USB HUB port and wait for Saleae dev to enumerate
    [Arguments]  ${active_device}
    Enable Usb Hub Port  ${active_device}
    Wait For Device To Enumerate  ${active_device}
    Select Active Device  ${active_device}

Low Level Suite Setup
    [Documentation]  Suite setup sets Z flag and boots OSE with test application.
    LOG  Low Level Suite Setup
    Kill Saleae SW
    Connect To Acroname Hub
    Disable All USB Hub Ports
    BSP TestSuite Setup TFTP Boot
    ## Download OSE with test application built in
    ${result}  Write OSE TST To TGW And Set Z Flag  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_WRITTEN_AND_Z_SET_OK
    # Download firmware for wlan
    ${response}      Download Wifi Firmware And Reset    ${SERIAL_HANDLE}
    Should be equal       ${response}                 FIRMWARE_DOWNLOADED_OK
    Sleep  1.0s
    CANoe Set Power Supply Off  VBAT
    Sleep  4s

Low Level Suite Teardown
    [Documentation]  Suite teardown removes Z flag and powers of the TGW.
    LOG  Low Level Suite Teardown
    # Powers on and remove Z flag
    Canoe Set Power Supply Voltage  VBAT_Sup  24.0
    CANoe Set Power Supply On  VBAT
    ${result}  Wait OSE Boot And Prevent Reset  ${SERIAL_HANDLE}
    Should be equal  ${result}  OSE_BOOT_OK
    ${result}  Remove Z Flag From OSE TST Image  ${SERIAL_HANDLE}
    Should be equal  ${result}  FLAG_REMOVED_OK
    Disable All USB Hub Ports
    Disconnect From Acroname Hub
    BSP TestSuite Teardown

Low Level Test Setup
    [Documentation]  Start Saleae SW.
    LOG  Low Level Test Setup
    Start Saleae SW
    Sleep  5s

Low Level Test Teardown
    [Documentation]  Kill Saleae SW.
    LOG  Low Level Test Teardown
    Kill Saleae SW
    Disable All USB Hub Ports
    CANoe Set Power Supply Off  VBAT
    Canoe Set Power Supply Voltage  VBAT_Sup  24.0