function sSocket(const af, Struct, protocol: Integer): TSocketHandle;
begin
  Result := Sockets.fpSocket(af, Struct, protocol);
end;

function sCloseSocket(const s: TSocketHandle): Integer;
begin
  Result := Sockets.CloseSocket(s);
end;

function sConnect(const s: TSocketHandle; var name: TSockAddr; const namelen: Integer): Integer;
begin
  Result := Sockets.fpconnect(s, @name, namelen);
end;

function sIOCtl(const s: TSocketHandle; const cmd: DWORD; var arg: Integer): Integer;
begin
  Result := WinSock.ioctlsocket(s, cmd, arg);
end;

function sBind(const s: TSocketHandle; var addr: TSockAddr; const namelen: Integer): Integer;
begin
  Result := Sockets.fpbind(s, PSockAddr(@addr), namelen);
end;

function sAccept(const s: TSocketHandle; const addr: PSockAddr; const addrlen: PInteger): TSocketHandle;
begin
  Result := Sockets.fpaccept(s, addr, addrlen);
end;

function sGetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; var optlen: Integer): Integer;
begin
  Result := Sockets.fpgetsockopt(s, level, optname, optval, psocklen(@optlen));
end;

function sSetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; const optlen: Integer): Integer;
begin
  Result := Sockets.fpsetsockopt(s, level, optname, optval, optlen);
end;

function sListen(const s: TSocketHandle; const backlog: Integer): Integer;
begin
  Result := Sockets.fplisten(s, backlog);
end;

function sRecv(const s: TSocketHandle; var Buf; const len, flags: Integer): Integer;
begin
  Result := Sockets.fprecv(s, @Buf, len, flags);
end;

function sSelect(const nfds: Integer; const readfds, writefds, exceptfds: PFDSet; const timeout: PTimeVal): Longint;
begin
  Result := WinSock.select(nfds, readfds, writefds, exceptfds, timeout);
end;

function sSend(const s: TSocketHandle; const Buf; const len, flags: Integer): Integer;
begin
  Result := Sockets.fpsend(s, @Buf, len, flags);
end;

function sShutdown(const s: TSocketHandle; const how: Integer): Integer;
begin
  Result := Sockets.fpshutdown(s, how);
end;

function sGetHostByName(const Name: string): TInAddr;
var
  HostEnt: WinSock.PHostEnt;
begin
  HostEnt := WinSock.gethostbyname(PAnsiChar(Name));
  if Assigned(HostEnt) then
    begin
      Result.s_bytes[1] := Byte(HostEnt^.h_addr^[0]);
      Result.s_bytes[2] := Byte(HostEnt^.h_addr^[1]);
      Result.s_bytes[3] := Byte(HostEnt^.h_addr^[2]);
      Result.s_bytes[4] := Byte(HostEnt^.h_addr^[3]);
    end
  else
    Result.s_addr := 0;
end;

function sHtons(const hostshort: Word): Word;
begin
  Result := Sockets.htons(hostshort);
end;

function sInet_addr(const cp: MarshaledAString): DWord;
begin
  Result := WinSock.inet_addr(cp);
end;

function sGetLastError: Integer;
begin
  Result := WSAGetLastError;
end;

procedure sSetLastError(const Error: Integer);
begin
  WSASetLastError(Error);
end;

function sSetNonBlockMode(const Socket: TSocketHandle): Integer;
var
  Mode: Integer;
begin
  Mode := 1;
  Result := WinSock.ioctlsocket(Socket, LongInt(WinSock.FIONBIO), Mode);
end;

procedure sFD_CLR(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  WinSock.FD_CLR(Socket, FDSet);
end;

function sFD_ISSET(Socket: TSocketHandle; var FDSet: TFDSet): Boolean;
begin
  Result := WinSock.FD_ISSET(Socket, FDSet);
end;

procedure sFD_SET(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  WinSock.FD_SET(Socket, FDSet);
end;

procedure sFD_ZERO(var FDSet: TFDSet);
begin
  WinSock.FD_ZERO(FDSet);
end;
