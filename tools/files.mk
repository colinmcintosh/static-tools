# The files each tool ships: the one list the Makefiles, CI, and the release
# read (scripts reach it through `make print-tool-files`).
#
# A tool ships one static-PIE binary named after its tools/ directory unless
# FILES_<tool> lists something else. Names in DATA_FILES ship too, but they
# are not executables, so they skip the static-PIE check.

FILES_mtr := mtr mtr-packet
FILES_file := file magic.mgc
FILES_iproute2 := ip ss
FILES_sysstat := mpstat iostat pidstat sar sadc
FILES_libcap := getcap setcap
FILES_nmap := nmap nmap-services

DATA_FILES := magic.mgc nmap-services

# $(call tool_files,TOOL): the files TOOL ships.
tool_files = $(or $(FILES_$(1)),$(1))
