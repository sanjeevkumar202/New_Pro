Documentation
... The ChassisID Adapter provide functionality retrieving the Chassis ID.
... Automatic test cases for Getting the ChassisId for TEA2+ EU,

*** Settings ***
Library           Collections
Library           String
Library           XML
Library           Libs/Common/CTATester.py
Library           Libs/Common/CANoeTester.py
Library           Libs/Common/TelnetClientTester.py
Library           Libs/Common/BusManager.py
Library           Libs/Common/LogManager.py
Library           Libs/Common/WebSocketHelper.py
Library           Libs/Common/NightlyEnv.py
Library           Libs/Common/CTATester.py
Library           Libs/Common/ResourceManager.py
Library           robot.api.logger
Resource          Libs/RESTUtils.txt
Library           Robot/Libs/Common/OSManager.py
Resource          Resources/TestSetup_kw.robot
Resource          Resources/TGWRoutines_kw.robot
Resource          Libs/Common/WlanHelper.txt

Suite Setup       Suite Setup
Suite Teardown    Chassi_Suite_Teardown
Test Setup        Test Setup
Test Teardown     Test Teardown

Force Tags    Chassis_ID_Rest    TGW2.1    REST    Rest_OverWLAN
    ...    TEA2Plus_VT
    ...    TEA2_VT
    ...    Bridge_VT
*** Variables ***

${xml_file_path1}   ${EXECDIR}${/}Resources${/}DECO${/}
${xml_file_path2}   ${EXECDIR}${/}Resources${/}DriverAuthentication${/}Common${/}
${xml_file_path3}   ${EXECDIR}${/}Resources${/}ChassisId${/}Dataset1_01.zip
${xml_file_path4}   ${EXECDIR}${/}Resources${/}ChassisId${/}Dataset1_02.zip
${xml_file_path5}   ${EXECDIR}${/}Resources${/}ChassisId${/}Dataset1_03.zip   #the name should be dataset2
${xml_file_path6}   ${EXECDIR}${/}Resources${/}ChassisId${/}Dataset1_04.zip   #the name should be dataset2
${xml_file_path7}   ${EXECDIR}${/}Resources${/}ChassisId${/}Dataset1_05.zip   #the name should be dataset2
${xml_file_path8}   ${EXECDIR}${/}Resources${/}ChassisId${/}Dataset1_06.zip   #the name should be dataset2


${FLEETURL}=           http://192.168.10.1:33080/api
${WS_FLEETURL}=        ws://192.168.10.1:33080

*** Test Cases ***

ChassisId_rest
    [Documentation]    The ChassisID Adapter provide functionality retrieving the Chassis ID.
    [Tags]             Chassis_ID_Rest
    ...                LD_Req-43362    LD_Req-43361    LD_Req-43360
	Copy File     ${xml_file_path3}     C:/ftp/Chassis
	Copy File     ${xml_file_path4}     C:/ftp/Chassis
	Copy File     ${xml_file_path5}     C:/ftp/Chassis
	Copy File     ${xml_file_path6}     C:/ftp/Chassis
	Copy File     ${xml_file_path7}     C:/ftp/Chassis
	Copy File     ${xml_file_path8}     C:/ftp/Chassis
	Sleep                              5s
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2PLUS'	Telnet TGW CLI Send command     swdwn srv=192.168.10.50 port=21 login=vtec_ftp pwd=vtec_read path=/Chassis/ Dataset1_01.zip
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2'	    Telnet TGW CLI Send command     swdwn srv=192.168.10.50 port=21 login=vtec_ftp pwd=vtec_read path=/Chassis/ Dataset1_03.zip
    Run Keyword If   '${ARCHITECTURE}' == 'BRIDGE'	    Telnet TGW CLI Send command     swdwn srv=192.168.10.50 port=21 login=vtec_ftp pwd=vtec_read path=/Chassis/ Dataset1_05.zip
	Sleep                              15s
	Restart TGW
	CTA Wait Until Alive                5m
	Sleep                              15s
	Run Keyword If          '${ENV}' == 'UTESP' and '${ARCHITECTURE}' == 'TEA2'   Connect Over Wifi           ${ssid}       #${ssid} is a global variable declared in WlanHelper library
	${Chas_ID}=    get  /chassisid
    dictionary should contain key  ${Chas_ID}  ChassisID
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2PLUS'    Dictionary Should Contain Item  ${Chas_ID}  ChassisID      1234567812345678
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2'        Dictionary Should Contain Item  ${Chas_ID}  ChassisID      12345678123456781
    Run Keyword If   '${ARCHITECTURE}' == 'BRIDGE'      Dictionary Should Contain Item  ${Chas_ID}  ChassisID      1234567812345678
	Sleep                              5s
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2PLUS'	Telnet TGW CLI Send command     swdwn srv=192.168.10.50 port=21 login=vtec_ftp pwd=vtec_read path=/Chassis/ Dataset1_02.zip
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2'	    Telnet TGW CLI Send command     swdwn srv=192.168.10.50 port=21 login=vtec_ftp pwd=vtec_read path=/Chassis/ Dataset1_04.zip
    Run Keyword If   '${ARCHITECTURE}' == 'BRIDGE'	    Telnet TGW CLI Send command     swdwn srv=192.168.10.50 port=21 login=vtec_ftp pwd=vtec_read path=/Chassis/ Dataset1_06.zip
	Sleep                              15s
	Restart TGW
	CTA Wait Until Alive                5m
	Run Keyword If          '${ENV}' == 'UTESP' and '${ARCHITECTURE}' == 'TEA2'       Connect Over Wifi       ${ssid}
	${Chas_ID}=    get  /chassisid
    Dictionary Should Contain Key  ${Chas_ID}  ChassisID
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2PLUS'    Dictionary Should Contain Item  ${Chas_ID}  ChassisID      Volvo_01Volvo_01
    Run Keyword If   '${ARCHITECTURE}' == 'TEA2'        Dictionary Should Contain Item  ${Chas_ID}  ChassisID      Volvo_01Volvo_011
    Run Keyword If   '${ARCHITECTURE}' == 'BRIDGE'      Dictionary Should Contain Item  ${Chas_ID}  ChassisID      Volvo_01Volvo_01
	WS Connect                      ${WS_FLEETURL}  timeout=10
    WS start pinger
    WS stop threads
    WS Close


*** Keywords ***


Suite Setup
    # Simple suite setup, performs basic setup and then starts the SID

    Basic Suite Setup
    Create New Directory                        C:/ftp/Chassis
    ${HEADERS}=  Create Dictionary  Content-Type  application/json  Accept  resourceVersion\=1
    Set Suite Variable  ${HEADERS}
    ${deepSleepTime}=  Set Variable  ${90}
    Set Suite Variable  ${deepSleepTime}

    CTA Wait Until Alive                5m
	${parameter_list}=    create list  standByTime
    ${val_list}=          create list  	90			#${deepSleepTime}
    Set Vehicle Parameter     ${parameter_list}      ${val_list}    
    Sleep                               11s
    # FIXME for now Bus Power Off
    Sleep                               10s
    Set Mode Accessory
    CTA Wait Until Alive                5m
    Run Keyword If          '${ENV}' == 'UTESP' and '${ARCHITECTURE}' == 'TEA2'    WLAN Preparation

Test Setup

    Set mode drive
    Basic Setup
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_01.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_01.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_02.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_02.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_03.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_03.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_04.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_04.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_05.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_05.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_06.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_06.zip
    Empty Given Directory                       C:/ftp/Chassis
    Remove Given Directory                      C:/ftp/Chassis
    Create New Directory                        C:/ftp/Chassis

Test Teardown

    WS Close
    Basic Teardown

Chassi_Suite_Teardown
    Basic suite teardown
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_02.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_02.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_01.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_01.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_03.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_03.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_04.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_04.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_05.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_05.zip
    Remove Readonly Attribute                   C:/ftp/Chassis/Dataset1_06.zip
    Add Write Attribute                         C:/ftp/Chassis/Dataset1_06.zip

    Empty Given Directory                       C:/ftp/Chassis
    Remove Given Directory                      C:/ftp/Chassis
    Run Keyword If          '${ENV}' == 'UTESP' and '${ARCHITECTURE}' == 'TEA2'       WLANHelper Suite Teardown


Set mode parked
    [Documentation]  Enter parked mode.
    Bus Power ON
    Bus On
    Bus Set Keypos and VM  Parked

Set mode accessory
    [Documentation]  Enter accessory mode.
    Bus Power ON
    Bus On
    Bus Set Keypos and VM  Accessory

Set mode drive
    [Documentation]  Enter drive mode.
    Bus Power On
    Bus On
    Bus Set Keypos and VM  Drive
