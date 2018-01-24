*** Settings ***
Library           Collections
Library           Robot/Libs/Bsp/BspWifiTester.py
Library           Robot/Libs/Bsp/BspCommonTester.py
Resource          Robot/Libs/Bsp/BspResources.robot
#Library           Robot/Libs/Common/TelnetClientTester.py
#Library           Robot/Libs/Common/CANoeVTSTester.py
Library           String.py
Library         Process
#Library           String.py
Suite Setup       Wifi Suite Setup
Suite Teardown    Wifi Suite Teardown
Test Setup        Wifi Test Setup
Test Teardown     Wifi Test Teardown
Force Tags        Wifi          WLANWPS            BspWifi    #JIRA_ISSUE    OBT-6787

*** Variables ***
${VER}                          TGW2.1
${SETUP_TFTP_BOOT_COMPLETED}    SETUP_TFTP_BOOT_COMPLETED
${TELNET_HANDLE}
${SERIAL_HANDLE}
${unitSTA}                      0
${unitAP}                       1

${emulSn1}                      FBNPFP184409                    # placeholder for the SN of 1st device connected to the rig
${emulSn2}                      G6NPFP056806ZK3                 # placeholder for the SN of 2nd device connected to the rig
${macAddr1}                     F8:32:E4:E0:88:53               # placeholder for the MAC address of 1st device connected to the rig
${macAddr2}                     9C:5C:8E:E3:9B:12               # placeholder for the MAC address of 2nd device connected to the rig
${emul_1}                   1
${emul_2}                   2

##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
*** Keywords ***
Change Pin
  [Arguments]                   ${pin}
  Wifi Remove Pin               ${SERIAL_HANDLE}           ACTIVE
  Sleep                         2s
  WiFi Set Pin                  ${SERIAL_HANDLE}           ${pin}           ACTIVE
  Sleep                         2s

Copy Robust
  [Arguments]       ${sourceDirectory}          ${distDirectory}
    ${results}=         Run Process        robocopy          ${sourceDirectory}      ${distDirectory}       stdout=STDOUT   shell=True
    Should Be Equal As Integers            ${results.rc}     1                       msg=${results.stdout}

Connect Tablet
  [Arguments]            ${ssid}                      ${emulator}                      ${expectation}       ${pin}=${None}
  ${emulSn}=             Set Variable If              ${emulator}==${emul_1}           ${emulSn1}           ${emulSn2}
  ${macAddr}=            Set Variable If              ${emulator}==${emul_1}           ${macAddr1}          ${macAddr2}
  Log                    ${pin}
  ${method}=             Set Variable If              ${pin}==${None}                  persistent           pin
  ${thePin}=             Set Variable If              '${method}'== 'pin'              ${pin}
  Run Keyword If        '${method}'== 'pin'           Wait Until Keyword Succeeds      3x    30s            Wifi Tablet Connect           ${SERIAL_HANDLE}     ${ssid}             ${emulSn}      ${macAddr}         ${expectation}          ${method}      ${thePin}
  Run Keyword If        '${method}'== 'persistent'    Wait Until Keyword Succeeds      3x    30s            Wifi Tablet Connect           ${SERIAL_HANDLE}     ${ssid}             ${emulSn}      ${macAddr}         ${expectation}          ${method}

Find Tablet Ip
  [Arguments]           ${emulator}
  ${emulSn}=            Set Variable If               ${emulator}==${emul_1}           ${emulSn1}          ${emulSn2}
  ${tabletIpa}=         Wait Until Keyword Succeeds       4 min	     10 sec            Get Tablet Ipa      ${SERIAL_HANDLE}    ${emulSn}      ACTIVE
  [Return]              ${tabletIpa}

Wifi Suite Setup
  ${response}=                  BSP Tftp Boot With Test App And Prevent Reset
  Should be equal               ${response}                       SETUP_TFTP_BOOT_COMPLETED
  ${response}=                  Change Firewall Status            ${SERIAL_HANDLE}                firewall_on=False
  Should be equal               ${response}                       FIREWALL_STATUS_CHANGED_OK

  ${response}=                  Change Tst Firewall Status        ${SERIAL_HANDLE}                firewall_on=False
  Should Be Equal               ${response}                       FIREWALL_STATUS_CHANGED_OK


  ${response}                   WiFi Activate                     ${SERIAL_HANDLE}                ACTIVE
  Wifi Flush Input              ${SERIAL_HANDLE}

  # Toggling airplane mode causes a reset of Android's Wi-Fi functionality
  # (This is needed because sometimes Wi-Fi hangs on some Android devices)

  Tablet Toggle Airplane        ${SERIAL_HANDLE}           1           ${emulSn2}
  sleep                         5s
  Tablet Toggle Airplane        ${SERIAL_HANDLE}           0           ${emulSn2}
  sleep                         5s
  Tablet Toggle Airplane        ${SERIAL_HANDLE}           1           ${emulSn1}
  sleep                         5s
  Tablet Toggle Airplane        ${SERIAL_HANDLE}           0           ${emulSn1}
  sleep                         5s
  #WiFi Pow                      ${SERIAL_HANDLE}           on          ACTIVE
  Switch WiFi                   on                         ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Wifi Suite Teardown
  #WiFi Pow                      ${SERIAL_HANDLE}           off                         ACTIVE
  Switch WiFi                   off                ACTIVE
  LOG                           Wifi Suite Teardown
  #${result}                     Remove Z Flag From OSE TST Image                        ${SERIAL_HANDLE}
  #Should be equal               ${result}                                               FLAG_REMOVED_OK
  Wait Until Keyword Succeeds    3x    60s    Remove Flash Content                       ${SERIAL_HANDLE}
  BSP TestSuite Teardown
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#

Wifi Test Setup
  BSP TestCase Setup With Watch Dog Teaser
  ${response}=                  Change Firewall Status                  ${SERIAL_HANDLE}                firewall_on=False
  Should be equal               ${response}                             FIREWALL_STATUS_CHANGED_OK
  ${response}=                  Change Tst Firewall Status              ${SERIAL_HANDLE}           firewall_on=False
  Should Be Equal               ${response}                             FIREWALL_STATUS_CHANGED_OK
  ${response}                   WiFi Activate                           ${SERIAL_HANDLE}           ACTIVE
  Wifi Flush Input              ${SERIAL_HANDLE}
  Sleep         5s

  Tablet Toggle Airplane        ${SERIAL_HANDLE}           1            ${emulSn2}
  Sleep                         5s
  Tablet Toggle Airplane        ${SERIAL_HANDLE}           0            ${emulSn2}
  Sleep                         5s
  Tablet Toggle Airplane        ${SERIAL_HANDLE}           1            ${emulSn1}
  Sleep                         5s
  Tablet Toggle Airplane        ${SERIAL_HANDLE}           0            ${emulSn1}
  Sleep                         30s

  Tablet Start Wifi App         ${SERIAL_HANDLE}           ${emulSn2}
  Sleep                         10s
  Tablet Start Wifi App         ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         10s

  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         2s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn2}
  Sleep                         2s

##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Wifi Test Short Setup
  BSP TestCase Setup With Watch Dog Teaser
  ${response}=                  Change Firewall Status                  ${SERIAL_HANDLE}                firewall_on=False
  Should be equal               ${response}                             FIREWALL_STATUS_CHANGED_OK
  ${response}=                  Change Tst Firewall Status              ${SERIAL_HANDLE}           firewall_on=False
  Should Be Equal               ${response}                             FIREWALL_STATUS_CHANGED_OK
  ${response}                   WiFi Activate                           ${SERIAL_HANDLE}           ACTIVE
  Wifi Flush Input              ${SERIAL_HANDLE}

##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Wifi Test Short Teardown
  Wifi Stop AP                  ${SERIAL_HANDLE}           ACTIVE
  ${logLocation}=               Get Ram Log                 ${SERIAL_HANDLE}       ${SUITE NAME}       ${TEST NAME}       ${OUTPUT DIR}      ${TGW_BOX_POS}     %{TFTP_ROOT}
  Copy Robust                   %{TFTP_ROOT}/testoutput_${TGW_BOX_POS}/${SUITE NAME}               ${OUTPUT DIR}/testoutput_${TGW_BOX_POS}/${SUITE NAME}        #%{BSP_TEST_OUTPUT_SUB_DIR}/${SUITE NAME}             #C:/BSP_TEST_NIGHTLY_OUTPUT/Nightly_Test_Tgw_1_Output/${SUITE NAME}               #%{BSP_TEST_OUTPUT_SUB_DIR}/${SUITE NAME}         #${OUTPUT DIR}/testoutput_${TGW_BOX_POS}/${SUITE NAME}

##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#

Wifi Test Setup For Ftp
  Wifi Test Setup
  ${response}                   Download And Run Ftpd       ${SERIAL_HANDLE}
  Should be Equal               ${response}                 FTP_SERVER_OK
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Wifi Test Teardown
  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}            ${emulSn2}
  Sleep                         5s
  Tablet Forget Wifi            ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         5s
  Tablet Forget Wifi            ${SERIAL_HANDLE}           ${emulSn2}
  Sleep                         5s
  Forget All Networks           ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         5s
  Forget All Networks           ${SERIAL_HANDLE}           ${emulSn2}
  Sleep                         5s

  #WiFi Tablet Disable           ${SERIAL_HANDLE}           ${emulSn2}              ACTIVE
  #Sleep                         2s
  #WiFi Tablet Disable           ${SERIAL_HANDLE}           ${emulSn1}              ACTIVE
  #Sleep                         2s
  Wifi Stop AP                  ${SERIAL_HANDLE}           ACTIVE
  ${logLocation}=               Get Ram Log                 ${SERIAL_HANDLE}       ${SUITE NAME}       ${TEST NAME}       ${OUTPUT DIR}      ${TGW_BOX_POS}     %{TFTP_ROOT}
  Copy Robust                   %{TFTP_ROOT}/testoutput_${TGW_BOX_POS}/${SUITE NAME}               ${OUTPUT DIR}/testoutput_${TGW_BOX_POS}/${SUITE NAME}        #%{BSP_TEST_OUTPUT_SUB_DIR}/${SUITE NAME}             #C:/BSP_TEST_NIGHTLY_OUTPUT/Nightly_Test_Tgw_1_Output/${SUITE NAME}               #%{BSP_TEST_OUTPUT_SUB_DIR}/${SUITE NAME}         #${OUTPUT DIR}/testoutput_${TGW_BOX_POS}/${SUITE NAME}
  Tablet Stop Wifi App          ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         5s
  Tablet Stop Wifi App          ${SERIAL_HANDLE}           ${emulSn2}
  Sleep                         5s
  Adb Kill                      ${SERIAL_HANDLE}
  #BSP TestCase Teardown
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Wifi Test Teardown For Ftp
  Remove File From TGW If Existing      ${SERIAL_HANDLE}      rtoze_s.zip         /flash/
  Remove File From TGW If Existing      ${SERIAL_HANDLE}      rtose_s_get.zip     /flash/
  Remove File From TGW If Existing      ${SERIAL_HANDLE}      rtose_s_put.zip     /flash/
  Wifi Test Teardown
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Get Serial Numbers
  ${deviceSn}                   Get Tablet Serial Numbers       ${SERIAL_HANDLE}       ACTIVE
  log to console                ${deviceSn}
  ${deviceOne}=                 Get From Dictionary             ${deviceSn}         device_one
  ${deviceTwo}=                 Get From Dictionary             ${deviceSn}         device_two
  Set Suite Variable            ${emulSn1}                      ${deviceOne}
  Set Suite Variable            ${emulSn2}                      ${deviceTwo}
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Get Mac Addresses
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid               ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  WiFi Start AP                 ${SERIAL_HANDLE}           ${ssid}             \            INACTIVE
  #WiFi Set Pin                  ${SERIAL_HANDLE}           ${pinOne}           ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Disable           ${SERIAL_HANDLE}           ${emulSn1}          ACTIVE
  WiFi Tablet Disable           ${SERIAL_HANDLE}           ${emulSn2}          ACTIVE
  Sleep                         5s
  WiFi Tablet Enable            ${SERIAL_HANDLE}           ${emulSn1}          ACTIVE
  Sleep                         10s
  ${mac}=                       Get Tablet Mac Address     ${SERIAL_HANDLE}    ${ssid}      ${emulSn1}      ACTIVE          ${pinOne}
  Set Suite Variable            ${MacAddr1}                ${mac}
  WiFi Tablet Disable           ${SERIAL_HANDLE}           ${emulSn1}          ACTIVE
  WiFi Tablet Enable            ${SERIAL_HANDLE}           ${emulSn2}          ACTIVE
  Sleep                         10s
  ${mac}=                       Get Tablet Mac Address      ${SERIAL_HANDLE}    ${ssid}     ${emulSn2}      ACTIVE          ${pinOne}
  Set Suite Variable            ${MacAddr2}                 ${mac}
  WiFi Tablet Disable           ${SERIAL_HANDLE}           ${emulSn2}           ACTIVE
  WiFi Stop AP                  ${SERIAL_HANDLE}           ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
Switch WiFi
  [Arguments]     ${status}        ${state}
  Wait Until Keyword Succeeds      3x      30s        WiFi Pow        ${SERIAL_HANDLE}        ${status}        ${state}
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
*** Test Cases ***
WifiWPSReconnectionTest
  [Documentation]               Tests that a client can reconnect using saved credentials (i.e. without PIN)
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi          TGW2.1             BSPRS 28125v2       BSPRS 28114v3         BSPRS 28118v4     #ManualTest
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid        ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}     on                ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}     ${ssid}           \                INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}     ${pinOne}         ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}     ${emulSn2}        ACTIVE
  sleep                         10s
  #Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn2}
  #Sleep                         5s
  Connect Tablet                ${ssid}              ${emul_2}     ACTIVEONE         ${pinOne}
  Sleep                         10s
  ${tabletIpa}=                 Find Tablet Ip       ${emul_2}
  Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn2}
  Sleep                         5s
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}     ${emulSn2}    ${macAddr2}       ACTIVE
  Sleep                         20s
  Connect Tablet                ${ssid}              ${emul_2}     ACTIVEONE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiPowerOnAndOff
  [Documentation]  This Test is to check if wifi power on and off is working correctly
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi                        TGW2.1                                 BSPRS 28134v1
  [Setup]                       Wifi Test Short Setup
  [Teardown]                    Wifi Test Short Teardown
  #WiFi Pow                      ${SERIAL_HANDLE}     off               ACTIVE
  Switch WiFi                   off                ACTIVE
  Wifi Status                   ${SERIAL_HANDLE}     ${unitSTA}        INACTIVEONE
  Wifi Status                   ${SERIAL_HANDLE}     ${unitAP}         INACTIVEONE
  #WiFi Pow                      ${SERIAL_HANDLE}     on                ACTIVE
  Switch WiFi                   on                ACTIVE
  Wifi Status                   ${SERIAL_HANDLE}     ${unitSTA}        INACTIVE
  Wifi Status                   ${SERIAL_HANDLE}     ${unitAP}         INACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiCountrySettings
  [Documentation]               Tests that country setting and tx_power information is updated in TGW
  [Tags]                        EXCLUDE_IF_NO_WLAN      BspWifi      TGW2.1      BSPRS 28114v3
  [Setup]                       Wifi Test Short Setup
  [Teardown]                    Wifi Test Short Teardown
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid        ${TGW_BOX_POS}
  ${keyOne}=                    Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}            on                 ACTIVE
  Switch WiFi                   on                ACTIVE
  ${tx_power}=                  Set Variable           15
  ${country}=                   Set Variable           DK

  WiFi Start AP                 ${SERIAL_HANDLE}        ${ssid}             \                   INACTIVE
  WiFi Set AP TX Power          ${SERIAL_HANDLE}        ${tx_power}         INACTIVE
  WiFi Get AP TX Power          ${SERIAL_HANDLE}        ${tx_power}
  WiFi Set AP 80211d            ${SERIAL_HANDLE}        ${country}          ${tx_power}         INACTIVE
  WiFi Get AP 80211d            ${SERIAL_HANDLE}        ${country}          ${tx_power}         ACTIVE
  WiFi Set AP 80211d State      ${SERIAL_HANDLE}        on                    INACTIVE
  WiFi Get AP 80211d State      ${SERIAL_HANDLE}        on                    ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSChangeKey
  [Documentation]               Tests that changing network key will invalidate the tablet's stored credentials
  [Tags]                        EXCLUDE_IF_NO_WLAN      BspWifi      TGW2.1      BSPRS 28114v3
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid        ${TGW_BOX_POS}
  ${keyOne}=                    Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}     on            ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         5s
  WiFi Start AP                 ${SERIAL_HANDLE}     ${ssid}       ${keyOne}     INACTIVETWO
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}     ${pinOne}     ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}     ${emulSn1}    ACTIVE
  Sleep                         10s
  #Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn1}
  #Sleep                         5s
  Connect Tablet                ${ssid}              ${emul_1}          ACTIVEONE         ${pinOne}
  ${tabletIpa}=                 Find Tablet Ip       ${emul_1}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn1}
  Sleep                         5s
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}     ${emulSn1}    ${macAddr1}   ACTIVE
  WiFi Stop AP                  ${SERIAL_HANDLE}     ACTIVE
  ${keyTwo}=                    Generate Net Key
  WiFi Start AP                 ${SERIAL_HANDLE}     ${ssid}       ${keyTwo}     INACTIVETWO
  Sleep                         5s
  Connect Tablet                ${ssid}              ${emul_1}          INACTIVETWO
  Wifi Status                   ${SERIAL_HANDLE}     ${unitAP}     INACTIVE
  WiFi Stop AP                  ${SERIAL_HANDLE}     ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSMACAddressOfAuthenticatedRemoteDevice
  [Documentation]               This test case aims to test whether MAC address of the conencted device is reported or not.
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi              TGW2.1             BSPRS 28124v6           BSPRS 28131v1
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid       ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}    on              ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         5s
  WiFi Start AP                 ${SERIAL_HANDLE}    ${ssid}         \                   INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}    ${pinOne}       ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}    ${emulSn1}      ACTIVE
  Sleep                         20s
  #Tablet Start Act And Bind     ${SERIAL_HANDLE}    ${emulSn1}
  #Sleep                         15s
  Connect Tablet                ${ssid}             ${emul_1}       ACTIVEONE           ${pinOne}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}    ${emulSn1}
  Sleep                         5s
  Wifi Status                   ${SERIAL_HANDLE}    ${unitAP}       ACTIVE
  ${tabletIpa}=                 Find Tablet Ip      ${emul_1}
  Sleep                         5s
  ${mac}=                       Get Tablet Mac Address              ${SERIAL_HANDLE}     ${ssid}          ACTIVE
  Should Be Equal               ${mac}              ${macAddr1}
  ${tabletIpa}=                 Find Tablet Ip      ${emul_1}
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}    ${emulSn1}      ${macAddr1}          ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSTryConnectUsingCorrectPin
  [Documentation]               This test case aims to test if the taplet could connect using correct PIN.
  [Tags]                        EXCLUDE_IF_NO_WLAN          BspWifi           TGW2.1          BSPRS 28113v4       BSPRS 28114v3       BSPRS 28126v3       BSPRS 28127v1
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid        ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}     on              ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}     ${ssid}         \               INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}     ${pinOne}       ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}     ${emulSn2}      ACTIVE
  sleep                         10s
  #Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn2}
  #Sleep                         15s
  Connect Tablet                ${ssid}           ${emul_2}          ACTIVEONE         ${pinOne}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn2}
  Wait Until Keyword Succeeds    2 min	   10 sec    Wifi Status     ${SERIAL_HANDLE}       ${unitAP}           ACTIVE
  ${tabletIpa}=                 Find Tablet Ip       ${emul_2}
  Should Not Be Equal           ${tabletIpa}         0.0.0.0
  WiFi Ping                     tablet               ${tabletIpa}    ${SERIAL_HANDLE}      ${emulSn2}       20      1
  Tablet Forget Wifi            ${SERIAL_HANDLE}     ${emulSn2}
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSTryConnectUsingWrongPin
  [Documentation]               Tests that the tablet cannot connect using wrong PIN and that the PIN is blocked thereafter.
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi                        TGW2.1                                 BSPRS 28126v3       BSPRS 28127v1       BSPRS 28130v1
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid           ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}        on              ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}        ${ssid}         \               INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}        ${pinOne}       ACTIVE
  Change Pin                    ${pinOne}
  ${wrongpin}=                  Generate Another Pin    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}        ${emulSn2}      ACTIVE
  Sleep                         15s
  #Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  #Sleep                         15s
  Connect Tablet                ${ssid}                 ${emul_2}       INACTIVEONE     ${wrongpin}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         2s
  WiFi Tablet Disable            ${SERIAL_HANDLE}        ${emulSn2}      ACTIVE
  Sleep                         2s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         2s
  WiFi Tablet Enable            ${SERIAL_HANDLE}        ${emulSn2}      ACTIVE
  #Sleep                         60s

  Sleep                         30s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         15s
  Connect Tablet                ${ssid}                 ${emul_2}       INACTIVE        ${wrongpin}
  #WIll disable and enable wifi to avoid the impact of multiple tries of android to connect
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         2s
  WiFi Tablet Disable            ${SERIAL_HANDLE}        ${emulSn2}      ACTIVE
  Sleep                         2s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         2s
  WiFi Tablet Enable            ${SERIAL_HANDLE}        ${emulSn2}      ACTIVE
  Sleep                         60s
  #Set new pin then try to connect in later steps
  #WiFi Set Pin                  ${SERIAL_HANDLE}        ${pinOne}       ACTIVE
  Change Pin                    ${pinOne}
  #Connection will succed
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         5s
  Connect Tablet                ${ssid}                 ${emul_2}       ACTIVEONE       ${pinOne}
  Sleep                         5s
  ${tabletIpa}=                 Find Tablet Ip          ${emul_2}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         5s
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}        ${emulSn2}     ${macAddr2}      ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSReportingDisconnectedDeviceUponStopAP
  [Documentation]               Tests that TGW is able to disconnect a connected device by stopping the access point and that the mac address of the diconnected device is reported upon disconnection.
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi                        TGW2.1                                 BSPRS 28123v4       BSPRS 28126v3       BSPRS 28129v3
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid         ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}      on            ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}      ${ssid}       \              INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}      ${pinOne}     ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}      ${emulSn1}    ACTIVE
  Sleep                         10s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}      ${emulSn1}
  Sleep                         15s
  Connect Tablet                ${ssid}               ${emul_1}          ACTIVEONE         ${pinOne}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}      ${emulSn1}
  Sleep                         5s
  WiFi Stop AP                  ${SERIAL_HANDLE}      INACTIVEONE   ${macAddr1}
  Sleep                         5s
  Wait Until Keyword Succeeds	   2 min	          10 sec	    Wifi Status                    ${SERIAL_HANDLE}           ${unitAP}           INACTIVE
  Sleep                         15s
  Connect Tablet                ${ssid}               ${emul_1}          INACTIVETWO         ${pinOne}
  Sleep                         10s
  Wait Until Keyword Succeeds	   2 min	          10 sec	    Wifi Status                    ${SERIAL_HANDLE}           ${unitAP}           INACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSReportingDisconnectedDeviceUponTabletChooseToDisconnect
  [Documentation]               This test case aims to test if the mac address of the disconnected device is reported upon disconnection.
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi                        TGW2.1                                     BSPRS 28126v3
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid         ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}     on             ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}     ${ssid}        \               INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}     ${pinOne}      ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}     ${emulSn2}     ACTIVE
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn2}
  Sleep                         15s
  Connect Tablet                ${ssid}              ${emul_2}      ACTIVEONE       ${pinOne}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}     ${emulSn2}
  Sleep                         5s
  ${tabletIpa}=                 Find Tablet Ip       ${emul_2}
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}                    ${emulSn2}      ${macAddr2}     ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSPinIsValidForMoreThanOneConnection
  [Documentation]               This test case aims to test if it is possible or not to connect a second new device using a PIN that is already used in connecting a first device
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi                        TGW2.1             BSPRS 28126v3
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid         ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}      on            ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}      ${ssid}       \              INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}      ${pinOne}     ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}      ${emulSn2}    ACTIVE
  Sleep                         10s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}      ${emulSn2}
  Sleep                         15s
  Connect Tablet                ${ssid}               ${emul_2}     ACTIVEONE      ${pinOne}
  Sleep                         10s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}      ${emulSn2}
  Sleep                         10s
  ${tabletIpa}=                 Find Tablet Ip       ${emul_2}
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}      ${emulSn2}    ${macAddr2}    ACTIVE
  Sleep                         10s
  WiFi Tablet Enable            ${SERIAL_HANDLE}      ${emulSn1}    ACTIVE
  Sleep                         10s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}      ${emulSn1}
  Sleep                         15s
  Connect Tablet                ${ssid}               ${emul_1}     ACTIVEONE      ${pinOne}
  Sleep                         10s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}      ${emulSn1}
  Sleep                         10s
  ${tabletIpa}=                 Find Tablet Ip       ${emul_1}
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}      ${emulSn1}    ${macAddr1}    ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSMaxNumberOfSimultaneouslyConnectedDevices
  [Documentation]               Tests connecting two devices using the same PIN one at a time and then that they can't be connected simultaneously
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi                        TGW2.1                 BSPRS 28126v3          BSPRS 28122v4
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid          ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}       on               ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}       ${ssid}          \                INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}       ${pinOne}        ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}       ${emulSn1}       ACTIVE
  sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}       ${emulSn1}
  Sleep                         15s
  Connect Tablet                ${ssid}                ${emul_1}       ACTIVEONE         ${pinOne}
  Sleep                         10s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}       ${emulSn1}
  Sleep                         10s
  #connection request of tablet 2 will be refused
  WiFi Tablet Enable            ${SERIAL_HANDLE}       ${emulSn2}       ACTIVE
  Sleep                         10s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}       ${emulSn2}
  Sleep                         15s
  Connect Tablet                ${ssid}                ${emul_2}       INACTIVETWO       ${pinOne}
  Sleep                         10s
  ${tabletIpa}=                 Find Tablet Ip         ${emul_1}
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}       ${emulSn1}      ${macAddr1}       ACTIVE
  Sleep                         15s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}       ${emulSn2}
  Sleep                         5s
  Connect Tablet                ${ssid}                ${emul_2}       ACTIVEONE         ${pinOne}
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}       ${emulSn2}
  Sleep                         10s
  Connect Tablet                ${ssid}                ${emul_1}       INACTIVETWO
  ${tabletIpa}=                 Find Tablet Ip         ${emul_2}
  Sleep                         5s
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}       ${emulSn2}      ${macAddr2}       ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSFtpTest
  [Documentation]               Tests the IP connection between tablet and TGW using FTP. Requires that the environment
  ...                           variable WORKSPACE points to the TFTP server directory.
  ...                           This test is decided to be run manually or done manually because of the unpredictability
  ...                           of the tools that are using in testing the FTP for example BusyBox and AndFTP
  [Setup]                       Wifi Test Setup For Ftp
  [Teardown]                    Wifi Test Teardown For Ftp
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi          TGW2.1              BSPRS 28113v4       ManualTest
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid         ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}      on                ACTIVE
  Switch WiFi                   on                ACTIVE
  WiFi Start AP                 ${SERIAL_HANDLE}      ${ssid}           \                  INACTIVE
  #WiFi Set Pin                  ${SERIAL_HANDLE}      ${pinOne}         ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}      ${emulSn1}        ACTIVE
  sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}      ${emulSn1}
  Sleep                         15s
  Connect Tablet                ${ssid}                ${emul_1}        ACTIVEONE        ${pinOne}
  ${tabletIpa}=                 Find Tablet Ip         ${emul_2}
  Tablet Ftp Get                ${SERIAL_HANDLE}       ${emulSn1}       ACTIVE
  Tablet Ftp Put                ${SERIAL_HANDLE}       ${emulSn1}       ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSRemovePinAffectOnNewDevices
  [Documentation]               After successful connection, disables PIN then enables the same PIN and tries to pair new device in both cases.
  [Tags]                        EXCLUDE_IF_NO_WLAN                BspWifi           TGW2.1             BSPRS 28127v1
  ${pinOne}=                    Generate Pin
  ${ssid}=                      Generate Ssid              ${TGW_BOX_POS}
  ${key}=                       Generate Net Key
  #WiFi Pow                      ${SERIAL_HANDLE}           on                  ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                 ${SERIAL_HANDLE}           ${ssid}              \                               INACTIVE
  Sleep                         1s
  #WiFi Set Pin                  ${SERIAL_HANDLE}           ${pinOne}           ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable            ${SERIAL_HANDLE}           ${emulSn1}      ACTIVE
  sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         15s
  Connect Tablet                ${ssid}                    ${emul_1}          ACTIVEONE        ${pinOne}
  sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         10s
  Wifi Status                   ${SERIAL_HANDLE}           ${unitAP}           ACTIVE
  Sleep                         5s
  Wifi Remove Pin               ${SERIAL_HANDLE}           ACTIVE
  ${tabletIpa}=                 Find Tablet Ip             ${emul_1}
  Sleep                         5s
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}           ${emulSn1}      ${macAddr1}         ACTIVE
  Sleep                         5s
  Wifi Status                   ${SERIAL_HANDLE}           ${unitAP}           INACTIVE
  sleep                         30s
  #try conenct new device for the first time and will fail as pin is removed. that will not affect the already paired device

  WiFi Tablet Enable            ${SERIAL_HANDLE}           ${emulSn2}      ACTIVE
  sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn2}
  Sleep                         15s
  Connect Tablet                ${ssid}                    ${emul_2}          INACTIVE        ${pinOne}
  sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn2}

  Sleep                         2s
  WiFi Tablet Disable            ${SERIAL_HANDLE}        ${emulSn2}      ACTIVE
  Sleep                         2s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}        ${emulSn2}
  Sleep                         60s
  # to ignore serial output from last conenction try.
  ${response}                   WiFi Activate                     ${SERIAL_HANDLE}                ACTIVE
  Wifi Flush Input              ${SERIAL_HANDLE}
  Connect Tablet                ${ssid}                    ${emul_1}          ACTIVEONE
  Sleep                         5s
  Tablet Start Act And Bind     ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                         10s
  Wifi Status                   ${SERIAL_HANDLE}           ${unitAP}           ACTIVE
  ${tabletIpa}=                 Find Tablet Ip             ${emul_1}
  WiFi Tablet Disconnect        ${SERIAL_HANDLE}           ${emulSn1}      ${macAddr1}         ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#
WifiWPSRemovePinAffectOnPairedDevices
  [Documentation]                After successful connection, disables PIN then enables a new PIN and tries to reconnect in both cases.
  [Tags]                         EXCLUDE_IF_NO_WLAN                BspWifi           TGW2.1             BSPRS 28127v1
  ${pinOne}=                     Generate Pin
  ${ssid}=                       Generate Ssid               ${TGW_BOX_POS}
  ${key}=                        Generate Net Key
  #WiFi Pow                       ${SERIAL_HANDLE}           on              ACTIVE
  Switch WiFi                   on                ACTIVE
  Sleep                         1s
  WiFi Start AP                  ${SERIAL_HANDLE}           ${ssid}         \               INACTIVE
  Sleep                         1s
  #WiFi Set Pin                   ${SERIAL_HANDLE}           ${pinOne}       ACTIVE
  Change Pin                    ${pinOne}
  WiFi Tablet Enable             ${SERIAL_HANDLE}           ${emulSn1}      ACTIVE
  Sleep                          10s
  Tablet Start Act And Bind      ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                          15s
  Connect Tablet                 ${ssid}                    ${emul_1}       ACTIVEONE       ${pinOne}
  Sleep                          5s
  Tablet Start Act And Bind      ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                          10s
  Wifi Status                    ${SERIAL_HANDLE}           ${unitAP}       ACTIVE
  Sleep                          5s
  Wifi Remove Pin                ${SERIAL_HANDLE}           ACTIVE
  ${tabletIpa}=                  Find Tablet Ip             ${emul_1}
  Sleep                          5s
  WiFi Tablet Disconnect         ${SERIAL_HANDLE}           ${emulSn1}      ${macAddr1}      ACTIVE
  Sleep                          5s
  Wifi Status                    ${SERIAL_HANDLE}           ${unitAP}       INACTIVE
  Sleep                          15s
  Connect Tablet                 ${ssid}                    ${emul_1}       ACTIVEONE
  Sleep                          10s
  Tablet Start Act And Bind      ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                          10s
  Wifi Status                    ${SERIAL_HANDLE}           ${unitAP}       ACTIVE
  sleep                          20s
  ${pinTwo}=                     Generate Pin
  sleep                          2s
  #WiFi Set Pin                   ${SERIAL_HANDLE}           ${pinTwo}       ACTIVE
  Change Pin                    ${pinOne}
  Sleep                          20s
  ${tabletIpa}=                  Find Tablet Ip             ${emul_1}
  Sleep                          5s
  WiFi Tablet Disconnect         ${SERIAL_HANDLE}           ${emulSn1}      ${macAddr1}     ACTIVE
  Sleep                          15s
  Connect Tablet                 ${ssid}                    ${emul_1}       ACTIVEONE
  Sleep                          5s
  ${tabletIpa}=                  Find Tablet Ip             ${emul_1}
  Sleep                          5s
  Wifi Status                    ${SERIAL_HANDLE}           ${unitAP}       ACTIVE
  ${tabletIpa}=                  Find Tablet Ip             ${emul_1}
  Sleep                          5s
  Tablet Start Act And Bind      ${SERIAL_HANDLE}           ${emulSn1}
  Sleep                          5s
  WiFi Tablet Disconnect         ${SERIAL_HANDLE}           ${emulSn1}      ${macAddr1}     ACTIVE
##---------------------------------------------------------------------------------------------------------------------#
##---------------------------------------------------------------------------------------------------------------------#

