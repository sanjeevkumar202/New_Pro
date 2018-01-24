


"""
    This python file is called from a jenkins job and executes all the BSP robot
    files on all different TGW's in the test rig.
    This file can also be called manually to trigger test execution on one or more
    TGW's depending on the input.

    Example:
    ExecuteBspSuite.py
    This example will execute all robot scripts on all TGW's in the test rig

    Example: ExecuteBspSuite.py testObjects=[1,2] testsuites=['BspDin']
    This example will start the robot test BspDin on tge 1 and 2 in the test rig.

    Changelog:
        2015-07-01 Mattias Lindahl
            Initial version
        2015-08-03 Mattias Lindahl
            Combined all log files to a single log file
        2015-08-06 Mattias Lindahl
            Changed names of log files to get them in the correct order in the final log.
"""

import sys
import os
import shutil
import subprocess
import re
curdir = os.path.curdir
os.sys.path.insert(0,curdir)
from Robot.Libs.Bsp.SetTestObject import *

hitlist = {'python.exe': 1,
           'Logic.exe': 1,
           'CANoe32.exe': 1}

def kill_processes(hitlist):
        """
        Kill all processes in the hitlist map.
        Return the number of processes killed
        """
        processes = subprocess.Popen(["wmic", "process", "get", "ProcessId,Description,ExecutablePath"], bufsize=0, stdin=None, stdout=subprocess.PIPE)

        pattern = re.compile('(\S+ ?\S+) +(\S.*\S) +([0-9]+) *')
        line = "dummy"
        killcount = 0
        while (line):
            line = processes.stdout.readline()
            m = pattern.match(line)
            if (m):
                pid = m.group(3)
                descr = m.group(1)
                exePath = m.group(2)
                if (int(pid) == os.getpid()):
                    print('skipping ' + descr + ' with pid ' + pid)
                    continue
                if (descr in hitlist):
                    killcount += 1
                    print('killing ' + descr + ' with pid ' + pid)
                    subprocess.call(['taskkill', '/F', '/PID', pid], bufsize=0, stdout=sys.stdout, stderr=sys.stderr)
        return killcount

def is_suite_to_be_executed(name, testSuites):
    """
        This method checks if the test suite shall be executed or not,
        depending on input to the call to this file
        Arguments:
            name       - The name of the test suite to check.
            testSuites - The test suites that shall be executed
    """
    if len(testSuites) == 0:
        return True
    else:
        for test_case in testSuites:
            if str(test_case) == name:
                return True

        return False

def run_testcase(testCase, testIdx, tgwPosition, dryRun, tgwVariables, testSuitesToExecute, testCasesToExecute, externalExcludes):
    """
        This method will build the string used to call a robot test suite via a pybot command
        Arguments:
            testCase            - Name of th etest suite to execute
            testIdx             - Index used for sorting result
            tgwPosition         - TGW position in the test rig for the TGW to be executed.
            dryRun              - If dryrun, then only the robot and the python interface will be tested.
                                  No real testing in that case, used for debugging.
            tgwVariables        - TGW settings for the TGW to be executed, set in SetTestObject.py.
            testSuitesToExecute - Test suites to be executed.
            testCasesToExecute  - Test cases to be executed.
    """
    # Init local variables
    dryrun_txt = ""
    includeStr = ""
    excludeStr = ""
    incExcStr  = ""
    testCaseStr = ""

    # Get variables from SetTestObject.py
    tgwBoxPosition = tgwVariables.__getitem__("TGW_BOX_POS")
    tgwHwVersion   = tgwVariables.__getitem__("TGW_VERSION")
    robotInclude   = tgwVariables.__getitem__("ROBOT_INCLUDE")
    robotExclude   = tgwVariables.__getitem__("ROBOT_EXCLUDE")

    output_dir    = " testoutput_" + str(tgwPosition)
    report_name   = "t" + testIdx + "_" + testCase
    reports       = " --NoStatusRC --output " + output_dir + "/" + report_name + "_output.xml --report " + output_dir + "/" + report_name + "_report.html --log " + output_dir + "/" + report_name + "_log.html"
    variable_file = " --variablefile Robot/Libs/Bsp/SetTestObject.py:" + str(tgwPosition)

    # Check if dryrun shall be used
    if (dryRun):
        dryrun_txt = " --dryrun "

    # Add any includes from SetTestObject.py
    if len(robotInclude) > 0:
        includeStr = " --include " + robotInclude

    # Check if there are any test cases specified to run
    if len(testCasesToExecute) > 0:
        for testToExecute in testCasesToExecute:
            testCaseStr = testCaseStr + " --test " + testToExecute

    # Add any excludes from SetTestObject.py
    if len(robotExclude) > 0:
        excludeLst = robotExclude.split(";")
        for exclude in excludeLst:
            excludeStr = excludeStr + " --exclude " + exclude

    if len(externalExcludes) > 0:
        for exclude in externalExcludes:
            excludeStr = excludeStr + " --exclude " + exclude

    # Check if an extra include exclude file exists and use content if so.
    path = os.getcwd()
    file_name = "extra_exclude_include_for_tgw_in_pos_" + str(tgwBoxPosition) + ".txt"
    file_name = file_name.lower()
    path_and_file_name = path + "\\" + file_name
    if os.path.isfile(path_and_file_name):
        fp = open(path_and_file_name, 'r')
        incExcStr = " " + fp.read(50)
        fp.close()
    else:
        incExcStr = ""

    # Kill processes
    killed = kill_processes(hitlist)
    if killed > 0:
        print "Killed " + str(killed) + " processes.\n"

    # Build Final string
    call_string   = "pybot --pythonpath " + path + " " + dryrun_txt + includeStr + incExcStr + excludeStr + variable_file + testCaseStr + reports + " Robot/Testsuites/Bsp/" + testCase + ".robot"

    if is_suite_to_be_executed(testCase, testSuitesToExecute):
        print call_string
        os.system(call_string)
    else:
        print("TestSuite " + testCase + " skipped due to input parameters")

def remove_output_directories(tgwPositions):
    """
        This method will remove output directories. Used for cleaning old tests when starting a new test.
        Arguments:
            tgwPositions - TGW's to be executed.

    """
    print ("Removing all output directories")
    parent_dir = os.path.curdir

    for pos in tgwPositions:
        output_dir    = "testoutput_" + str(pos)
        if os.path.exists(output_dir):
            print ("Removing directory: " + output_dir)
            shutil.rmtree(output_dir)

    print ("DONE")

def combine_testsuite_results(tgwPosition, tgwHwVersion, modem):
    """
        This method will combine test results for all BSP test cases for one TGW in a single log file.
        Arguments:
            tgwPositions - TGW's to be executed.
            tgwHwVersion - TGW HW vesrion, set in SetTestObject.py.
            modem        - Modem used in the TGW, set in SetTestObject.py.
    """
    # Combine all testsuites in one single output
    output_dir    = " testoutput_" + str(tgwPosition)
    call_string = "rebot -o " + output_dir + "/output.xml --log " + output_dir + "/log.html --report " + output_dir + "/report.html --name \"Testsuite results for TGW position " + str(tgwPosition) + \
                  " Tgw version " + str(tgwHwVersion) + " Modem " + str(modem) + "\" " + output_dir + "/*_output.xml"
    print call_string
    os.system(call_string)

def combine_tgw_results(tgwPositions):
    """
        This method will combine test results for all BSP test suites in a single log file
        Arguments:
            tgwPositions - TGW's to be executed.
    """
    xml_files = ""

    for tgw_position in tgwPositions:
        output_dir    = " testoutput_" + str(tgw_position)
        xml_files = xml_files + output_dir + "/output.xml "

    call_string = "rebot -o output.xml --log log.html --report report.html --name \"Testsuite results for all TGW positions\" " + xml_files
    print call_string
    os.system(call_string)

def remove_extra_include_exclude_file(tgwPosition):
    path = os.getcwd()
    file_name = "extra_exclude_include_for_tgw_in_pos_" + str(tgwPosition) + ".txt"
    file_name = file_name.lower()
    path_and_file_name = path + "\\" + file_name
    if os.path.isfile(path_and_file_name):
        os.remove(path_and_file_name)

# **********************************************************
# Place all testsuites for one TGW here
# **********************************************************
def execute_bsp_testsuite_for_tgw(tgwPosition, dryRun, testSuites, testCases, externalExcludes):
    """
        This method execute all test cases on the TGW at the requested tgwPosition.
        Arguments:
            tgwPosition  - TGW position in the test rig for the TGW to be executed.
            dryRun       - If dryrun, then only the robot and the python interface will be tested.
                                  No real testing in that case, used for debugging.
            testSuites   - Test suites to be executed.
            testCases    - Test cases to be executed.
    """
    tgwVariablesInstance = TestObjectVariables()
    tgwVariables = tgwVariablesInstance.get_variables(tgwPosition)

    # BspTestSetup will be executed first, it will erase the flash and
    # prepare the flash file system.
    run_testcase("BspTestSetup",       "01", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)

    # All testSuites
    run_testcase("BspGsm",             "04", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspDin",             "02", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspPowerFail",       "05", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspPwrMgmt",         "03", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspFlash",           "06", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspRtc",             "07", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspGps",             "08", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspDout",            "09", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspAin",             "10", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    # Disable BspFullRs232Serial and BspJ1708.
    # Add BspFullRs232Serial when DevTrack_11874 is fixed. Add BspJ1708 after updating the c test program.
    #run_testcase("BspFullRs232Serial", "11", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    #run_testcase("BspJ1708",           "12", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspInfoIf",          "13", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspCan",             "14", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspSecureSector",    "15", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspUsb",             "16", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspWlan",            "17", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspBootloader",      "18", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspPerf",            "19", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspMisc",            "20", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspFlashNoFS",       "21", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspLowLevel",        "22", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)
    run_testcase("BspWifi",            "23", tgwPosition, dryRun, tgwVariables, testSuites, testCases, externalExcludes)

    tgwHwVersion = tgwVariables.__getitem__("TGW_VERSION")
    tgwModem     = tgwVariables.__getitem__("TGW_MODEM")

    # Finally, combine all test cases in one log file
    combine_testsuite_results(tgwPosition, tgwHwVersion, tgwModem)

# **********************************************************
# Place all TGWs to be tested here
# **********************************************************

# ********************************
# Default settings
# ********************************
dryRun              = False
testObjectPositions = [1, 2, 3, 4, 5, 6]
testCases           = []
testSuites          = []
externalExcludes    = []

# ********************************
# Example: ExecuteBspSuite.py testObjects=[5] dryRun=true testsuites=['BspDin','BspTestSetup'] testcases=['DIN_Driver_Open_Close','TestSuite_Start']
# ********************************

for argv in sys.argv:
    input_param = argv.split('=')

    if len(input_param) == 2:
        if (input_param[0].lower() == "exclude"):
            externalExcludes = eval(input_param[1])
            print("Setting externalExcludes to: " + str(input_param[1]))

        if (input_param[0].lower() == "testobjects"):
            newObjectPosition = eval(input_param[1])
            if type(newObjectPosition) == type(testObjectPositions):
                print("New Test Objects: " + str(newObjectPosition))
                testObjectPositions = newObjectPosition

        elif (input_param[0].lower() == "dryrun"):
            if (input_param[1].lower() == "true"):
                print("Setting dryRun to: " + str(input_param[1]))
                dryRun = True

        elif (input_param[0].lower() == "testsuites"):
            newTestSuites = eval(input_param[1])
            if type(newTestSuites) == type(testSuites):
                print("Running testSuite: " + str(input_param[1]))
                testSuites = newTestSuites

        elif (input_param[0].lower() == "testcases"):
            newTestCases = eval(input_param[1])
            if type(newTestCases) == type(testCases):
                print("Running testCase: " + str(input_param[1]))
                testCases = newTestCases

# Kill processes
killed = kill_processes(hitlist)
if killed > 0:
    print "Killed " + str(killed) + " processes.\n"

# Clean all previous output directories
remove_output_directories(testObjectPositions)

for pos in testObjectPositions:
    remove_extra_include_exclude_file(pos)
    execute_bsp_testsuite_for_tgw(pos, dryRun, testSuites, testCases, externalExcludes)

# Combine all test suites in a single log file
combine_tgw_results(testObjectPositions)
