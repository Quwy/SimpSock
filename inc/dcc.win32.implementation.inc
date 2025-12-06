function sSocket(const af, Struct, protocol: Integer): TSocketHandle;
begin
  Result := WinApi.WinSock.socket(af, Struct, protocol);
end;

function sCloseSocket(const s: TSocketHandle): Integer;
begin
  Result := WinApi.WinSock.closesocket(s);
end;

function sConnect(const s: TSocketHandle; var name: TSockAddr; const namelen: Integer): Integer;
begin
  Result := WinApi.WinSock.connect(s, name, namelen);
end;

function sIOCtl(const s: TSocketHandle; const cmd: DWORD; var arg: Integer): Integer;
begin
  Result := WinApi.WinSock.ioctlsocket(s, cmd, arg);
end;

function sBind(const s: TSocketHandle; var addr: TSockAddr; const namelen: Integer): Integer;
begin
  Result := WinApi.WinSock.bind(s, addr, namelen);
end;

function sAccept(const s: TSocketHandle; const addr: PSockAddr; const addrlen: PInteger): TSocketHandle;
begin
  Result := WinApi.WinSock.accept(s, addr, addrlen);
end;

function sGetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; var optlen: Integer): Integer;
begin
  Result := WinApi.WinSock.getsockopt(s, level, optname, optval, optlen);
end;

function sSetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; const optlen: Integer): Integer;
begin
  Result := WinApi.WinSock.setsockopt(s, level, optname, optval, optlen);
end;

function sListen(const s: TSocketHandle; const backlog: Integer): Integer;
begin
  Result := WinApi.WinSock.listen(s, backlog);
end;

function sRecv(const s: TSocketHandle; var Buf; const len, flags: Integer): Integer;
begin
  Result := WinApi.WinSock.recv(s, Buf, len, flags);
end;

function sSelect(const nfds: Integer; const readfds, writefds, exceptfds: PFDSet; const timeout: PTimeVal): Longint;
begin
  Result := WinApi.WinSock.select(nfds, readfds, writefds, exceptfds, timeout);
end;

function sSend(const s: TSocketHandle; const Buf; const len, flags: Integer): Integer;
begin
  Result := WinApi.WinSock.send(s, Buf, len, flags);
end;

function sShutdown(const s: TSocketHandle; const how: Integer): Integer;
begin
  Result := WinApi.WinSock.shutdown(s, how);
end;

function sGetHostByName(const Name: string): TInAddr;
var
  HostEnt: WinApi.WinSock.PHostEnt;
  M: TMarshaller;
begin
  HostEnt := WinApi.WinSock.gethostbyname(M.AsUTF8(Name).ToPointer);
  FillChar(Result, SizeOf(Result), 0);
  if Assigned(HostEnt) then
    begin
      Result.S_un_b.s_b1 := HostEnt^.h_addr^[0];
      Result.S_un_b.s_b2 := HostEnt^.h_addr^[1];
      Result.S_un_b.s_b3 := HostEnt^.h_addr^[2];
      Result.S_un_b.s_b4 := HostEnt^.h_addr^[3];
    end;
end;

function sHtons(const hostshort: Word): Word;
begin
  Result := WinApi.WinSock.htons(hostshort);
end;

function sInet_addr(const cp: MarshaledAString): DWord;
begin
  Result := WinApi.WinSock.inet_addr(cp);
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
  Result := WinApi.WinSock.ioctlsocket(Socket, WinApi.WinSock.FIONBIO, Mode);
end;

procedure sFD_CLR(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  WinApi.WinSock.FD_CLR(Socket, FDSet);
end;

function sFD_ISSET(Socket: TSocketHandle; var FDSet: TFDSet): Boolean;
begin
  Result := WinApi.WinSock.FD_ISSET(Socket, FDSet);
end;

procedure sFD_SET(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  WinApi.WinSock.FD_SET(Socket, FDSet);
end;

procedure sFD_ZERO(var FDSet: TFDSet);
begin
  WinApi.WinSock.FD_ZERO(FDSet);
end;

var
  WSALData: WSAData;

initialization
  WSAStartup($0101, WSALData);

finalization
  WSACleanup;

