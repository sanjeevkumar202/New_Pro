*** Settings ***
Documentation  This test suite will verify the USB driver.
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Bsp/BspUsbTester.py
Library  Collections

Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${SERIAL_HANDLE}
${CDCSER_SERIAL_HANDLE}
${DEBUG}  ${1}


*** Keywords ***
CheckDiffNetworkInterface
  [Documentation]  Check diff, current with earlier Network Interface device connected to the Windows PC.
  [Arguments]  ${netlist1}
   ${netlist2}  Usb List Networks  ${DEBUG}
   Should not be equal  ${netlist1}  ${netlist2}

MountAndCheckUsbContent
  [Documentation]  Mount USB and check the USB file content.
  [Arguments]

  #Disconnect the USB device by removing power
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  1

  Sleep  2s
   #Get the last time stamp in ramlog
  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${lasttimestamp}  Get Last Time Stamp From Ramlog  ${ramlog}

  #Connect the USB device by removing power
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0

  Sleep  5s

  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Usb Check Device State Change  Device #0 state changed to 1  ${ramlog}  ${lasttimestamp}
  Should be equal  ${result}  Device State Change OK

  Sleep  5s
  ${flashDriveContent}  Usb List Flash Drive Content  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Check String Content  ${flashDriveContent}  Doc.txt
  Should be equal  ${result}  Doc.txt

  ${result}  Check String Content  ${flashDriveContent}  BigFile.txt
  Should be equal  ${result}  BigFile.txt

UnmountAndCheckUsbContent
  [Documentation]  Unmount USB and check that no USB is connected.
  [Arguments]

  #Get the last time stamp in ramlog
  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${lasttimestamp}  Get Last Time Stamp From Ramlog  ${ramlog}

  #Disconnect the USB device by removing power
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  1

  Sleep  5s

  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Usb Check Device State Change  Device #0 state changed to 0  ${ramlog}  ${lasttimestamp}
  Should be equal  ${result}  Device State Change OK

  Sleep  5s
  ${flashDriveContent}  Usb List Flash Drive Content  ${TELNET_HANDLE}  ${DEBUG}
  Should be equal  ${flashDriveContent}  No Flash Drive Found

CheckUsbReadTestFileOnFlashDrive
  [Documentation]  Reads from USB and checks file content.
  [Arguments]

  #Get the last time stamp in ramlog
  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${lasttimestamp}  Get Last Time Stamp From Ramlog  ${ramlog}

  #Make sure flash drive is connected
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0

  Sleep  5s

  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Usb Check Device State Change  Device #0 state changed to 1  ${ramlog}  ${lasttimestamp}
  Should be equal  ${result}  Device State Change OK
  Sleep  5s
  ${textfilecontent}  Usb Read Text File On Flash Drive  Doc.txt  ${TELNET_HANDLE}  ${DEBUG}

  ${result}  Check String Content  ${textfilecontent}  Row 1
  Should be equal  ${result}   Row 1

  ${result}  Check String Content  ${textfilecontent}  Row 2
  Should be equal  ${result}   Row 2

  ${result}  Check String Content  ${textfilecontent}  Row 3
  Should be equal  ${result}   Row 3

  ${result}  Check String Content  ${textfilecontent}  Row 4
  Should be equal  ${result}  Row 4

  ${result}  Check String Content  ${textfilecontent}  Row 5
  Should be equal  ${result}   Row 5


*** Test Cases ***
#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite
  [Tags]  TGW2.0  TGW2.1  FLASH_SMALL_FS_TEST

  BSP TestSuite Setup TFTP Boot


#*************************************************************************************************
# USB_COMM_STARTUP
#*************************************************************************************************
USB Communication Startup
  [Documentation]  To verify that the USB driver is starting up properly and that the necessary
  ...              drivers are correctly installed and configured.
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}

  ${result}  Check String Content  ${ramlog}  Register driver usb_imx
  Should be equal  ${result}  Register driver usb_imx

  ${result}  Check String Content  ${ramlog}  Register driver usb_cdcser
  Should be equal  ${result}  Register driver usb_cdcser

  ${result}  Check String Content  ${ramlog}  Register driver mst_disk
  Should be equal  ${result}  Register driver mst_disk

  ${result}  Check String Content  ${ramlog}  dda/mx/usbcdcHost0: successfully activated
  Should be equal  ${result}  dda/mx/usbcdcHost0: successfully activated

  ${result}  Check String Content  ${ramlog}  dda/mx/usbcdcHost1: successfully activated
  Should be equal  ${result}  dda/mx/usbcdcHost1: successfully activated

  ${result}  Check String Content  ${ramlog}  dda/mx/usbcdcHost2: successfully activated
  Should be equal  ${result}  dda/mx/usbcdcHost2: successfully activated

  ${result}  Check String Content  ${ramlog}  dda/mx/usbcdcOtg0: successfully activated
  Should be equal  ${result}  dda/mx/usbcdcOtg0: successfully activated

  ${result}  Check String Content  ${ramlog}  dda/mx/usbh2: successfully activated
  Should be equal  ${result}  dda/mx/usbh2: successfully activated

  ${result}  Check String Content  ${ramlog}  dda/mx/usbmst: successfully activated
  Should be equal  ${result}  dda/mx/usbmst: successfully activated

  ${result}  Check String Content  ${ramlog}  dda/mx/usbotg: successfully activated
  Should be equal  ${result}  dda/mx/usbotg: successfully activated

  ${result}  Check String Content  ${ramlog}  BSP: Started USB
  Should be equal  ${result}  BSP: Started USB

  ${result}  Check String Content  ${ramlog}  Init USB driver OSE interface
  Should be equal  ${result}  Init USB driver OSE interface

  ${result}  Check String Content  ${ramlog}  Starting USB host and device
  Should be equal  ${result}  Starting USB host and device

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_HOST_CONNECT
#*************************************************************************************************
USB Host Connect
  [Documentation]  To verify that the USB detects devices that are connected to the USB interface
  ...              and powered on.
  [Tags]  TGW2.0  TGW2.1  USB_FLASH_DRIVE

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #Get the last time stamp in ramlog
  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${lasttimestamp}  Get Last Time Stamp From Ramlog  ${ramlog}

  #Disconnect the USB device by removing power
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  1

  Sleep  2s

  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Usb Check Device State Change  Device #0 state changed to 0  ${ramlog}  ${lasttimestamp}
  Should be equal  ${result}  Device State Change OK

  #Get the last time stamp in ramlog
  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${lasttimestamp}  Get Last Time Stamp From Ramlog  ${ramlog}

  #Connect the USB device by removing power
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0

  Sleep  2s

  ${ramlog}  Check Usb Ramlog  ${TELNET_HANDLE}  ${DEBUG}
  ${result}  Usb Check Device State Change  Device #0 state changed to 1  ${ramlog}  ${lasttimestamp}
  Should be equal  ${result}  Device State Change OK

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_MST_FS_MOUNT
#*************************************************************************************************
USB Mass Storage File System Mount
  [Documentation]  To verify that the BSP detects Mass Storage devices connected to the Host2 and
  ...              automatically mounts the volume to /mst.
  [Tags]  TGW2.0  TGW2.1  USB_FLASH_DRIVE

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  Wait Until Keyword Succeeds   100s   1s   MountAndCheckUsbContent

  Wait Until Keyword Succeeds   100s   1s   UnmountAndCheckUsbContent

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_MST_READ
#*************************************************************************************************
USB Mass Storage Read
  [Documentation]  To verify that the BSP can read files from the Mass Storage devices connected
  ...              to the external host (Host2).
  [Tags]  TGW2.0  TGW2.1  USB_FLASH_DRIVE

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Watchdog Teaser  ${SERIAL_HANDLE}
  Should be equal  ${result}  TEASER_OK

  Wait Until Keyword Succeeds   100s   1s   CheckUsbReadTestFileOnFlashDrive

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_MST_READ_SPEED
#*************************************************************************************************
USB Mass Storage Read Speed
  [Documentation]  To verify that the BSP has proper performance when reading files from Mass
  ...              Storage devices connected to the Host2
  [Tags]  TGW2.0  TGW2.1  USB_FLASH_DRIVE

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #Make sure flash drive is connected
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0

  ${filetransfer}  Usb Copy File From Flash Drive  BigFile.txt  1  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${filetransfer}  File Transfer Speed OK

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_EVENT_NOTIFICATION
#*************************************************************************************************
USB Event Notification
  [Documentation]  To verify that the BSP can detect and forward to the application events that
  ...              happen on the USB bus (MST device connect/disconnect)
  [Tags]  TGW2.0  TGW2.1  JIRA_ISSUE  OBT-5080

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  #Make sure flash drive is connected
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0

  ${result}  Usb Test Event Notification  START  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Test Started

  #Disconnect flash drive
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  1

  ${event_string_dis}  Usb Test Event Notification  DISCONNECT  ${SERIAL_HANDLE}  ${DEBUG}
  ${result}  Check String Content  ${event_string_dis}  Mass Storage Disconnected Event - on USB HOST unit 0
  Should be equal  ${result}  Mass Storage Disconnected Event - on USB HOST unit 0

  #Connect flash drive
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0

  ${event_string_con}  Usb Test Event Notification  CONNECT  ${SERIAL_HANDLE}  ${DEBUG}
  ${result}  Check String Content  ${event_string_con}  Mass Storage Connected Event - on USB HOST unit 0
  Should be equal  ${result}  Mass Storage Connected Event - on USB HOST unit 0

  ${event_string}  Usb Test Event Notification  STOP  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${event_string}  Test Stopped

  BSP TestCase Teardown

#*************************************************************************************************
# USB_OC_EVENT_NOTIFICATION
#*************************************************************************************************
USB Over Current Event Notification
  [Documentation]  To verify that the BSP can detect and forward to the application over-current
  ...              events that happen on the USB bus. In addition, over-current spike handling
  ...              will be is verified.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# USB_HUB_MST
#*************************************************************************************************
USB HUB Using Mass Storage
  [Documentation]  To verify that the BSP can detect and forward to the application events that
  ...              happen on an external USB hub (MST device connect/disconnect).
  ...              This test case is run on the TGW with small file system.
  [Tags]  TGW2.0  TGW2.1  FLASH_SMALL_FS_TEST  USB_HUB_MST

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Connect To Telnet  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  Canoe Set Vts Variable  USB_HUB_VBUS_Enable  Relay  0

  ${result}  Usb Test Event Notification  START  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Test Started

  #Disconnect flash drive
  Canoe Set Vts Variable  USB_HUB_VBUS_Enable  Relay  1

  ${event_string_dis}  Usb Test Event Notification  CONNECT  ${SERIAL_HANDLE}  ${DEBUG}
  ${result}  Check String Content  ${event_string_dis}  Mass Storage Connected Event - on USB HOST unit 0
  Should be equal  ${result}  Mass Storage Connected Event - on USB HOST unit 0

  #Connect flash drive
  Canoe Set Vts Variable  USB_HUB_VBUS_Enable  Relay  0

  ${event_string_con}  Usb Test Event Notification  DISCONNECT  ${SERIAL_HANDLE}  ${DEBUG}
  ${result}  Check String Content  ${event_string_con}  Mass Storage Disconnected Event - on USB HOST unit 0
  Should be equal  ${result}  Mass Storage Disconnected Event - on USB HOST unit 0

  ${event_string}  Usb Test Event Notification  STOP  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${event_string}  Test Stopped

  BSP TestCase Teardown


#*************************************************************************************************
# USB_COMM_RNDIS_DEVICE_CONNECT
#*************************************************************************************************
USB RNDIS Device Connect
  [Documentation]  To verify that TGW2 acting as RNDIS device can be connected to a Windows PC.
  [Tags]  TGW2.0  TGW2.1  USB_RNDIS_DEVICE

  BSP TestCase Setup
  # Default Values
  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  0
  Canoe Set Vts Variable  USB_HUB_VBUS_Enable  Relay  0
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0
  Sleep  10s

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${netlist1}  Usb List Networks  ${DEBUG}
  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  1
  Wait Until Keyword Succeeds   100s   1s   CheckDiffNetworkInterface   ${netlist1}

  ${result}  Usb Check RNDIS Device Connect  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  RNDIS Device Connected
  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  0  # set to default

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_RNDIS_DEVICE_TRANSFER
#*************************************************************************************************
USB RNDIS Device Transfer
  [Documentation]  To verify that TGW2 acting as RNDIS device can transfer Ethernet packets to
  ...              and from a Windows PC.
  [Tags]  TGW2.0  TGW2.1  USB_RNDIS_DEVICE

  BSP TestCase Setup
  # Default Values
  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  0
  Canoe Set Vts Variable  USB_HUB_VBUS_Enable  Relay  0
  Canoe Set Vts Variable  VBUS_CTRL_USB  Relay  0
  Sleep  10s

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${netlist1}  Usb List Networks  ${DEBUG}
  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  1
  Wait Until Keyword Succeeds   100s   1s   CheckDiffNetworkInterface   ${netlist1}

  sleep  3s
  ${netlist2}  Usb List Networks  ${DEBUG}
  ${networkInterface}  Usb Get Latest Interface  ${netlist1}  ${netlist2}  ${DEBUG}

  ${result}  Usb Transfer RNDIS  ${networkInterface}  ${TELNET_HANDLE}  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Transfer successful

  ##Set back to default
  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  0

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_ECM_DEVICE_CONNECT
#*************************************************************************************************
USB EMC Device Connect
  [Documentation]  To verify that TGW2 acting as ECM device can be connected to a Linux PC.
  [Tags]  TGW2.0  TGW2.1  USB_ECM_DEVICE

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  1

  ${result}  Connect To Telnet Raspberry  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Usb Check Ecm Established  ${TELNET_HANDLE}  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Device ECM Established

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_ECM_DEVICE_TRANSFER
#*************************************************************************************************
USB EMC Device Transfer
  [Documentation]  To verify that TGW2 acting as ECM device can transfer Ethernet packets to and
  ...              from a Linux PC.
  [Tags]  TGW2.0  TGW2.1    USB_ECM_DEVICE

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK

  ${result}  Usb transfer Ecm  ${TELNET_HANDLE}  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  No IP found

  Canoe Set Vts Variable  USB_HOST_CTRL  Relay  1

  ${result}  Connect To Telnet Raspberry  $(DEBUG)
  Should be equal  ${result}  CONNECT_TO_TELNET_OK

  ${result}  Usb Check Ecm Established  ${TELNET_HANDLE}  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Device ECM Established

  ${result}  Usb transfer Ecm  ${TELNET_HANDLE}  ${SERIAL_HANDLE}  ${DEBUG}
  Should be equal  ${result}  Transfer successful

  BSP TestCase Teardown

#*************************************************************************************************
# USB_COMM_RNDIS_HOST_CONNECT
#*************************************************************************************************
USB RNDIS Host Connect
  [Documentation]  To verify that TGW2 acting as RNDIS host can be connected to a RNDIS device.
  ...              The test should be executed with a TGW2 acting as device.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# USB_COMM_RNDIS_HOST_TRANSFER
#*************************************************************************************************
USB RNDIS Host Transfer
  [Documentation]  To verify that TGW2 acting as RNDIS device can transfer Ethernet packets to and
  ...              from a second TGW2 acting as RNDIS device. The test should be executed with a
  ...              TGW2 acting as device.
  [Tags]  TGW2.0  TGW2.1  ManualTest

  Fail  Manual test  ManualTest

#*************************************************************************************************
# USB_COMM_CDC_EXT_HOST
#*************************************************************************************************
USB CDC EXT Host
    [Documentation]  To verify that TGW2 acting as host can transfer on CDC serial connection to
    ...              external devices.
    [Tags]  TGW2.0  TGW2.1  USB_TO_SERIAL

    BSP TestCase Setup

    sleep   2s

    ${result}  Boot And Load    ${SERIAL_HANDLE}
    Should be equal  ${result}  BOOT_OSE_OK
    sleep    2s

    Log_To_Console    Turn on USB OTG (alter ID/Sense)
    Canoe Set Vts Variable  USB_HOST_CTRL  Relay  0
    sleep    1s

    Log_To_Console    Open secondary serial port
    ${result}  Connect Win Cdcport
    Should be equal  ${result}  CONNECT_TO_SERIAL_OK
    sleep    2s

    Log_To_Console    Test CDC Serial connection
    ${result}  Usb Check Cdc Serial    ${SERIAL_HANDLE}    ${CDCSER_SERIAL_HANDLE}    ${DEBUG}
    Log_To_Console   ${result}
    Should be equal  ${result}  CDC Serial Communication OK
    sleep    2s

    Log_To_Console    Turn off USB OTG
    Canoe Set Vts Variable  USB_HOST_CTRL  Relay  1

    BSP TestCase Teardown


#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite
  [Tags]  TGW2.0  TGW2.1  FLASH_SMALL_FS_TEST
  BSP TestSuite Teardown