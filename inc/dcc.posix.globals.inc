type
  TSocketHandle = Integer;
  //TInAddr = Posix.NetinetIn.in_addr;
  //PInAddr = Posix.NetinetIn.Pin_addr;
  //TSockAddr = Posix.SysSocket.sockaddr;
  //PSockAddr = Posix.SysSocket.Psockaddr;
  TFDSet = Posix.SysSelect.fd_set;
  PFDSet = Posix.SysSelect.Pfd_set;
  TTimeVal = Posix.SysTime.timeval;
  PTimeVal = Posix.SysTime.Ptimeval;

  SunB = record
    s_b1, s_b2, s_b3, s_b4: Byte;
  end;
  SunW = record
    s_w1, s_w2: Word;
  end;
  in_addr = record
    case integer of
      0: (S_un_b: SunB);
      1: (S_un_w: SunW);
      2: (S_addr: DWord);
  end;
  TInAddr = in_addr;
  PInAddr = ^TInAddr;
  sockaddr_in = record
    case Integer of
      0: (sin_family: Word;
          sin_port: Word;
          sin_addr: TInAddr;
          sin_zero: array[0..7] of Byte);
      1: (sa_family: Word;
          sa_data: array[0..13] of Byte)
  end;
  TSockAddrIn = sockaddr_in;
  PSockAddrIn = ^TSockAddrIn;
  PSockAddr = ^TSockAddr;
  TSockAddr = sockaddr_in;

const
  SOL_SOCKET = Posix.SysSocket.SOL_SOCKET;
  SO_ERROR = Posix.SysSocket.SO_ERROR;
  PF_INET = Posix.SysSocket.PF_INET;
  SOCK_STREAM = Posix.SysSocket.SOCK_STREAM;
  IPPROTO_IP = Posix.NetinetIn.IPPROTO_IP;
  SOCKET_ERROR = -1;
  EINPROGRESS = Posix.Errno.EINPROGRESS;
  EWOULDBLOCK = Posix.Errno.EWOULDBLOCK;
  ENOTSOCK = Posix.Errno.ENOTSOCK;
  SO_SNDBUF = Posix.SysSocket.SO_SNDBUF;
  SD_BOTH = Posix.SysSocket.SHUT_RDWR;
  FIONREAD = Linuxapi.KernelIoctl.FIONREAD;
  INADDR_ANY = Posix.NetinetIn.INADDR_ANY;
  SOMAXCONN = Posix.SysSocket.SOMAXCONN;
  INADDR_NONE = DWord(not 0);

const
  INVALID_SOCKET: TSocketHandle = TSocketHandle(-1);

