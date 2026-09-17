#include <arpa/inet.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define DEFAULT_PORT 15353
#define DNS_HEADER_SIZE 12
#define MAX_PACKET_SIZE 512

static const uint8_t expected_question[] = {
	7, 'f', 'i', 'x', 't', 'u', 'r', 'e',
	4, 't', 'e', 's', 't',
	0,
	0, 1,
	0, 1,
};

static const uint8_t answer[] = {
	0xc0, 0x0c,
	0x00, 0x01,
	0x00, 0x01,
	0x00, 0x00, 0x00, 0x3c,
	0x00, 0x04,
	192, 0, 2, 1,
};

static void fail(const char *message)
{
	perror(message);
	exit(EXIT_FAILURE);
}

int main(int argc, char **argv)
{
	struct sockaddr_in address = {
		.sin_family = AF_INET,
		.sin_port = htons(DEFAULT_PORT),
		.sin_addr.s_addr = htonl(INADDR_LOOPBACK),
	};
	uint8_t query[MAX_PACKET_SIZE];
	uint8_t response[MAX_PACKET_SIZE];
	int socket_fd;
	int reuse = 1;

	if (argc > 2) {
		fprintf(stderr, "usage: %s [port]\n", argv[0]);
		return EXIT_FAILURE;
	}
	if (argc == 2) {
		char *end = NULL;
		long port = strtol(argv[1], &end, 10);

		if (*argv[1] == '\0' || *end != '\0' || port < 1 || port > 65535) {
			fprintf(stderr, "invalid port: %s\n", argv[1]);
			return EXIT_FAILURE;
		}
		address.sin_port = htons((uint16_t)port);
	}

	socket_fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (socket_fd == -1) {
		fail("socket");
	}
	if (setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse)) == -1) {
		fail("setsockopt");
	}
	if (bind(socket_fd, (struct sockaddr *)&address, sizeof(address)) == -1) {
		fail("bind");
	}

	puts("READY");
	fflush(stdout);

	for (;;) {
		struct sockaddr_in client;
		socklen_t client_length = sizeof(client);
		ssize_t query_length = recvfrom(
			socket_fd,
			query,
			sizeof(query),
			0,
			(struct sockaddr *)&client,
			&client_length
		);
		size_t response_length;

		if (query_length == -1) {
			if (errno == EINTR) {
				continue;
			}
			fail("recvfrom");
		}
		if ((size_t)query_length < DNS_HEADER_SIZE + sizeof(expected_question) ||
		    memcmp(query + DNS_HEADER_SIZE, expected_question, sizeof(expected_question)) != 0 ||
		    query[4] != 0 || query[5] != 1) {
			fprintf(stderr, "ignored unexpected DNS query\n");
			continue;
		}

		response_length = DNS_HEADER_SIZE + sizeof(expected_question) + sizeof(answer);
		memcpy(response, query, DNS_HEADER_SIZE + sizeof(expected_question));
		response[2] = (uint8_t)(0x84 | (query[2] & 0x01));
		response[3] = 0x00;
		response[6] = 0x00;
		response[7] = 0x01;
		response[8] = 0x00;
		response[9] = 0x00;
		response[10] = 0x00;
		response[11] = 0x00;
		memcpy(
			response + DNS_HEADER_SIZE + sizeof(expected_question),
			answer,
			sizeof(answer)
		);

		if (sendto(
			    socket_fd,
			    response,
			    response_length,
			    0,
			    (struct sockaddr *)&client,
			    client_length
		    ) == -1) {
			fail("sendto");
		}
	}
}
