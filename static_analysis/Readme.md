# Static Analysis

Static analysis is to be used to initial test you code before pushing it to the repository. This is simply to reduce churn on the intial submits to the repository. That is, each developer should run this locally against their own code and fix the issues before submitting them. 

Aside from the tests below, you should also be running the 'black' tool against the code. Working on adding that. 


<b>Example Usage</b>
This assumes:
1. I'm executing the static_test.py from the directory in which it lives. 
2. Source code to validate lives under the folder: C:\gitrepogrecoe\test\static_analysis\code

```
python static_test.py -src C:\gitrepogrecoe\test\static_analysis\code
```
<b>NOTE</b> Do not put parenthesis around the path

# Prerequisite
Create the conda environment that installs the needed toos:

```
conda env create -f environment.yml
```

Activate the environment

```
conda activate StaticAnalysis
```

Now you are ready to run the static_test.py file

# Tests Run
This section covers the tools that will be run against your code. All results are put in files named after the tool that created them in the /test_outputs directory. This directory is created for you upon execution. 

## flake8

Tool call
```
flake8 --output-file=...\test_outputs\flake8_output.txt --statistics --config="...\configuration\tox.ini" "YOUR_SOURCE"
```

Original call in CBPX build
```
python3 -m flake8 --output-file=flake8.txt --statistics --config="$SrcRoot/tox.ini" "$SrcRoot" 
```

## mypy

Tool call
```
mypy "YOUR_SOURCE" --ignore-missing-imports --no-strict-optional > ...\test_outputs\mypy_output.txt
```

Original call in CBPX build
```
python3 -m mypy "$SrcRoot" --ignore-missing-imports --no-strict-optional
```

## bandit

Tool call
```
bandit -r "YOUR_SOURCE" -x out/,packages/,pywin32/,scripts/,servicemock/,test/ -n 4 -s B110,B314,B404,B405,B406 > ...\test_outputs\bandit_output.txt
```

Original call in CBPX build
```
python3 -m bandit -r "$SrcRoot" -x out/,packages/,pywin32/,scripts/,servicemock/,test/ -n 4 -s B110,B314,B404,B405,B406 -f xml -o "$SrcRoot/bandit-test-linux.xml"
```

## pylint

Tool call
```
pylint --rcfile "...\configuration\.pylintrc" "YOUR_SOURCE" > ...\test_outputs\pylint_output.txt
```

Original call in CBPX build
```
python3 -m pylint --output-format=junit -j 0 --rcfile "${SrcRoot}/.pylintrc" "${SrcRoot}" || true >> "${SrcRoot}/pylint-test-linux.xml"
```



## black?
Not in build file

