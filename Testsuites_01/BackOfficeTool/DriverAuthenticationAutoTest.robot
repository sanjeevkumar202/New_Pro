
*** Settings ***
Documentation  This test suite will verify the functions of the BackOfficeTool
Library           Robot/Libs/BackOfficeTool/BackOfficeTool.py
Library           Collections
Library           Process
Library           OperatingSystem
Library           Robot/Libs/Common/CTATester.py
Library           Robot/Libs/Common/CANoeTester.py
Library           Robot/Libs/Common/VDPTester.py
Library           Robot/Libs/Common/TelnetClientTester.py
Library           Robot/Libs/Common/BusManager.py
Library           Robot/Libs/Common/LogManager.py
Library           Robot/Libs/HMI.py
Resource          Resources/TestSetup_kw.robot

Suite Setup       DriverAuth Suite Setup
Suite Teardown    DriverAuth Suite Teardown
Test Setup        DriverAuth Test Setup
Test Teardown     Basic Teardown

Force Tags        DriverAuthentication
...               TESP_VTC
...               TGW2.0      TGW2.1
...               CANOE_ONLY
...               DriverAuthenticationBackOfficeTool
...               UnderDevelopment
*** Variables ***
${tachoDr1Id}            1&#x1;&#x0;1000700111910000
${tachoDr1Nm}            Tacho
${klausId}               0klaus
${klausNm}               klaus

*** Keywords ***

LogOutManualDriver
    Log    Logging out...
	sleep 								5s
	#only one "down" to get to the Log out menu item
	HMI Push Button                     Down
	HMI Push Button                     Enter
	HMI Expect Page                     LogoutQPopup_page
	HMI Push Button                     Enter
	sleep								5s
	HMI Push Button                     Up
	HMI Wait For Page                   LoginMenu_page

HMI Login Klaus BOTool
    HMI Push Button                     Enter
    HMI Expect Page                     NewUserPopup_page
    HMI Type                            klaus
    HMI Push Button                     Enter
    HMI Expect Page                     PinPopup_page
    ${Klaus}=                           CTA Receive Message Async       ${driverLoginReqKlaus}
    HMI Type                            1111
    CTA Wait Until                      ${Klaus}
    HMI Expect Page                     VerifyingPopup_page
    CTA Send Message                    ${driverLoginResSuccKlaus}
    HMI Wait For Page                   WelcomeTextPopup_page
    HMI Wait For Page                   MainMenu_page

DriverAuth Suite Setup
    Basic Suite Setup
    Telnet TGW CLI Send Command                                 log disable=* *
    Telnet TGW CLI Send command         setpar /GLOBAL/VEHICLESETTINGS/STANDBYTIME=120
    Sleep    5s
    Telnet TGW CLI Send command         log enable=*DFSystemModeManager* *
    canoe set environment variable      EnvTachoStartStop        1
    canoe Set Environment Variable      EnvVehicleSpeed          0
	# do we really need the reset here?
	Bus Power Off
    Sleep    15s
    Bus Power ON
    CTA Wait Until Alive                5m
    Sleep    30s
    StartTESPSID
    ${driveLoginResFailDriver1}=       Build Driver Login Res PDU       failedUnknownDriver     ${tachoDr1Id}      ${tachoDr1Nm}
    Set Global variable     		   ${driveLoginResFailDriver1}
    ${driverLoginReqKlaus}=            Build Driver Login Req PDU       ${klausId}                  1111
    Set Global variable     		   ${driverLoginReqKlaus}
	${driverLoginResSuccKlaus}=        Build Driver Login Res PDU       successful              ${klausId}    ${klausNm}
	Set Global variable     		   ${driverLoginResSuccKlaus}
    ${cleanoutdriversconfig}=          Build Driver Login Config PDU    0                       1         4000     True
    Set Global variable     		   ${cleanoutdriversconfig}
	${driverLoginConfig}=              Build Driver Login Config PDU   	10                      40000     40000    True
    Set Global variable     		   ${driverLoginConfig}
	${driveLoginResFailKlaus}=         Build Driver Login Res PDU       failedUnknownDriver     ${klausId}     abc
	Set Global variable     		   ${driveLoginResFailKlaus}
	${driverLogOutReqKlaus}=           Build Logout Driver PDU        	${klausId}
	Set Global variable     		   ${driverLogOutReqKlaus}
    ${driverLoginReqDriver1}=          Build Driver Login Req PDU       ${tachoDr1Id}        1234
	Set Global variable     		   ${driverLoginReqDriver1}
	${driverLogoutReqDriver1}=         Build Logout Driver PDU          ${tachoDr1Id}
	Set Global variable     		   ${driverLogoutReqDriver1}
	${autoLogoutConfig}=               Build Driver Login Config PDU    10                      40000       40     True
	Set Global variable     		   ${autoLogoutConfig}

DriverAuth Test Setup
    canoe set environment variable      EnvDrivercardsDriver1    0
    Telnet TGW CLI Send Command                                 log disable=* *
    Basic Setup
    Bus Set Key Position                Drive
    CTA Send Message                    ${cleanoutdriversconfig}
    Sleep                               15s
    CTA Send Message                    ${driverLoginConfig}
    Sleep                               5s

DriverAuth Suite Teardown
    canoe set environment variable      EnvDrivercardsDriver1    0
    Remove Xml Files
    Basic Suite Teardown

TachoLoginDriver1
    Log    Inserting driver card...
    Sleep    20s

    canoe set environment variable      EnvDrivercardsDriver1    1
    CTA receive message                 ${driverLoginReqDriver1}

TachoLogoutDriver1
    Log    Removing driver card...
    canoe set environment variable      EnvDrivercardsDriver1    0

    CTA receive message                 ${driverLogoutReqDriver1}

Build Driver Login Req PDU
   [Documentation]  builds the below PDU
    ...             <?xml version="1.0" encoding="UTF-8"?>
    ...             <!-- PDU for service 10(Driver Authentication ) -->
    ...             <pdu service="10" version="3">
    ...               <driverLoginReq>
    ...                 <driverId> ${driverId}</driverId>
    ...                 <pincode> ${pinCode}</pincode>
    ...               </driverLoginReq>
    ...             </pdu>
    [Arguments]      ${driverId}     ${pinCode}
    Set Pdu                             DriverAuthentication
    Set Pdu Type                        driverLoginReq
    Set Pdu Data                        driverLoginReq.driverId     ${driverId}
    Set Pdu Data                        driverLoginReq.pincode      ${pinCode}
    ${request}=                         Get XML
    [return]                            ${request}

Build Driver Login Res PDU
   [Documentation]  builds the below PDU
    ...             <?xml version="1.0" encoding="UTF-8"?>
    ...             <!-- PDU for service 10(Driver Authentication ) -->
    ...             <pdu service="10" version="3">
    ...               <driverLoginResp>
    ...                 <loginState>
    ...                   <${loginState}>${loginState} num value </${loginState}>
    ...                 </loginState>
    ...                 <driverId>${driverId}</driverId>
    ...                 <driverName>${drivername}</driverName>
    ...               </driverLoginResp>
    ...             </pdu>
    [Arguments]     ${loginState}      ${driverId}      ${drivername}
    Set Pdu                             DriverAuthentication
    Set Pdu Type                        driverLoginResp
    Set Pdu Data                        driverLoginResp.loginState      ${loginState}
    Set Pdu Data                        driverLoginResp.driverId        ${driverId}
    Set Pdu Data                        driverLoginResp.driverName      ${drivername}
    ${request}=                         Get XML
    [Return]                            ${request}

Build Driver Login Config PDU
   [Documentation]  builds the below PDU
    ...             <?xml version="1.0" encoding="UTF-8"?>
    ...             <!-- PDU for service 10(Driver Authentication ) -->
    ...             <pdu service="10" version="3">
    ...               <driverLoginConfig>
    ...                 <nrOfCachedDrivers>${nrOfCachedDrivers}</nrOfCachedDrivers>
    ...                 <cleanOutTimeout>${cleanOutTimeout0</cleanOutTimeout>
    ...                 <autoLogoutTimeout>${autoLogoutTimeout}</autoLogoutTimeout>
    ...                 <driverloginEnable>${driverloginEnable}</driverloginEnable>
    ...               </driverLoginConfig>
    ...             </pdu>
    [Arguments]      ${nrOfCachedDrivers}       ${cleanOutTimeout}       ${autoLogoutTimeout}          ${driverloginEnable}
    Set Pdu                             DriverAuthentication
    Set Pdu Type                        driverLoginConfig
    Set Pdu Data                        driverLoginConfig.nrOfCachedDrivers       ${nrOfCachedDrivers}
    Set Pdu Data                        driverLoginConfig.cleanOutTimeout         ${cleanOutTimeout}
    Set Pdu Data                        driverLoginConfig.autoLogoutTimeout       ${autoLogoutTimeout}
    Set Pdu Data                        driverLoginConfig.driverloginEnable       ${driverloginEnable}
    ${request}=                         Get XML
    [Return]                            ${request}

Build Logout Driver PDU
   [Documentation]  builds the below PDU
   ...             <?xml version="1.0" encoding="UTF-8"?>
   ...             <!-- PDU for service 10(Driver Authentication ) -->
   ...             <pdu service="10" version="3">
   ...               <logoutDriver>
   ...                 <driverId>${driverId}</driverId>
   ...               </logoutDriver>
   ...             </pdu>
   [Arguments]                          ${driverId}
   Set Pdu                              DriverAuthentication
   Set Pdu Type                         logoutDriver
   Set Pdu Data                         logoutDriver.driverId   ${driverId}
   ${request}=                          Get XML
   [Return]                             ${request}

Remove Xml Files
    Remove File     		   ${driveLoginResFailDriver1}
    Remove File     		   ${driverLoginReqKlaus}
	Remove File     		   ${driverLoginResSuccKlaus}
    Remove File     		   ${cleanoutdriversconfig}
    Remove File     		   ${driverLoginConfig}
	Remove File     		   ${driveLoginResFailKlaus}
	Remove File     		   ${driverLogOutReqKlaus}
	Remove File     		   ${driverLoginReqDriver1}
	Remove File     		   ${driverLogoutReqDriver1}
	Remove File     		   ${autoLogoutConfig}

*** Test Cases ***

TachographLoginBackOfficeTool
    [Documentation]    Login to HMI using simulated tachograph driver. expecting response in CTA.
    [Tags]             TachographLoginBackofficeTool
    ...                BackofficeToolDriverAuthentication
    ...                UTESP
    ...                I2
    ...                SWRS 11014v25    SWRS 11020v18    SWRS 14992v7    SWRS 9004v20
    ...    TEA2Plus_VT
    ...    Bridge_VT
    ...    TEA2_VT
    Wait Until Keyword Succeeds         3m       1s   TachoLoginDriver1
    Sleep                               20s
    Wait Until Keyword Succeeds         3m       1s   TachoLogoutDriver1

FailTachographLoginBackOfficeTool
    [Documentation]    Login to HMI using simulated tachograph driver. expecting response in CTA.
    [Tags]             FailTachographLogin
    ...                SWRS 14994v3
    ...    TEA2Plus_VT
    ...    TEA2_VT
    HMI Expect Page                     LoginMenu_page
    TachoLoginDriver1
    Sleep                               10s
    CTA Send Message                    ${driveLoginResFailDriver1}
    HMI Wait For Page                   LoggedOutPopup_page
    Sleep                               10s
    HMI Expect Page                     LoginMenu_page
