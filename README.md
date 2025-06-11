# San2Patch Benchmark (VulnLoc + San2Vuln)

A comprehensive security vulnerability benchmark based on the VulnLoc benchmark (added functionality test), extended with recent vulnerabilities and vulnerabilities without fixes (San2Vuln benchmark).

For a complete list of San2Vuln benchmarks, refer to [san2vuln.md](san2vuln.md).

## Usage

### Setup

#### Prebuilt Docker Image (Recommended)

We provide a prebuilt docker image for the benchmark.

```bash
docker pull acorn421/san2patch-benchmark:latest
docker run -it --name san2patch-benchmark acorn421/san2patch-benchmark:latest /bin/bash
```

#### Build Docker Image

```bash
docker build -t san2patch-benchmark:latest .
docker run -it --name san2patch-benchmark san2patch-benchmark:latest /bin/bash
```

### Test

#### Vulnerability Testing

```bash
# Test build (CVE-2016-10094, inside the container)
cd /san2patch-benchmark/libtiff/CVE-2016-10094/
bash config.sh
bash build.sh
bash test.sh 1.tif

# Check the result
cat /experiment/san2patch-benchmark/libtiff/CVE-2016-10094/src/tools/tiff2pdf.out
```

#### Functionality Testing

```bash
# Test build (CVE-2016-10094, inside the container)
cd /san2patch-benchmark/libtiff/CVE-2016-10094/
bash config_func.sh
bash build_func.sh
bash test_func.sh

# Check the result
echo "Functionality test result: $?"
```


**Note**: In the San2Patch, prebuilt docker image is run as containers to automatically perform compilation, vulnerability tests, and functionality tests.


## Functionality Testing

We have added functionality tests to each project in the VulnLoc benchmark using unit tests to ensure patch correctness:

### Test Scripts

- **`setup_func.sh`**: Sets up the repository for functionality tests
  - *Note*: If `setup_func.sh` and `setup.sh` are identical, this file does not exist. Instead, the repository configured in `setup.sh` is copied.
- **`config_func.sh`**: Configures the project with appropriate flags
- **`build_func.sh`**: Builds the binary containing the bug with required sanitizer instrumentation
- **`test_func.sh`**: Performs functionality tests based on unit tests
  - Compares unit tests passed before and after patch application
  - For projects without unit tests, `test_func.sh` always passes. Therefore, patches for these projects may require thorough manual verification.

### Test Process

The functionality testing process compares the list of unit tests that pass before applying a patch with those that pass after the patch is applied. This ensures that:
1. The patch fixes the intended vulnerability
2. The patch doesn't break existing functionality
3. All critical functionality remains intact

## Note

- The metadata (crash traces, vulnerability types) for San2Vuln datasets is currently being updated and may not be fully complete.
- We have deleted the vulnerabilities that cannot be reproduced in the original VulnLoc benchmark. (e.g. ffmpeg)
- We have removed scripts that are not used in san2patch (e.g. scripts for other tools).

---

# Original VulnLoc Benchmark Documentation

Security vulnerability benchmark with instrumentation support for repair tools.

## Usage

**NOTE:** Please ignore the two bugs in ffmpeg (bug id 9 and 10), since they could not be reproduced
easily.

To setup and test each of the bugs, first install the dependencies to projects in the benchmark.
`Dockerfile` contains the list of libraries to be installed. One can also use it to build a
docker image, and set up bugs in its container.

For each bug (e.g. `CVE-2016-9264`), the scripts for setting it up and building it are under
their corresponding directory:

- `setup.sh`: Set up source code version for that bug.
- `config.sh`: Configure the project with appropriate flags.
- `build.sh`: Build the binary which contains the bug, with the required sanitizer instrumentation.

Note that the scripts are assumed to run in some docker environment, where the project source code
is in some pre-defined directories (e.g. `/experiment`). Users can adjust the scripts to suit
their directory structure.

After building the binary, to reproduce each bug, run the binary against the provided exploit input.
Inputs can be found in `tests/` directory under each bug directory.
The exact command and exploit input to be used for each bug can be found in `meta-data.json` file.
In this file, for each bug, the command for bug reproduction is a combination of the `binary_path`, `crash_input`, and `exploit_file_list`.
`crash_input` specifies the command line argument to be suppied after the binary path, in which the special `$POC` string is to be replaced with path to the actual exploit input file.
For exploit input file, use any of the ones in `exploit_file_list`.

## Note

1. In `meta-data.json` file, the `build_command` entry is not intended to be used for reproducing the bug in a dynamic analysis setting.
Instead, `build_script` entry is for reproducing bugs with exploit input.
The `build_command` entry is just provided as a command to build the project, which is more commonly
used by static analysis tools.
