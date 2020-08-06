"""
    Run all tests for your branch. Expects a single parameter - source which is the full disk 
    path of your source files on disk. 

    Example:

    python static_test.py -src C:\gitrepogrecoe\test\static_analysis\code

    Run does tests in this order:

    *black
    pylint
    bandit
    mypy
    flake8

    *Output is only to command line to say what happened as it does cause side effects to files. Others dump 
    a log of what they found in ./test_outputs/
"""
import os
import sys
import argparse
import shutil
import json
import subprocess


"""
    Paths/files needed later
"""
expected_conda_environment = "StaticAnalysis"
root_folder = os.getcwd()
static_config_settings = os.path.join(root_folder, 'static_analysis.json')
output_folder = os.path.join(root_folder, 'test_outputs')
configuration_folder = os.path.join(root_folder, 'configuration')
tox_ini = os.path.join(configuration_folder, "tox.ini")
pylintrc = os.path.join(configuration_folder, '.pylintrc')


"""
    Constant raw commands for the different tools
"""
raw_pylint_call = 'pylint --rcfile "{}" "{}" > {}'
raw_bandit_call = 'bandit -r "{}" -x out/,packages/,pywin32/,scripts/,servicemock/,test/ -n 4 -s B110,B314,B404,B405,B406 > {}'
raw_mypy_call = 'mypy "{}" --ignore-missing-imports --no-strict-optional > {}'
raw_flake8_call = 'flake8 --output-file={} --statistics --config="{}" "{}"'
raw_black_call = "black --line-length 120 {}"

"""
    Helper functions 
"""
def create_outputs_directory():
    """
        Create the output folder, if it exists, clear it first 
        so we don't have a lot of history in the files. 
    """
    global output_folder
    if os.path.exists(output_folder):
        shutil.rmtree(output_folder)    
        
    os.makedirs(output_folder)

def load_configuration():
    """
        Attempts to load the static_analysis.json file if it exists. If there, it overrides
        the parameter input and MUST have at least the source_folder setting to identify where to 
        load up the source files for validation from. 
    """
    global static_config_settings
    return_object = None
    if os.path.exists(static_config_settings):
        with open(static_config_settings) as config:
            all_of_it = config.read()
            return_object = json.loads(all_of_it)

    return return_object
 
def check_conda_environment():
    global expected_conda_environment

    output = subprocess.check_output(["conda", 'env', 'list'])
    output = output.decode(sys.stdout.encoding)
    outputs = output.split(os.linesep)
    split_outputs = []
    for out in outputs:
        if out.startswith("#"):
            continue
        split_outputs.append( [x for x in out.split(' ') if len(x) > 0] )
        if len(split_outputs[-1]) == 0:
            split_outputs.pop(-1)

    for split in split_outputs:
        if len(split) == 3:
            if split[0] != expected_conda_environment:
                print("\nWARNING: Expected conda env {} not active, active env is {}\n".format(expected_conda_environment, split[0]))
            else:
                print("\nExpected conda environemnt {} is active.\n".format(expected_conda_environment))


"""
    Required arguments can come from either the static_analysis.json file or the command line. 
    
    The json file supercedes any command line setting provided by the user.
    
    Required values:
        json            cmdline     Meaning
        source_folder   -src        Source code location as full path
"""
source_code_location = None
conf = load_configuration()
if conf:
    source_code_location = conf['source_folder']
else:
    parser = argparse.ArgumentParser(description='Python static code enforcement!')
    parser.add_argument("-src", required=True, type=str, help="Your source code full disk path")
    programargs = parser.parse_args(sys.argv[1:])
    source_code_location = programargs.src


if not source_code_location or not os.path.exists(source_code_location):
    print("The path for your source code does not exist - ", source_code_location)
    raise Exception("Source code location missint")



"""
    Output files for each of the steps
"""
flake8_output_file = os.path.join(output_folder, 'flake8_output.txt')
pylint_output_file = os.path.join(output_folder, 'pylint_output.txt')
bandit_output_file = os.path.join(output_folder, 'bandit_output.txt')
mypy_output_file = os.path.join(output_folder, 'mypy_output.txt')


"""
    Format each of the commands to run
"""
pylint_call = raw_pylint_call.format(pylintrc, source_code_location, pylint_output_file)
bandit_call = raw_bandit_call.format(source_code_location, bandit_output_file)
mypy_call = raw_mypy_call.format(source_code_location, mypy_output_file)
flake8_call = raw_flake8_call.format(flake8_output_file, tox_ini, source_code_location)
black_call = raw_black_call.format(source_code_location)

all_calls = [black_call, pylint_call, bandit_call, mypy_call, flake8_call]


"""
    Create/clear the output directory then fun all tests. 
"""
check_conda_environment()
create_outputs_directory()

for test in all_calls:
    print("EXECUTION > ", test)
    os.system(test)
    print("FINISHED\n")
