#!/bin/sh
# Insert sibling-sadc lookup immediately before execv(SADC_PATH, args)
# in upstream sar.c. Used only from tools/sysstat/Dockerfile.
set -eu

file=${1:?sar.c path required}
inc=${2:?sadc-sibling.inc path required}

test -f "${file}"
test -f "${inc}"

n=$(grep -c 'execv(SADC_PATH, args);' "${file}" || true)
if [ "${n}" != 1 ]; then
	echo "ERROR: expected exactly one execv(SADC_PATH, args); in ${file}, got ${n}" >&2
	exit 1
fi

awk -v inc="${inc}" '
	/execv\(SADC_PATH, args\);/ && !ins {
		while ((getline line < inc) > 0)
			print line
		close(inc)
		ins = 1
	}
	{ print }
' "${file}" > "${file}.sibling"
mv "${file}.sibling" "${file}"

grep -q 'readlink("/proc/self/exe"' "${file}"
grep -q 'execv(SADC_PATH, args);' "${file}"
