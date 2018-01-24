*** Settings ***
Documentation  This test suite will set up the TGW for BSP testing.

Library   OperatingSystem
Library   Robot/Libs/Bsp/BspCommonTester.py
Library   Robot/Libs/Common/CANoeVTSTester.py
Library   Robot/Libs/Bsp/BspSaleaeInterface.py
Library   Robot/Libs/Bsp/BspSaleaeOutputParser.py
Library   Robot/Libs/Bsp/BspSaleaeChannelMap.py
Library   Robot/Libs/Bsp/BspAcronameUsbHubTester.py
Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${KEY_WORD_CONNECTED}  [VBAT_ADC]

*** Test Cases ***
#*************************************************************************************************
# Test Suite Start
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Setup TFTP Boot  ${False}

TestSuite Start Small FS
  [Documentation]  Set Up the test suite
  [Tags]  FLASH_SMALL_FS_TEST
  BSP TestSuite Setup TFTP Small FS Boot

Setup TGW for BSP test
  [Documentation]  Set Up the TGW for BSP testing
  [Tags]  TGW2.0  TGW2.1  FLASH_SMALL_FS_TEST

  ${result}  Erase TGW Flash Memory  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_FLASH_ERASED_OK

  ${result}  Setup TGW Flash File Structure  ${SERIAL_HANDLE}
  Should be equal  ${result}  TGW_FLASH_SETUP_OK

Download executable files to TGW
  [Documentation]  Download all executable files to the TGW used for testing
  [Tags]  TGW2.0  TGW2.1  FLASH_SMALL_FS_TEST

  ${result}  Write Test Application To TGW From TFTP  ${SERIAL_HANDLE}
  Should be equal  ${result}  FILE_DOWNLOADED_OK

Check If Logic Analyzer Present
  [Documentation]  Check if the Logic Analyzer is connected to the TGW currently active
  [Tags]           TGW2.1  LOW_LEVEL
  [Setup]          Analyzer Present Test Setup
  [Teardown]       Analyzer Present Test Teardown

  ${saleae_connected}=  Check If Saleae Connected To TGW

  ${log_output}=  Set Variable If  ${saleae_connected}==${True}  CONNECTED  DISCONNECTED
  LOG  Saleae Logic Analyzer is ${log_output}  console=true

  ${inc_exc_data}=  Set Variable If  ${saleae_connected}==${True}  --include LOW_LEVEL  --exclude LOW_LEVEL
  Write Variable In File  ${inc_exc_data}

#*************************************************************************************************
# Test Suite End
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1  FLASH_SMALL_FS_TEST

  BSP TestSuite Teardown

  CANoe Close Application

*** Keywords ***
Select Saleae Device and Wait Enum
    [Documentation]  Enable selected USB HUB port and wait for Saleae dev to enumerate
    [Arguments]  ${active_device}
    Enable Usb Hub Port  ${active_device}
    Wait For Device To Enumerate  ${active_device}
    Select Active Device  ${active_device}

Check If Saleae Connected To TGW
    [Documentation]  Test if the Saleae is connected to the currently executing TGW
    [Return]  ${saleae_connected}

    ${active_device}  Get Device From Name List  ${KEY_WORD_CONNECTED}
    LOG  ${active_device}

    Select Saleae Device and Wait Enum  ${active_device}

    ${DigitalChannels}  Map Names To Channels  ${active_device}  ${KEY_WORD_CONNECTED}
    LOG  ${DigitalChannels}

    Set Active Channels  ${DigitalChannels}  None
    ${DigChannels}  ${AnChannels}  Get Active Channels

    ${AllSamplerates}  Get All Sample Rates
    LOG  ${AllSamplerates}
    Set Sample Rate By Minimum  2500000  0
    Set Capture Duration In Seconds  0.05

    Sleep  1.0s

    Capture Start And Wait Until Finished

    ${saleae_connected}  Export Data  is_saleae_connected  ${DigitalChannels}  No_Analog  DIGITAL_ONLY
    Wait Until Processing Done  ${120.0}
    ${resulting_list}  CSV Read To List  ${saleae_connected}

    ${vbat_adc_value}=  Get Sample Value  ${resulting_list}  VBAT_ADC  0.0

    ${saleae_connected}=  Evaluate  ${vbat_adc_value}==${1.0}

Write Variable In File
    [Documentation]  Write a file to filesystem containing include or exclude params
    [Arguments]  ${variable}
    Create File  ${EXECDIR}/extra_exclude_include_for_tgw_in_pos_${TGW_BOX_POS}.txt  ${variable}

Analyzer Present Test Setup
    [Documentation]  Start Saleae SW.
    LOG  Analyzer Present Test Setup
    Connect To Acroname Hub
    Disable All USB Hub Ports
    Start Saleae SW
    Sleep  2s

Analyzer Present Test Teardown
    [Documentation]  Kill Saleae SW.
    LOG  Analyzer Present Test Teardown
    Kill Saleae SW
    Disable All USB Hub Ports
    Disconnect From Acroname Hub
