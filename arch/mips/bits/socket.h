struct msghdr
{
	void *msg_name;
	socklen_t msg_namelen;
	struct iovec *msg_iov;
	int msg_iovlen;
	void *msg_control;
	socklen_t msg_controllen;
	int msg_flags;
};

struct cmsghdr
{
	socklen_t cmsg_len;
	int cmsg_level;
	int cmsg_type;
};

#define SOCK_STREAM    2
#define SOCK_DGRAM     1

#define SOL_SOCKET     65535

#define SO_DEBUG        1
#define SO_REUSEADDR    4
#define SO_TYPE         0x1008
#define SO_ERROR        0x1007
#define SO_DONTROUTE    16
#define SO_BROADCAST    32
#define SO_SNDBUF       0x1001
#define SO_RCVBUF       0x1002
#define SO_KEEPALIVE    8
#define SO_OOBINLINE    256
#define SO_NO_CHECK     11
#define SO_PRIORITY     12
#define SO_LINGER       128
#define SO_BSDCOMPAT    14
#define SO_REUSEPORT    512
#define SO_PASSCRED     17
#define SO_PEERCRED     18
#define SO_RCVLOWAT     0x1004
#define SO_SNDLOWAT     0x1003
#define SO_RCVTIMEO     0x1006
#define SO_SNDTIMEO     0x1005
#define SO_SNDBUFFORCE  31
#define SO_RCVBUFFORCE  33
#define SO_ACCEPTCONN   0x1009
#define SO_PROTOCOL     0x1028
#define SO_DOMAIN       0x1029

#define SOCK_NONBLOCK     0200
#define SOCK_CLOEXEC  02000000
