program CrossSocketSample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  MVCFramework.Logger,
  MVCFramework.Commons,
  MVCFramework.REPLCommandsHandlerU,
  Web.ReqMulti,
  Web.WebReq,
  Web.WebBroker,
  Controllers.MainU in 'Controllers.MainU.pas',
  WebModuleU in 'WebModuleU.pas' {MyWebModule: TWebModule},
  MVCFramework.WebBrokerCrossSocketBridge in '..\..\sources\MVCFramework.WebBrokerCrossSocketBridge.pas',
  Net.CrossSocket.Iocp in 'C:\DLib\Delphi-Cross-Socket\Net\Net.CrossSocket.Iocp.pas',
  Net.CrossHttpServer in 'C:\DLib\Delphi-Cross-Socket\Net\Net.CrossHttpServer.pas';

{$R *.res}

procedure RunServer(APort: Integer);
var
  LServer: TCrossSocketWebBrokerBridge;
  // LCustomHandler: TMVCCustomREPLCommandsHandler;
  LCmd: string;
begin
  Writeln('** DMVCFramework Server ** build ' + DMVCFRAMEWORK_VERSION);
  LCmd := 'start';
  if ParamCount >= 1 then
    LCmd := ParamStr(1);

  // LCustomHandler := function(const Value: String; const Server: TIdHTTPWebBrokerBridge; out Handled: Boolean): THandleCommandResult
  // begin
  // Handled := False;
  // Result := THandleCommandResult.Unknown;
  //
  // // Write here your custom command for the REPL using the following form...
  // // ***
  // // Handled := False;
  // // if (Value = 'apiversion') then
  // // begin
  // // REPLEmit('Print my API version number');
  // // Result := THandleCommandResult.Continue;
  // // Handled := True;
  // // end
  // // else if (Value = 'datetime') then
  // // begin
  // // REPLEmit(DateTimeToStr(Now));
  // // Result := THandleCommandResult.Continue;
  // // Handled := True;
  // // end;
  // end;

  LServer := TCrossSocketWebBrokerBridge.Create;
  try
    // LServer.OnParseAuthentication := TMVCParseAuthentication.OnParseAuthentication;
    LServer.DefaultPort := APort;
    // LServer.KeepAlive := True;

    { more info about MaxConnections
      http://ww2.indyproject.org/docsite/html/frames.html?frmname=topic&frmfile=index.html }
    // LServer.MaxConnections := 0;

    { more info about ListenQueue
      http://ww2.indyproject.org/docsite/html/frames.html?frmname=topic&frmfile=index.html }
    // LServer.ListenQueue := 200;
    { required if you use JWT middleware }
    // LServer.OnParseAuthentication := TMVCParseAuthentication.OnParseAuthentication;

    LServer.Active := True;
    Writeln('Write "quit" or "exit" to shutdown the server');
    // repeat
    // if LCmd.IsEmpty then
    // begin
    // Write('-> ');
    // ReadLn(LCmd)
    // end;
    // try
    // case HandleCommand(LCmd.ToLower, LServer, LCustomHandler) of
    // THandleCommandResult.Continue:
    // begin
    // Continue;
    // end;
    // THandleCommandResult.Break:
    // begin
    // Break;
    // end;
    // THandleCommandResult.Unknown:
    // begin
    // REPLEmit('Unknown command: ' + LCmd);
    // end;
    // end;
    // finally
    // LCmd := '';
    // end;
    // until False;
    ReadLn;
  finally
    LServer.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  IsMultiThread := True;
  try
    if WebRequestHandler <> nil then
      WebRequestHandler.WebModuleClass := WebModuleClass;
    WebRequestHandlerProc.MaxConnections := 1024;
    RunServer(8080);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;

end.
