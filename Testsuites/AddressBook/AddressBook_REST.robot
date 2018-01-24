*** Settings ***

Documentation     This test suite is intended to test the functions of address book initiated from BOS

Library           XML
Library           requests
Library           Collections
Library           String
Library           Libs/Common/CTATester.py            # BOS Communication library
Library           Libs/Common/BusManager.py           # CAN/J1708 Communication library
Library           Libs/Common/WebSocketHelper.py
Library           Libs/Common/CANoeTester.py
Resource          Libs/RESTUtils.txt
Resource          Robot/Resources/DriverLoginLogout_kw.robot
Resource          Resources/TestSetup_kw.robot
Resource          Libs/Common/WlanHelper.txt

Suite Setup       Suite Setup
Suite Teardown    Suite Teardown

Test Setup        Test Setup
Test Teardown     Test Teardown

Force Tags        AddressBook    TGW2.1   REST    Rest_OverWLAN   
...    TEA2Plus_VT
...    TEA2_VT
...    Bridge_VT

*** Variables ***

${FLEETURL}=                        http://192.168.10.1:33080/api
${WS_FLEETURL}=                     ws://192.168.10.1:33080
${SYNCHRONIZE_PRIVATE_CONTACTS}     ${True}
${USR_CERT}      ${EXECDIR}${/}Resources${/}Common${/}sslkeys${/}user.cert.pem
${USR_KEY}      ${EXECDIR}${/}Resources${/}Common${/}sslkeys${/}user.key.pem
${CA_CERT}      ${EXECDIR}${/}Resources${/}Common${/}sslkeys${/}ca-chain.cert.pem

*** Test Cases ***

Error when setting phone and email to null
    [Documentation]  Bug fix according to OBT-7721, editing details with empty fields resulting in previous value.
    [Tags]  LD_Req-43427
    Enable Service

    ${driverName}=  get from dictionary  ${DRIVERS}  driver2
    Create Driver And Login REST  ${WS_FLEETURL}  driver2  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Clear Private Address Book
    Clear Public Address Book

    Make driver setting sync resp   0driver2   4

    # Create a new contact
    ${addrbook_dict}=  create dictionary
    Set To Dictionary  ${addrbook_dict}  name           Berra
    Set To Dictionary  ${addrbook_dict}  email          the@berra.domain
    Set To Dictionary  ${addrbook_dict}  mobilePhone    123
    Set To Dictionary  ${addrbook_dict}  otherPhone     321
    Set To Dictionary  ${addrbook_dict}  contactType    PRIVATE
    ${c}=  Post  /contacts  ${addrbook_dict}
    Log  ${addrbook_dict}

    # List all contacts
    ${contacts}=   Get  /contacts
    log    ${contacts}
    ${contact}=  Get From List  ${contacts}    0
    ${contactId}=  Get From Dictionary  ${contact}  contactId
    Set To Dictionary  ${addrbook_dict}  contactId  ${contactId}
    Dictionaries Should Be Equal  ${contact}  ${addrbook_dict}

    # Test removing mobilePhone and otherPhone and verify
    Set To Dictionary       ${addrbook_dict}  email         the@berra.domain
    Remove From Dictionary  ${addrbook_dict}  mobilePhone
    Remove From Dictionary  ${addrbook_dict}  otherPhone
    ${c}=  put  /contacts   ${addrbook_dict}
    Log  ${addrbook_dict}

    ${contacts}=   get  /contacts
    log    ${contacts}
    ${contact}=  Get From List  ${contacts}    0
    Addressbook should contain  ${contact}  the@berra.domain  123  321

    # Test setting email and otherPhone number to empty (and restore mobile phone) and verify
    Remove From Dictionary  ${addrbook_dict}  email
    Set To Dictionary       ${addrbook_dict}  mobilePhone   123
    Remove From Dictionary  ${addrbook_dict}  otherPhone
    ${c}=  put  /contacts   ${addrbook_dict}
    Log  ${addrbook_dict}

    ${contacts}=   get  /contacts
    log    ${contacts}
    ${contact}=  Get From List  ${contacts}    0
    Addressbook should contain  ${contact}  the@berra.domain  123  321

    # Test setting mobilePhone and otherPhone number to null and verify
    ${addrbook_dict}=  Set to Addressbook  ${addrbook_dict}  the@berra.domain  ${None}  ${None}
    ${c}=  put  /contacts  ${addrbook_dict}
    Log  ${addrbook_dict}

    ${contacts}=   get  /contacts
    log    ${contacts}
    ${contact}=  Get From List  ${contacts}    0
    Addressbook should contain  ${contact}  the@berra.domain  ${EMPTY}  ${EMPTY}

    # Test setting email and otherPhone number to null and verify
    ${addrbook_dict}=  Set to Addressbook  ${addrbook_dict}  ${None}  123  ${None}
    ${c}=  put  /contacts  ${addrbook_dict}
    Log  ${addrbook_dict}

    ${contacts}=   get  /contacts
    log    ${contacts}
    ${contact}=  Get From List  ${contacts}    0
    Addressbook should contain  ${contact}  ${EMPTY}  123  ${EMPTY}

    # Test setting mobilePhone and otherPhone number to empty and verify
    ${addrbook_dict}=  Set to Addressbook  ${addrbook_dict}  the@berra.domain  ${EMPTY}  ${EMPTY}
    ${c}=  put  /contacts  ${addrbook_dict}
    Log  ${addrbook_dict}

    ${contacts}=   get  /contacts
    log    ${contacts}
    ${contact}=  Get From List      ${contacts}  0
    Addressbook should contain  ${contact}  the@berra.domain  ${EMPTY}  ${EMPTY}

    # Test setting email and otherPhone number to empty and verify
    ${addrbook_dict}=  Set to Addressbook  ${addrbook_dict}  ${EMPTY}  123  ${EMPTY}
    ${c}=  put  /contacts  ${addrbook_dict}
    Log  ${addrbook_dict}

    ${contacts}=   get  /contacts
    ${contact}=  Get From List      ${contacts}  0
    Addressbook should contain  ${contact}  ${EMPTY}  123  ${EMPTY}
    log    ${contacts}

    Disable service
    WS stop threads
    WS Close

Supported address book settings
    [Documentation]    OBS shall support the following address book settings: AddB_ServiceEnable
    [Tags]     I2
    ...        LD_Req-43408 v1

    Enable service
    Disable service

Number of public address entries 10-REST
    [Documentation]    The maximum number of address entries in the public address book shall be 300.
    [Tags]    LD_Req-43420 v1    LD_Req-43421 v1    LD_Req-43413 v1

    Enable service

    ${adrbk}=  Make address book update req   10
    Verify address book entries    ${adrbk}


Number of public address entries 300-REST
    [Documentation]    The maximum number of address entries in the public address book shall be 300.
    [Tags]    LD_Req-43420 v1    LD_Req-43421 v1    LD_Req-43413 v1
    ...       UnderDevelopment    #ProblemReport   GTAG4_12014
    Enable service

    CTA set timeout  10m
    ${adrbk}=  Make address book update req   300    17  #  Increased timeout due to larger list
    Verify address book entries    ${adrbk}

Private addressbook-rest
    [Documentation]   To verify private address book. NB Check size of driver cache...
    [Tags]    LD_Req-43422 v1    LD_Req-43423 v1   LD_Req-43451 v1  LD_Req-43448 v1    LD_Req-43450 v1     PrivateAddressbookRest

    Enable service
    Clear public address book

    # Clear driver cache
    :for  ${driverId}  in  @{drivers.keys()}
    \  ${driverName}=  get from dictionary  ${DRIVERS}  ${driverId}
    \  Create Driver And Login REST  ${WS_FLEETURL}  ${driverId}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}
    \  Clear private address book
    \  ${driverName}=  get from dictionary  ${DRIVERS}  ${driverId}
    \  Logout Driver REST  ${WS_FLEETURL}  ${driverId}  ${driverName}

    :for  ${driverId}  in   @{drivers.keys()}
    \  ${driverName}=  get from dictionary  ${DRIVERS}  ${driverId}
    \  Create Driver And Login REST  ${WS_FLEETURL}  ${driverId}  1256  ${driverName}    ${SYNCHRONIZE_PRIVATE_CONTACTS}
    \  Make driver setting sync resp    0${driverId}   2
    \  Check Private AddressBook Settings  2
    \  Enter private address            kalle
    \  Fail to enter private duplicate  kalle
    \  Enter private address            olle
    \  ${empty_dic}=  create dictionary
    \  ${fname}=  resource new temp name
    \  ${au}=  CTA receive save message async  privateAddressBookUpdateTemplate.xml  ${fname}
    \  post  /contacts/synchronize  ${empty_dic}
    \  CTA Wait Until  ${au}
    \  @{addressNames}    Create List  kalle  olle
    \  Verify Private Address Book Update  ${driverId}  ${fname}  @{addressNames}
    \  ${driverName}=  get from dictionary  ${DRIVERS}  ${driverId}
    \  Logout Driver REST  ${WS_FLEETURL}  ${driverId}  ${driverName}

    :for  ${driverId}  in   @{drivers.keys()}
    \  ${driverName}=  get from dictionary  ${DRIVERS}  ${driverId}
    \  Create Driver And Login REST  ${WS_FLEETURL}  ${driverId}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}
    \  Make driver setting sync resp    0${driverId}   10
    \  Check Private AddressBook Settings  10
    \  Enter private address            pelle
    \  Enter private address            krille
    \  Enter private address            patrik
    \  Enter private address            sven
    \  Fail to enter private duplicate  krille
    \  Enter private address            anders
    \  Delete Private Address           krille
    \  ${empty_dic}=  create dictionary
    \  ${fname}=  resource new temp name
    \  ${au}=  CTA receive save message async  privateAddressBookUpdateTemplate.xml  ${fname}
    \  post  /contacts/synchronize  ${empty_dic}
    \  CTA Wait Until  ${au}
    \  @{addressNames}    Create List  pelle  patrik  sven  anders
    \  Verify Private Address Book Update  ${driverId}  ${fname}  @{addressNames}
    \  ${driverName}=  get from dictionary  ${DRIVERS}  ${driverId}
    \  Logout Driver REST  ${WS_FLEETURL}  ${driverId}  ${driverName}

Delete one private
    [Documentation]    Delete one private address book entry. This TC is to cover for one PR report (OBT-2859)
    [Tags]             LD_Req-43422 v1    LD_Req-43429 v1  LD_Req-43448 v1   LD_Req-43455 v1    LD_Req-43456 v1

    Enable service
    set test variable                ${hmiuser}   driver1


    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}
    Clear public address book
    Clear private address book
    Make driver setting sync resp    0${hmiuser}   3
    Check Private AddressBook Settings  3
    Enter private address            Rut

    ${adrbk}=  create list
    ${abe}=  create dictionary
    set to dictionary  ${abe}  name   Rut
    set to dictionary  ${abe}  email  Rut@volvo-fake.com
    set to dictionary  ${abe}  mobilePhone  +467
    set to dictionary  ${abe}  otherPhone   +4631
    append to list  ${adrbk}  ${abe}
    Verify address book entries      ${adrbk}   private

    WS Connect          ${WS_FLEETURL}    timeout=10
    # Get contactId and delete that one.
    ${e}=  get dh  /contacts?filter\=private  timeout=${30.0}
    ${e}=  set variable  ${e.json()}
    ${e}=  get from dictionary  @{e}[0]  contactId
    delete  /contacts/${e}

    # Check that Rut is gone.
    ${lc}=  get  /contacts?filter=private
    length should be  ${lc}  0

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}
    WS Close

Unique address entry names-rest
    [Documentation]    All address entry names in the address books shall be unique within its address book type
    ...               (private or public).
    [Tags]    LD_Req-43416 v1

    Enable service

    set test variable                ${hmiuser}   driver1


    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Clear private address book
    Clear public address book

    Clear private address book
    Make driver setting sync resp    0${hmiuser}   2
    Check Private AddressBook Settings  2
    Enter private address            kalle
    Fail to enter private duplicate  kalle
    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}

Number of private address book entries 0-rest
    [Documentation]    Max number of entries allowed in the private address book shall be configurable per driver
    ...                from BOS with
    [Tags]    LD_Req-43424 v1    LD_Req-43411 v1

    Enable service

    # test 0 entries  - CHECK grey contacts menu???
    set test variable   ${hmiuser}   driver1


    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Clear private address book
    Make driver setting sync resp   0driver1   0
    Fail to enter private address
    ${driverName}=  get from dictionary  ${DRIVERS}  driver1
    Logout Driver REST  ${WS_FLEETURL}  driver1  ${driverName}

Number of private address book entries 5-rest
    [Documentation]    Max number of entries allowed in the private address book shall be configurable per driver
    ...                from BOS with
    [Tags]    LD_Req-43424 v1    LD_Req-43411 v1  LD_Req-43448 v1

    Enable service

    # test 5 entries

    set test variable   ${hmiuser}   driver1

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}
    sleep  5s
    Make driver setting sync resp   0driver1   5
    Check Private AddressBook Settings  5
    Clear private address book
    Clear public address book
    Enter private addresses         4
    Enter private address           kalle
    Fail to enter private address
    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}

Number of private address book entries 100-rest
    [Documentation]    Max number of entries allowed in the private address book shall be configurable per driver
    ...                from BOS with
    [Tags]    LD_Req-43424 v1    LD_Req-43411 v1

    Enable service

    # test 100 entries
    set test variable   ${hmiuser}   driver1

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}
    Clear private address book
    Clear public address book
    Make driver setting sync resp   0driver1   100
    Enter private addresses         99
    Enter private address           kalle
    Fail to enter private address
    ${driverName}=  get from dictionary  ${DRIVERS}  driver1
    Logout Driver REST  ${WS_FLEETURL}  driver1  ${driverName}

Edit private entries-REST
    [Documentation]   Testing the PUT operation on addressbook entries.
    [Tags]    LD_Req-43426 v1    LD_Req-43429 v1    LD_Req-43453 v1    LD_Req-43458 v1

    Enable service

    set test variable   ${hmiuser}   driver1

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}
    Make driver setting sync resp   0${hmiuser}   4
    Clear private address book

    ${names}=  create dictionary  kalle  carola  ville  vilhelmina  valle  vanna  pelle  petra
    ${k}=  get dictionary keys  ${names}
    :for  ${n}  in  @{k}
    \  Enter private address  ${n}

    WS Connect          ${WS_FLEETURL}    timeout=10

    ${pa}=  get  /contacts?filter=private
    ${pa1}=  create list

    :for  ${ae}  in  @{pa}
    \  log dictionary  ${ae}
    \  ${n}=  get from dictionary  ${ae}  name
    \  ${n}=  get from dictionary  ${names}  ${n}
    \  set to dictionary  ${ae}  name  ${n}
    \  put  /contacts  ${ae}
    \  append to list  ${pa1}  ${ae}
    \  ${n}=  check notification  /contacts
    \  dictionary should contain item  ${n}  event  contactsUpdated

    ${pa2}=  get  /contacts?filter=private

    sort list  ${pa1}
    sort list  ${pa2}
    lists should be equal  ${pa1}  ${pa2}

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}
    WS Close

Check_no_duplicate_contactsupdated
    [Documentation]   Testing the no duplicate notifications on  contactsUpdated are sent for a single edit.
    [Tags]
    # I'm using the construction in 'Edit private entries'-test as base for this specific test.
    # Will trick (by misspelling) the notification receiving mechanims in RESTutils for the contacts notifications,
    # just to be able to observe the second obsolete nootification that shouldn't be there.

    Enable service

    set test variable   ${hmiuser}   driver1

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Make driver setting sync resp   0${hmiuser}   4

    Clear private address book

    # Populate contacts with single address information
    Enter private address  kalle

    Ws_Connect    ${WS_FLEETURL}    timeout=400
    WS start pinger

    # Change name on same contact, from kalle to carola
    ${private_addresses}=    get  /contacts?filter=private
    ${private_addresses}=    Evaluate     ${private_addresses}[0]  # pick the first item, assuming list with single item.
    set to dictionary  ${private_addresses}  name  carola    # replace 'kalle' with 'carola'

    # push out new name to tgw
    put  /contacts  ${private_addresses}

    # Expect one single notification for event contactsUpdated
    Ws Wait For Notification  event  contactsUpdated

    # Waiting for a second notification on contactsUpdated should fail.
    Run Keyword And Expect Error     WebSocketTimeoutException: Could not find the specified notification     Ws Wait For Notification  event  contactsUpdated
    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}

    WS stop threads
    WS Close

Sort addresses-REST
    [Documentation]  Test sorting privpub and pubpriv API.
    [Tags]    LD_Req-43426 v1    LD_Req-43429 v1

    # FIXME taags
    Enable service
    WS Connect          ${WS_FLEETURL}    timeout=10
    WS start pinger

    set test variable   ${hmiuser}   driver1

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Make driver setting sync resp   0${hmiuser}   4

    Clear private address book
    Clear public address book

    ${adrbk}=  Make address book update req   4
    Verify address book entries    ${adrbk}

    ${names}=  create list  Anders  Gustav  Bertil  Carlos
    :for  ${n}  in  @{names}
    \  Enter private address  ${n}

    ${contacts}=  get  /contacts?sort=pubpriv

    ${k}=  get dictionary keys  ${contacts}
    ${i}=  Convert To Integer  0
    :for  ${k}  in  @{contacts}
    \  ${x}=  get from dictionary  ${k}  contactType
    \  Run Keyword If  ${i} < 4  should contain  ${x}  PUBLIC
    \  Run Keyword Unless  ${i} < 4  should contain  ${x}  PRIVATE
    \  ${i}=  Set Variable  ${i + 1}

    ${contacts}=  get  /contacts?sort=privpub

    ${k}=  get dictionary keys  ${contacts}
    ${i}=  Convert To Integer  0
    :for  ${k}  in  @{contacts}
    \  ${x}=  get from dictionary  ${k}  contactType
    \  Run Keyword If  ${i} < 4  should contain  ${x}  PRIVATE
    \  Run Keyword Unless  ${i} < 4  should contain  ${x}  PUBLIC
    \  ${i}=  Set Variable  ${i + 1}

    Clear private address book
    Clear public address book

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}

    WS stop threads
    WS Close


Error codes
    [Documentation]  Provoke error reporting as described in the API.
    [Tags]    LD_Req-43414 v1    LD_Req-43415 v1    LD_Req-43417 v1    LD_Req-43413 v1

    # FIXME check max length of fields
    Disable service

    ${e}=  create dictionary
    set to dictionary  ${e}  name           The Provoker
    set to dictionary  ${e}  email          the@provoker.domain
    set to dictionary  ${e}  mobilePhone    +1666
    set to dictionary  ${e}  otherPhone     +4690000
    set to dictionary  ${e}  contactType  PRIVATE

    # While disabled, fail to enter a contact
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_DISABLED

    Enable service


    ${driverName}=  get from dictionary  ${DRIVERS}  driver2
    Create Driver And Login REST  ${WS_FLEETURL}  driver2  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Clear private address book

    Make driver setting sync resp   0driver2   4
    set to dictionary  ${e}  name           ${Empty}
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_NAME
    set to dictionary  ${e}  name           The Provoker

    set to dictionary  ${e}  email          .the@provoker.domain
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_EMAIL
    set to dictionary  ${e}  email          the@provoker.domain

    set to dictionary  ${e}  mobilePhone    ++99XX
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_MOBILE
    set to dictionary  ${e}  mobilePhone    +166

    set to dictionary  ${e}  otherPhone          98+23XX
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_OTHER
    set to dictionary  ${e}  otherPhone        +4690000

    ${e}=  create dictionary  name  The Provoker  email  ${Empty}  mobilePhone  ${Empty}  otherPhone  ${Empty}
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_ONLY_NAME

    ${e}=  create dictionary  name  The Provoker2  email  the@provoker.domain  mobilePhone  ${Empty}  otherPhone  ${Empty}
    ${c}=  post  /contacts  ${e}  status_code=${200}

    ${e}=  create dictionary  name  The Provoker3  email  ${Empty}  mobilePhone  +1666  otherPhone  ${Empty}
    ${c}=  post  /contacts  ${e}  status_code=${200}

    ${e}=  create dictionary  name  The Provoker3  email  ${Empty}  mobilePhone  +1666  otherPhone  ${Empty}
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_DUPLICATE

    ${e}=  create dictionary  name  The Provoker4  email  ${Empty}  mobilePhone  ${Empty}  otherPhone  +4690000
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_ONLY_NAME

    # If for example phones are left out it should still be possible to enter contact if email and name are set.
    ${e}=  create dictionary  name  The Provoker5  email  the@provoker.domain
    ${c}=  post  /contacts  ${e}  status_code=${200}


Check_no_crash_when_malformed_uid
    [Documentation]    Testing tgw does not crash when entering malformed uid.
    [Tags]    Check_no_crash_when_malformed_uid

    Enable service
    ${malformed}=  Set variable  1
    ${r}=  requests.delete  ${FLEETURL}/contacts/${malformed}  headers=${HEADERS}  timeout=${10.0}

    should be equal  ${r.status_code}  ${400}

Verify swedish language support in address book
    [Documentation]   Verify that swedish name can be used in all functions.
    [Tags]    LD_Req-43447 v1    LD_Req-43450 v1    LD_Req-43453 v1

    # Pre
    Enable service
    set test variable   ${hmiuser}   driver1

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Make driver setting sync resp   0${hmiuser}   4
    Clear private address book
    WS Connect          ${WS_FLEETURL}    timeout=10

    # Create new entry
    ${entry}=  create dictionary
    set to dictionary  ${entry}  name         abcåäö
    set to dictionary  ${entry}  email        abc@volvo-fake.com
    set to dictionary  ${entry}  mobilePhone  +1
    set to dictionary  ${entry}  otherPhone   +1
    set to dictionary  ${entry}  contactType  PRIVATE
    post  /contacts    ${entry}  status_code=${200}

    # Check notification
    ${n}=  check notification  /contacts
    dictionary should contain item  ${n}  event  contactsUpdated

    # List
    ${contacts}=  get  /contacts?filter=private
    ${contact}=  Get From List  ${contacts}  0
    dictionary should contain item  ${contact}  email         abc@volvo-fake.com
    dictionary should contain item  ${contact}  mobilePhone   +1
    dictionary should contain item  ${contact}  otherPhone    +1
    dictionary should contain item  ${contact}  contactType   PRIVATE
    dictionary should contain key   ${contact}  contactId
    dictionary should contain item  ${contact}  name          abcåäö

    # Modify entry
    put  /contacts  ${contact}

    # Check notification
    ${n}=  check notification  /contacts
    dictionary should contain item  ${n}  event  contactsUpdated

    # List
    ${contacts}=  get  /contacts?filter=private
    ${contact}=  Get From List  ${contacts}  0
    dictionary should contain item  ${contact}  email         abc@volvo-fake.com
    dictionary should contain item  ${contact}  mobilePhone   +1
    dictionary should contain item  ${contact}  otherPhone    +1
    dictionary should contain item  ${contact}  contactType   PRIVATE
    dictionary should contain key   ${contact}  contactId
    dictionary should contain item  ${contact}  name          abcåäö

    # Post
    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}
    WS Close

Check validation on update contact
    [Documentation]  Update contacts should validate the input to be correct.
    [Tags]    LD_Req-43416 v1

    # Pre
    Enable service

    Set test variable               ${hmiuser}      driver1

    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Create Driver And Login REST  ${WS_FLEETURL}  ${hmiuser}  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}
    Make driver setting sync resp   0${hmiuser}      4

    Clear private address book
    Clear public address book

    # Create a new contact
    ${names}=  create list  Kennart  Kjell
    :for  ${n}  in  @{names}
    \  Enter private address  ${n}

    WS Connect                      ${WS_FLEETURL}  timeout=10

    # Get contacts
    ${contacts}=  get  /contacts

    # Get contact1 name
    ${name1}=            get from dictionary  ${contacts[0]}  name

    # Get contact2 contact except for name
    ${contactId2}=       get from dictionary  ${contacts[1]}  contactId
    ${email2}=           get from dictionary  ${contacts[1]}  email
    ${mobilePhone2}=     get from dictionary  ${contacts[1]}  mobilePhone
    ${otherPhone2}=      get from dictionary  ${contacts[1]}  otherPhone
    ${contactType2}=     get from dictionary  ${contacts[1]}  contactType

    # Update contact name on contact2 to contact 1.
    ${contact}=  create dictionary
    set to dictionary  ${contact}  contactId    ${contactId2}
    set to dictionary  ${contact}  name         ${name1}
    set to dictionary  ${contact}  email        ${email2}
    set to dictionary  ${contact}  mobilePhone  ${mobilePhone2}
    set to dictionary  ${contact}  otherPhone   ${otherPhone2}
    set to dictionary  ${contact}  contactType  ${contactType2}

    log dictionary  ${contact}
    ${c}=  put  /contacts  ${contact}  ${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_DUPLICATE


    # Get contact
    ${contacts}=  get  /contacts
    ${length}=  Get Length  ${contacts}
    Should Be Equal  ${2}  ${length}

    # Post
    ${driverName}=  get from dictionary  ${DRIVERS}  ${hmiuser}
    Logout Driver REST  ${WS_FLEETURL}  ${hmiuser}  ${driverName}

    WS Close
    Disable service

Error codes on PUT
    [Documentation]  Provoke error reporting as described in the API.
    [Tags]    LD_Req-43414 v1    LD_Req-43415 v1    LD_Req-43417 v1    LD_Req-43413 v1    LD_Req-43416 v1    LD_Req-43427 v1

    Disable service

    ${e}=  create dictionary
    set to dictionary  ${e}  name           The Provoker
    set to dictionary  ${e}  email          the@provoker.domain
    set to dictionary  ${e}  mobilePhone    +1666
    set to dictionary  ${e}  otherPhone     +4690000
    set to dictionary  ${e}  contactType    PRIVATE

    ${f}=  create dictionary
    set to dictionary  ${f}  name           Magnus
    set to dictionary  ${f}  email          magnus@altran.com
    set to dictionary  ${f}  mobilePhone    +12345
    set to dictionary  ${f}  otherPhone     +23456
    set to dictionary  ${f}  contactType    PRIVATE

    # While disabled, fail to enter a contact
    ${c}=  post  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_DISABLED

    Enable service

    ${driverName}=  get from dictionary  ${DRIVERS}  driver2
    Create Driver And Login REST  ${WS_FLEETURL}  driver2  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Clear private address book
    Make driver setting sync resp   0driver2   4

    # Prepare two contacts
    ${c}=  post  /contacts  ${e}  status_code=${200}
    ${c}=  post  /contacts  ${f}  status_code=${200}
    ${contacts}=   get  /contacts

    ${contactId}=  get from dictionary  ${contacts[0]}  contactId
    ${fname}=  get from dictionary  ${contacts[0]}  name
    should be equal  Magnus  ${fname}
    set to dictionary  ${f}  contactId  ${contactId}

    ${contactId}=  get from dictionary  ${contacts[1]}  contactId
    ${ename}=  get from dictionary  ${contacts[1]}  name
    should be equal  The Provoker  ${ename}
    set to dictionary  ${e}  contactId  ${contactId}
    ${contactId}=  get from dictionary  ${e}  contactId

    set to dictionary  ${e}  name           ${Empty}
    ${c}=  put  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_NAME
    set to dictionary  ${e}  name           The Provoker

    set to dictionary  ${e}  email          .the@provoker.domain
    ${c}=  put  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_EMAIL
    set to dictionary  ${e}  email          the@provoker.domain

    set to dictionary  ${e}  mobilePhone    ++99XX
    ${c}=  put  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_MOBILE
    set to dictionary  ${e}  mobilePhone    +166

    set to dictionary  ${e}  otherPhone          98+23XX
    ${c}=  put  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_INVALID_OTHER
    set to dictionary  ${e}  otherPhone        +4690000

    ${e}=  create dictionary  contactId  ${contactId}  name  The Provoker  email  ${Empty}  mobilePhone  ${Empty}  otherPhone  ${Empty}
    ${c}=  put  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_ONLY_NAME

    ${e}=  create dictionary  contactId  ${contactId}  name  The Provoker2  email  the@provoker.domain  mobilePhone  ${Empty}  otherPhone  ${Empty}
    ${c}=  put  /contacts  ${e}  status_code=${200}

    ${e}=  create dictionary  contactId  ${contactId}  name  The Provoker3  email  ${Empty}  mobilePhone  +1666  otherPhone  ${Empty}
    ${c}=  put  /contacts  ${e}  status_code=${200}

    ${e}=  create dictionary  contactId  ${contactId}  name  Magnus  email  ${Empty}  mobilePhone  +1666  otherPhone  ${Empty}
    ${c}=  put  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_DUPLICATE

    ${e}=  create dictionary  contactId  ${contactId}  name  The Provoker4  email  ${Empty}  mobilePhone  ${Empty}  otherPhone  +4690000
    ${c}=  put  /contacts  ${e}  status_code=${400}
    dictionary should contain item  ${c.json()}  message  ERROR_CONTACTS_ONLY_NAME

    # If for example phones are left out it should still be possible to enter contact if email and name are set.
    ${e}=  create dictionary  contactId  ${contactId}  name  The Provoker5  email  the@provoker.domain
    ${c}=  put  /contacts  ${e}  status_code=${200}

    Disable service

FilterAddressBook
    [Documentation]    Filter addressbook by mobilePhone, PRIVATE or email.
    [Tags]
    Enable service

    ${driverName}=  get from dictionary  ${DRIVERS}  driver2
    Create Driver And Login REST  ${WS_FLEETURL}  driver2  1256  ${driverName}  ${SYNCHRONIZE_PRIVATE_CONTACTS}

    Clear private address book
    Make driver setting sync resp   0driver2   4

    ${e}=  create dictionary
    set to dictionary  ${e}  name           Gurkan
    set to dictionary  ${e}  email          master@bbbb.team
    set to dictionary  ${e}  mobilePhone    ${Empty}
    set to dictionary  ${e}  otherPhone     ${Empty}
    set to dictionary  ${e}  contactType    PRIVATE
    post  /contacts    ${e}  status_code=${200}

    ${e}=  create dictionary
    set to dictionary  ${e}  name           Bengt Spiskummin
    set to dictionary  ${e}  email          spis@kumm.in
    set to dictionary  ${e}  mobilePhone    +4677705525112
    set to dictionary  ${e}  otherPhone     +4677705525113
    set to dictionary  ${e}  contactType    PRIVATE
    post  /contacts    ${e}  status_code=${200}

    ${e}=  create dictionary
    set to dictionary  ${e}  name           Lennart Kanel
    set to dictionary  ${e}  email          ${Empty}
    set to dictionary  ${e}  mobilePhone    +4677702222222
    set to dictionary  ${e}  otherPhone     +4677702222223
    set to dictionary  ${e}  contactType    PRIVATE
    post  /contacts    ${e}  status_code=${200}

    # Filter by PRIVATE
    ${c}=  get  /contacts?filter=private
    ${l}=  Get Length    ${c}
    Should be true   ${l}==3
    ${fname}=  get from dictionary  ${c[0]}  name
    should be equal  Bengt Spiskummin  ${fname}
    ${fname}=  get from dictionary  ${c[1]}  name
    should be equal  Gurkan  ${fname}
    ${fname}=  get from dictionary  ${c[2]}  name
    should be equal  Lennart Kanel  ${fname}

    # Filter by email address
    ${c}=  get  /contacts?filter=email
    ${l}=  Get Length    ${c}
    Should be true   ${l}==2
    ${fname}=  get from dictionary  ${c[0]}  name
    should be equal  Bengt Spiskummin  ${fname}
    ${fname}=  get from dictionary  ${c[1]}  name
    should be equal  Gurkan  ${fname}

    # Filter by mobilephone
    ${c}=  get  /contacts?filter=mobilephone
    ${l}=  Get Length    ${c}
    Should be true   ${l}==2
    ${fname}=  get from dictionary  ${c[0]}  name
    should be equal  Bengt Spiskummin  ${fname}
    ${fname}=  get from dictionary  ${c[1]}  name
    should be equal  Lennart Kanel  ${fname}

Error adding contact after reboot with tacho login
    [Documentation]  Checking if TGW accepts new private contacts after reboot. (OBT-6403)
    ...              1. Login driver1 via tacho
    ...              2. Add public contacts
    ...              3. Reboot TGW (driver1 remains logged in)
    ...              4. Add private contact
    [Tags]    LD_Req-43427 v1    ErrorAddingContact    

    # Pre
    ${random}=  Evaluate  random.randint(5, 30)  modules=random, sys            # Create random integer 5-30
    ${msg}=  resource new temp name
    CTA Set Timeout  3m

    # Force disable
    Disable service
    Delete File From Flash  /flash/tgw_root/SettingsManager/_ADDRESS_BOOK_SERVICEENABLED

    Enable service
    WS Connect  ${WS_FLEETURL}
    WS start pinger

	Login Driver    TACHO    ${tachoDr1Id}    ${SYNCHRONIZE_PRIVATE_CONTACTS}
    WS stop threads
    WS Close

    Make driver setting sync resp  1&amp;#x1;&amp;#x0;1000700111910000  ${random}
    Check Private AddressBook Settings  ${random}

    CTA send message expect response   publicAddressBookUpdateReq.xml    publicAddressBookUpdateResp.xml

    # Create new entry
    ${contact}=  Create Dictionary
    Set To Dictionary  ${contact}  name         Kristoffer Haglund
    Set To Dictionary  ${contact}  email        kristoffer.haglund@consultant.volvo.com
    Set To Dictionary  ${contact}  mobilePhone  +1
    Set To Dictionary  ${contact}  otherPhone   +1
    Set To Dictionary  ${contact}  contactType  PRIVATE

    Post  /contacts    ${contact}

    Wait Until Keyword Succeeds  2m  8s  Read File From Flash  /flash/tgw_root/SettingsManager/_ADDRESS_BOOK_SERVICEENABLED

    Log To Console  Restarting TGW ...

    Bus power Off
    Sleep                               5s
    Bus Power On

    ${req}=  CTA receive save message async  privateAddressBookSynchReq.xml  ${msg}
    CTA Wait Until  ${req}

    #CTA send message                    driverLoginResp_Driver1.xml
    ${driverLoginRespFailDriver1}=      Driver Authentication Create Login Resp  successful  1&#x1;&#x0;1000700111910000  Ronnie Petersson
    CTA Send Message                    ${driverLoginRespFailDriver1}

    Log To Console  TGW is active ...

    WS Connect  ${WS_FLEETURL}
    WS start pinger

    Respond To Sync Private Address Book  ${msg}

    # Handling for the missing check on contactsSynchronized notification
    ${contactsNotification}=  Check notification  /contacts
    ${contactsEvent}=         get from dictionary  ${contactsNotification}  event
    ${contactsNotification}=  Run Keyword If  '${contactsEvent}'=='contactsUpdated'  Check notification  /contacts
    ...  ELSE IF  '${contactsEvent}'!='contactsUpdated'  Copy Dictionary  ${contactsNotification}

    Dictionary should contain item  ${contactsNotification}  event  contactsSynchronized

    ${privateContacts}=  get  /contacts?filter=private
    Log To Console  Private contacts found: ${privateContacts}

    Delete  /contacts

    ${privateContacts}=  get  /contacts?filter=private
    Length Should Be  ${privateContacts}  ${0}

    ${publicContacts}=  get  /contacts?filter=public
    Length Should Be  ${publicContacts}  ${5}

    ${r}=  post  /contacts  ${contact}  status_code=${200}

    Check Private AddressBook Settings  ${random}

    # Post
	Logout Driver    TACHO    ${tachoDr1Id}

    Disable service

    WS stop threads
    WS Close
    Driver Authentication Remove XML File  ${driverLoginRespFailDriver1}
*** Keywords ***
Addressbook Should Contain
    [Documentation]  Used when checking addressbook for items
    [Arguments]  ${addrbook}  ${email}  ${mobile}  ${other}

    Dictionary Should Contain Key   ${addrbook}  contactId
    Dictionary Should Contain Item  ${addrbook}  name         Berra
    Dictionary Should Contain Item  ${addrbook}  email        ${email}
    Dictionary Should Contain Item  ${addrbook}  mobilePhone  ${mobile}
    Dictionary Should Contain Item  ${addrbook}  otherPhone   ${other}
    Dictionary Should Contain Item  ${addrbook}  contactType  PRIVATE

Set to addressbook
    [Documentation]  Sets mail, phone and other in addressbook
    [Arguments]  ${addressbook}  ${email}  ${mobile}  ${other}

    Set To Dictionary  ${addressbook}  email         ${email}
    Set To Dictionary  ${addressbook}  mobilePhone   ${mobile}
    Set To Dictionary  ${addressbook}  otherPhone    ${other}
    [return]  ${addressbook}

Delete File From Flash
    [Documentation]  Delete specificed file
    [Arguments]  ${filePath}

    ${r}=  telnet TGW cli send command  rm ${filePath}
    Log To Console  ${r}

Read File From Flash
    [Documentation]  Check if file exists and return it
    [Arguments]  ${filePath}

    ${fileNotFoundError}=  Set Variable  Non existent file
    ${fileContents}=  telnet TGW cli send command  cat ${filePath}
    Log To Console  ${fileContents}

    Should Not Start With  ${fileContents[0]}  ${fileNotFoundError}
    [return]  ${fileContents}

Respond To Sync Private Address Book
    [Arguments]    ${fname}
    [Documentation]   Receive a private address book sync request and respond
    ...               with a successful response.

    ${msgid}=  get element  ${fname}  xpath=privateAddressBookSynchReq/msgId
    ${fname}=  resource get  privateAddressBookSynchResp.xml
    ${xmlroot}=  parse xml  ${fname}
    add element  ${xmlroot}  ${msgid}  xpath=privateAddressBookSynchResp
    log element  ${xmlroot}
    ${fname}=  set variable  ${TEMPDIR}${/}privateAddressBookSynchRespMSGID.xml
    save xml  ${xmlroot}  ${fname}

    CTA send message     ${fname}

Enable service
    CTA send message expect response   addressBookSettingReq_enable.xml    addressBookSettingResp.xml
    CTA send message expect response   msgConfigReq_enable.xml             msgConfigResp.xml

Disable service
    CTA send message expect response   addressBookSettingReq_disable.xml    addressBookSettingResp.xml
    CTA send message expect response   msgConfigReq_disable.xml             msgConfigResp.xml

Make address book update req
    [Arguments]   ${numentries}   ${time_out}=${10}
    [Documentation]  Make a public address book of ${numentries} entries.
    ...              time_out argument configurable due to latency in large address book handling.
    ${xmlroot}=         parse xml     <pdu service="17" version="2"><publicAddressBookUpdateReq><msgId>123</msgId><entries /></publicAddressBookUpdateReq></pdu>
    ${elist}=           get element    ${xmlroot}   publicAddressBookUpdateReq/entries
    ${adrbk}=           create list
    :for   ${n}   in range   ${numentries}
    \  ${e}=  create dictionary
    \  set to dictionary  ${e}  name           Carolus ${n} Rex
    \  set to dictionary  ${e}  email          user${n}@host.domain
    \  set to dictionary  ${e}  mobilePhone    +1${n}
    \  set to dictionary  ${e}  otherPhone     +4631${n}
    \  append to list  ${adrbk}  ${e}
    \    ${item}=   parse xml    <item />
    \    add element   ${item}    <name>Carolus ${n} Rex</name>
    \    add element   ${item}    <mobilenumber>+1${n}</mobilenumber>
    \    add element   ${item}    <otherNumber>+4631${n}</otherNumber>
    \    add element   ${item}    <email>user${n}@host.domain</email>
    \    add element   ${elist}   ${item}
    ${fname}=   set variable   ${TEMPDIR}${/}req-${numentries}.xml
    save xml           ${xmlroot}      ${fname}

    WS Connect          ${WS_FLEETURL}    timeout=${time_out}

    #CTA send message expect response   ${fname}   addressBookUpdateResp_OK.xml  FIXME
    CTA send message  ${fname}
    ${n}=  check notification  /contacts
    dictionary should contain item  ${n}  event  contactsUpdated

    WS Close

    [Return]  ${adrbk}

Check Private AddressBook Settings
    [Documentation]  Get Private addressbook settings and check that response is ok.
    [Arguments]      ${maxPrivContacts}

    ${ps}=  get  /contacts/settings
    ${maxPrivJson}=     get from dictionary  ${ps}  maxprivcontacts
    ${maxPrivExpect}=   Convert To Integer  ${maxPrivContacts}

    Should Be Equal  ${maxPrivExpect}  ${maxPrivJson}


Make private address book
    [Arguments]    ${driverId}    ${size}
    [Documentation]   Make a private addressbook for 'driverId' with 'size' entries
    ${ts}=       get time   epoch
    ${xmlroot}=   parse xml   <pdu service="17" version="2"><privateAddressBookSynchResp /></pdu>
    add element   ${xmlroot}   <msgId>1</msgId>                           xpath=privateAddressBookSynchResp
    add element   ${xmlroot}   <sendOBSUpdate>0</sendOBSUpdate>           xpath=privateAddressBookSynchResp
    add element   ${xmlroot}   <privateAddressBookUpdate />               xpath=privateAddressBookSynchResp
    add element   ${xmlroot}   <driverId>0${driverId}</driverId>          xpath=privateAddressBookSynchResp/privateAddressBookUpdate
    add element   ${xmlroot}   <changeTimestamp>${ts}</changeTimestamp>   xpath=privateAddressBookSynchResp/privateAddressBookUpdate
    add element   ${xmlroot}   <entries />                                xpath=privateAddressBookSynchResp/privateAddressBookUpdate

    :for  ${n}   in range  ${size}
    \  ${item}=       parse xml   <item />
    \  add element    ${item}   <name>Gustavus ${n} Rex</name>
    \  add element    ${item}   <mobilenumber>+479${n}</mobilenumber>
    \  add element    ${item}   <otherNumber></otherNumber>
    \  add element    ${item}   <email>a${n}@volvo.net</email>
    \  add element    ${xmlroot}   ${item}    xpath=privateAddressBookSynchResp/privateAddressBookUpdate/entries
    ${fname}=         set variable   ${TEMPDIR}${/}privateaddressbookupdate.xml
    save xml          ${xmlroot}   ${fname}
    CTA send message  ${fname}

Clear public address book
    Make address book update req  0

Clear private address book
    WS Connect          ${WS_FLEETURL}    timeout=10
    delete  /contacts
    ${n}=  check notification  /contacts
    dictionary should contain item  ${n}  event  contactsUpdated
    # Check number of private contacts
    ${lc}=  get  /contacts?filter=private
    length should be  ${lc}  0
    WS Close

Verify address book entries
    [Documentation]  Checks that the number of entries in the entire address book is ${noe}
    [Arguments]  ${adrbk}  ${book}=public
    ${noe}=  get length  ${adrbk}
    ${c}=  get dh  /contacts?filter\=${book}  timeout=${30.0}
    log  ${c.headers}
    # Expect 'content-range': '0-9/4'
    ${cr}=  get from dictionary  ${c.headers}  content-range
    @{cr}=  split string  ${cr}  /
    ${len}=  evaluate  @{cr}[1]
    should be equal as integers  ${noe}  ${len}
    @{cr}=   split string  @{cr}[0]  -
    ${offset}=  evaluate  @{cr}[0]
    ${limit}=   evaluate  @{cr}[1]
    should be true  ${limit} <= ${len}
    # Now verify the contents
    :for  ${i}  in range  ${len}
    \  ${e}=  get dh  /contacts?filter\=${book}&offset\=${i}&limit\=1  timeout=${30.0}
    \  log  ${e.headers}
    \  dictionary should contain item  ${e.headers}  content-range  ${i}-1/${len}
    \  ${e}=  set variable  ${e.json()}
    \  ${e}=  set variable  @{e}[0]
    \  dictionary should contain item  ${e}  contactType  ${book.upper()}
    \  remove from dictionary  ${e}  contactId  contactType
    \  ${ix}=  get index from list  ${adrbk}  ${e}
    \  should not be equal  ${ix}  ${-1}
    \  remove from list  ${adrbk}  ${ix}

    should be empty  ${adrbk}

Make driver setting sync resp
    [Arguments]    ${driverId}   ${mboxsize}

    ${xmlroot}=   parse xml    <pdu service="6" version="6"><driverSettingsSynchResp></driverSettingsSynchResp></pdu>
    add element    ${xmlroot}   <msgId>123</msgId>                                 xpath=driverSettingsSynchResp
    add element    ${xmlroot}   <sendOBSDriverSettings>1</sendOBSDriverSettings>   xpath=driverSettingsSynchResp
    ${x}=   parse xml  <bosDriverSettingsUpdate></bosDriverSettingsUpdate>
    ${ts}=  get time  epoch
    add element   ${x}   <timestamp>${ts}</timestamp>
    add element   ${x}   <driverId>${driverId}</driverId>
    add element   ${x}   <minVolume>50</minVolume>
    add element   ${x}   <menuProtection>1</menuProtection>
    add element   ${x}   <writeToNumber>1</writeToNumber>
    add element   ${x}   <privateAddressBookEntries>${mboxsize}</privateAddressBookEntries>
    add element   ${x}   <writeNewMail>1</writeNewMail>
    add element   ${x}   <nightlyAutoResetEnable>1</nightlyAutoResetEnable>
    add element   ${xmlroot}   ${x}                                                xpath=driverSettingsSynchResp
    ${x}=   parse xml   <obsDriverSettingsUpdate></obsDriverSettingsUpdate>
    add element   ${x}   <timestamp>${ts}</timestamp>
    add element   ${x}   <driverId>${driverId}</driverId>
    add element   ${x}   <screenSaverTimeout>123</screenSaverTimeout>
    add element   ${x}   <volume>50</volume>
    add element   ${x}   <currentLanguage><english>0</english></currentLanguage>
    add element   ${x}   <metrics><eu>0</eu></metrics>
    add element   ${x}   <showDecoNotifications>1</showDecoNotifications>
    # obsDriverSettingsUpdate is OPTIONAL add element  ${xmlroot}   ${x}
    ${fname}=     set variable   ${TEMPDIR}${/}driversettingssynchresp.xml
    save xml      ${xmlroot}  ${fname}
    CTA send message expect response   ${fname}  obsDriverSettingsUpdate.xml

 #   ${n}=  check notification  /contacts
 #   dictionary should contain item  ${n}  event  contactsSynchronized

Fail to enter private address
    [Documentation]    Fail to add new contact to private address book.
    ${abe}=  create dictionary
    set to dictionary  ${abe}  name   Nemo
    set to dictionary  ${abe}  email  nemo@volvo.com
    set to dictionary  ${abe}  mobilePhone  +467
    set to dictionary  ${abe}  otherPhone   +4631
    set to dictionary  ${abe}  contactType  PRIVATE
    ${r}=  post  /contacts  ${abe}  status_code=${400}
    dictionary should contain item  ${r.json()}  message  ERROR_CONTACTS_FULL

Fail to enter private duplicate
    [Documentation]    Fail to enter new contact to private address book. Name already in book!
    ...                Start at Messages in Main Menu.
    [Arguments]   ${name}

    ${abe}=  create dictionary
    set to dictionary  ${abe}  name   ${name}
    set to dictionary  ${abe}  email  ${name}@volvo.com
    set to dictionary  ${abe}  mobilePhone  +467
    set to dictionary  ${abe}  otherPhone   +4631
    set to dictionary  ${abe}  contactType  PRIVATE  # FIXME needed? Obvious?
    ${r}=  post  /contacts  ${abe}  status_code=${400}
    dictionary should contain item  ${r.json()}  message  ERROR_CONTACTS_DUPLICATE

Delete Private Address
    [Documentation]    Delete one private address book entry.
    [Arguments]        ${deleteName}

    WS Connect          ${WS_FLEETURL}    timeout=10

    ${e}=  get dh  /contacts?filter\=private  timeout=${30.0}
    ${e}=  set variable  ${e.json()}

    ${deleteId}=  Set Variable  ${None}

    :FOR  ${contact}   IN   @{e}
    \  ${name}=  get from dictionary  ${contact}  name
    \  ${contactId}=  get from dictionary  ${contact}  contactId
    \  ${deleteId}=   Set Variable If  "${name}" == "${deleteName}"  ${contactId}  ${deleteId}
    \  Run Keyword If    "${name}" == "${deleteName}"    Exit For Loop

    delete  /contacts/${deleteId}

    ${n}=  check notification  /contacts
    dictionary should contain item  ${n}  event  contactsUpdated

    WS Close

Enter private address
    [Documentation]   Add new contact to private address book.
    [Arguments]   ${name}

    WS Connect          ${WS_FLEETURL}    timeout=10

    ${abe}=  create dictionary
    set to dictionary  ${abe}  name   ${name}
    set to dictionary  ${abe}  email  ${name}@volvo-fake.com
    set to dictionary  ${abe}  mobilePhone  +467
    set to dictionary  ${abe}  otherPhone   +4631

    log dictionary  ${abe}
    ${c}=  post  /contacts  ${abe}
    ${c}=  set variable  ${c.json()}
    log dictionary  ${c}
    dictionary should contain item  ${c}  name         ${name}
    dictionary should contain item  ${c}  email        ${name}@volvo-fake.com
    dictionary should contain item  ${c}  mobilePhone  +467
    dictionary should contain item  ${c}  otherPhone   +4631
    dictionary should contain item  ${c}  contactType  PRIVATE
    dictionary should contain key   ${c}  contactId

    ${n}=  check notification  /contacts
    dictionary should contain item  ${n}  event  contactsUpdated
    WS Close

Enter private addresses
    [Arguments]   ${noe}
    :for   ${n}   in range  ${noe}
    \   Enter private address   U${n}

Test Setup
    Basic Setup

    Bus set key position    drive

    #${ssid}=      Run Keyword If          '${ENV}' == 'UTESP'    Connect Over Wifi      #connect wifi in when wifi is used (env is UTESP)
    # Order management used at zero speed
    Canoe set environment variable      EnvTachoStartStop      1
    Canoe set environment variable      EnvDrivercardsDriver1  0
    Canoe Set environment variable      EnvVehicleSpeed        0
    #CTA Send Message                    driverLoginConfig_enable.xml
    ${driverLogInConfig}=                Driver Authentication Create Login Config    0                      1       60     True
    CTA Send Message                    ${driverLogInConfig}
    Sleep                               5s
    Driver Authentication Remove XML File  ${driverLogInConfig}

Test Teardown
    canoe set environment variable  EnvDrivercardsDriver1   0  # Forceful logout

    # FIXME login and logout tacho driver; flushes the HMI logins!
    :for  ${d}  in  @{DRIVERS.keys()}
    \  ${arg}=  create dictionary  driverId  ${d}
    \  run keyword and ignore error  post  /drivers/actions/logout  ${arg}

    Run Keyword And Ignore Error        WS stop threads
    Run Keyword And Ignore Error        WS Close

    #Run Keyword If          '${ENV}' == 'UTESP'       Disconnect And Disable Wifi         ${ssid}
    Basic Teardown

Suite Setup
    Basic suite setup

    ${HEADERS}=  create dictionary  Content-Type  application/json  Accept  resourceVersion\=1
    set suite variable  ${HEADERS}

    ${DRIVERS}=  create dictionary  driver1  Driver1  driver2  Driver2  driver3  Driver3
    set suite variable  ${DRIVERS}
    Run Keyword If          '${ENV}' == 'UTESP' and '${ARCHITECTURE}' == 'TEA2'      WLAN Preparation
Suite Teardown
    Disable service
    Basic Suite Teardown
    Run Keyword If          '${ENV}' == 'UTESP' and '${ARCHITECTURE}' == 'TEA2'       WLANHelper Suite Teardown

Verify Private Address Book Update
    [Documentation]
    [Arguments]  ${driverId}  ${fname}  @{itemNames}

    ${manualDriverId}=  set variable  0${driverId}

    ${msgid}=  get element text  ${fname}  xpath=privateAddressBookUpdate/driverId
    LOG  ${msgid}
    Should Be Equal  ${msgid}  ${manualDriverId}

    ${entries}=  get element  ${fname}  xpath=privateAddressBookUpdate/entries
    LOG  ${entries}

    ${children}=  Get Child Elements  ${entries}
    LOG  ${children}

    ${lenChild}=  Get Length  ${children}
    ${lenNames}=  Get Length  ${itemNames}
    Should Be Equal  ${lenChild}  ${lenNames}

    :FOR  ${child}  IN  @{children}
    \  LOG   ${child}
    \  ${name}=          get element text  ${child}  xpath=name
    \  ${mobilenumber}=  get element text  ${child}  xpath=mobilenumber
    \  ${otherNumber}=   get element text  ${child}  xpath=otherNumber
    \  ${email}=         get element text  ${child}  xpath=email
    \  List Should Contain Value   ${itemNames}      ${name}
    \  Should Be Equal As Strings  ${mobilenumber}   +467
    \  Should Be Equal As Strings  ${otherNumber}    +4631
    \  Should Be Equal As Strings  ${email}          ${name}@volvo-fake.com

Get dh
    [Arguments]  ${url}  ${status_code}=${200}  ${timeout}=${10.0}  ${verify_server}=${False}
    ${verify_server}=   Set Variable If     ${verify_server}==${TRUE}     ${CA_CERT}    ${FALSE}

    ${CertAndKey}=  Create List  ${USR_CERT}  ${USR_KEY}
    ${r}=  requests.get  ${FLEETURL}${url}  headers=${HEADERS}  timeout=${timeout}  cert=${CertAndKey}  verify=${verify_server}
    Log     URL Fleet used: ${FLEETURL}${url}
    should be equal  ${r.status_code}  ${status_code}
    [return]   ${r}
