	/* static-tools: before SADC_PATH and PATH, try the sadc next to this sar,
	 * but only if nobody who cannot already change sar can change it: a
	 * regular file with sar's owner, not setuid, setgid, or world-writable,
	 * and group-writable only if sar is writable by the same group (umask
	 * 002 gives both 0775). Otherwise anyone who can create files in sar's
	 * directory (say /tmp) could plant a sadc that root runs. The file is
	 * opened once, checked, and run from that descriptor, so it cannot be
	 * swapped in between. O_NONBLOCK keeps a planted FIFO from blocking the
	 * open; it has no effect on a regular file. /proc/self/exe is the sar
	 * that was exec'd, even when argv[0] is relative. If any check fails,
	 * fall through to the original execv/execvp. */
	{
		extern char **environ;
		char sib[4096];
		struct stat self_st, sib_st;
		ssize_t n = readlink("/proc/self/exe", sib, sizeof(sib));
		char *slash;
		int fd;

		if (n > 0 && (size_t)n < sizeof(sib) &&
		    stat("/proc/self/exe", &self_st) == 0) {
			sib[n] = '\0';
			slash = strrchr(sib, '/');
			if (slash && (size_t)(slash - sib) + 6 <= sizeof(sib)) {
				memcpy(slash + 1, "sadc", 5);
				fd = open(sib, O_RDONLY | O_NOFOLLOW | O_NONBLOCK |
					  O_CLOEXEC);
				if (fd >= 0) {
					if (fstat(fd, &sib_st) == 0 &&
					    S_ISREG(sib_st.st_mode) &&
					    sib_st.st_uid == self_st.st_uid &&
					    !(sib_st.st_mode &
					      (S_ISUID | S_ISGID | S_IWOTH)) &&
					    (!(sib_st.st_mode & S_IWGRP) ||
					     (sib_st.st_gid == self_st.st_gid &&
					      (self_st.st_mode & S_IWGRP))))
						fexecve(fd, args, environ);
					close(fd);
				}
			}
		}
	}
