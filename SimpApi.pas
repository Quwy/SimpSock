unit SimpApi;

interface

{$IFDEF FPC}
  {$IFDEF MSWINDOWS}
    {$I inc/fpc.win32.units.inc}
    {$I inc/fpc.win32.globals.inc}
  {$ELSE}
    {$I inc/fpc.posix.units.inc}
    {$I inc/fpc.posix.globals.inc}
  {$ENDIF}
{$ELSE}
  {$IFDEF MSWINDOWS}
    {$I inc/dcc.win32.units.inc}
    {$I inc/dcc.win32.globals.inc}
  {$ELSE}
    {$I inc/dcc.posix.units.inc}
    {$I inc/dcc.posix.globals.inc}
  {$ENDIF}
{$ENDIF}

{$I inc/api.interface.func.inc}

implementation

{$IFDEF FPC}
  {$IFDEF MSWINDOWS}
    {$I inc/fpc.win32.implementation.inc}
  {$ELSE}
    {$I inc/fpc.posix.implementation.inc}
  {$ENDIF}
{$ELSE}
  {$IFDEF MSWINDOWS}
    {$I inc/dcc.win32.implementation.inc}
  {$ELSE}
    {$I inc/dcc.posix.implementation.inc}
  {$ENDIF}
{$ENDIF}

end.
