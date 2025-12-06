type
  TSocketHandle = WinApi.WinSock.TSocket;
  TInAddr = WinApi.WinSock.TInAddr;
  PInAddr = WinApi.WinSock.PInAddr;
  TSockAddr = WinApi.WinSock.TSockAddr;
  PSockAddr = WinApi.WinSock.PSockAddr;
  TFDSet = WinApi.WinSock.TFDSet;
  PFDSet = WinApi.WinSock.PFDSet;
  TTimeVal = WinApi.WinSock.TTimeVal;
  PTimeVal = WinApi.WinSock.PTimeVal;

const
  SOL_SOCKET = WinApi.WinSock.SOL_SOCKET;
  SO_ERROR = WinApi.WinSock.SO_ERROR;
  PF_INET = WinApi.WinSock.PF_INET;
  SOCK_STREAM = WinApi.WinSock.SOCK_STREAM;
  IPPROTO_IP = WinApi.WinSock.IPPROTO_IP;
  SOCKET_ERROR = WinApi.WinSock.SOCKET_ERROR;
  EINPROGRESS = WinApi.WinSock.EINPROGRESS;
  EWOULDBLOCK = WinApi.WinSock.WSAEWOULDBLOCK;
  ENOTSOCK = WinApi.WinSock.WSAENOTSOCK;
  SO_SNDBUF = WinApi.WinSock.SO_SNDBUF;
  SD_BOTH = WinApi.WinSock.SD_BOTH;
  FIONREAD = WinApi.WinSock.FIONREAD;
  INADDR_ANY = WinApi.WinSock.INADDR_ANY;
  SOMAXCONN = WinApi.WinSock.SOMAXCONN;
  INVALID_SOCKET = WinApi.WinSock.INVALID_SOCKET;
  INADDR_NONE = WinApi.WinSock.INADDR_NONE;
