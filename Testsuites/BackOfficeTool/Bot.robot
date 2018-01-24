*** Settings ***
Documentation  This test suite will verify the functions of the BackOfficeTool
Library           Robot/Libs/BackOfficeTool/BackOfficeTool.py
Library           Collections
Library           DateTime
Library           XML

*** Variables ***


*** Keywords ***

*** Test Cases ***

DriverLogin
    [Documentation]  This is a test.
    
    Set Pdu       DriverAuthentication
    Set Pdu Type  driverLoginReq
    Set Pdu Data  driverLoginReq.driverId  aaaa
    Set Pdu Data  driverLoginReq.pincode   0000

    ${request}=  Get XML
    #log  Generated request ${request}  WARN

    Set Pdu       DriverAuthentication
    Set Pdu Type  driverLoginResp
    Set Pdu Data  driverLoginResp.driverId  aaaa
    Set Pdu Data  driverLoginResp.driverName   TheStig
    Set Pdu Data  driverLoginResp.loginState   successful
    
    ${response}=  Get XML
    log  Generated response ${response}  WARN

    Set Pdu       DriverAuthentication
    Set Pdu Type  driverLoginConfig
    Set Pdu Data  driverLoginConfig.nrOfCachedDrivers   10 
    Set Pdu Data  driverLoginConfig.cleanOutTimeout     40000   
    Set Pdu Data  driverLoginConfig.autoLogoutTimeout   40
    Set Pdu Data  driverLoginConfig.driverloginEnable   1

    ${config}=  Get XML
    log  Generated response ${config}  WARN

    Set Pdu       DriverAuthentication
    Set Pdu Type  logoutDriver
    Set Pdu Data  logoutDriver.driverId    aaaa 

    ${logout}=  Get XML
    log  Generated response ${logout}  WARN


    Remove File  ${request}
    Remove File  ${response}
    Remove File  ${config}
    Remove File  ${logout}


EventLog
    [Documentation]  Test EventLog Protocol
       
    Set Pdu       EventLog

    Set Bot Log  debug
    
    Set Pdu Type  logConfigReq
    Set Pdu Data  logConfigReq.msgId              123
    Set Pdu Data  logConfigReq.reset              1

    ${li}=   New Inst   EventLogPatternConfig
    ${now}=  Get Time  epoch
    ${then}=  Set Variable  ${now+1000}

    Set Inst Data  ${li}   patternId              123
    Set Inst Data  ${li}   sendPolicy             low
    Set Inst Data  ${li}   lifeTimeBegin          ${now}
    Set Inst Data  ${li}   lifeTimeEnd            ${then}
    Set Inst Data  ${li}   enabled                1

    ${tr}=  New Inst   Trigger

    log  Trigger ${tr}  WARN

    Set Inst Data  ${tr}   randomDelay            123
    Set Inst Data  ${tr}   triggerId              123

    ${trtype}=  New Inst  TriggerType
    Set Inst Type  ${trtype}  periodic
    Set Inst Data  ${trtype}  periodic.period              123
    Set Inst Data  ${trtype}  periodic.startAt             ${now}
    
    Set Inst Data  ${tr}   triggerType            ${trtype}
    Set Inst Data  ${tr}   dataContentId          123

    ${trigger_list}=  Create List  ${tr} 

    Set Inst Data  ${li}   triggers               ${trigger_list}
    
    Add List Item  logConfigReq.logPatternConfig  ${li}  

    ${li}=  New Inst   DataContentConfig
    Set Inst Data  ${li}   dataContentId          123

    ${data_items}=  Create List  123  124  125  126

    Set Inst Data  ${li}   dataItems              ${data_items}
    
    Add List Item  logConfigReq.dataContentConfig  ${li}  
    
    ${request}=  Get XML

    ${input}=  Get XML String
    ${output}=  Get XML String
    
    ${patfile}=  Get XML Pattern  ${input}  ${output}
    
    #Remove File  ${request}

adbBlueLevelTriggerOnChange
    Set Pdu       EventLog
    Set Pdu Type  logConfigReq
    Set Pdu Data  logConfigReq.msgId              123
    Set Pdu Data  logConfigReq.reset              1
    ${li}=   New Inst   EventLogPatternConfig
    ${now}=  Get Time  epoch
    ${then}=  Set Variable  ${now+1000}
    ${now}=	 Convert Date	 ${now} 	exclude_millis=yes
    ${then}=	 Convert Date	 ${then} 	exclude_millis=yes

    Set Inst Data  ${li}   patternId              123
    Set Inst Data  ${li}   sendPolicy           low
    #Set Inst Data  ${li}   sendPolicy.low             0
    Set Inst Data  ${li}   lifeTimeBegin          ${now}
    Set Inst Data  ${li}   lifeTimeEnd            ${then}
    Set Inst Data  ${li}   enabled                1

    ${tr}=  New Inst   Trigger

    Set Inst Data  ${tr}   randomDelay            0
    Set Inst Data  ${tr}   triggerId              3

    ${trtype}=  New Inst  TriggerType
    Set Inst Type  ${trtype}  adBlueLevelChangedWhileStopped
    Set Inst Data  ${trtype}  adBlueLevelChangedWhileStopped              200

    Set Inst Data  ${tr}   triggerType            ${trtype}
    ${trigger_list}=  Create List  ${tr}

    Set Inst Data  ${li}   triggers               ${trigger_list}
    Add List Item  logConfigReq.logPatternConfig  ${li}
    ${request}=  Get XML
    ${input}=  Get XML String
    ${output}=  Get XML String

    ${patfile}=  Get XML Pattern  ${input}  ${output}

DummyTest
    sleep     1s
    ${now}=  Get Time  epoch
    log to console       ${now}
    ${time}=	 Convert Date	 ${now} 	exclude_millis=yes
    log to console      ${time}

BuildEventLogTearDownLogConfig
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

BuildAdBlueChangedEventLogReportAXPdu
   Set Pdu          EventLog
   Set Pdu Type     eventLogReport
   Set Inst Data  ${li}   patternId              123
   Set Inst Data  ${tr}   triggerId              3
   Set Inst TriggerTime

BuildTriggerPeriodicPepport
   Set Pdu         EventLog
   Set Pdu Type    eventLogReport
   Set Pdu Data    eventLogReport.patternId    1
   Set Pdu Data    eventLogReport.triggerId    1
   Set Pdu Data    eventLogReport.triggerTime    .*5:00|(.*0:00)

   ${li}=  New Inst   DataContentReport
   Set Inst Data  ${li}   dataContentId          13
   Set Inst Data  ${li}   duration              .*

   #${speed}=      New Inst         Speed
   #Set Inst Type    ${speed}      speed
   #Set Inst Data    ${speed}      .*

   #${lovVehicleDistanceDelta}=     New Inst         LovVehicleDistanceDelta
   #Set Inst Type    ${lovVehicleDistanceDelta}      lovVehicleDistanceDelta
   #Set Inst Data    ${lovVehicleDistanceDelta}      0

   ${speed}=        New Inst       DataItem_speed
   Set Inst Data          ${li}           ${speed}      .*

   ${lovVehicleDistanceDelta}=     New Inst       DataItem_lovVehicleDistanceDelta
   Set Inst Data          ${li}           ${lovVehicleDistanceDelta}      0



   #${data_items}=  Create List          0

    #Set Inst Data  ${li}   dataItems              ${data_items}
    #Add List Item  DataContentReport.data  ${li}

   #@{data_items}=     Create List            0
   #@{data_items}      Convert To List          @{data_items}
   #Set Inst Data   ${li}    data              @{data_items}
   ${request}=  Get XML



#   ${data}=  New Inst   Data
#
#   ${item}=  New Inst   item
#
#   ${speed}=  New Inst   speed
#   Set Inst Data  ${speed}   .*
#
#   Set Inst Data    ${item}   speed      ${speed}
#   Set Inst Data    ${data}   item       ${item}
#   Set Inst Data    ${li}     data       ${data}
#
#   ${data_items}=  Create List  2
#   Set Inst Data  ${li}   dataItems              ${data_items}
#
#
#   ${data_items}=  Create List   .*    2

BuildTriggerPeriodicEventLog
    Set Pdu         EventLog
    Set Pdu Type    logConfigReq
    Set Pdu Data    logConfigReq.msgId              1
    Set Pdu Data    logConfigReq.reset              1
    ${li}=          New Inst    EventLogPatternConfig
    ${now}=         Get Time    epoch
    ${then}=        Set Variable  ${now+1000}
    Set Inst Data   ${li}   patternId              1
    Set Inst Data   ${li}   sendPolicy             low
    Set Inst Data   ${li}   lifeTimeBegin          ${now}
    Set Inst Data   ${li}   lifeTimeEnd            ${then}
    Set Inst Data   ${li}   enabled                1
    ${tr}=          New Inst   Trigger
    Set Inst Data   ${tr}   randomDelay            0
    Set Inst Data   ${tr}   triggerId              1
    ${trtype}=      New Inst  TriggerType
    Set Inst Type   ${trtype}  periodic
    Set Inst Data   ${trtype}  periodic.period              300
    Set Inst Data   ${trtype}  periodic.startAt             ${now}
    Set Inst Data   ${tr}   triggerType            ${trtype}
    Set Inst Data   ${tr}   dataContentId          13
    ${trigger_list}=  Create List  ${tr}
    Set Inst Data   ${li}   triggers               ${trigger_list}
    Add List Item  logConfigReq.logPatternConfig  ${li}
    ${li}=          New Inst   DataContentConfig
    Set Inst Data   ${li}   dataContentId          13
    ${data_items}=  Create List  3
    Set Inst Data   ${li}   dataItems              ${data_items}
    Add List Item   logConfigReq.dataContentConfig  ${li}
    ${request}=     Get XML

BuildTriggerPeriodicEventLogConfigRes
    Set Pdu         EventLog
    Set Pdu Type    logConfigResp
    Set Pdu Data    logConfigResp.msgId              1
    Set Pdu Data    logConfigResp.errorCode                      0
    Set Pdu Data    logConfigResp.errorDesc            \
    #Set Pdu Data    logConfigResp.msgId              1111
    ${request}=     Get XML
    ${resp}=  parse xml  ${request}
    #add element  ${resp}  <msgId>1111</msgId>       xpath=logConfigResp
    #set element text    ${resp}    11111     xpath=logConfigResp/msgId
    #Set Element Attribute   ${resp}    msgId      2222     xpath=logConfigResp/msgId
    #add element  ${resp}  <msgId>1111</msgId>       index=1     xpath=logConfigResp
    #Set Element Text     ${resp}    2222     xpath=logConfigResp/msgId
   # Set Pdu Data    logConfigResp.msgId              1111
    #add element  ${resp}    msgId      xpath=logConfigResp
    Set Element Text     ${resp}    3333     xpath=logConfigResp/msgId
    log element  ${resp}
    save xml  ${resp}  ${request}
    #${input}=  Get XML String
    #${output}=  Get XML String
    log to console     ${request}
    #${patfile}=  Get XML Pattern  ${input}     \

buildTriggerPeriodicEventLogReport
   Set Pdu              EventLog
   Set Pdu Type         eventLogReport



BuildTriggerPeriodicEventLogReportX

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


BuildTriggerAdbLevChangeLogConfigReq
    Set Pdu         EventLog
    Set Pdu Type    logConfigReq
    Set Pdu Data    logConfigReq.msgId              123
    Set Pdu Data    logConfigReq.reset              1
    ${li}=          New Inst    EventLogPatternConfig
    ${currentTime}=         Get Time    epoch
    ${future}=             Evaluate                 ${currentTime}+31622400
    ${past}=             Evaluate                 ${currentTime}-31622400
    Set Inst Data   ${li}   patternId              123
    Set Inst Data   ${li}   sendPolicy             low
    Set Inst Data   ${li}   lifeTimeBegin          ${past}
    Set Inst Data   ${li}   lifeTimeEnd            ${future}
    Set Inst Data   ${li}   enabled                1
    ${tr}=          New Inst   Trigger
    Set Inst Data   ${tr}   randomDelay            0
    Set Inst Data   ${tr}   triggerId              3
    ${trtype}=      New Inst  TriggerType
    Set Inst Type   ${trtype}  adBlueLevelChangedWhileStopped
    Set Inst Data   ${tr}   triggerType            ${trtype}
    ${trigger_list}=  Create List  ${tr}
    Set Inst Data   ${li}   triggers               ${trigger_list}
    Add List Item  logConfigReq.logPatternConfig  ${li}
    ${request}=     Get XML

testperiodicconfigtea2plus
    Set Pdu         EventLog
    Set Pdu Type    logConfigReq
    Set Pdu Data    logConfigReq.msgId              1
    Set Pdu Data    logConfigReq.reset              1
    ${li}=          New Inst    EventLogPatternConfig
    ${currTime}=         Get Time    epoch
    ${future}=             Evaluate                 ${currTime}+31622400
    ${past}=             Evaluate                 ${currTime}-31622400
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
    log to console     ${request}
    ${req}=  Parse xml  ${request}
    ${newReqparsed}=        remove element   ${req}   xpath=logConfigReq/logPatternConfig/item/triggers/item/dataContentId
    save xml   ${newReqparsed}   ${request}
    #[Return]     ${request}