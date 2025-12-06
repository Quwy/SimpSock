type
  TSocketHandle = Winsock.TSocket;
  TInAddr = Sockets.TInAddr;
  PInAddr = Sockets.PInAddr;
  TSockAddr = Sockets.TSockAddr;
  PSockAddr = Sockets.PSockAddr;
  TFDSet = WinSock.TFDSet;
  PFDSet = WinSock.PFDSet;
  TTimeVal = WinSock.TTimeVal;
  PTimeVal = WinSock.PTimeVal;

const
  SOL_SOCKET = WinSock.SOL_SOCKET;
  SO_ERROR = WinSock.SO_ERROR;
  PF_INET = WinSock.PF_INET;
  SOCK_STREAM = WinSock.SOCK_STREAM;
  IPPROTO_IP = WinSock.IPPROTO_IP;
  SOCKET_ERROR = WinSock.SOCKET_ERROR;
  EINPROGRESS = WinSock.EINPROGRESS;
  EWOULDBLOCK = WinSock.WSAEWOULDBLOCK;
  ENOTSOCK = WinSock.WSAENOTSOCK;
  SO_SNDBUF = WinSock.SO_SNDBUF;
  SD_BOTH = 2;
  FIONREAD = WinSock.FIONREAD;
  INADDR_ANY = WinSock.INADDR_ANY;
  SOMAXCONN = WinSock.SOMAXCONN;
  INVALID_SOCKET = Winsock.INVALID_SOCKET;
  INADDR_NONE = WinSock.INADDR_NONE;
