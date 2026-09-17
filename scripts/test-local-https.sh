#!/bin/sh
set -eu

client=$1
client_bin=$2
openssl_bin=$3
port=${4:-18443}

cert=/tmp/static-tools-test-cert.pem
key=/tmp/static-tools-test-key.pem
server_log=/tmp/static-tools-test-https.log
server_pid=

cleanup() {
	if [ -n "${server_pid}" ]; then
		kill "${server_pid}" 2>/dev/null || true
		wait "${server_pid}" 2>/dev/null || true
	fi
}
trap cleanup EXIT INT TERM

"${openssl_bin}" req -x509 -newkey rsa:2048 -nodes \
	-keyout "${key}" \
	-out "${cert}" \
	-days 1 \
	-subj /CN=127.0.0.1 \
	-addext subjectAltName=IP:127.0.0.1 \
	>/dev/null 2>&1

"${openssl_bin}" s_server \
	-accept "127.0.0.1:${port}" \
	-cert "${cert}" \
	-key "${key}" \
	-www \
	>"${server_log}" 2>&1 &
server_pid=$!

ready=false
attempt=0
while [ "${attempt}" -lt 20 ]; do
	if "${openssl_bin}" s_client \
		-connect "127.0.0.1:${port}" \
		-CAfile "${cert}" \
		-verify_return_error \
		</dev/null >/dev/null 2>&1; then
		ready=true
		break
	fi
	attempt=$((attempt + 1))
	sleep 0.1
done

if [ "${ready}" != true ]; then
	echo "HTTPS test server did not become ready" >&2
	cat "${server_log}" >&2
	exit 1
fi

url="https://127.0.0.1:${port}/"
case "${client}" in
	curl)
		status=$("${client_bin}" \
			--cacert "${cert}" \
			--max-time 5 \
			--silent \
			--output /dev/null \
			--write-out '%{http_code}' \
			"${url}")
		test "${status}" = 200
		;;
	wget)
		if ! output=$("${client_bin}" \
			--ca-certificate="${cert}" \
			--output-document=/dev/null \
			--timeout=5 \
			--tries=1 \
			"${url}" 2>&1); then
			echo "${output}" >&2
			cat "${server_log}" >&2
			exit 1
		fi
		;;
	*)
		echo "unsupported HTTPS test client: ${client}" >&2
		exit 2
		;;
esac
