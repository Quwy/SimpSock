function inet_addr(const cp: pcchar): cuint32; cdecl; external;

var
  LocalErrno: Integer = Low(Integer);

function sSocket(const af, Struct, protocol: Integer): TSocketHandle;
begin
  Result := fpSocket(af, Struct, protocol);
end;

function sCloseSocket(const s: TSocketHandle): Integer;
begin
  Result := fpClose(s);
end;

function sConnect(const s: TSocketHandle; var name: TSockAddr; const namelen: Integer): Integer;
begin
  Result := fpConnect(s, @name, namelen);
end;

function sIOCtl(const s: TSocketHandle; const cmd: DWord; var arg: Integer): Integer;
begin
  Result := fpIOCtl(s, cmd, @arg);
end;

function sBind(const s: TSocketHandle; var addr: TSockAddr; const namelen: Integer): Integer;
begin
  Result := fpBind(s, PSockAddr(@addr), namelen);
end;

function sAccept(const s: TSocketHandle; const addr: PSockAddr; const addrlen: PInteger): TSocketHandle;
begin
  Result := fpAccept(s, addr, psocklen(@addrlen));
end;

function sGetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; var optlen: Integer): Integer;
begin
  Result := fpgetsockopt(s, level, optname, optval, psocklen(@optlen));
end;

function sSetSockOpt(const s: TSocketHandle; const level, optname: Integer; const optval: Pointer; const optlen: Integer): Integer;
begin
  Result := fpsetsockopt(s, level, optname, optval, optlen);
end;

function sListen(const s: TSocketHandle; const backlog: Integer): Integer;
begin
  Result := fpListen(s, backlog);
end;

function sRecv(const s: TSocketHandle; var Buf; const len, flags: Integer): Integer;
begin
  Result := fpRecv(s, @Buf, len, flags);
end;

function sSelect(const nfds: Integer; const readfds, writefds, exceptfds: PFDSet; const timeout: PTimeVal): Longint;
begin
  Result := fpSelect(nfds, readfds, writefds, exceptfds, timeout);
end;

function sSend(const s: TSocketHandle; const Buf; const len, flags: Integer): Integer;
begin
  Result := fpSend(s, @Buf, len, flags);
end;

function sShutdown(const s: TSocketHandle; const how: Integer): Integer;
begin
  Result := fpShutdown(s, how);
end;

function sGetHostByName(const Name: string): TInAddr;
var
  Addr: array of THostAddr;
begin
  Addr := nil;
  if ResolveName(Name, Addr) > 0 then
    Result := Addr[0]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function sHtons(const hostshort: Word): Word;
begin
  Result := htons(hostshort);
end;

function sInet_addr(const cp: MarshaledAString): DWORD;
begin
  Result := inet_addr(pcchar(cp));
end;

function sGetLastError: Integer;
begin
  if LocalErrno <> Low(Integer) then
    begin
      Result := LocalErrno;
      LocalErrno := Low(Integer);
    end
  else
    Result := errno;
end;

procedure sSetLastError(const Error: Integer);
begin
  LocalErrno := Error;
end;

function sSetNonBlockMode(const Socket: TSocketHandle): Integer;
var
  Flags: Integer;
begin
  Flags := FpFcntl(Socket, F_GETFL, 0);
  if Flags = -1 then
    Result := Flags
  else
    begin
      Flags := Flags or O_NONBLOCK;
      Result := FpFcntl(Socket, F_SETFL, Flags);
    end
end;

procedure sFD_CLR(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  fpFD_CLR(Socket, FDSet);
end;

function sFD_ISSET(Socket: TSocketHandle; var FDSet: TFDSet): Boolean;
begin
  Result := (fpFD_ISSET(Socket, FDSet) <> 0);
end;

procedure sFD_SET(Socket: TSocketHandle; var FDSet: TFDSet);
begin
  fpFD_SET(Socket, FDSet);
end;

procedure sFD_ZERO(var FDSet: TFDSet);
begin
  fpFD_ZERO(FDSet);
end;

initialization
  //FpSigAction(SIGPIPE, SIG_IGN, nil);

