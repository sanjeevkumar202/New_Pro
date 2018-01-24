


"""
    This python file is called from a jenkins job and executes the BSP Stress Test


    Changelog:
        2016-06-22 Mattias Lindahl
            Initial version

"""

import sys
import os
import shutil
curdir = os.path.curdir
os.sys.path.insert(0,curdir)
from Robot.Libs.Bsp.SetTestObject import *

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

def run_testcase(testSuiteParam): # [] testCase, testIdx, tgwPosition, dryRun, tgwVariables, testSuitesToExecute, testCasesToExecute, externalExcludes):
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
    testCaseStr = ""

    # Get variables from SetTestObject.py
    tgwVariables = testSuiteParam["tgwVariables"]
    tgwHwVersion = tgwVariables.__getitem__("TGW_VERSION")
    robotInclude = tgwVariables.__getitem__("ROBOT_INCLUDE")
    robotExclude = tgwVariables.__getitem__("ROBOT_EXCLUDE")

    output_dir    = " testoutput_" + str(testSuiteParam["tgwPosition"])
    report_name   = "t" + testSuiteParam["testIdx"] + "_" + testSuiteParam["testSuite"]
    reports       = " --NoStatusRC --output " + output_dir + "/" + report_name + "_output.xml --report " + output_dir + "/" + report_name + "_report.html --log " + output_dir + "/" + report_name + "_log.html"
    variable_file = ' --variablefile Robot/Libs/Bsp/SetTestObject.py:' + str(testSuiteParam["tgwPosition"]) + ":" + str(testSuiteParam["testDuration"])

    # Check if dryrun shall be used
    if (dryRun):
        dryrun_txt = " --dryrun "

    # Add any includes from SetTestObject.py
    if len(robotInclude) > 0:
        includeStr = " --include " + robotInclude

    # Check if there are any test cases specified to run
    if len(testSuiteParam["testCases"]) > 0:
        for testToExecute in testSuiteParam["testCases"]:
            testCaseStr = testCaseStr + " --test " + testToExecute

    # Add any excludes from SetTestObject.py
    if len(robotExclude) > 0:
        excludeLst = robotExclude.split(";")
        for exclude in excludeLst:
            excludeStr = excludeStr + " --exclude " + exclude

    if len(externalExcludes) > 0:
        for exclude in externalExcludes:
            excludeStr = excludeStr + " --exclude " + exclude

    # Build Final string
    call_string   = "pybot" + dryrun_txt + includeStr + excludeStr + variable_file + testCaseStr + reports + " Robot/Testsuites/Bsp/" + testSuiteParam["testSuite"] + ".robot"

    if is_suite_to_be_executed(testSuiteParam["testSuite"], testSuiteParam["testSuites"]):
        print call_string
        os.system(call_string)
    else:
        print("TestSuite " + testSuiteParam["testSuite"] + " skipped due to input parameters")

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

# **********************************************************
# Place all testsuites for one TGW here
# **********************************************************
def execute_bsp_testsuite_for_tgw(stressTestParam): #tgwPosition, dryRun, testSuites, testCases, externalExcludes):
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
    tgwVariables = tgwVariablesInstance.get_variables(stressTestParam["tgwPosition"])

    stressTestParam["tgwVariables"] = tgwVariables
    stressTestParam["testSuite"]    = "BspStressTest"
    stressTestParam["testIdx"]      = "01"

    run_testcase(stressTestParam)

    tgwHwVersion = tgwVariables.__getitem__("TGW_VERSION")
    tgwModem     = tgwVariables.__getitem__("TGW_MODEM")

    # Finally, combine all test cases in one log file
    combine_testsuite_results(stressTestParam["tgwPosition"], tgwHwVersion, tgwModem)

# **********************************************************
# Place all TGWs to be tested here
# **********************************************************

# ********************************
# Default settings
# ********************************
dryRun              = False
testObjectPositions = [1]
testCases           = []
testDuration        = 0.1
testSuites          = ['BspStressTest']
externalExcludes    = []

# ********************************
# Example: ExecuteStressTestSuite.py testObjects=[5] testDuration=1.5 dryRun=true testCases=['Boot Both TGWs And Check Serial Communication']
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

        elif (input_param[0].lower() == "testduration"):
            if (float(input_param[1]) > 0):
                print("Running Stress Test for: " + str(input_param[1])) + " hours"
                testDuration = float(input_param[1])

        elif (input_param[0].lower() == "testcases"):
            newTestCases = eval(input_param[1])
            if type(newTestCases) == type(testCases):
                print("Running testCase: " + str(input_param[1]))
                testCases = newTestCases

# Clean all previous output directories
remove_output_directories(testObjectPositions)

stressTestParam = {}

for pos in testObjectPositions:
    stressTestParam["tgwPosition"] =      pos
    stressTestParam["dryRun"] =           dryRun
    stressTestParam["testSuites"] =       testSuites
    stressTestParam["testCases"] =        testCases
    stressTestParam["externalExcludes"] = externalExcludes
    stressTestParam["testDuration"] =     testDuration

    execute_bsp_testsuite_for_tgw(stressTestParam)

# Combine all test suites in a single log file
combine_tgw_results(testObjectPositions)
