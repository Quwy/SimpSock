var
  LocalErrno: Integer = Low(Integer);

function sSocket(const af, Struct, protocol: Integer): TSocketHandle;
begin
  Result := Posix.SysSocket.socket(af, Struct, protocol);
end;

function sCloseSocket(const s: TSocketHandle): Integer;
begin
  Result := Posix.Unistd.__close(s);
end;

function sConnect(const s: TSocketHandle; var name: TSockAddr; const namelen: Integer): Integer;
begin
  Result := Posix.SysSocket.connect(s, Posix.SysSocket.sockaddr(name), namelen);
end;

function sIOCtl(const s: TSocketHandle; const cmd: DWord; var arg: Integer): Integer;
begin
  Result := Posix.StrOpts.ioctl(s, cmd, arg);
end;

function sBind(const s: TSocketHandle; var addr: TSockAddr; const namelen: Integer): Integer;
begin
  Result := Posix.SysSocket.bind(s, Posix.SysSocket.sockaddr(addr), namelen);
end;

function sAccept(const s: TSocketHandle; const addr: PSockAddr; const addrlen: PInteger): TSocketHandle;
begin
  Result := Posix.SysSocket.accept(s, Posix.SysSocket.Psockaddr(addr)^, psocklen_t(addrlen)^);
end;

function sGetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; var optlen: Integer): Integer;
begin
  Result := Posix.SysSocket.getsockopt(s, level, optname, optval^, socklen_t(optlen));
end;

function sSetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; const optlen: Integer): Integer;
begin
  Result := Posix.SysSocket.setsockopt(s, level, optname, optval, optlen);
end;

function sListen(const s: TSocketHandle; const backlog: Integer): Integer;
begin
  Result := Posix.SysSocket.listen(s, backlog);
end;

function sRecv(const s: TSocketHandle; var Buf; const len, flags: Integer): Integer;
begin
  Result := Posix.SysSocket.recv(s, Buf, len, flags);
end;

function sSelect(const nfds: Integer; const readfds, writefds, exceptfds: PFDSet; const timeout: PTimeVal): Longint;
begin
  Result := Posix.SysSelect.select(nfds, readfds, writefds, exceptfds, timeout);
end;

function sSend(const s: TSocketHandle; const Buf; const len, flags: Integer): Integer;
begin
  Result := Posix.SysSocket.send(s, Buf, len, flags);
end;

function sShutdown(const s: TSocketHandle; const how: Integer): Integer;
begin
  Result := Posix.SysSocket.shutdown(s, how);
end;

function sGetHostByName(const Name: string): TInAddr;
var
  Hint: addrinfo;
  HostInfo: Paddrinfo;
  M: TMarshaller;
begin
  FillChar(Result, SizeOf(Result), 0);
  if Name <> '' then
    begin
      FillChar(Hint, SizeOf(Hint), 0);
      Hint.ai_family := AF_INET;
      {$IFDEF LINUX}
      {$WARN SYMBOL_PLATFORM OFF}
      Hint.ai_flags := AI_IDN;
      {$WARN SYMBOL_PLATFORM ON}
      {$ENDIF}
      Hint.ai_socktype := SOCK_STREAM;
      HostInfo := nil;
      if (Posix.NetDB.getaddrinfo(M.AsUTF8(Name).ToPointer, nil, Hint, HostInfo) = 0) and Assigned(HostInfo) then
        begin
          Result := PSockAddrIn(HostInfo^.ai_addr)^.sin_addr;
          Posix.NetDB.freeaddrinfo(HostInfo^);
        end;
    end;
end;

function sHtons(const hostshort: Word): Word;
begin
  Result := Posix.ArpaInet.htons(hostshort);
end;

function sInet_addr(const cp: MarshaledAString): DWORD;
begin
  Result := Posix.ArpaInet.inet_addr(cp);
end;

function sGetLastError: Integer;
begin
  if LocalErrno <> Low(Integer) then
    begin
      Result := LocalErrno;
      LocalErrno := Low(Integer);
    end
  else
    Result := Posix.Errno.errno;
end;

procedure sSetLastError(const Error: Integer);
begin
  LocalErrno := Error;
end;

function sSetNonBlockMode(const Socket: TSocketHandle): Integer;
var
  Flags: Integer;
begin
  Flags := Posix.Fcntl.fcntl(Socket, Posix.Fcntl.F_GETFL, 0);
  if Flags = -1 then
    Result := Flags
  else
    begin
      Flags := Flags or Posix.Fcntl.O_NONBLOCK;
      Result := Posix.Fcntl.fcntl(Socket, Posix.Fcntl.F_SETFL, Flags);
    end
end;

procedure sFD_CLR(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  Posix.SysSelect.FD_CLR(Socket, FDSet);
end;

function sFD_ISSET(Socket: TSocketHandle; var FDSet: TFDSet): Boolean;
begin
  Result := Posix.SysSelect.FD_ISSET(Socket, FDSet);
end;

procedure sFD_SET(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  Posix.SysSelect._FD_SET(Socket, FDSet);
end;

procedure sFD_ZERO(var FDSet: TFDSet);
begin
  Posix.SysSelect.FD_ZERO(FDSet);
end;

