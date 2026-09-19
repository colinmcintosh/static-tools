#!/bin/sh
# Insert sibling-sadc lookup immediately before execv(SADC_PATH, args)
# in upstream sar.c, and the <fcntl.h> it needs after <sys/stat.h>.
# Used only from tools/sysstat/Dockerfile.
set -eu

file=${1:?sar.c path required}
inc=${2:?sadc-sibling.inc path required}

test -f "${file}"
test -f "${inc}"

for anchor in 'execv(SADC_PATH, args);' '#include <sys/stat.h>'; do
	n=$(grep -cF "${anchor}" "${file}" || true)
	if [ "${n}" != 1 ]; then
		echo "ERROR: expected exactly one ${anchor} in ${file}, got ${n}" >&2
		exit 1
	fi
done

awk -v inc="${inc}" '
	/execv\(SADC_PATH, args\);/ && !ins {
		while ((getline line < inc) > 0)
			print line
		close(inc)
		ins = 1
	}
	{ print }
	/^#include <sys\/stat\.h>$/ { print "#include <fcntl.h>" }
' "${file}" > "${file}.sibling"
mv "${file}.sibling" "${file}"

grep -q 'fexecve(fd, args, environ);' "${file}"
grep -q '^#include <fcntl.h>$' "${file}"
grep -q 'execv(SADC_PATH, args);' "${file}"
