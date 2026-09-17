#!/bin/sh
set -eu

client=$1
client_bin=$2
server_bin=$3
port=${4:-15353}

server_log=/tmp/static-tools-test-dns.log
server_pid=

cleanup() {
	if [ -n "${server_pid}" ]; then
		kill "${server_pid}" 2>/dev/null || true
		wait "${server_pid}" 2>/dev/null || true
	fi
}
trap cleanup EXIT INT TERM

: >"${server_log}"
"${server_bin}" "${port}" >"${server_log}" 2>&1 &
server_pid=$!

ready=false
attempt=0
while [ "${attempt}" -lt 20 ]; do
	if grep -q '^READY$' "${server_log}" && kill -0 "${server_pid}" 2>/dev/null; then
		ready=true
		break
	fi
	attempt=$((attempt + 1))
	sleep 0.1
done

if [ "${ready}" != true ]; then
	echo "DNS test server did not become ready" >&2
	cat "${server_log}" >&2
	exit 1
fi

case "${client}" in
	dig)
		if ! output=$(timeout 5 "${client_bin}" \
			"@127.0.0.1" \
			-p "${port}" \
			fixture.test \
			A \
			+short 2>&1); then
			echo "${output}" >&2
			cat "${server_log}" >&2
			exit 1
		fi
		printf '%s\n' "${output}" | grep -qx '192\.0\.2\.1'
		;;
	drill)
		if ! output=$(timeout 5 "${client_bin}" \
			-p "${port}" \
			"@127.0.0.1" \
			fixture.test \
			A 2>&1); then
			echo "${output}" >&2
			cat "${server_log}" >&2
			exit 1
		fi
		printf '%s\n' "${output}" | grep -q 'ANSWER SECTION'
		printf '%s\n' "${output}" | grep -q '192\.0\.2\.1'
		;;
	*)
		echo "unsupported DNS test client: ${client}" >&2
		exit 2
		;;
esac
