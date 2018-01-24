*** Settings ***
Documentation  This test suite will verify the DOUT driver.
Library  Robot/Libs/Bsp/BspDoutTester.py
Library  Robot/Libs/Bsp/BspCommonTester.py
Library  Robot/Libs/Common/CANoeVTSTester.py
Library  Robot/Libs/Bsp/BspPwrMgmtTester.py
Resource  Robot/Libs/Bsp/BspResources.robot

*** Variables ***
${TELNET_HANDLE}
${DEBUG}  ${1}

*** Test Cases ***

#*************************************************************************************************
# START_OF_TEST_SUITE
#*************************************************************************************************
TestSuite Start
  [Documentation]  Set Up the test suite.
  [Tags]  TGW2.0  TGW2.1
  BSP TestSuite Setup TFTP Boot

#*************************************************************************************************
# DOUT_FULL_TEST
#*************************************************************************************************
DOUT full test
  [Documentation]  To verify that the digital output driver works. This test also verifies setting
  ...              of all digital outputs and that short circuit is detected as supposed to.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional & Non-Functional (Robustness)
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1


  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  Sleep  0.5s

  # Open Dout driver
  ${result}  Dout Driver Open  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  # Connect load to the outputs
  Canoe Vt2516 Set Relay Org Component Active  Wake_Up
  Canoe Vt2516 Set Relay Org Component Active  D_OUT_1
  Canoe Vt2516 Set Relay Org Component Active  D_OUT_CTRL_UBAT_V_CTR
  Canoe Vt2516 Set Relay Org Component Active  HW_RESET
  Canoe Vt2516 Set Relay Org Component Active  ASSISTANCE_BUTTON_STS

  # Get Dout status
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_WAKE_UP
  Should be equal  ${result}  function DOUT_WAKE_UP, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_D_OUT1
  Should be equal  ${result}  function DOUT_D_OUT1, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_CTRL_UBAT_V
  Should be equal  ${result}  function DOUT_CTRL_UBAT_V, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_HW_RESET
  Should be equal  ${result}  function DOUT_HW_RESET, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS
  Should be equal  ${result}  function DOUT_ASSISTANCE_BUTTON_STS, status STATUS_OK INACTIVE

  # Deactivate and check monitored status
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_WAKE_UP  0
  Should be equal  ${result}  DOUT_WAKE_UP value INACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_D_OUT1  0
  Should be equal  ${result}  DOUT_D_OUT1 value INACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_CTRL_UBAT_V  0
  Should be equal  ${result}  DOUT_CTRL_UBAT_V value INACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_HW_RESET  0
  Should be equal  ${result}  DOUT_HW_RESET value INACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS  0
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS value INACTIVE status STATUS_OK

  #  Check 'STATUS_SHORT_CIRCUIT' when all high-side outputs is con to vbat and all low-side outputs to GND
  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Vbat Active  Wake_Up
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_WAKE_UP, value ACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Vbat Inactive  Wake_Up
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Gnd Active  D_OUT_1
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_D_OUT1, value ACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Gnd Inactive  D_OUT_1
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Vbat Active  D_OUT_CTRL_UBAT_V_CTR
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_CTRL_UBAT_V, value ACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Vbat Inactive  D_OUT_CTRL_UBAT_V_CTR
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Vbat Active  HW_RESET
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_HW_RESET, value ACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Vbat Inactive  HW_RESET
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Vbat Active  ASSISTANCE_BUTTON_STS
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS, value ACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Vbat Inactive  ASSISTANCE_BUTTON_STS
  Sleep  4.0
  Flush Serial Input  ${SERIAL_HANDLE}

  # Get Dout status
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_WAKE_UP
  Should be equal  ${result}  function DOUT_WAKE_UP, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_D_OUT1
  Should be equal  ${result}  function DOUT_D_OUT1, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_CTRL_UBAT_V
  Should be equal  ${result}  function DOUT_CTRL_UBAT_V, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_HW_RESET
  Should be equal  ${result}  function DOUT_HW_RESET, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS
  Should be equal  ${result}  function DOUT_ASSISTANCE_BUTTON_STS, status STATUS_OK INACTIVE

  # Activate and check monitored status
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_WAKE_UP  1
  Should be equal  ${result}  DOUT_WAKE_UP value ACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_D_OUT1  1
  Should be equal  ${result}  DOUT_D_OUT1 value ACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_CTRL_UBAT_V  1
  Should be equal  ${result}  DOUT_CTRL_UBAT_V value ACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_HW_RESET  1
  Should be equal  ${result}  DOUT_HW_RESET value ACTIVE status STATUS_OK
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS  1
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS value ACTIVE status STATUS_OK

  # Get status
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_WAKE_UP
  Should be equal  ${result}  function DOUT_WAKE_UP, status STATUS_OK ACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_D_OUT1
  Should be equal  ${result}  function DOUT_D_OUT1, status STATUS_OK ACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_CTRL_UBAT_V
  Should be equal  ${result}  function DOUT_CTRL_UBAT_V, status STATUS_OK ACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_HW_RESET
  Should be equal  ${result}  function DOUT_HW_RESET, status STATUS_OK ACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS
  Should be equal  ${result}  function DOUT_ASSISTANCE_BUTTON_STS, status STATUS_OK ACTIVE

  # Set all high-side outputs to GND and all low-side outputs to VBAT and check STATUS_SHORT_CIRCUIT
  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Gnd Active  Wake_Up
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_WAKE_UP, value INACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Gnd Inactive  Wake_Up
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Vbat Active  D_OUT_1
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_D_OUT1, value INACTIVE, status STATUS_OPEN_CIRCUIT
  Canoe Vt2516 Set Relay Vbat Inactive  D_OUT_1
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Gnd Active  D_OUT_CTRL_UBAT_V_CTR
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_CTRL_UBAT_V, value INACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Gnd Inactive  D_OUT_CTRL_UBAT_V_CTR
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Gnd Active  HW_RESET
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_HW_RESET, value INACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Gnd Inactive  HW_Reset
  Sleep  1.0

  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Gnd Active  ASSISTANCE_BUTTON_STS
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS, value INACTIVE, status STATUS_SHORT_CIRCUIT
  Canoe Vt2516 Set Relay Gnd Inactive  ASSISTANCE_BUTTON_STS
  Sleep  4.0

  # Get status
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_WAKE_UP
  Should be equal  ${result}  function DOUT_WAKE_UP, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_D_OUT1
  Should be equal  ${result}  function DOUT_D_OUT1, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_CTRL_UBAT_V
  Should be equal  ${result}  function DOUT_CTRL_UBAT_V, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_HW_RESET
  Should be equal  ${result}  function DOUT_HW_RESET, status STATUS_OK INACTIVE
  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS
  Should be equal  ${result}  function DOUT_ASSISTANCE_BUTTON_STS, status STATUS_OK INACTIVE

  # Disconnect the load from the outputs
  Canoe Vt2516 Set Relay Org Component Inactive  Wake_Up
  Canoe Vt2516 Set Relay Org Component Inactive  D_OUT_1
  Canoe Vt2516 Set Relay Org Component Inactive  D_OUT_CTRL_UBAT_V_CTR
  Canoe Vt2516 Set Relay Org Component Inactive  HW_RESET
  Canoe Vt2516 Set Relay Org Component Inactive  ASSISTANCE_BUTTON_STS

  BSP TestCase Teardown

#*************************************************************************************************
# DOUT_OVERVOLTAGE_PROTECTION
#*************************************************************************************************
DOUT overvoltage protection
  [Documentation]  To verify that the BSP inactivates the outputs in case of overvoltage (32V).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  Sleep  0.5s

  ${result}  Dout Driver Open  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_HW_RESET  1
  Should be equal  ${result}  DOUT_HW_RESET value ACTIVE status STATUS_OK

  ${result}  Dout Get  ${SERIAL_HANDLE}  DOUT_HW_RESET
  Should be equal  ${result}  function DOUT_HW_RESET, status STATUS_OK ACTIVE

  # Raise VBAT over threshold 32V and monitor status error.
  Flush Serial Input  ${SERIAL_HANDLE}
  CANoe Set Power Supply Voltage  VBAT_SUP  32.5

  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_HW_RESET, value INACTIVE, status DOUT_STATUS_OVER_VOLTAGE

  # Reactivate output and check status error,
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_HW_RESET  1
  Sleep  1.0s
  Should be equal  ${result}  DOUT_HW_RESET value ACTIVE status DOUT_STATUS_OVER_VOLTAGE

  # Set VBAT under threshold, outpus should be activated again.
  CANoe Adjust VBAT From DUT  ${SERIAL_HANDLE}  VBAT_SUP  30.5
  Sleep  1.0s
  ${result}  Pow Read Vbat  ${SERIAL_HANDLE}  ${1}
  LOG  ${result}
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_HW_RESET  1
  Should be equal  ${result}  DOUT_HW_RESET value ACTIVE status STATUS_OK

  ${result}  Dout Driver Close  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  BSP TestCase Teardown

#*************************************************************************************************
# DOUT_SET_PWM
#*************************************************************************************************
DOUT pwm set/stop
  [Documentation]  Test the digital outputs driver capability to drive assistance status output
  ...              PWM. Also, test that a failure in the output is correctly detected and the
  ...              output is inactivated for 3s, and then reactivated back (by the test
  ...              application).
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  Sleep  0.5s

  ${result}  Dout Driver Open  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  # Set CANoe config for measuring 0.1 Hz
  ${result}  Dout Start PWM  ${SERIAL_HANDLE}  1
  Should be equal  ${result}  val 0.100000Hz status STATUS_OK
  # Check CANoe meas result
  # Wait for CANoe meas result, MeasDuration is set to 25s for ASSISTANCE_BUTTON_STS
  Sleep  26s
  ${result}  CANoe Get VTS Variable  ASSISTANCE_BUTTON_STS  PWMDC
  ${result}  Check PWMDC In Valid Range  ${result}  50
  Should Be Equal  ${result}  SUCCESS
  ${result}  CANoe Get VTS Variable  ASSISTANCE_BUTTON_STS  PWMFreq
  ${result}  Check PWMFreq In Valid Range  ${result}  0.1
  Should Be Equal  ${result}  SUCCESS
  ${result}  Dout Stop PWM  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  # Set CANoe config for measuring 1.3 Hz
  ${result}  Dout Start PWM  ${SERIAL_HANDLE}  13
  Should be equal  ${result}  val 1.300000Hz status STATUS_OK
  # Check CANoe meas result
  # Wait for CANoe meas result, MeasDuration is set to 25s for ASSISTANCE_BUTTON_STS
  Sleep  26s
  ${result}  CANoe Get VTS Variable  ASSISTANCE_BUTTON_STS  PWMDC
  ${result}  Check PWMDC In Valid Range  ${result}  50
  Should Be Equal  ${result}  SUCCESS
  ${result}  CANoe Get VTS Variable  ASSISTANCE_BUTTON_STS  PWMFreq
  ${result}  Check PWMFreq In Valid Range  ${result}  1.3
  Should Be Equal  ${result}  SUCCESS
  ${result}  Dout Stop PWM  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK
  Should be equal  ${result}  status STATUS_OK

  # Set CANoe config for measuring 2.7 Hz
  ${result}  Dout Start PWM  ${SERIAL_HANDLE}  27
  Should be equal  ${result}  val 2.700000Hz status STATUS_OK
  # Check CANoe meas result
  # Wait for CANoe meas result, MeasDuration is set to 25s for ASSISTANCE_BUTTON_STS
  Sleep  26s
  ${result}  CANoe Get VTS Variable  ASSISTANCE_BUTTON_STS  PWMDC
  ${result}  Check PWMDC In Valid Range  ${result}  50
  Should Be Equal  ${result}  SUCCESS
  ${result}  CANoe Get VTS Variable  ASSISTANCE_BUTTON_STS  PWMFreq
  ${result}  Check PWMFreq In Valid Range  ${result}  2.7
  Should Be Equal  ${result}  SUCCESS
  ${result}  Dout Stop PWM  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK


  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS  1
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS value ACTIVE status STATUS_OK

  # Shortcut ASSISTANCE_BUTTON_STS and remove shortcut from output line before 3 secs since short cutting
  Flush Serial Input  ${SERIAL_HANDLE}
  Canoe Vt2516 Set Relay Gnd Active  ASSISTANCE_BUTTON_STS
  ${result}  Monitor Dout  ${SERIAL_HANDLE}
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS, value INACTIVE, status STATUS_SHORT_CIRCUIT

  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS  1
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS value ACTIVE status STATUS_SHORT_CIRCUIT

  Sleep  1.0s
  Canoe Vt2516 Set Relay Gnd Inactive  ASSISTANCE_BUTTON_STS

  Sleep  3.0s
  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_ASSISTANCE_BUTTON_STS  1
  Should be equal  ${result}  DOUT_ASSISTANCE_BUTTON_STS value ACTIVE status STATUS_OK

  ${result}  Dout Driver Close  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  BSP TestCase Teardown

#*************************************************************************************************
# DOUT_SET_TACHO_PULLUP
#*************************************************************************************************
DOUT tacho pullup select
  [Documentation]  Test the digital outputs driver capability to set the INFO_IF pullup.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case accoring to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  Sleep  0.5s

  ${result}  Dout Driver Open  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  # Check INFO IF
  ${info_if_ref}  CANoe Get VTS Variable  INFO_IF  Avg


  ${result}  Dout Tacho Pullup  ${SERIAL_HANDLE}  OFF
  Should be equal  ${result}  pullup OFF
  Sleep  0.5
  #Check INFO IF value, shall have deccreased
  ${info_if_off}  CANoe Get VTS Variable  INFO_IF  Avg
  ${result}  Check Info If After Pullup  ${info_if_ref}  ${info_if_off}  OFF
  Should Be Equal  ${result}  SUCCESS

  ${result}  Dout Tacho Pullup  ${SERIAL_HANDLE}  ON
  Should be equal  ${result}  pullup ON
  Sleep  0.5
  #Check INFO IF value, shall have increased
  ${result}  CANoe Get VTS Variable  INFO_IF  Avg
  ${result}  Check Info If After Pullup  ${info_if_off}  ${result}  ON
  Should Be Equal  ${result}  SUCCESS

  ${result}  Dout Driver Close  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  BSP TestCase Teardown

#*************************************************************************************************
# DOUT_MEASURE_FAULT_TIMINGS
#*************************************************************************************************
DOUT measure fault timings
  [Documentation]  Test the digital outputs driver capability to maintain hold period of at least
  ...              10ms between activation command and filtering, also it measures in case of a
  ...              fault condition (shortcut) the suspend time. DOUT_CTRL_UBAT_V_CTR must be
  ...              short circuit to GND.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  Sleep  0.5s

  ${result}  Dout Driver Open  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  # Short circuit DOUT_CTRL_UBAT_V_CTR to GND.
  Canoe Vt2516 Set Relay Gnd Active  D_OUT_CTRL_UBAT_V_CTR

  ${hold_time}  Dout Short Timing Hold  ${SERIAL_HANDLE}
  ${susp_time}  Dout Short Timing Susp  ${SERIAL_HANDLE}
  ${result}  Check Dout Hold Timing  ${hold_time}
  Should Be Equal  ${result}  SUCCESS
  ${result}  Check Dout Susp Timing  ${susp_time}
  Should Be Equal  ${result}  SUCCESS

  ${result}  Dout Driver Close  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  BSP TestCase Teardown

#*************************************************************************************************
# DOUT_MULTI_DOUT_1
#*************************************************************************************************
DOUT multi test DOUT_1
  [Documentation]  Test case for tesing multiple switching of D_OUT_1.
  ...              Priority:      1,
  ...              Level:         Component,
  ...              Type:          Functional,
  ...              Applicability: TGW2.0, TGW2.1
  # Tag test case according to:  BSP  req  req  req  ...
  [Tags]  TGW2.0  TGW2.1

  BSP TestCase Setup

  ${result}  Boot And Load  ${SERIAL_HANDLE}
  Should be equal  ${result}  BOOT_OSE_OK
  Sleep  0.5s

  # Open DOut driver
  ${result}  Dout Driver Open  ${SERIAL_HANDLE}
  Should be equal  ${result}  status STATUS_OK

  # Connect load to the outputs
  Canoe Vt2516 Set Relay Org Component Active  D_OUT_1

  :FOR  ${INDEX}  IN RANGE  0  30
  \  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_D_OUT1  1
  \  Should be equal  ${result}  DOUT_D_OUT1 value ACTIVE status STATUS_OK
  \  Sleep  0.5
  \  ${result}  Dout Set  ${SERIAL_HANDLE}  DOUT_D_OUT1  0
  \  Should be equal  ${result}  DOUT_D_OUT1 value INACTIVE status STATUS_OK
  \  Sleep  0.5

  # Disconnect load
  Canoe Vt2516 Set Relay Org Component Inactive  D_OUT_1

  BSP TestCase Teardown

#*************************************************************************************************
# END_OF_TEST_SUITE
#*************************************************************************************************
TestSuite End
  [Documentation]  Cleanup the test suite.
  [Tags]  TGW2.0  TGW2.1

  BSP TestSuite Teardown