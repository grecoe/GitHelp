'''
    Run all tests for your branch. Expects a single parameter - source which is the full disk 
    path of your source files on disk. 

    Example:

    python static_test.py -src C:\gitrepogrecoe\test\static_analysis\code
'''
import os
import sys
import argparse


'''
    Program arguments
'''
parser = argparse.ArgumentParser(description='Python static code enforcement!')
parser.add_argument("-src", required=True, type=str, help="Your source code full disk path")
programargs = parser.parse_args(sys.argv[1:])

if not os.path.exists(programargs.src):
    print("The path for your source code does not exist - ", programargs.src)


'''
    Paths/files needed later
'''
root_folder = os.getcwd() #'.'

output_folder = os.path.join(root_folder, 'test_outputs')
configuration_folder = os.path.join(root_folder, 'configuration')
tox_ini = os.path.join(configuration_folder, "tox.ini")
pylintrc = os.path.join(configuration_folder, '.pylintrc')

source_code_location = programargs.src
#source_code_location = os.path.join(root_folder, 'code')

'''
    Raw commands for the different tools
'''
raw_pylint_call = 'pylint --rcfile "{}" "{}" > {}'
raw_bandit_call = 'bandit -r "{}" -x out/,packages/,pywin32/,scripts/,servicemock/,test/ -n 4 -s B110,B314,B404,B405,B406 > {}'
raw_mypy_call = 'mypy "{}" --ignore-missing-imports --no-strict-optional > {}'
raw_flake8_call = 'flake8 --output-file={} --statistics --config="{}" "{}"'

'''
    Output files
'''
flake8_output_file = os.path.join(output_folder, 'flake8_output.txt')
pylint_output_file = os.path.join(output_folder, 'pylint_output.txt')
bandit_output_file = os.path.join(output_folder, 'bandit_output.txt')
mypy_output_file = os.path.join(output_folder, 'mypy_output.txt')

'''
    Formatted commands for the different tools
'''
pylint_call = raw_pylint_call.format(pylintrc, source_code_location, pylint_output_file)
bandit_call = raw_bandit_call.format(source_code_location, bandit_output_file)
mypy_call = raw_mypy_call.format(source_code_location, mypy_output_file)
flake8_call = raw_flake8_call.format(flake8_output_file, tox_ini, source_code_location)

all_calls = [pylint_call, bandit_call, mypy_call, flake8_call]

def create_outputs_directory():
    global output_folder
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)



create_outputs_directory()

for test in all_calls:
    print("EXECUTION > ", test)
    os.system(test)
    print("FINISHED\n")
