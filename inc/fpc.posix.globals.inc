type
  TSocketHandle = Integer;
  TInAddr = Sockets.in_addr;
  PInAddr = Sockets.pin_addr;
  TSockAddr = Sockets.sockaddr;
  PSockAddr = Sockets.Psockaddr;
  TFDSet = BaseUnix.TFDSet;
  PFDSet = BaseUnix.PFDSet;
  TTimeVal = BaseUnix.timeval;
  PTimeVal = BaseUnix.ptimeval;
  TSockAddrIn = Sockets.sockaddr_in;
  PSockAddrIn = Sockets.psockaddr_in;

const
  SOL_SOCKET = Sockets.SOL_SOCKET;
  SO_ERROR = Sockets.SO_ERROR;
  PF_INET = Sockets.PF_INET;
  SOCK_STREAM = Sockets.SOCK_STREAM;
  IPPROTO_IP = Sockets.IPPROTO_IP;
  SOCKET_ERROR = -1;
  EINPROGRESS = Sockets.EINPROGRESS;
  EWOULDBLOCK = Sockets.EWOULDBLOCK;
  ENOTSOCK = Sockets.ENOTSOCK;
  SO_SNDBUF = Sockets.SO_SNDBUF;
  SD_BOTH = Sockets.SHUT_RDWR;
  FIONREAD = termio.FIONREAD;
  INADDR_ANY = Sockets.INADDR_ANY;
  SOMAXCONN = Sockets.SOMAXCONN;
  INADDR_NONE = DWord(not 0);

const
  INVALID_SOCKET: TSocketHandle = TSocketHandle(-1);
