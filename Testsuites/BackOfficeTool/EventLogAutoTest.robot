
*** Settings ***
Documentation  This test suite will verify the functions of the BackOfficeTool
Library           Robot/Libs/BackOfficeTool/BackOfficeTool.py
Library           XML
Library           String
Library           Robot/Libs/Common/TelnetClientTester.py
Library           Libs/Common/VDPTester.py
Library           Robot/Libs/Common/BusManager.py
Library           Robot/Libs/Common/CTATester.py
Library           Robot/Libs/Common/ResourceManager.py
Library           Robot/Libs/Common/CANoeTester.py
Library           Robot/Libs/Common/GetCurrentWeekDay.py
Resource          Robot/Libs/Common/UDDriverAuthenticationSupportKeywords.txt
Resource          Resources/TestSetup_kw.robot
Resource          Resources/TGWRoutines_kw.robot

#Suite Setup       Event Logging Test Suite Setup
#Suite Teardown    Event Logging Test Suite Teardown
#Test Setup        Event Logging Test Setup
#Test Teardown     Event Logging Test Tear Down

Suite Setup       Event Logging Test Suite Setup
Suite Teardown    Event Logging Test Suite Teardown
Test Setup        Event Logging Test Setup
Test Teardown     Event Logging Test Tear Down

Force Tags        EventLogging
...               EventLogAutoTestBOTool
...               UnderDevelopment
#...               Bridge
#...               AVT
#...               UTESP
#...               TGW2.0    TGW2.1
*** Variables ***
${Temp_Folder}          C:${/}TestEventLog
@{TPMPresWarning}   ExtremeOverPressure     OverPressure        NoWarningPressure       UnderPressure       ExtremeUnderPressure        Spare       Error       NotAvailable
@{TPMLeakageWarn}   NoLeakageDetected       SlowLeakageDetected        FastLeakageDetected       Spare1       Spare2        Spare3       Error      NotAvailable
@{TPMBattery}       BatteryOK               BatteryLow                 BatteryVeryLow            Spare1       Spare2        Spare3       Error      NotAvailable
@{outOfScopeMode}   Inactive                Active


*** Keywords ***
remove element from xml
    [Arguments]    ${xmlFile}
    ${req}=  Parse xml  ${xmlFile}
    ${newReqparsed}=        remove element   ${req}   xpath=logConfigReq/logPatternConfig/item/triggers/item/dataContentId
    save xml   ${newReqparsed}   ${xmlFile}
    #[Return]     ${request}
Set triggers lifetime
    [Documentation]  Set the begin time and duration of the triggers
    ...              configuration request. Return start time (GMT) for PC
    [Arguments]  ${pdu}  ${startdly}  ${duration}
    ${startPC}=  get current date  time_zone=UTC  increment=${startdly}
    # get TGW time
    ${t}=  telnet tgw os send command  date
    ${t}=  remove string  @{t}[0]  '\r'
    ${t}=  convert date  ${t.strip()}  date_format=%a %b %d %H:%M:%S GMT %Y
    ${start}=       add time to date  ${t}      ${startdly}  exclude_millis=true
    ${end}=         add time to date  ${start}  ${duration}  exclude_millis=true
    ${ltb}=         get elements  ${pdu}  logConfigReq/logPatternConfig/item/lifeTimeBegin
    :for  ${e}  in  @{ltb}
    \  set element text  ${e}  ${start}
    ${lte}=         get elements  ${pdu}  logConfigReq/logPatternConfig/item/lifeTimeEnd
    :for  ${e}  in  @{lte}
    \  set element text  ${e}  ${end}
    log element       ${pdu}
    [Return]   ${startPC}

Set vehicle speed
    [Arguments]   ${speed}  ${gear}=10
    [Documentation]  Set vehicle speed and proper engine speed as well.
    ${rpm}=  evaluate  40.0*${speed}
    ${rpm}=  set variable if   ${gear}==0   400
    ...                        ${speed}==0   0
    ...                        ${rpm}<400   400  ${rpm}
    vdp set  Speed   ${speed}   km/h
    vdp set  EngineSpeed  ${rpm}   rpm

Reset Tyre DB
    #  0:vehicle, 1:tireId   2: tireActive, 3:pressureReference, 4:pressureActual, 5:batteryStatus, 6:pressureWarningStatus, 7:leakageWarningStatus
    #____________________________________________________________________  TRUCK ____________________________________________________________________________
    set test variable  @{TruckTPM_Answers0}       0     99      1     150       2220         0              2            0           600000
    set test variable  @{TruckTPM_Answers1}       0     98      1     180       2000         0              2            0           12500000  @{TruckTPM_Answers0}
    set test variable  @{TruckTPM_Answers2}       0     97      1    1120         10         1              2            0           1000000   @{TruckTPM_Answers1}
    set test variable  @{TruckTPM_Answers3}       0     95      1     550        300         2              2            0           10000000  @{TruckTPM_Answers2}

    set test variable  @{TruckTPMTyreInfo_TyreId_Tyre}          99      98      97     95
    set test variable  @{TruckTPMTyreInfo_RefPres_Tyre}        150     180    1122    553
    set test variable  @{TruckTPMTyreInfo_Pressure_Tyre}      2220    2001      10    304
    set test variable  @{TruckTPMTyreInfo_Temperature_Tyre}      6     125      10    100
    set test variable  @{TruckTPMTyreInfo_Battery_Tyre}          0       0       1      2
    set test variable  @{TruckTPMTyreInfo_Active_Tyre}           1       1       1      1
    set test variable  @{TruckTPMTyreInfo_PresWarning_Tyre}      2       2       2      2
    set test variable  @{TruckTPMTyreInfo_LeakageWarn_Tyre}      0       0       0      0

    #____________________________________________________________________  TRAILER 1____________________________________________________________________________
    set test variable  @{Trailer1TPM_Answers0}    1    255      0    1500     550    0    2      1      600000
    set test variable  @{Trailer1TPM_Answers1}    1    241      0     180    2000    0    2      0      12500000      @{Trailer1TPM_Answers0}
    set test variable  @{Trailer1TPM_Answers2}    1    231      1    1120      10    1    2      0      1000000     @{Trailer1TPM_Answers1}
    set test variable  @{Trailer1TPM_Answers3}    1    228      1    2050     300    2    2      0      10000000     @{Trailer1TPM_Answers2}
    set test variable  @{Trailer1TPM_Answers4}    1    202      1     650     300    2    2      0      7000000     @{Trailer1TPM_Answers3}
    set test variable  @{Trailer1TPM_Answers5}    1    200      0    1500     550    0    2      1      600000     @{Trailer1TPM_Answers4}
    set test variable  @{Trailer1TPM_Answers6}    1    198      0     180    2000    0    2      0      12500000      @{Trailer1TPM_Answers5}
    set test variable  @{Trailer1TPM_Answers7}    1    196      1    1120      10    1    2      2      1000000      @{Trailer1TPM_Answers6}
    set test variable  @{Trailer1TPM_Answers8}    1    195      1    2050     300    2    1      1      10000000      @{Trailer1TPM_Answers7}
    set test variable  @{Trailer1TPM_Answers9}    1    194      1     650     300    2    0      0      7000000      @{Trailer1TPM_Answers8}
    set test variable  @{Trailer1TPM_Answers10}   1    193      0    1500     550    0    4      1      600000      @{Trailer1TPM_Answers9}
    set test variable  @{Trailer1TPM_Answers11}   1    191      0     180    2000    0    3      0      12500000      @{Trailer1TPM_Answers10}
    set test variable  @{Trailer1TPM_Answers12}   1    190      1    1120      10    1    2      2      1000000      @{Trailer1TPM_Answers11}
    set test variable  @{Trailer1TPM_Answers13}   1    189      1    2050     300    2    1      1      10000000      @{Trailer1TPM_Answers12}
    set test variable  @{Trailer1TPM_Answers14}   1    188      1     650     300    2    0      0      7000000      @{Trailer1TPM_Answers13}
    set test variable  @{Trailer1TPM_Answers15}   1    187      0    1500     550    0    4      1      600000      @{Trailer1TPM_Answers14}
    set test variable  @{Trailer1TPM_Answers16}   1    186      0     180    2000    0    3      0      12500000      @{Trailer1TPM_Answers15}
    set test variable  @{Trailer1TPM_Answers17}   1    185      1    1120      10    1    2      2      1000000      @{Trailer1TPM_Answers16}
    set test variable  @{Trailer1TPM_Answers18}   1    184      1    2050     300    2    1      1      10000000      @{Trailer1TPM_Answers17}
    set test variable  @{Trailer1TPM_Answers19}   1    183      1     650     300    2    0      0      7000000      @{Trailer1TPM_Answers18}
    set test variable  @{Trailer1TPM_Answers20}   1    182      0    1500     550    0    4      1      600000      @{Trailer1TPM_Answers19}
    set test variable  @{Trailer1TPM_Answers21}   1    181      0     180    2000    0    3      0      12500000      @{Trailer1TPM_Answers20}
    set test variable  @{Trailer1TPM_Answers22}   1    180      1    1120      10    1    2      2      1000000      @{Trailer1TPM_Answers21}
    set test variable  @{Trailer1TPM_Answers23}   1    179      1    2050     300    2    1      1      10000000      @{Trailer1TPM_Answers22}
    set test variable  @{Trailer1TPM_Answers24}   1    178      1     650     300    2    0      0      7000000      @{Trailer1TPM_Answers23}
    set test variable  @{Trailer1TPM_Answers25}   1    177      0    1500     550    0    4      1      600000      @{Trailer1TPM_Answers24}
    set test variable  @{Trailer1TPM_Answers26}   1    175      0     180    2000    0    3      0      12500000      @{Trailer1TPM_Answers25}
    set test variable  @{Trailer1TPM_Answers27}   1    174      1    1120      10    1    2      2      1000000      @{Trailer1TPM_Answers26}
    set test variable  @{Trailer1TPM_Answers28}   1    173      1    2050     300    2    1      1      10000000      @{Trailer1TPM_Answers27}
    set test variable  @{Trailer1TPM_Answers29}   1    172      1     650     300    2    0      0      7000000      @{Trailer1TPM_Answers28}
    set test variable  @{Trailer1TPM_Answers30}   1    171      0    1500     550    0    4      1      600000      @{Trailer1TPM_Answers29}
    set test variable  @{Trailer1TPM_Answers31}   1    170      0     180    2000    0    3      0      12500000      @{Trailer1TPM_Answers30}
    set test variable  @{Trailer1TPM_Answers32}   1    169      1    1120      10    1    2      2      1000000      @{Trailer1TPM_Answers31}
    set test variable  @{Trailer1TPM_Answers33}   1    168      1    2050     300    2    1      1      10000000      @{Trailer1TPM_Answers32}
    set test variable  @{Trailer1TPM_Answers34}   1    167      1     650     300    2    0      0      7000000      @{Trailer1TPM_Answers33}
    set test variable  @{Trailer1TPM_Answers35}   1    166      0    1500     550    0    4      1      600000      @{Trailer1TPM_Answers34}
    set test variable  @{Trailer1TPM_Answers36}   1    165      0     180    2000    0    3      0      12500000      @{Trailer1TPM_Answers35}
    set test variable  @{Trailer1TPM_Answers37}   1    164      1    1120      10    1    2      2      1000000      @{Trailer1TPM_Answers36}
    set test variable  @{Trailer1TPM_Answers38}   1    163      1    2050     300    2    1      1      10000000      @{Trailer1TPM_Answers37}
    set test variable  @{Trailer1TPM_Answers39}   1    162      1     650     300    2    0      0      7000000      @{Trailer1TPM_Answers38}

    set test variable  @{Trailer1TPMTyreInfo_TyreId_Tyre}          255     241     231     228     202     200         198     196         195         194         193     191     190     189     188     187     186     185     184     183     182     181     180     179     178     177     175     174     173     172     171     170     169     168     167     166     165     164     163     162     161
    set test variable  @{Trailer1TPMTyreInfo_RefPres_Tyre}        1500     180    1122    2050     645    1500        180    1122         2050        645         1500    180    1122     2050    645     1500    180    1122    2050    645     1500     180    1122    2050    645     1500     180    1122    2050    645     1500     180    1122    2050    645     1500     180    1122    2050    645     1500
    set test variable  @{Trailer1TPMTyreInfo_Pressure_Tyre}        550    2001      10     304     301     550         2001     0          304         301         550    2001     0       304     301     550     2001     0     304     301      550    2001     0       304    301      550     2001     0     304     301      550     2001     0      304    301      550    2001     0      304     301      550
    set test variable  @{Trailer1TPMTyreInfo_Temperature_Tyre}       6     125      10     100      70       6           125      10         100         70          6       125     10      100     70      6       125     10      100     70      6       125     10      100     70      6       125     10      100     70      6       125     10      100     70      6       125     10      100     70      6
    set test variable  @{Trailer1TPMTyreInfo_Battery_Tyre}           0       0       1       2       2       0           0       1           2           2           0       0       1       2       2       0       0       1       2       2       0       0       1       2       2       0       0       1       2       2       0       0       1       2       2       0       0       1       2       2       0
    set test variable  @{Trailer1TPMTyreInfo_Active_Tyre}            0       0       1       1       1       0           0       1           1           1           0       0       1       1       1       0       0       1       1       1       0       0       1       1       1       0       0       1       1       1       0       0       1       1       1       0       0       1       1       1       0
    set test variable  @{Trailer1TPMTyreInfo_PresWarning_Tyre}       2       2       2       2       2       2           2       2           1           0           4       3       2       1       0       4       3       2       1       0       4       3       2       1       0        4      3       2       1       0       4       3       2       1       0       4       3       2       1       0       4
    set test variable  @{Trailer1TPMTyreInfo_LeakageWarn_Tyre}       1       0       0       0       0       1           0       2           1           0           1       0       2       1       0       1       0       2        1      0       1       0       2       1       0       1       0       2       1       0       1       0       2       1       0       1       0       2       1       0       1

    #____________________________________________________________________  TRAILER 2____________________________________________________________________________
    set test variable  @{Trailer2TPM_Answers0}    2    159      1     150    2220    0    2       0      600000
    set test variable  @{Trailer2TPM_Answers1}    2    158      1     180    2000    0    2       0      12500000     @{Trailer2TPM_Answers0}
    set test variable  @{Trailer2TPM_Answers2}    2    157      1    1120      10    1    2       0      1000000      @{Trailer2TPM_Answers1}
    set test variable  @{Trailer2TPM_Answers3}    2    156      1     550     300    2    2       0      10000000     @{Trailer2TPM_Answers2}

    set test variable  @{Trailer2TPMTyreInfo_TyreId_Tyre}          159     158     157    156
    set test variable  @{Trailer2TPMTyreInfo_RefPres_Tyre}         150     180    1122    553
    set test variable  @{Trailer2TPMTyreInfo_Pressure_Tyre}       2220    2001      10    304
    set test variable  @{Trailer2TPMTyreInfo_Temperature_Tyre}       6     125      10    100
    set test variable  @{Trailer2TPMTyreInfo_Battery_Tyre}           0       0       1      2
    set test variable  @{Trailer2TPMTyreInfo_Active_Tyre}            1       1       1      1
    set test variable  @{Trailer2TPMTyreInfo_PresWarning_Tyre}       2       2       2      2
    set test variable  @{Trailer2TPMTyreInfo_LeakageWarn_Tyre}       0       0       0      0


Build Log Config Res OK tea2plus
    Set Pdu         EventLog
    Set Pdu Type    logConfigResp
    Set Pdu Data    logConfigResp.msgId              1
    Set Pdu Data    logConfigResp.errorCode                      0
    ${request}=     Get XML
    [Return]                            ${request}


Install eventlog configuration
    [Arguments]  ${conf}  @{args}
    [Documentation]  Install supplied configuration (logConfigReq), restart TGW
    ...  and receive positive response.
    ...  The trigger active time is delayed by 1 minute.
    ...  Vehicle mode is set to Drive

    # Pick an invoke identifier
    ${msgid}=  Evaluate  str(random.randint(10000,19999))  modules=random

    #${f}=  resource get  ${conf}
    ${req}=  Parse xml  ${conf}

    # Make trigger active one minute from now and stay on for an hour
    ${start}=  Set triggers lifetime  ${req}  90s  1h  # 60s seems to little
    set element text  ${req}  ${msgid}  xpath=logConfigReq/msgId
    log element  ${req}
    ${reqf}=  resource new temp name
    save xml  ${req}  ${reqf}

    # Prepare positive response
    #${logConfigResOk}=           Build Log Config Res OK tea2plus
    #Set Suite Variable      ${logConfigResOk}
    #${f}=  resource get  logConfigResp_ok.xml
    #${f}=  resource get          ${logConfigResOk
    ${resp}=  parse xml  ${logConfigResOk}
    #add element  ${resp}  <msgId>${msgid}</msgId>  xpath=logConfigResp
    Set Element Text     ${resp}    ${msgid}     xpath=logConfigResp/msgId
    log element  ${resp}
    ${respf}=  resource new temp name
    save xml  ${resp}  ${respf}

    CTA send message  ${reqf}

    Bus Set Keypos And Vm             Parked
    sleep                             20s
    Bus Power Off
    sleep                             3s

    # Do some extras while the TGW is down
    run keyword if  @{args}!=[]  run keyword  @{args}

    CTA set timeout    6m
    ${cta}=  CTA receive message async   ${respf}
    Bus Power On
    Sleep                             10s
    Bus Set Keypos And Vm             Drive

    CTA Wait Until  ${cta}

    # Wait until the trigger is active
    ${start}=  convert date  ${start}  result_format=epoch
    :for  ${i}  in range  100
    \  ${now}=  get current date  time_zone=UTC  result_format=epoch
    \  exit for loop if  ${start} < ${now}
    \  sleep  1s

    # FIXME DEBUG:
    ${t}=  telnet tgw os send command  date
    ${p}=  telnet tgw cli send command  cmdgetpattern
    log many  @{t}
    log many  @{p}


Event Logging Test Suite Setup
    Basic Suite Setup
    Build Pdus
    Telnet TGW CLI Send command             setpar /GLOBAL/VEHICLESETTINGS/STANDBYTIME=90
    # Prepare the tachograph
    Run Keyword If  '${VARIANT}' != 'UD'  CANoe Set System Variable    TACHO::TachoStartStop      1
#    CANoe Set System Variable    EnvCountry    29    #0x1D
    Run Keyword If  '${VARIANT}' != 'UD'  CANoe Set System Variable    TACHO::Country             0

    #[mm], unlike in TEA2Plus the AdBlue Level is sent in mm. Max is 1020 = 100%)
    CANoe Set Environment Variable    EnvAdBlueLevel    1020
    Telnet TGW CLI Send command   setpar /VDP/ADBLUELEVELMAX=1020    #Set the Max Signal Value for Percentage Calculation 1020=100%

    #make sure there is SOME config saved onboard even on a fresh, clean tgw - this is the
    #CTA Send Message                  EventLoggingTearDown_LogConfig.xml
    CTA Send Message                 ${eventLogTearDownConfigReq}
    # only time the response will be sent without restarting the obs
    Run Keyword If  '${VARIANT}' == 'UD'  bus set infotainment signal value  FrontalCollisionDriverAlert_ISig_9        7



Remove Xml Files
    Remove File     		   ${triggerperiodicEventLogReportX}
    Remove File     		   ${triggerPeriodicEventLogReq}
	Remove File     		   ${trigPercEventLogConfRes}
    Remove File     		   ${eventLogTearDownConfigReq}
    Remove File     		   ${triggerPeriodicEventLogTea2Plus}
    Remove File     		   ${triggerPeriodicEventLogReport}
    Remove File     		   ${logConfigResOk}

Event Logging Test Suite Teardown
    Remove Xml Files
    Basic Suite Teardown

Event Logging Test Setup
    [Documentation]  Leave vehicle still, in mode Drive, no driver logged in
    Basic Setup
    Reset Tyre DB
    vdp set  AdBlueLevelLow           0  enum
    Set vehicle speed                 0
    Run Keyword If  '${VARIANT}' != 'UD'  CANoe Set System Variable  TACHO::DrivercardsDriver1  0    # No Driver Card Inserted
    Bus Set Keypos And Vm             Drive

Event Logging Test Tear Down
    #Set vehicle speed                 0
    #CANoe Set Environment Variable    EnvAdBlueLevel             0
    #CANoe Set System Variable         TACHO::DrivercardsDriver1  0    # No Driver Card Inserted

    # Sum of AdblueWhileRunning And \ AdblueWhileStopped is the Adblue level used
    Run Keyword If                    '${ARCHITECTURE}' == 'tea2plus'    CANoe Set Environment Variable    EnvAdBlueConVehicleRunning    0
    Run Keyword If                    '${ARCHITECTURE}' == 'tea2plus'    CANoe Set Environment Variable    EnvAdBlueConVehicleStopped    0

    Basic Teardown

Build Event Log Config Req PDU
    [Documentation]  builds the below PDU
    ...
    [Arguments]
    Set Pdu                              EventLog
    Set Pdu Type                         logConfigReq
    Set Pdu Data                         logConfigReq.msgId              123
    Set Pdu Data                         logConfigReq.reset              1

    ${li}=   New Inst   EventLogPatternConfig
    ${now}=  Get Time  epoch

    Set Inst Data  ${li}   patternId              123
    Set Inst Data  ${li}   sendPolicy             low
    ${then}=             Evaluate                 ${now}+31622400
    ${now}=             Evaluate                 ${now}-31622400
    Set Inst Data  ${li}   lifeTimeBegin          ${now}
    Set Inst Data  ${li}   lifeTimeEnd            ${then}
    Set Inst Data  ${li}   enabled                1

   ${tr}=  New Inst   Trigger
    Set Inst Data  ${tr}   randomDelay            0
    Set Inst Data  ${tr}   triggerId              1

    ${trtype}=  New Inst  TriggerType
    Set Inst Type  ${trtype}  periodic
    Set Inst Data  ${trtype}  period              300
    Set Inst Data  ${trtype}  startAt             ${now}

    Set Inst Data  ${tr}   triggerType            ${trtype}
    Set Inst Data  ${tr}   dataContentId          13

    Add List Item  logConfigReq.triggers          ${tr}
    Add List Item  logConfigReq.logPatternConfig  ${li}

    ${li}=  New Inst   DataContentConfig
    Set Inst Data  ${li}   dataContentId          123
    Set Inst Data  ${li}   dataItems              list(123,124,125,126)

    Add List Item  logConfigReq.dataContentConfig  ${li}


    ${request}=  Get XML
    [Return]                             ${request}

Build Event Log Tear Down Log Config Pdu
    Set Pdu       EventLog
    Set Pdu Type  logConfigReq
    Set Pdu Data  logConfigReq.msgId              123
    Set Pdu Data  logConfigReq.reset              1
    ${li}=  New Inst   DataContentConfig
    Set Inst Data  ${li}   dataContentId          123
    ${data_items}=  Create List  2
    Set Inst Data  ${li}   dataItems              ${data_items}
    Add List Item  logConfigReq.dataContentConfig  ${li}
    ${request}=  Get XML
    [Return]                            ${request}

Build Trigger Periodic Event Log Req Pdu
    Set Pdu         EventLog
    Set Pdu Type    logConfigReq
    Set Pdu Data    logConfigReq.msgId              1
    Set Pdu Data    logConfigReq.reset              1
    ${li}=          New Inst    EventLogPatternConfig
    ${currTime}=         Get Time    epoch
    #${future}=             Evaluate                 ${currTime}+31622400
    #${past}=             Evaluate                 ${currTime}-31622400
    ${past}=            Set Variable          1286668800
    ${future}=            Set Variable         1767225599
    Set Inst Data   ${li}   patternId              1
    Set Inst Data   ${li}   sendPolicy             low
    Set Inst Data   ${li}   lifeTimeBegin          ${past}
    Set Inst Data   ${li}   lifeTimeEnd            ${future}
    Set Inst Data   ${li}   enabled                1
    ${tr}=          New Inst   Trigger
    Set Inst Data   ${tr}   randomDelay            0
    Set Inst Data   ${tr}   triggerId              1
    ${trtype}=      New Inst  TriggerType
    Set Inst Type   ${trtype}  periodic
    Set Inst Data   ${trtype}  periodic.period              30
    Set Inst Data   ${trtype}  periodic.startAt             ${past}

    Set Inst Data   ${tr}   triggerType            ${trtype}
    Set Inst Data   ${tr}   dataContentId          13
    ${trigger_list}=  Create List  ${tr}
    Set Inst Data   ${li}   triggers               ${trigger_list}
    Add List Item  logConfigReq.logPatternConfig  ${li}
    ${li}=          New Inst   DataContentConfig
    Set Inst Data   ${li}   dataContentId          13
    ${data_items}=  Create List  3    23

    Set Inst Data   ${li}   dataItems              ${data_items}
    Add List Item   logConfigReq.dataContentConfig  ${li}
    ${request}=     Get XML
    [Return]                            ${request}

Build Trigger Periodic Event Log Config Res Pdu
    Set Pdu         EventLog
    Set Pdu Type    logConfigResp
    Set Pdu Data    logConfigResp.msgId              1
    Set Pdu Data    logConfigResp.errorCode                      0
    Set Pdu Data    logConfigResp.errorDesc            \
    ${request}=     Get XML
    ${input}=  Get XML String
    ${output}=  Get XML String
    ${patfile}=  Get XML Pattern  ${input}     \
    [Return]                            ${patfile}

Build Trigger Periodic Event Log ReportX Pdu

    Set Pdu         EventLog
    Set Pdu Type    eventLogReport
    Set Pdu Data    eventLogReport.patternId    1
    Set Pdu Data    eventLogReport.triggerId    1
    Set Pdu Data    eventLogReport.triggerTime    .*5:00|(.*0:00)
    ${li}=           New Inst   DataContentReport
    Set Inst Data  ${li}   dataContentId          13
    Set Inst Data  ${li}   duration              .*
    ${data}=         New Inst   DataItem

    Set Inst Type    ${data}        speed


    Set Inst Data    ${data}           speed     .*
    #${data_items}=    Create List     3
    ${data_items}=    Create List     ${data}

    Set Inst Data    ${li}            data         ${data_items}

    Set Pdu Data      eventLogReport.dataContentReport        ${li}

    ${request}=     Get XML
    ${input}=  Get XML String
    ${output}=  Get XML String

    ${patfile}=  Get XML Pattern  ${input}     ${output}
    [Return]      ${patfile}

Build Pdus
    ${triggerperiodicEventLogReportX}=          Build Trigger Periodic Event Log ReportX Pdu
    Set Suite variable     		                ${triggerperiodicEventLogReportX}
    ${triggerPeriodicEventLogReq}=              Build Trigger Periodic Event Log Req Pdu
    Set Suite variable     		                ${triggerPeriodicEventLogReq}
    ${trigPercEventLogConfRes}=                 Build Trigger Periodic Event Log Config Res Pdu
    Set Suite variable     		                ${trigPercEventLogConfRes}
    ${eventLogTearDownConfigReq}=               Build Event Log Tear Down Log Config Pdu
    Set Suite variable     		                ${eventLogTearDownConfigReq}
    ${triggerPeriodicEventLogReport}=           Build Periodic Event Log Report Tea2plus
    Set Suite variable     		                ${triggerPeriodicEventLogReport}
    ${triggerPeriodicEventLogTea2Plus}=         Build Periodic Event Log Config Tea2plus
    Set Suite variable     		                ${triggerPeriodicEventLogTea2Plus}
    ${logConfigResOk}=                          Build Log Config Res OK tea2plus
    Set Suite variable     		                ${logConfigResOk}

Teardown Trigger Periodic
    [Documentation]   Finish off the periodic trigger for the benefit of others...
    #CTA Send Message                  EventLoggingTearDown_LogConfig.xml
    CTA Send Message                 ${eventLogTearDownConfigReq}
    Restart TGW
    CTA wait until alive              5m
    Event Logging Test Tear Down

Build Periodic Event Log Report Tea2plus
    Set Pdu         EventLog
    Set Pdu Type    eventLogReport
    Set Pdu Data    eventLogReport.patternId    1
    Set Pdu Data    eventLogReport.triggerId    1
    Set Pdu Data    eventLogReport.triggerTime     (.*:30)|(.*:00)    #.*
    ${request}=     Get XML
    [Return]      ${request}

Build Periodic Event Log Config Tea2plus
    Set Pdu         EventLog
    Set Pdu Type    logConfigReq
    Set Pdu Data    logConfigReq.msgId              1
    Set Pdu Data    logConfigReq.reset              1
    ${li}=          New Inst    EventLogPatternConfig
    ${currTime}=         Get Time    epoch
    #${future}=             Evaluate                 ${currTime}+31622400
    #${past}=             Evaluate                 ${currTime}-31622400
    ${past}=            Set Variable          1286668800
    ${future}=            Set Variable         1767225599
    Set Inst Data   ${li}   patternId              1
    Set Inst Data   ${li}   sendPolicy             low
    Set Inst Data   ${li}   lifeTimeBegin          ${past}
    Set Inst Data   ${li}   lifeTimeEnd            ${future}
    Set Inst Data   ${li}   enabled                1
    ${tr}=          New Inst   Trigger
    Set Inst Data   ${tr}   randomDelay            0
    Set Inst Data   ${tr}   triggerId              1
    ${trtype}=      New Inst  TriggerType
    Set Inst Type   ${trtype}  periodic
    Set Inst Data   ${trtype}  periodic.period              30
    Set Inst Data   ${trtype}  periodic.startAt             ${past}

    Set Inst Data   ${tr}   triggerType            ${trtype}
    ${trigger_list}=  Create List  ${tr}
    Set Inst Data   ${li}   triggers               ${trigger_list}
    Add List Item  logConfigReq.logPatternConfig  ${li}
    ${request}=     Get XML
    [Return]      ${request}


*** Test Cases ***

TriggerPeriodicAVT
    [Documentation]    Trigger Periodic
    ...    Description:
    ...    The trigger Periodic is used to create log data reports periodically from a specified start
    ...    time.
    ...    Adjustable parameters:
    ...    period time,start time
    ...    Condition:
    ...    The trigger shall be set periodically according to the schedule:
    ...    triggertime = start time + period time * x
    ...    x= 0, 1, ...
    ...    If one or more scheduled triggertimes are missed (e.g. OBS is in DeepSleep mode) while
    ...    the trigger is active, the trigger shall be set and return to the original schedule.
    ...    The trigger shall not be set at trigger activation until the next triggertime according to the
    ...    schedule.
    [Tags]      TriggerPeriodicBOTool
    ...         EventLogAutoTestBOTool
    ...     TGW2.0    TGW2.1     UTESP
    ...    Bridge_AVT
    Comment    Preparation Step
    CANoe Set System Variable    KeyPos    2    #Key Position \ 2= Drive
    sleep    20s
    CANoe Set System Variable    Odometer        50000      # meters
    #_________________________    #______Step1___________    #__________________________
    Comment    Step1: Setting up EventLogging Pattern
    CTA Set Timeout    6m
    #CTA Send Message    TriggerPeriodic_Eventlog.xml    #Trigger is set to a period of 300s
    CTA Send Message     ${triggerPeriodicEventLogReq}
    Sleep    10s
    Telnet TGW Os Send Command               reset

    Sleep    10s
    CANoe Set System Variable    KeyPos    2    #Key Position \ 2= Drive
    #CTA receive message    TriggerPeriodic_EventlogConfigRespX.xml
    CTA receive message      ${trigPercEventLogConfRes}
    #_________________________    #______Step2___________    #__________________________
    Comment    Step2: Firing Trigger
    CTA set timeout    7m
    sleep    290s
    #CTA receive message    TriggerPeriodic_EventlogReportX.xml
    CTA receive message      ${triggerperiodicEventLogReportX}
    #_________________________    #______Step3___________    #__________________________
    Comment    Step3: Firing Trigger
    CTA set timeout    7m
    sleep    290s
    #CTA receive message    TriggerPeriodic_EventlogReportX.xml
    CTA receive message      ${triggerperiodicEventLogReportX}
    #_________________________    #______Step4___________    #__________________________
    Comment    Step4: Firing Trigger
    CTA set timeout    7m
    sleep    290s
    #CTA receive message    TriggerPeriodic_EventlogReportX.xml
    CTA receive message      ${triggerperiodicEventLogReportX}

    CANoe Set System Variable    KeyPos    0
    sleep    20s

TriggerPeriodicTea2Plus
    [Documentation]    Trigger Periodic
    ...    Electronic Architecture: TEA2, TEA2+, Bridge
    ...    Description:
    ...    The trigger Periodic is used to create log data reports periodically from a specified start
    ...    time.
    ...    Adjustable parameters:
    ...    period time,start time
    ...    Condition:
    ...    The trigger shall be set periodically according to the schedule:
    ...    triggertime = start time + period time * X
    ...    x= 0, 1, ...
    ...    If one or more scheduled triggertimes are missed (e.g. OBS is in DeepSleep mode) while
    ...    the trigger is active, the trigger shall be set and return to the original schedule.
    ...    The trigger shall not be set at trigger activation until the next triggertime according to the
    ...    schedule.
    [Tags]    EventLogging    TriggerPeriodic    TriggerPeriodicTea2PlusBOTool
    ...   TGW2.1      UTESP
    ...       SWRS 11189v30
    ...    TEA2Plus_VT
    ...    Bridge_VT
    ...    TEA2_VT
    ...    TEA2Plus_UD
    [Teardown]   Teardown Trigger Periodic
    #${triggerPeriodicEventLogTea2Plus}=      Build Periodic Event Log Config Tea2plus
    #Set Suite Variable         ${triggerPeriodicEventLogTea2Plus}
    remove element from xml                ${triggerPeriodicEventLogTea2Plus}
    #Install eventlog configuration  TriggerPeriodic_Eventlog.xml  # Period = 30s
    Install eventlog configuration     ${triggerPeriodicEventLogTea2Plus}

    # Get in sync with the period
    CTA set timeout    60s
    #CTA receive message    TriggerPeriodic_EventlogReportX.xml
    #${triggerPeriodicEventLogReport}=            Build Periodic Event Log Report Tea2plus
    #Set Suite Variable        ${triggerPeriodicEventLogReport}
    CTA receive message    ${triggerPeriodicEventLogReport}
    CTA set timeout    20s
    sleep    25s
    #CTA receive message    TriggerPeriodic_EventlogReportX.xml
    CTA receive message    ${triggerPeriodicEventLogReport}
    sleep    25s
    #CTA receive message    TriggerPeriodic_EventlogReportX.xml
    CTA receive message    ${triggerPeriodicEventLogReport}