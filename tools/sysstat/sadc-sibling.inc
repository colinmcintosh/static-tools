	/* static-tools: try sadc next to this binary before SADC_PATH/PATH.
	 * /proc/self/exe is the sar we exec'd, even when argv[0] is relative.
	 * After this execv fails, fall through to the original execv/execvp. */
	{
		char sib[4096];
		ssize_t n = readlink("/proc/self/exe", sib, sizeof(sib) - 1);

		if (n > 0) {
			char *slash;

			sib[n] = '\0';
			slash = strrchr(sib, '/');
			if (slash && (size_t)(slash - sib) + 6 <= sizeof(sib)) {
				memcpy(slash + 1, "sadc", 5);
				execv(sib, args);
			}
		}
	}
