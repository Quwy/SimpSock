unit SimpSock;

{$IFDEF FPC}
  {$mode delphi}
  {$modeswitch functionreferences}
  {$modeswitch anonymousfunctions}
{$ENDIF}

interface

uses
  SysUtils, Classes, SyncObjs, Generics.Collections, SimpApi;

type
  TTcpSocket = class;
  
  ESocketException = class(Exception);

  TSocketErrorType = (seOpen, seClose, seRead, seWrite, seAccept, seGeneral);

  TSocketNotifyEvent = procedure(const Sender: TTcpSocket) of object;

  TSocketErrorEvent = procedure(const Sender: TTcpSocket; const ErrorType: TSocketErrorType; const ErrorCode: Integer; var Handled: Boolean) of object;

  TSocketIncomingEvent = procedure(const Sender: TTcpSocket; const Data: Pointer; const Size: Cardinal; out Handled: Cardinal) of object;

  TWaitAction = (waOpen, waSend);

  TSocketBuffer = class(TObject)
  strict private
    FData: Pointer;
    FDataSize, FBlockSize, FBufferSize: Cardinal;
    function    RoundSize(const Size: Cardinal): Cardinal;
    procedure   CorrectBufferSize;
  public
    constructor Create(const BlockSize: Cardinal);
    destructor  Destroy; override;

    function    AppendBy(const AppendSize: Cardinal): Pointer;
    procedure   TrimBy(const TrimSize: Cardinal);
    procedure   ScrollAndTrimBy(const HandledSize: Cardinal);
    procedure   Clear;
  public
    property    Data: Pointer read FData;
    property    Size: Cardinal read FDataSize;
  end;

  TSocketState = (sstDisconnecting, sstDisconnected, sstConnecting, sstConnected);

  TSocketThreadEventType = (steRead, steWrite, steExcept, steFault);

  TSocketThreadEvent = procedure(const EventType: TSocketThreadEventType; const EventData: Integer) of object;

  { TSocketThread }

  TSocketThread = class(TThread)
  strict private
    FSocketHandle, FServiceSocketHandle: TSocketHandle;
    FSocketEventsHandler: TSocketThreadEvent;
    FCheckForWrite, FActualServiceSocket: Boolean;
    procedure   CallEventHandler(const EventType: TSocketThreadEventType; const EventData: Integer);
    function    IfThen(const Cond: Boolean; const IfTrue, IfFalse: Pointer): Pointer;
    procedure   ForceContinue;
    procedure   RefreshServiceSocket;
    function    MaxHandle(const Arg1, Arg2: TSocketHandle): TSocketHandle;
    function    GetSocketError: Integer;
  protected
    procedure   Execute; override;

    property    FreeOnTerminate;
    property    OnTerminate;
  public
    constructor Create(const SocketHandle: TSocketHandle; const SocketEventsHandler: TSocketThreadEvent; const ThreadTerminationHandler: TNotifyEvent);
    procedure   EnableCheckForWrite;
    procedure   DisableCheckForWrite;

    property    SocketHandle: TSocketHandle read FSocketHandle;
  end;

  { TTcpSocket }

  TTcpSocket = class(TObject)
  strict private
    FRxBuffer, FTxBuffer: TSocketBuffer;
    FMaxPacketSize: Cardinal;
    FSocketThread: TSocketThread;
    FSocketState: TSocketState;
    FOnIncoming: TSocketIncomingEvent;
    FOnError: TSocketErrorEvent;
    FOnConnect, FOnDisconnect: TSocketNotifyEvent;
    function    Min(const Arg1, Arg2: Cardinal): Cardinal;
    procedure   SetMaxPacketSize(const Value: Cardinal);
    function    GetActive: Boolean;
    function    GetHandle: TSocketHandle;
    function    GetConnecting: Boolean;
    function    GetRxBufferSize: Cardinal;
    procedure   ProcessRx(const IncomingSize: Integer);
    procedure   ProcessTx;
    function    TrySend(const Data: Pointer; const Size: Cardinal): Cardinal;
    procedure   SafeSend(const Data: Pointer; const Size: Cardinal);
    function    DoError(const ErrorType: TSocketErrorType; const ErrorCode: Integer): Boolean;
    procedure   OnSocketThreadEvent(const EventType: TSocketThreadEventType; const EventData: Integer);
    function    DoIncoming(const Data: Pointer; const Size: Cardinal): Cardinal;
    procedure   OnSocketThreadTerminated(Sender: TObject);
    procedure   InternalClose;
    procedure   InternalOpen;
    procedure   CalcMaxPacketSize;
  strict protected
    procedure   SetHandle(const SocketHandle: TSocketHandle);
    procedure   RaiseError(const ErrorType: TSocketErrorType; const ErrorCode: Integer);
    procedure   DoConnecting; virtual;
    procedure   DoDisconnecting; virtual;
    procedure   DoConnected; virtual;
    procedure   DoDisconnected; virtual;
  public
    constructor Create;
    destructor  Destroy; override;

    procedure   Open; virtual;
    procedure   Close; virtual;
    function    Send(const Data: Pointer; const Size: Cardinal): Boolean; virtual;
    procedure   ForceIncomingEvent; // can be called from OnDisconnect to collect unused data

    property    Handle: TSocketHandle read GetHandle;
    property    Active: Boolean read GetActive;
    property    Connecting: Boolean read GetConnecting;
    property    MaxPacketSize: Cardinal read FMaxPacketSize write SetMaxPacketSize;
    property    RxBufferSize: Cardinal read GetRxBufferSize;

    property    OnError: TSocketErrorEvent read FOnError write FOnError;
    property    OnIncoming: TSocketIncomingEvent read FOnIncoming write FOnIncoming;
    property    OnConnect: TSocketNotifyEvent read FOnConnect write FOnConnect;
    property    OnDisconnect: TSocketNotifyEvent read FOnDisconnect write FOnDisconnect;
  end;

type
  TSimpleClientSocket = class(TTcpSocket)
  strict private
    FPort: Word;
    FHost: string;
    FAddress: TSockAddr;
    function    LookupName(const Name: string): TInAddr;
    procedure   SetHost(const Value: string);
    procedure   SetPort(const Value: Word);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   Open; override;

    property    Host: string read FHost write SetHost;
    property    Port: Word read FPort write SetPort;
  end;

  TSimpleServerSocket = class;
  TServerClientSocket = class;

  TSrvSocketNotifyEvent = procedure(const Sender: TSimpleServerSocket) of object;

  TSrvSocketEvent = procedure(const Sender: TSimpleServerSocket; const WorkerSocket: TServerClientSocket) of object;

  TSrvWorkerErrorEvent = procedure(const Sender: TSimpleServerSocket; const WorkerSocket: TServerClientSocket; const ErrorType: TSocketErrorType; const ErrorCode: Integer; var Handled: Boolean) of object;

  TSrvIncomingEvent = procedure(const Sender: TSimpleServerSocket; const WorkerSocket: TServerClientSocket; const Data: Pointer; const Size: Cardinal; out Handled: Cardinal) of object;

  TSrvAcceptRequestEvent = procedure(const Sender: TSimpleServerSocket; var AllowAccept: Boolean) of object;

  TSrvErrorEvent = procedure(const Sender: TSimpleServerSocket; const ErrorType: TSocketErrorType; const ErrorCode: Integer; var Handled: Boolean) of object;

  TServerSocketThreadEventType = (ssteSocketTriggered, ssteFault);

  TServerSocketThreadEvent = procedure(const EventType: TServerSocketThreadEventType; const EventData: Integer) of object;

  TSrvSocketState = (sssClosed, sssOpen, sssClosing);

  TServerClientSocket = class(TTcpSocket)
  strict private
    FServerSocket: TSimpleServerSocket;
    FAddress: TSockAddr;
    function    GetRemoteAddress: string;
    function    GetRemotePort: Word;
  public
    constructor Create(const AServerSocket: TSimpleServerSocket);

    procedure   Open; override;

    property    ServerSocket: TSimpleServerSocket read FServerSocket;
    property    RemoteAddress: string read GetRemoteAddress;
    property    RemotePort: Word read GetRemotePort;
  end;

  TServerSocketThread = class(TThread)
  strict private
    FSocketHandle: TSocketHandle;
    FSocketEventsHandler: TServerSocketThreadEvent;
    procedure   CallEventHandler(const EventType: TServerSocketThreadEventType; const EventData: Integer);

    property    FreeOnTerminate;
    property    OnTerminate;
  protected
    procedure   Execute; override;
  public
    constructor Create(const SocketHandle: TSocketHandle; const SocketEventsHandler: TServerSocketThreadEvent; const ThreadTerminationHandler: TNotifyEvent);

    property    SocketHandle: TSocketHandle read FSocketHandle;
  end;

  TSimpleServerSocket = class(TObject)
  strict private
    FSocketState: TSrvSocketState;
    FSocketHandle: TSocketHandle;
    FSocketThread: TServerSocketThread;
    FPort: Word;
    FOnIncoming: TSrvIncomingEvent;
    FOnOpen, FOnClose: TSrvSocketNotifyEvent;
    FOnError: TSrvErrorEvent;
    FOnWorkerSocketConnect, FOnWorkerSocketDisconnect: TSrvSocketEvent;
    FOnWorkerSocketError: TSrvWorkerErrorEvent;
    FOnAcceptRequest: TSrvAcceptRequestEvent;
    FMaxPacketSize: Cardinal;
    FClientWorkers: TDictionary<TSocketHandle, TServerClientSocket>;
    procedure   OnWorkerSocketError(const Sender: TTcpSocket; const ErrorType: TSocketErrorType; const ErrorCode: Integer; var Handled: Boolean);
    procedure   OnWorkerSocketIncoming(const Sender: TTcpSocket; const Data: Pointer; const Size: Cardinal; out Handled: Cardinal);
    procedure   OnWorkerSocketConnect(const Sender: TTcpSocket);
    procedure   OnWorkerSocketDisconnect(const Sender: TTcpSocket);
    procedure   SetPort(const Value: Word);
    function    GetClientCount: Integer;
    function    GetWorkerSocketBySocket(const SocketToFind: TSocketHandle): TServerClientSocket;
    procedure   SetMaxPacketSize(const Value: Cardinal);
    function    DoAcceptRequest: Boolean;
    procedure   OnServerSocketThreadEvent(const EventType: TServerSocketThreadEventType; const EventData: Integer);
    procedure   OnSocketThreadTerminated(Sender: TObject);
    procedure   InternalClose;
    procedure   InternalOpen;
    procedure   DoOpen;
    procedure   DoClose;
    procedure   DoClosing;
    procedure   DoWorkerSocketError(const WorkerSocket: TServerClientSocket; const ErrorType: TSocketErrorType; const ErrorCode: Integer; var Handled: Boolean);
    procedure   DoWorkerSocketConnect(const WorkerSocket: TServerClientSocket);
    procedure   DoWorkerSocketDisconnect(const WorkerSocket: TServerClientSocket);
    procedure   DoIncoming(const WorkerSocket: TServerClientSocket; const Data: Pointer; const Size: Cardinal; out Handled: Cardinal);
    procedure   DropWorkers;
    procedure   CalcMaxPacketSize;
  strict protected
    function    GetActive: Boolean; protected
    procedure   RaiseError(const ErrorType: TSocketErrorType; const ErrorCode: Integer);
  public
    constructor Create;
    destructor  Destroy; override;
    procedure   Open; virtual;
    procedure   Close; virtual;

    property    ClientsBySocket[const SocketToFind: TSocketHandle]: TServerClientSocket read GetWorkerSocketBySocket;
    property    ClientCount: Integer read GetClientCount;
    property    Active: Boolean read GetActive;

    property    Port: Word read FPort write SetPort;
    property    Handle: TSocketHandle read FSocketHandle;
    property    MaxPacketSize: Cardinal read FMaxPacketSize write SetMaxPacketSize;

    property    OnIncoming: TSrvIncomingEvent read FOnIncoming write FOnIncoming;
    property    OnOpen: TSrvSocketNotifyEvent read FOnOpen write FOnOpen;
    property    OnClose: TSrvSocketNotifyEvent read FOnClose write FOnClose;
    property    OnError: TSrvErrorEvent read FOnError write FOnError;
    property    OnClientConnected: TSrvSocketEvent read FOnWorkerSocketConnect write FOnWorkerSocketConnect;
    property    OnClientDisconnected: TSrvSocketEvent read FOnWorkerSocketDisconnect write FOnWorkerSocketDisconnect;
    property    OnClientError: TSrvWorkerErrorEvent read FOnWorkerSocketError write FOnWorkerSocketError;
    property    OnClientAccept: TSrvAcceptRequestEvent read FOnAcceptRequest write FOnAcceptRequest;
  end;

type
  TIP = packed record
    case Byte of
      0: (Long: Integer);
      1: (b1, b2, b3, b4: Byte);
      2: (c1, c2, c3, c4: Char);
      3: (Bytes: array [1..4] of Byte);
      4: (Chars: array [1..4] of Char);
  end;

const
  SOCKET_ERROR_TYPE: array[TSocketErrorType] of string = ('Open', 'Close', 'Read', 'Write', 'Accept', 'General');
  DEFAULT_PACKET_SIZE = 1500;

function SockAddrToIP(const Address: TSockAddr): TIP;
function IPToStr(const IP: TIP): string;
function StrToIP(const Address: string): TIP;

implementation

{$IFNDEF FPC}
type
  PtrUInt = NativeUInt;
{$ENDIF}

const
  SOCKET_ERROR_TEXT = 'Socket error: %s (%d), while ''%s''';

{ TSocketBuffer }

function TSocketBuffer.AppendBy(const AppendSize: Cardinal): Pointer;
var
  OldSize: Cardinal;
begin
  OldSize := FDataSize;
  Inc(FDataSize, AppendSize);
  CorrectBufferSize;
  Result := Pointer(PtrUInt(FData) + OldSize);
end;

procedure TSocketBuffer.Clear;
begin
  FDataSize := 0;
  CorrectBufferSize;
end;

function TSocketBuffer.RoundSize(const Size: Cardinal): Cardinal;
begin
  if Size > 0 then
    Result := ((Size div FBlockSize) + 1) * FBlockSize
  else
    Result := 0;
end;

procedure TSocketBuffer.CorrectBufferSize;
var
  NewBufferSize: Cardinal;
begin
  NewBufferSize := RoundSize(FDataSize);
  if NewBufferSize <> FBufferSize then
    begin
      FBufferSize := NewBufferSize;
      if FBufferSize > 0 then
        ReallocMem(FData, FBufferSize)
      else
        begin
          FreeMem(FData);
          FData := nil;
        end;
    end;
end;

constructor TSocketBuffer.Create(const BlockSize: Cardinal);
begin
  inherited Create;

  FBlockSize := BlockSize;
  FBufferSize := 0;
  FData := nil;
  FDataSize := 0;
end;

destructor TSocketBuffer.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TSocketBuffer.ScrollAndTrimBy(const HandledSize: Cardinal);
begin
  Dec(FDataSize, HandledSize);
  Move(Pointer(PtrUInt(FData) + HandledSize)^, FData^, FDataSize);
  CorrectBufferSize;
end;

procedure TSocketBuffer.TrimBy(const TrimSize: Cardinal);
begin
  Dec(FDataSize, TrimSize);
  CorrectBufferSize;
end;

{ TSocketThread }

procedure TSocketThread.EnableCheckForWrite;
begin
  FCheckForWrite := True;
  ForceContinue;
end;

constructor TSocketThread.Create(const SocketHandle: TSocketHandle; const SocketEventsHandler: TSocketThreadEvent; const ThreadTerminationHandler: TNotifyEvent);
begin
  inherited Create(True);
  OnTerminate := ThreadTerminationHandler;
  FreeOnTerminate := True;

  FSocketHandle := SocketHandle;
  FSocketEventsHandler := SocketEventsHandler;
  FCheckForWrite := False;
  FActualServiceSocket := False;
end;

procedure TSocketThread.CallEventHandler(const EventType: TSocketThreadEventType; const EventData: Integer);
begin
  if Assigned(FSocketEventsHandler) then
    Synchronize(Self,
      procedure
      begin
        FSocketEventsHandler(EVentType, EventData);
      end);
end;

procedure TSocketThread.DisableCheckForWrite;
begin
  FCheckForWrite := False;
end;

procedure TSocketThread.Execute;
var
  ReadFds, WriteFds, ExceptFds: TFDSet;
  Res, ErrCode: Integer;
begin
  NameThreadForDebugging(ClassName);
  while not Terminated do
    begin
      RefreshServiceSocket;

      sFD_ZERO(ReadFds);
      sFD_ZERO(ExceptFds);
      sFD_ZERO(WriteFds);

      sFD_SET(FSocketHandle, ReadFds);
      sFD_SET(FSocketHandle, WriteFds);
      sFD_SET(FSocketHandle, ExceptFds);

      sFD_SET(FServiceSocketHandle, ReadFds);

      Res := sSelect(MaxHandle(FSocketHandle, FServiceSocketHandle) + 1, @ReadFds, PFDSet(IfThen(FCheckForWrite, @WriteFds, nil)), @ExceptFds, nil);

      if not Terminated then
        if Res > 0 then
          begin
            ErrCode := GetSocketError;

            if sFD_ISSET(FSocketHandle, ReadFds) then CallEventHandler(steRead, ErrCode);
            if sFD_ISSET(FSocketHandle, WriteFds) then CallEventHandler(steWrite, ErrCode);
            if sFD_ISSET(FSocketHandle, ExceptFds) then CallEventHandler(steExcept, ErrCode);
          end
        else
          CallEventHandler(steFault, sGetLastError);
    end;

  ForceContinue;
end;

procedure TSocketThread.ForceContinue;
begin
  if FActualServiceSocket then
    begin
      sCloseSocket(FServiceSocketHandle);
      FActualServiceSocket := False;
    end;
end;

function TSocketThread.GetSocketError: Integer;
var
  ErrCodeSize: Integer;
begin
  Result := 0;
  ErrCodeSize := SizeOf(Result);
  if sGetSockOpt(FSocketHandle, SOL_SOCKET, SO_ERROR, @Result, ErrCodeSize) <> 0 then Result := sGetLastError;
end;

function TSocketThread.IfThen(const Cond: Boolean; const IfTrue, IfFalse: Pointer): Pointer;
begin
  if Cond then
    Result := IfTrue
  else
    Result := IfFalse;
end;

procedure TSocketThread.RefreshServiceSocket;
begin
  if not FActualServiceSocket then
    begin
      FServiceSocketHandle := sSocket(PF_INET, SOCK_STREAM, IPPROTO_IP);
      FActualServiceSocket := True;
    end;
end;

function TSocketThread.MaxHandle(const Arg1, Arg2: TSocketHandle): TSocketHandle;
begin
  if Arg1 > Arg2 then
    Result := Arg1
  else
    Result := Arg2;
end;

{ TTcpSocket }

function TTcpSocket.DoIncoming(const Data: Pointer; const Size: Cardinal): Cardinal;
begin
  if Assigned(FOnIncoming) then
    try
      FOnIncoming(Self, Data, Size, Result);
    except
      { nothing }
    end
  else
    Result := Size; // free buffer
end;

procedure TTcpSocket.ForceIncomingEvent;
begin
  if FRxBuffer.Size > 0 then
    FRxBuffer.ScrollAndTrimBy(DoIncoming(FRxBuffer.Data, FRxBuffer.Size));
end;

procedure TTcpSocket.InternalOpen;
begin
  CalcMaxPacketSize;

  DoConnected;

  FSocketThread.DisableCheckForWrite;

  if Assigned(FOnConnect) then
    try
      FOnConnect(Self);
    except
      // nothing
    end;
end;

function TTcpSocket.GetActive: Boolean;
begin
  Result := (FSocketState = sstConnected);
end;

function TTcpSocket.GetConnecting: Boolean;
begin
  Result := (FSocketState = sstConnecting);
end;

function TTcpSocket.GetHandle: TSocketHandle;
begin
  if Assigned(FSocketThread) then
    Result := FSocketThread.SocketHandle
  else
    Result := INVALID_SOCKET;
end;

function TTcpSocket.GetRxBufferSize: Cardinal;
begin
  Result := FRxBuffer.Size;
end;

procedure TTcpSocket.ProcessRx(const IncomingSize: Integer);
const
  MSG_WAITALL = $100;
var
  RxRes: Integer;
begin
  RxRes := sRecv(Handle, FRxBuffer.AppendBy(IncomingSize)^, IncomingSize, 0);

  if RxRes = SOCKET_ERROR then
    RaiseError(seRead, sGetLastError)
  else
    begin
      if RxRes < IncomingSize then FRxBuffer.TrimBy(IncomingSize - RxRes);
      FRxBuffer.ScrollAndTrimBy(DoIncoming(FRxBuffer.Data, FRxBuffer.Size));
    end;
end;

procedure TTcpSocket.ProcessTx;
begin
  if FTxBuffer.Size > 0 then
    FTxBuffer.ScrollAndTrimBy(TrySend(FTxBuffer.Data, FTxBuffer.Size))
  else
    FSocketThread.DisableCheckForWrite;
end;

function TTcpSocket.TrySend(const Data: Pointer; const Size: Cardinal): Cardinal;
var
  Res, Err: Integer;
begin
  Result := 0;
  Err := 0;
  repeat
    Res := sSend(Handle, Pointer(PtrUInt(Data) + Result)^, Min(FMaxPacketSize, Size - Result), 0);
    if Res <> SOCKET_ERROR then
      begin
        Inc(Result, Res);
        FSocketThread.DisableCheckForWrite;
      end
    else
      begin
        Err := sGetLastError;
        if (Err <> EWOULDBLOCK) and (Err <> EINPROGRESS) then
          RaiseError(seWrite, Err);
        FSocketThread.EnableCheckForWrite;
      end;
  until (Err <> 0) or (Result = Size);
end;

procedure TTcpSocket.SafeSend(const Data: Pointer; const Size: Cardinal);
var
  Sent: Cardinal;
begin
  if Size > 0 then
    if FTxBuffer.Size > 0 then
      begin
        Move(Data^, FTxBuffer.AppendBy(Size)^, Size);
        ProcessTx;
      end
    else
      begin
        Sent := TrySend(Data, Size);
        if Sent < Size then
          Move(Pointer(PtrUInt(Data) + Sent)^, FTxBuffer.AppendBy(Size - Sent)^, Size - Sent);
      end;
end;

function TTcpSocket.Send(const Data: Pointer; const Size: Cardinal): Boolean;
begin
  Result := False;

  if Active then
    begin
      SafeSend(Data, Size);
      Result := True;
    end
  else
    sSetLastError(ENOTSOCK);

  if not Result then RaiseError(seWrite, sGetLastError);
end;

procedure TTcpSocket.CalcMaxPacketSize;
var
  Size, SizeLen: Integer;
begin
  if FMaxPacketSize < 16 then
    begin
      SizeLen := SizeOf(Size);
      if (sGetSockOpt(Handle, SOL_SOCKET, SO_SNDBUF, @Size, SizeLen) = 0) and (Size > 0) then
        FMaxPacketSize := Size
      else
        FMaxPacketSize := DEFAULT_PACKET_SIZE;
    end;
end;

procedure TTcpSocket.Close;
begin
  if Active then
    begin
      DoDisconnecting;
      sShutdown(Handle, SD_BOTH);
      sCloseSocket(Handle);
      InternalClose;
    end
  else
    if Connecting then
      begin
        DoDisconnecting;
        sCloseSocket(Handle);
        DoDisconnected;
      end;
end;

constructor TTcpSocket.Create;
begin
  inherited Create;
  FMaxPacketSize := 0;
  FOnConnect := nil;
  FOnDisconnect := nil;
  FOnIncoming := nil;
  FOnError := nil;
  FSocketState := sstDisconnected;
  FSocketThread := nil;
  FRxBuffer := TSocketBuffer.Create(65536);
  FTxBuffer := TSocketBuffer.Create(65536);
end;

destructor TTcpSocket.Destroy;
begin
  FRxBuffer.Free;
  FTxBuffer.Free;

  inherited Destroy;
end;

procedure TTcpSocket.InternalClose;
begin
  DoDisconnected;

  if Assigned(FOnDisconnect) then
    try
      FOnDisconnect(Self);
    finally
      // nothing
    end;

  FRxBuffer.Clear;
  FTxBuffer.Clear;
end;

procedure TTcpSocket.DoConnected;
begin
  FSocketState := sstConnected;
end;

procedure TTcpSocket.DoConnecting;
begin
  FSocketState := sstConnecting;
  FSocketThread.EnableCheckForWrite;
  FSocketThread.Start;
end;

procedure TTcpSocket.DoDisconnected;
begin
  FSocketState := sstDisconnected;
end;

procedure TTcpSocket.DoDisconnecting;
begin
  FSocketState := sstDisconnecting;
  FSocketThread.Terminate;
end;

function TTcpSocket.DoError(const ErrorType: TSocketErrorType; const ErrorCode: Integer): Boolean;
begin
  Result := False;

  if Assigned(FOnError) then
    try
      FOnError(Self, ErrorType, ErrorCode, Result);
    except
      // nothing
    end;
end;

function TTcpSocket.Min(const Arg1, Arg2: Cardinal): Cardinal;
begin
  if Arg1 < Arg2 then
    Result := Arg1
  else
    Result := Arg2;
end;

procedure TTcpSocket.RaiseError(const ErrorType: TSocketErrorType; const ErrorCode: Integer);
begin
  if not DoError(ErrorType, ErrorCode) then
    raise ESocketException.CreateFmt(SOCKET_ERROR_TEXT, [SysErrorMessage(ErrorCode), ErrorCode, SOCKET_ERROR_TYPE[ErrorType]]);
end;

procedure TTcpSocket.SetHandle(const SocketHandle: TSocketHandle);
begin
  FSocketThread := TSocketThread.Create(SocketHandle, OnSocketThreadEvent, OnSocketThreadTerminated);
end;

procedure TTcpSocket.SetMaxPacketSize(const Value: Cardinal);
const
  MIN_VALUE = 16;
begin
  if Value < MIN_VALUE then
    FMaxPacketSize := MIN_VALUE
  else
    FMaxPacketSize := Value;
end;

procedure TTcpSocket.OnSocketThreadEvent(const EventType: TSocketThreadEventType; const EventData: Integer);
var
  IncomingData: Integer;
  WasActive: Boolean;
begin
  case EventType of
    steRead:
      if FSocketState = sstConnected then
        if sIOCtl(Handle, FIONREAD, IncomingData) <> SOCKET_ERROR then
          if IncomingData > 0 then
            ProcessRx(IncomingData)
          else
            if {$IFDEF MSWINDOWS}False{$ELSE}EventData = 0{$ENDIF} then
              // just empty event (for example, incoming IP packet with wrong CRC on Linux)
            else
              begin
                DoDisconnecting;
                sCloseSocket(Handle);
                InternalClose;
              end
        else
          RaiseError(seRead, sGetLastError);

    steWrite:
      if FSocketState = sstConnecting then
        if EventData = 0 then
          InternalOpen
        else
          begin
            DoDisconnecting;
            sCloseSocket(Handle);
            DoDisconnected;
            RaiseError(seOpen, EventData);
          end
      else
        ProcessTx;

    steExcept:
      if FSocketState = sstConnecting then
        begin
          DoDisconnecting;
          sCloseSocket(Handle);
          DoDisconnected;
          RaiseError(seOpen, EventData);
        end
      else
        begin
          RaiseError(seGeneral, EventData);
          FSocketThread.EnableCheckForWrite;
        end;

  else
    WasActive := Active;
    DoDisconnecting;
    sCloseSocket(Handle);
    if WasActive then
      InternalClose
    else
      DoDisconnected;
    RaiseError(seGeneral, EventData);
  end;
end;

procedure TTcpSocket.OnSocketThreadTerminated(Sender: TObject);
begin
  if FSocketThread = Sender then FSocketThread := nil;
end;

procedure TTcpSocket.Open;
begin
  InternalOpen;
end;

{ TSimpleClientSocket }

constructor TSimpleClientSocket.Create;
begin
  inherited Create;

  FPort := 0;
  FHost := '';
  FAddress.sin_family := PF_INET;
  FAddress.sin_addr.S_addr := INADDR_ANY;
  FAddress.sin_port := 0;
end;

destructor TSimpleClientSocket.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TSimpleClientSocket.LookupName(const Name: string): TInAddr;
begin
  Result := sGetHostByName(Name);
end;

procedure TSimpleClientSocket.Open;
var
  Res: Integer;
  Socket: TSocketHandle;
begin
  if not (Active or Connecting) then
    begin
      Socket := sSocket(PF_INET, SOCK_STREAM, IPPROTO_IP);
      if Socket <> INVALID_SOCKET then
        if sSetNonBlockMode(Socket) = 0 then
          begin
            FAddress.sin_family := PF_INET;
            FAddress.sin_port := sHtons(FPort);
            FAddress.sin_addr.S_addr := sInet_addr(PAnsiChar(AnsiString(FHost)));
            if Cardinal(FAddress.sin_addr.S_addr) = INADDR_NONE then FAddress.sin_addr := LookupName(FHost);

            if sConnect(Socket, FAddress, SizeOf(FAddress)) <> 0 then
              begin
                Res := sGetLastError;
                if (Res = EINPROGRESS) or (Res = EWOULDBLOCK) then
                  begin
                    SetHandle(Socket);
                    DoConnecting;
                  end
                else
                  begin
                    sCloseSocket(Socket);
                    RaiseError(seOpen, Res);
                  end;
              end
            else
              begin
                SetHandle(Socket);
                DoConnecting;
                inherited Open;
              end;
          end
        else
          begin
            Res := sGetLastError;
            sCloseSocket(Socket);
            RaiseError(seOpen, Res);
          end
      else
        RaiseError(seOpen, sGetLastError);
    end;
end;

procedure TSimpleClientSocket.SetHost(const Value: string);
begin
  if Active or Connecting then
    raise ESocketException.Create('Host change allowed only in inactive state')
  else
    FHost := Value;
end;

procedure TSimpleClientSocket.SetPort(const Value: Word);
begin
  if Active or Connecting then
    raise ESocketException.Create('Port change allowed only in inactive state')
  else
    FPort := Value;
end;

{ TServerClientSocket }

constructor TServerClientSocket.Create(const AServerSocket: TSimpleServerSocket);
begin
  inherited Create;

  FServerSocket := AServerSocket;
end;

function TServerClientSocket.GetRemoteAddress: string;
begin
  Result := IPToStr(SockAddrToIP(FAddress));
end;

function TServerClientSocket.GetRemotePort: Word;
begin
  Result := sHtons(FAddress.sin_port);
end;

procedure TServerClientSocket.Open;
var
  Socket: TSocketHandle;
  Len: Integer;
begin
  if Assigned(FServerSocket) and not (Active or Connecting) then
    begin
      Len := SizeOf(FAddress);
      Socket := sAccept(FServerSocket.Handle, @FAddress, @Len);
      if Socket <> INVALID_SOCKET then
        begin
          SetHandle(Socket);
          DoConnecting;
          inherited Open;
        end
      else
        begin
          DoDisconnected;
          RaiseError(seAccept, sGetLastError);
        end;
    end;
end;

{ TServerSocketThread }

procedure TServerSocketThread.CallEventHandler(const EventType: TServerSocketThreadEventType; const EventData: Integer);
begin
  if Assigned(FSocketEventsHandler) then
    Synchronize(Self,
      procedure
      begin
        FSocketEventsHandler(EventType, EventData);
      end);
end;

constructor TServerSocketThread.Create(const SocketHandle: TSocketHandle; const SocketEventsHandler: TServerSocketThreadEvent;
  const ThreadTerminationHandler: TNotifyEvent);
begin
  inherited Create(False);
  OnTerminate := ThreadTerminationHandler;
  FreeOnTerminate := True;

  FSocketHandle := SocketHandle;
  FSocketEventsHandler := SocketEventsHandler;
end;

procedure TServerSocketThread.Execute;
var
  ReadFds, WriteFds, ExceptFds: TFDSet;
  Res: Integer;
begin
  NameThreadForDebugging(ClassName);

  while not Terminated do
    begin
      sFD_ZERO(ReadFds);
      sFD_ZERO(ExceptFds);
      sFD_ZERO(WriteFds);

      sFD_SET(FSocketHandle, ReadFds);
      sFD_SET(FSocketHandle, WriteFds);
      sFD_SET(FSocketHandle, ExceptFds);

      Res := sSelect(FSocketHandle + 1, @ReadFds, @WriteFds, @ExceptFds, nil);

      if not Terminated then
        if Res > 0 then
          begin
            if sFD_ISSET(FSocketHandle, ReadFds) then CallEventHandler(ssteSocketTriggered, 0);
          end
        else
          CallEventHandler(ssteFault, sGetLastError);
    end;
end;

{ TSimpleServerSocket }

constructor TSimpleServerSocket.Create;
begin
  inherited Create;

  FSocketState := sssClosed;
  FSocketHandle := INVALID_SOCKET;
  FSocketThread := nil;
  FPort := 0;
  FMaxPacketSize := 0;

  FOnIncoming := nil;
  FOnOpen := nil;
  FOnClose := nil;
  FOnWorkerSocketConnect := nil;
  FOnWorkerSocketDisconnect := nil;
  FOnAcceptRequest := nil;
  FOnWorkerSocketError := nil;

  FClientWorkers := TDictionary<TSocketHandle, TServerClientSocket>.Create;
end;

destructor TSimpleServerSocket.Destroy;
begin
  Close;
  FClientWorkers.Free;

  inherited Destroy;
end;

procedure TSimpleServerSocket.RaiseError(const ErrorType: TSocketErrorType; const ErrorCode: Integer);
var
  Handled: Boolean;
begin
  Handled := False;

  if Assigned(FOnError) then
    try
      FOnError(Self, ErrorType, ErrorCode, Handled);
    except
      { nothing }
    end;

  if not Handled then
    raise ESocketException.CreateFmt(SOCKET_ERROR_TEXT, [SysErrorMessage(ErrorCode), ErrorCode, SOCKET_ERROR_TYPE[ErrorType]]);
end;

procedure TSimpleServerSocket.Open;
var
  Address: TSockAddr;
  Err: Integer;
begin
  if FSocketState = sssClosed then
    begin
      FSocketHandle := sSocket(PF_INET, SOCK_STREAM, IPPROTO_IP);
      if FSocketHandle <> INVALID_SOCKET then
        begin
          Address.sin_family := PF_INET;
          Address.sin_port := sHtons(FPort);
          Address.sin_addr.s_addr := INADDR_ANY;
          if sBind(FSocketHandle, Address, SizeOf(Address)) <> 0 then
            begin
              Err := sGetLastError;
              sCloseSocket(FSocketHandle);
              FSocketHandle := INVALID_SOCKET;
              RaiseError(seOpen, Err);
            end
          else
            if sListen(FSocketHandle, SOMAXCONN) = 0 then
              InternalOpen
            else
              begin
                Err := sGetLastError;
                sCloseSocket(FSocketHandle);
                FSocketHandle := INVALID_SOCKET;
                RaiseError(seOpen, Err);
              end;
        end
      else
        RaiseError(seOpen, sGetLastError);
    end;
end;

procedure TSimpleServerSocket.CalcMaxPacketSize;
var
  Size, SizeLen: Integer;
begin
  if FMaxPacketSize < 16 then
    begin
      SizeLen := SizeOf(Size);
      if (sGetSockOpt(FSocketHandle, SOL_SOCKET, SO_SNDBUF, @Size, SizeLen) = 0) and (Size > 0) then
        FMaxPacketSize := Size
      else
        FMaxPacketSize := DEFAULT_PACKET_SIZE;
    end;
end;

procedure TSimpleServerSocket.Close;
begin
  if FSocketState = sssOpen then
    begin
      DoClosing;
      sCloseSocket(Handle);
      InternalClose;
    end;
end;

function TSimpleServerSocket.GetWorkerSocketBySocket(const SocketToFind: TSocketHandle): TServerClientSocket;
begin
  if (SocketToFind <> INVALID_SOCKET) and (FClientWorkers.Count > 0) then
    Result := FClientWorkers[SocketToFind]
  else
    Result := nil;
end;

procedure TSimpleServerSocket.InternalClose;
begin
  DropWorkers;

  DoClose;

  if Assigned(FOnClose) then
    try
      FOnClose(Self);
    except
      { nothing }
    end;
end;

procedure TSimpleServerSocket.InternalOpen;
begin
  CalcMaxPacketSize;

  DoOpen;

  FSocketThread := TServerSocketThread.Create(FSocketHandle, OnServerSocketThreadEvent, OnSocketThreadTerminated);

  if Assigned(FOnOpen) then
    try
      FOnOpen(Self);
    except
      { nothing }
    end;
end;

procedure TSimpleServerSocket.SetPort(const Value: Word);
begin
  if Active then
    raise ESocketException.Create('Port change allowed only in inactive state')
  else
    FPort := Value;
end;

procedure TSimpleServerSocket.OnServerSocketThreadEvent(const EventType: TServerSocketThreadEventType; const EventData: Integer);
var
  Client: TServerClientSocket;
begin
  case EventType of
    ssteSocketTriggered:
      if Active and DoAcceptRequest then
        begin
          Client := TServerClientSocket.Create(Self);
          Client.OnError := OnWorkerSocketError;
          Client.OnIncoming := OnWorkerSocketIncoming;
          Client.OnConnect := OnWorkerSocketConnect;
          Client.OnDisconnect := OnWorkerSocketDisconnect;
          Client.MaxPacketSize := FMaxPacketSize;
          Client.Open;

          if not Client.Active then
            Client.Free;
        end;

  else
    sCloseSocket(FSocketHandle);
    InternalClose;
    RaiseError(seGeneral, EventData);
  end;
end;

function TSimpleServerSocket.GetActive: Boolean;
begin
  Result := (FSocketState = sssOpen);
end;

function TSimpleServerSocket.GetClientCount: Integer;
begin
  Result := FClientWorkers.Count;
end;

procedure TSimpleServerSocket.SetMaxPacketSize(const Value: Cardinal);
const
  MIN_VALUE = 16;
begin
  if Value < MIN_VALUE then
    FMaxPacketSize := MIN_VALUE
  else
    FMaxPacketSize := Value;
end;

procedure TSimpleServerSocket.OnWorkerSocketConnect(const Sender: TTcpSocket);
begin
  FClientWorkers.Add(Sender.Handle, TServerClientSocket(Sender));
  DoWorkerSocketConnect(TServerClientSocket(Sender));
end;

procedure TSimpleServerSocket.OnWorkerSocketDisconnect(const Sender: TTcpSocket);
begin
  DoWorkerSocketDisconnect(TServerClientSocket(Sender));
  FClientWorkers.Remove(Sender.Handle);
  Sender.Free;
end;

procedure TSimpleServerSocket.OnWorkerSocketError(const Sender: TTcpSocket; const ErrorType: TSocketErrorType; const ErrorCode: Integer; var Handled: Boolean);
begin
  DoWorkerSocketError(TServerClientSocket(Sender), ErrorType, ErrorCode, Handled);
end;

procedure TSimpleServerSocket.OnWorkerSocketIncoming(const Sender: TTcpSocket; const Data: Pointer; const Size: Cardinal; out Handled: Cardinal);
begin
  DoIncoming(TServerClientSocket(Sender), Data, Size, Handled);
end;

procedure TSimpleServerSocket.OnSocketThreadTerminated(Sender: TObject);
begin
  FSocketThread := nil;
end;

function TSimpleServerSocket.DoAcceptRequest: Boolean;
begin
  Result := True;

  if Assigned(FOnAcceptRequest) then
    try
      FOnAcceptRequest(Self, Result);
    except
      Result := False;
    end;
end;

procedure TSimpleServerSocket.DoClose;
begin
  FSocketState := sssClosed;
end;

procedure TSimpleServerSocket.DoClosing;
begin
  FSocketState := sssClosing;
  FSocketThread.Terminate;
end;

procedure TSimpleServerSocket.DoIncoming(const WorkerSocket: TServerClientSocket; const Data: Pointer; const Size: Cardinal; out Handled: Cardinal);
begin
  if Assigned(FOnIncoming) then
    try
      FOnIncoming(Self, WorkerSocket, Data, Size, Handled);
    except
      Handled := Size;
    end
  else
    Handled := Size; // free buffer
end;

procedure TSimpleServerSocket.DoOpen;
begin
  FSocketState := sssOpen;
end;

procedure TSimpleServerSocket.DoWorkerSocketConnect(const WorkerSocket: TServerClientSocket);
begin
  if Assigned(FOnWorkerSocketConnect) then
    try
      FOnWorkerSocketConnect(Self, WorkerSocket);
    except
      // nothing
    end;
end;

procedure TSimpleServerSocket.DoWorkerSocketDisconnect(const WorkerSocket: TServerClientSocket);
begin
  if Assigned(FOnWorkerSocketDisconnect) then
    try
      FOnWorkerSocketDisconnect(Self, WorkerSocket);
    except
      // nothing
    end;
end;

procedure TSimpleServerSocket.DoWorkerSocketError(const WorkerSocket: TServerClientSocket; const ErrorType: TSocketErrorType; const ErrorCode: Integer;
  var Handled: Boolean);
begin
  if Assigned(FOnWorkerSocketError) then
    try
      FOnWorkerSocketError(Self, WorkerSocket, ErrorType, ErrorCode, Handled);
    except
      Handled := True;
    end
  else
    Handled := False;
end;

procedure TSimpleServerSocket.DropWorkers;
var
  Worker: TServerClientSocket;
begin
  for Worker in FClientWorkers.Values do
    Worker.Close;
end;

{ Routines }

function SockAddrToIP(const Address: TSockAddr): TIP;
begin
  Result.Long := Address.sin_addr.S_addr;
end;

function IPToStr(const IP: TIP): string;
begin
  Result := IntToStr(IP.b1) + '.' + IntToStr(IP.b2) + '.' + IntToStr(IP.b3) + '.' + IntToStr(IP.b4);
end;

function StrToIP(const Address: string): TIP;
var
  s: string;
  i, c: Integer;
begin
  i := 1;
  for c := 1 to 4 do
    begin
      s := '';
      while (i <= Length(Address)) and (Address[i] <> '.') do
        begin
          s := s + Address[i];
          Inc(i);
        end;
      Result.Bytes[c] := StrToInt(s);
      Inc(i);
    end;
end;

initialization

finalization
  repeat
    TThread.Sleep(10);
  until not CheckSynchronize;

end.


