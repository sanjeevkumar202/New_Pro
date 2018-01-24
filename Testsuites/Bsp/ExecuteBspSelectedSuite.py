"""
    This file is a copy of ExecuteBspSuite. The different is it contain one more testsuite name in execute_bsp_testsuite_for_tgw

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
curdir = os.path.curdir
os.sys.path.insert(0,curdir)
from Robot.Libs.Bsp.SetTestObject import *

def is_suite_to_be_executed(name, testSuites):
    if len(testSuites) == 0:
        return True
    else:
        for test_case in testSuites:
            if str(test_case) == name:
                return True

        return False

# **********************************************************
# This method will build the string used to call a testsuite
# **********************************************************
def run_testcase(testCase, testIdx, tgwPosition, dryRun, tgwVariables, testSuitesToExecute, testCasesToExecute):

    # Init local variables
    dryrun_txt = ""
    includeStr = ""
    excludeStr = ""
    testCaseStr = ""

    # Get variables from SetTestObject.py
    tgwHwVersion = tgwVariables.__getitem__("TGW_VERSION")
    robotInclude = tgwVariables.__getitem__("ROBOT_INCLUDE")
    robotExclude = tgwVariables.__getitem__("ROBOT_EXCLUDE")

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

    # Build Final string
    call_string   = "pybot" + dryrun_txt + includeStr + excludeStr + variable_file + testCaseStr + reports + " Robot/Testsuites/Bsp/" + testCase + ".robot"

    if is_suite_to_be_executed(testCase, testSuitesToExecute):
        print call_string
        os.system(call_string)
    else:
        print("TestSuite " + testCase + " skipped due to input parameters")

# **********************************************************
# Remove existing output dirs
# **********************************************************
def remove_output_directories(tgwPositions):

    print ("Removing all output directories")
    parent_dir = os.path.curdir

    for pos in tgwPositions:
        output_dir    = "testoutput_" + str(pos)
        if os.path.exists(output_dir):
            print ("Removing directory: " + output_dir)
            shutil.rmtree(output_dir)

    print ("DONE")

# **********************************************************
# Combine test results for all BSP test cases for one TGW in a single log file
# **********************************************************
def combine_testsuite_results(tgwPosition, tgwHwVersion, modem):
    # Combine all testsuites in one single output
    output_dir    = " testoutput_" + str(tgwPosition)
    call_string = "rebot -o " + output_dir + "/output.xml --log " + output_dir + "/log.html --report " + output_dir + "/report.html --name \"Testsuite results for TGW position " + str(tgwPosition) + \
                  " Tgw version " + str(tgwHwVersion) + " Modem " + str(modem) + "\" " + output_dir + "/*_output.xml"
    print call_string
    os.system(call_string)

# **********************************************************
# Combine test results for all BSP test suites in a single log file
# **********************************************************
def combine_tgw_results(tgwPositions):
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
def execute_bsp_testsuite_for_tgw(tgwPosition, dryRun, testSuites, testCases):

    tgwVariablesInstance = TestObjectVariables()
    tgwVariables = tgwVariablesInstance.get_variables(tgwPosition)

    # BspTestSetup will be executed first, it will erase the flash and
    # prepare the flash file system.
    run_testcase("BspTestSetup",       "01", tgwPosition, dryRun, tgwVariables, testSuites, testCases)

    # All testSuites
    run_testcase("BspPwrMgmt",         "03", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspGsm",             "04", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspDin",             "02", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspPowerFail",       "05", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspFlash",           "06", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspRtc",             "07", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspGps",             "08", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspDout",            "09", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspAin",             "10", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    # Disable BspFullRs232Serial and BspJ1708.
    # Add BspFullRs232Serial when DevTrack_11874 is fixed. Add BspJ1708 after updating the c test program.
    #run_testcase("BspFullRs232Serial", "11", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    #run_testcase("BspJ1708",           "12", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspInfoIf",          "13", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspCan",             "14", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspSecureSector",    "15", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspUsb",             "16", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspWlan",            "17", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspBootloader",      "18", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspPerf",            "19", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspMisc",            "20", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspFlashNoFS",       "21", tgwPosition, dryRun, tgwVariables, testSuites, testCases)
    run_testcase("BspGalaxy",          "22", tgwPosition, dryRun, tgwVariables, testSuites, testCases)

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

# ********************************
# Example: ExecuteBspSuite.py testObjects=[5] dryRun=true testsuites=['BspDin','BspTestSetup'] testcases=['DIN_Driver_Open_Close','TestSuite_Start']
# ********************************

for argv in sys.argv:
    input_param = argv.split('=')

    if len(input_param) == 2:
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

# Clean all previous output directories
remove_output_directories(testObjectPositions)

for pos in testObjectPositions:
    execute_bsp_testsuite_for_tgw(pos, dryRun, testSuites, testCases)

# Combine all test suites in a single log file
combine_tgw_results(testObjectPositions)





#
#
#
# def execute_bsp_testsuite_for_tgw(tgwPosition, dryRun, testCases, testSuites=None):
#     print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
#     print(testSuites)
#     testSuites="BspgalaxytestTwo"
#     print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
#     print(testSuites)
#     print("xxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
#     tgwVariablesInstance = TestObjectVariables()
#     tgwVariables = tgwVariablesInstance.get_variables(tgwPosition)
#
#     # BspTestSetup will be executed first, it will erase the flash and
#     # prepare the flash file system.
#     if not testSuites:
#         run_testcase("BspTestSetup",       "01", tgwPosition, dryRun, tgwVariables, testCases)
#         # All testcases
#         run_testcase("BspPwrMgmt",         "03", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspGsm",             "04", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspDin",             "02", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspPowerFail",       "05", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspFlash",           "06", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspRtc",             "07", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspGps",             "08", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspDout",            "09", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspAin",             "10", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspFullRs232Serial", "11", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspJ1708",           "12", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspInfoIf",          "13", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspCan",             "14", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspSecureSector",    "15", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspUsb",             "16", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspWlan",            "17", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspBootloader",      "18", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspPerf",            "19", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspMisc",            "20", tgwPosition, dryRun, tgwVariables, testCases)
#         run_testcase("BspFlashNoFS",       "21", tgwPosition, dryRun, tgwVariables, testCases)
#     else:
#         run_testcase(testSuites,   "01", tgwPosition, dryRun, tgwVariables, testCases)
