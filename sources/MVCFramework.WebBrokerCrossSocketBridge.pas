// ***************************************************************************
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2020 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// THIS UNIT HAS BEEN INSPIRED BY IdHTTPWebBrokerBridge.pas
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************** }

unit MVCFramework.WebBrokerCrossSocketBridge;

interface

uses
  System.Classes,
  Web.HTTPApp,
  System.SysUtils,
  Web.WebBroker,
  WebReq,
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Serializer.Commons,
  MVCFramework.Logger,
  Net.CrossHttpServer;

type
  ECrossSocketWebBrokerBridgeException = class(EMVCException);

  ECrossSocketInvalidIdxGetVariable = class(ECrossSocketWebBrokerBridgeException)

  end;

  ECrossSocketInvalidIdxSetVariable = class(ECrossSocketWebBrokerBridgeException)

  end;

  ECrossSocketInvalidStringVar = class(ECrossSocketWebBrokerBridgeException)

  end;

  TCrossSocketHTTPAppRequest = class(TWebRequest)
  private
    fRequest: ICrossHttpRequest;
  protected
    fBody: TBytes;
    function GetDateVariable(Index: Integer): TDateTime; override;
    function GetIntegerVariable(Index: Integer): Integer; override;
    function GetStringVariable(Index: Integer): string; override;
    function GetRemoteIP: string; override;
    function GetRawPathInfo: string; override;
    function GetRawContent: TBytes; override;
  public
    constructor Create(const ARequest: ICrossHttpRequest);
    destructor Destroy; override;
    function GetFieldByName(const Name: string): string; override;
    function ReadClient(var Buffer; Count: Integer): Integer; override;
    function ReadString(Count: Integer): string; override;
    function TranslateURI(const URI: string): string; override;
    function WriteClient(var ABuffer; ACount: Integer): Integer; override;
    function WriteHeaders(StatusCode: Integer; const ReasonString, Headers: string): Boolean; override;
    function WriteString(const AString: string): Boolean; override;
  end;

  TCrossSocketHTTPAppResponse = class(TWebResponse)
  private
    fResponse: ICrossHttpResponse;
    fStatusCode: Integer;
  protected
    fContent: string;
    fSent: Boolean;
    function GetContent: string; override;
    function GetDateVariable(Index: Integer): TDateTime; override;
    function GetStatusCode: Integer; override;
    function GetIntegerVariable(Index: Integer): Integer; override;
    function GetLogMessage: string; override;
    function GetStringVariable(Index: Integer): string; override;
    procedure SetContent(const AValue: string); override;
    procedure SetContentStream(AValue: TStream); override;
    procedure SetStatusCode(AValue: Integer); override;
    procedure SetStringVariable(Index: Integer; const Value: string); override;
    procedure SetDateVariable(Index: Integer; const Value: TDateTime); override;
    procedure SetIntegerVariable(Index: Integer; Value: Integer); override;
    procedure SetLogMessage(const Value: string); override;
    procedure MergeHeaders;
  public
    procedure SendRedirect(const URI: string); override;
    procedure SendResponse; override;
    procedure SendStream(AStream: TStream); override;
    function Sent: Boolean; override;
    constructor Create( { ARequest: TWebRequest; } AResponse: ICrossHttpResponse);
  end;

  TCrossSocketWebBrokerBridge = class(TObject)
  private
    fActive: Boolean;
    fHttpServer: ICrossHttpServer;
    fDefaultPort: UInt16;
    procedure SetActive(const Value: Boolean);
    procedure SetDefaultPort(const Value: UInt16);
  public
    constructor Create(const UseSSL: Boolean = False); virtual;
    destructor Destroy; override;
    property Active: Boolean read fActive write SetActive;
    property DefaultPort: UInt16 read fDefaultPort write SetDefaultPort;
  end;

implementation

uses
  Math, Net.CrossSocket.Base, Net.CrossHttpParams, System.NetEncoding,
  IdGlobal, System.DateUtils, System.IOUtils;

const
  RespIDX_Version = 0;
  RespIDX_ReasonString = 1;
  RespIDX_Server = 2;
  RespIDX_WWWAuthenticate = 3;
  RespIDX_Realm = 4;
  RespIDX_Allow = 5;
  RespIDX_Location = 6;
  RespIDX_ContentEncoding = 7;
  RespIDX_ContentType = 8;
  RespIDX_ContentVersion = 9;
  RespIDX_DerivedFrom = 10;
  RespIDX_Title = 11;
  RespIDX_ContentLength = 0;
  RespIDX_Date = 0;
  RespIDX_Expires = 1;
  RespIDX_LastModified = 2;

  ReqIDX_Method = 0;
  ReqIDX_ProtocolVersion = 1;
  ReqIDX_URL = 2;
  ReqIDX_Query = 3;
  ReqIDX_PathInfo = 4;
  ReqIDX_PathTranslated = 5;
  ReqIDX_CacheControl = 6;
  ReqIDX_Date = 7;
  ReqIDX_Accept = 8;
  ReqIDX_From = 9;
  ReqIDX_Host = 10;
  ReqIDX_IfModifiedSince = 11;
  ReqIDX_Referer = 12;
  ReqIDX_UserAgent = 13;
  ReqIDX_ContentEncoding = 14;
  ReqIDX_ContentType = 15;
  ReqIDX_ContentLength = 16;
  ReqIDX_ContentVersion = 17;
  ReqIDX_DerivedFrom = 18;
  ReqIDX_Expires = 19;
  ReqIDX_Title = 20;
  ReqIDX_RemoteAddr = 21;
  ReqIDX_RemoteHost = 22;
  ReqIDX_ScriptName = 23;
  ReqIDX_ServerPort = 24;
  ReqIDX_Content = 25;
  ReqIDX_Connection = 26;
  ReqIDX_Cookie = 27;
  ReqIDX_Authorization = 28;

constructor TCrossSocketHTTPAppRequest.Create(const ARequest: ICrossHttpRequest);
begin
  fRequest := ARequest;
  inherited Create;

  if fRequest.PostDataSize > 0 then
  begin
    case fRequest.BodyType of
      btBinary:
        begin
          SetLength(fBody, ARequest.ContentLength);
          TBytesStream(fRequest.Body).Read(fBody, Length(fBody));
        end;
    else
      SetLength(fBody, 0);
    end;
    // fContentStream := TBytesStream.Create([]);
    // if fRequest.BodyType = btBinary then
    // begin
    // TBytesStream(fRequest.Body).Position := 0;
    // fContentStream.Write(TBytesStream(fRequest.Body).Bytes, ARequest.ContentLength);
    // fContentStream.Position := 0;
    // fconte
    // end;
  end;
  // else
  // begin
  // if FRequestInfo.FormParams <> '' then
  // begin { do not localize }
  // // an input form that was submitted as "application/www-url-encoded"...
  // fContentStream := TStringStream.Create(FRequestInfo.FormParams);
  // end
  // else
  // begin
  // // anything else for now...
  // fContentStream := TStringStream.Create(FRequestInfo.UnparsedParams);
  // end;
  // FFreeContentStream := True;
  // end;

  // FThread := AThread;
  // FRequestInfo := ARequestInfo;
  // FResponseInfo := AResponseInfo;
  // inherited Create;
  // for i := 0 to ARequestInfo.Cookies.Count - 1 do
  // begin
  // CookieFields.Add(ARequestInfo.Cookies[i].ClientCookie);
  // end;
  // if Assigned(FRequestInfo.PostStream) then
  // begin
  // FContentStream := FRequestInfo.PostStream;
  // FFreeContentStream := False;
  // end
  // else
  // begin
  // if FRequestInfo.FormParams <> '' then
  // begin { do not localize }
  // // an input form that was submitted as "application/www-url-encoded"...
  // FContentStream := TStringStream.Create(FRequestInfo.FormParams);
  // end
  // else
  // begin
  // // anything else for now...
  // FContentStream := TStringStream.Create(FRequestInfo.UnparsedParams);
  // end;
  // FFreeContentStream := True;
  // end;
end;

destructor TCrossSocketHTTPAppRequest.Destroy;
begin
  inherited;
end;

function TCrossSocketHTTPAppRequest.GetDateVariable(Index: Integer): TDateTime;
var
  lValue: string;
begin
  lValue := string(GetStringVariable(Index));
  if Length(lValue) > 0 then
  begin
    Result := ParseDate(lValue);
  end
  else
  begin
    Result := -1;
  end;
end;

function TCrossSocketHTTPAppRequest.GetIntegerVariable(Index: Integer): Integer;
begin
  Result := StrToIntDef(string(GetStringVariable(Index)), -1)
end;

function TCrossSocketHTTPAppRequest.GetRawPathInfo: string;
begin
  // Result := fRequest.URI;
  raise Exception.Create('DMVCFramework Not Implemented');
end;

function TCrossSocketHTTPAppRequest.GetRemoteIP: string;
begin
  Result := fRequest.Connection.PeerAddr;
  // Result := fRequest.RemoteIP;
  // raise Exception.Create('DMVCFramework Not Implemented');
end;

function TCrossSocketHTTPAppRequest.GetRawContent: TBytes;
begin
  Result := fBody;
end;

function TCrossSocketHTTPAppRequest.GetStringVariable(Index: Integer): string;
begin
  case Index of
    ReqIDX_Method:
      Result := fRequest.Method;
    ReqIDX_ProtocolVersion:
      Result := fRequest.Version;
    ReqIDX_URL:
      Result := fRequest.Path;
    ReqIDX_Query:
      fRequest.Params.ToString;
    ReqIDX_PathInfo:
      Result := fRequest.Path;
    ReqIDX_PathTranslated:
      Result := fRequest.Path;
    ReqIDX_CacheControl:
      Result := fRequest.Header.Params['Cache-Control']; { do not localize }
    ReqIDX_Date:
      Result := fRequest.Header.Params['Date']; { do not localize }
    ReqIDX_Accept:
      Result := fRequest.Accept;
    ReqIDX_From:
      Result := fRequest.Header.Params['From'];
    ReqIDX_Host:
      Result := fRequest.HostName;
    ReqIDX_IfModifiedSince:
      Result := fRequest.Header.Params['If-Modified-Since']; { do not localize }
    ReqIDX_Referer:
      Result := fRequest.Referer;
    ReqIDX_UserAgent:
      Result := fRequest.UserAgent;
    ReqIDX_ContentEncoding:
      Result := fRequest.ContentEncoding;
    ReqIDX_ContentType:
      Result := fRequest.ContentType;
    ReqIDX_ContentLength:
      Result := IntToStr(fRequest.PostDataSize);
    ReqIDX_ContentVersion:
      Result := fRequest.Header.Params['Content-Version']; { do not localize }
    ReqIDX_DerivedFrom:
      Result := fRequest.Header.Params['Derived-From']; { do not localize }
    ReqIDX_Expires:
      Result := fRequest.Header.Params['Expires']; { do not localize }
    ReqIDX_Title:
      Result := fRequest.Header.Params['Title']; { do not localize }
    ReqIDX_RemoteAddr:
      Result := fRequest.Connection.PeerAddr;
    ReqIDX_RemoteHost:
      Result := fRequest.Connection.PeerAddr;
    ReqIDX_ScriptName:
      Result := '';
    ReqIDX_ServerPort:
      Result := fRequest.Connection.PeerPort.ToString;
    ReqIDX_Connection:
      Result := fRequest.Header.Params['Connection']; { do not localize }
    ReqIDX_Cookie:
      Result := fRequest.Header.Params['Cookie']; { do not localize }
    ReqIDX_Authorization:
      Result := fRequest.Header.Params['Authorization']; { do not localize }
  else
    Result := '';
  end;
end;

function TCrossSocketHTTPAppRequest.GetFieldByName(const Name: string): string;
begin
  fRequest.Header.GetParamValue(Name, Result);
end;

function TCrossSocketHTTPAppRequest.ReadClient(var Buffer; Count: Integer): Integer;
begin
  raise Exception.Create('not implemented - ReadClient');
  // Result := fContentStream.Read(Buffer, Count);
  // // well, it shouldn't be less than 0. but let's not take chances
  // if Result < 0 then
  // begin
  // Result := 0;
  // end;
end;

function TCrossSocketHTTPAppRequest.ReadString(Count: Integer): string;
begin
  raise Exception.Create('not implemented - ReadString');
end;

// function TCrossSocketHTTPAppRequest.ReadString(Count: Integer):
// {$IFDEF WBB_ANSI}AnsiString{$ELSE}string{$ENDIF};
// {$IFDEF WBB_ANSI}
// var
// LBytes: TIdBytes;
// {$ENDIF}
// begin
// {$IFDEF WBB_ANSI}
//
// // RLebeau 2/21/2009: not using ReadStringFromStream() anymore.  Since
// // this method returns an AnsiString, the stream data should not be
// // decoded to Unicode and then converted to Ansi.  That can lose
// // characters.
//
// // Result := AnsiString(ReadStringFromStream(FContentStream, Count));
//
// LBytes := nil;
// TIdStreamHelper.ReadBytes(FContentStream, LBytes, Count);
//
// {$IFDEF DOTNET}
// // RLebeau: how to handle this correctly in .NET?
// Result := AnsiString(BytesToStringRaw(LBytes));
// {$ELSE}
// SetString(Result, PAnsiChar(LBytes), Length(LBytes));
// {$IFDEF HAS_SetCodePage}
// // RLebeau 2/21/2009: For D2009+, the AnsiString payload should have
// // the proper codepage assigned to it as well so it can be converted
// // correctly if assigned to other string variables later on...
// SetCodePage(PRawByteString(@Result)^, CharsetToCodePage(FRequestInfo.CharSet), False);
// {$ENDIF}
// {$ENDIF}
// {$ELSE}
// // RLebeau 1/15/2016: this method now returns a UnicodeString, so
// // lets use ReadStringFromStream() once again...
// Result := ReadStringFromStream(FContentStream, Count, CharsetToEncoding(FRequestInfo.CharSet));
//
// {$ENDIF}
// end;

function TCrossSocketHTTPAppRequest.TranslateURI(const URI: string): string;
begin
  Result := URI;
end;

function TCrossSocketHTTPAppRequest.WriteHeaders(StatusCode: Integer; const ReasonString, Headers: string): Boolean;
begin
  raise Exception.Create('not implemented - WriteHeaders');
  // FResponseInfo.ResponseNo := StatusCode;
  // FResponseInfo.ResponseText := {$IFDEF WBB_ANSI}string(ReasonString){$ELSE}ReasonString{$ENDIF};
  // FResponseInfo.CustomHeaders.Add({$IFDEF WBB_ANSI}string(Headers){$ELSE}Headers{$ENDIF});
  // FResponseInfo.WriteHeader;
  // Result := True;
end;

function TCrossSocketHTTPAppRequest.WriteString(const AString: string): Boolean;
begin
  raise Exception.Create('not implemented - WriteString');
end;

function TCrossSocketHTTPAppRequest.WriteClient(var ABuffer; ACount: Integer): Integer;
begin
  raise Exception.Create('not implemented - WriteClient');
  // SetLength(LBuffer, ACount);
  // {$IFNDEF CLR}
  // Move(ABuffer, LBuffer[0], ACount);
  // {$ELSE}
  // // RLebeau: this can't be right?  It is interpretting the source as a
  // // null-terminated character string, which is likely not the case...
  // CopyTIdBytes(ToBytes(string(ABuffer)), 0, LBuffer, 0, ACount);
  // {$ENDIF}
  // FThread.Connection.IOHandler.Write(LBuffer);
  // Result := ACount;
end;

{ TIdHTTPAppResponse }

constructor TCrossSocketHTTPAppResponse.Create(AResponse: ICrossHttpResponse);
begin
  inherited Create(nil);
  // fRequest := ARequest;
  fResponse := AResponse;
  StatusCode := http_status.OK;
end;

function TCrossSocketHTTPAppResponse.GetContent: string;
begin
  raise Exception.Create('not implemented - GetContent');
end;

function TCrossSocketHTTPAppResponse.GetLogMessage: string;
begin
  raise Exception.Create('not implemented - GetLogMessage');
end;

function TCrossSocketHTTPAppResponse.GetStatusCode: Integer;
begin
  Result := fStatusCode;
end;

function TCrossSocketHTTPAppResponse.GetDateVariable(Index: Integer): TDateTime;
  function ToGMT(ADateTime: TDateTime): TDateTime;
  begin
    Result := ADateTime;
    if Result <> -1 then
      Result := Result - OffsetFromUTC;
  end;

begin
  case Index of
    RespIDX_Date:
      Result := ToGMT(ISOTimeStampToDateTime(fResponse.Header.Params['Date']));
    RespIDX_Expires:
      Result := ToGMT(ISOTimeStampToDateTime(fResponse.Header.Params['Expires']));
    RespIDX_LastModified:
      Result := ToGMT(ISOTimeStampToDateTime(fResponse.Header.Params['LastModified']));
  else
    raise ECrossSocketInvalidIdxGetVariable.Create(Format('Invalid Index for GetDateVariable: %d', [Index]));
  end;
end;

procedure TCrossSocketHTTPAppResponse.SetDateVariable(Index: Integer; const Value: TDateTime);
// WebBroker apps are responsible for conversion to GMT
  function ToLocal(ADateTime: TDateTime): TDateTime;
  begin
    Result := ADateTime;
    if Result <> -1 then
      Result := Result + OffsetFromUTC;
  end;

begin
  case Index of
    RespIDX_Date:
      fResponse.Header.Params['Date'] := DateTimeToISOTimeStamp(ToLocal(Value));
    RespIDX_Expires:
      fResponse.Header.Params['Expires'] := DateTimeToISOTimeStamp(ToLocal(Value));
    RespIDX_LastModified:
      fResponse.Header.Params['LastModified'] := DateTimeToISOTimeStamp(ToLocal(Value));
  else
    raise ECrossSocketInvalidIdxSetVariable.Create(Format('Invalid Index for SetDateVariable: %d', [Index]));
  end;
end;

function TCrossSocketHTTPAppResponse.GetIntegerVariable(Index: Integer): Integer;
begin
  case Index of
    RespIDX_ContentLength:
      Result := fResponse.Header.Params['Content-Length'].ToInt64;
  else
    raise ECrossSocketInvalidIdxGetVariable.Create(Format('Invalid Index for GetIntegerVariable: %d', [Index]));
  end;
end;

procedure TCrossSocketHTTPAppResponse.SetIntegerVariable(Index, Value: Integer);
begin
  case Index of
    RespIDX_ContentLength:
      fResponse.Header.Params['Content-Length'] := Value.ToString;
  else
    raise ECrossSocketInvalidIdxSetVariable.Create(Format('Invalid Index for SetIntegerVariable: %d', [Index]));
  end;
end;

function TCrossSocketHTTPAppResponse.GetStringVariable(Index: Integer): string;
begin
  case Index of
    // RespIDX_Version:
    // Result := fRequest.ProtocolVersion;
    RespIDX_ReasonString:
      Result := fResponse.ReasonString;
    RespIDX_Server:
      Result := fResponse.Header.Params['Server'];
    RespIDX_WWWAuthenticate:
      raise Exception.Create('Not Implemented');
    // Result := fResponse.WWWAuthenticate.Text;
    RespIDX_Realm:
      raise Exception.Create('Not Implemented');
    // Result := fResponse.AuthRealm;
    RespIDX_Allow:
      Result := fResponse.Header.Params['Allow']; { do not localize }
    RespIDX_Location:
      Result := fResponse.Location;
    RespIDX_ContentEncoding:
      Result := fResponse.Header.Params['content-encoding'];
    // Result := fResponse.ContentEncoding;
    RespIDX_ContentType:
      begin
        // if FContentType <> '' then
        // begin
        // Result := FContentType;
        // Exit;
        // end;
        Result := fResponse.ContentType;
      end;
    RespIDX_ContentVersion:
      Result := fResponse.Header.Params['Content-Version'];
    RespIDX_DerivedFrom:
      Result := fResponse.Header.Params['Derived-From'];
    RespIDX_Title:
      Result := fResponse.Header.Params['Title'];
  else
    raise ECrossSocketInvalidIdxGetVariable.Create(Format('Invalid Index for GetStringVariable: %d', [Index]));
  end;
end;

procedure TCrossSocketHTTPAppResponse.SetStringVariable(Index: Integer; const Value: string);
begin
  case Index of
    RespIDX_ReasonString:
      fResponse.ReasonString := Value;
    RespIDX_Server:
      fResponse.Header.Params['server'] := Value;
    RespIDX_WWWAuthenticate:
      raise Exception.Create('Not Implemented');
    // fResponse.WWWAuthenticate.Text := LValue;
    RespIDX_Realm:
      raise Exception.Create('Not Implemented');
    // fResponse.AuthRealm := LValue;
    RespIDX_Allow:
      fResponse.Header.Params['Allow'] := Value;
    RespIDX_Location:
      fResponse.Location := Value;
    RespIDX_ContentEncoding:
      fResponse.Header.Params['Content-Encoding'] := Value;
    RespIDX_ContentType:
      fResponse.ContentType := Value;
    RespIDX_ContentVersion:
      fResponse.Header.Params['Content-Version'] := Value;
    RespIDX_DerivedFrom:
      fResponse.Header.Params['Derived-From'] := Value;
    RespIDX_Title:
      fResponse.Header.Params['Title'] := Value;
  else
    raise ECrossSocketInvalidIdxSetVariable.Create(Format('Invalid Index for SetStringVariable: %d', [Index]));
  end;
end;

procedure TCrossSocketHTTPAppResponse.SendRedirect(const URI: string);
begin
  if fSent then
    Exit;
  fSent := True;
  MergeHeaders;
  fResponse.Redirect(URI);
end;

procedure TCrossSocketHTTPAppResponse.SendResponse;
var
  lBytes: TBytesStream;
begin
  if fSent then
    Exit;
  fSent := True;
  // Reset to -1 so Indy will auto set it
  // fResponse.ContentLength := -1;
  MergeHeaders;
  // if (fResponse.ContentType = '') and
  // ((fResponse.ContentText <> '') or (Assigned(FResponseInfo.ContentStream))) and
  // (HTTPApp.DefaultCharSet <> '') then
  // begin
  // // Indicate how to convert UTF16 when write.
  // ContentType := Format('text/html; charset=%s', [HTTPApp.DefaultCharSet]); { Do not Localize }
  // end;
  // fResponse.ContentType := fContentType;

  if (ContentStream <> nil) and (ContentStream.Size > 0) then
  begin
    fResponse.StatusCode := StatusCode;
    ContentStream.Position := 0;
//    if TFile.Exists('output.dat') then
//      TFile.Delete('output.dat');
//    var
//    fs := TFileStream.Create('output.dat', fmCreate);
//    try
//      fs.CopyFrom(ContentStream, 0);
//    finally
//      fs.Free;
//    end;
//    ContentStream.Position := 0;
    if ContentStream is TFileStream then
    begin
      var l := TMemoryStream.Create;
      l.CopyFrom(ContentStream,0);
      l.Position := 0;
      SetContentStream(l);
    end;

    fResponse.Send(ContentStream, 0, ContentStream.Size,
      procedure(const AConnection: ICrossConnection; const ASuccess: Boolean)
      begin
        // AConnection.SendStream(ContentStream)
      end);

    // fResponse.Send(lBytes.Bytes, 0, lBytes.Size,
    // procedure(const AConnection: ICrossConnection; const ASuccess: Boolean)
    // begin
    // lBytes.Free;
    // end);
     //fResponse.SendFile('C:\DEV\dmvcframework\unittests\general\TestServer\bin\www\index.html')
  end
  else
  begin
    fResponse.SendStatus(StatusCode, '');
  end;
end;

procedure TCrossSocketHTTPAppResponse.SendStream(AStream: TStream);
begin
  SetContentStream(AStream);
  SendResponse;
end;

function TCrossSocketHTTPAppResponse.Sent: Boolean;
begin
  Result := fSent;
end;

procedure TCrossSocketHTTPAppResponse.SetContent(const AValue: string);
begin
  SetContentStream(TStringStream.Create(AValue));
end;

procedure TCrossSocketHTTPAppResponse.SetLogMessage(const Value: string);
begin
  // logging not supported
end;

procedure TCrossSocketHTTPAppResponse.SetStatusCode(AValue: Integer);
begin
  fStatusCode := AValue;
end;

procedure TCrossSocketHTTPAppResponse.SetContentStream(AValue: TStream);
begin
  inherited SetContentStream(AValue);
  // fResponse.Header.Add('content-length', AValue.Size.ToString, False);
  // FResponseInfo.ContentStream := AValue;
end;

function DoHTTPEncode(const AStr: string): String;
begin
  Result := TNetEncoding.URL.Encode(string(AStr));
end;

procedure TCrossSocketHTTPAppResponse.MergeHeaders;
var
  i: Integer;
  lSrcCookie: TCookie;
begin
  for i := 0 to Cookies.Count - 1 do
  begin
    lSrcCookie := Cookies[i];
    fResponse.Cookies.AddOrSet(lSrcCookie.Name, lSrcCookie.Value, SecondsBetween(Now, lSrcCookie.Expires),
      lSrcCookie.Path, lSrcCookie.Domain, lSrcCookie.HttpOnly, lSrcCookie.Secure);
    // LDestCookie := FResponseInfo.Cookies.Add;
    // LDestCookie.CookieName := DoHTTPEncode(LSrcCookie.Name);
    // LDestCookie.Value := DoHTTPEncode(LSrcCookie.Value);
    // LDestCookie.Domain := String(LSrcCookie.Domain);
    // LDestCookie.Path := String(LSrcCookie.Path);
    // LDestCookie.Expires := LSrcCookie.Expires;
    // LDestCookie.Secure := LSrcCookie.Secure;
  end;
  for i := 0 to CustomHeaders.Count - 1 do
  begin
    fResponse.Header.Add(CustomHeaders.Names[i], CustomHeaders.ValueFromIndex[i]);
  end;
end;

{ TIdHTTPWebBrokerBridge }

// procedure TIdHTTPWebBrokerBridge.InitComponent;
// begin
// inherited InitComponent;
// // FOkToProcessCommand := True;
// end;

type
  TCrossSocketWebBrokerBridgeRequestHandler = class(TWebRequestHandler)
  private
    class var FWebRequestHandler: TCrossSocketWebBrokerBridgeRequestHandler;
  public
    constructor Create(AOwner: TComponent); override;
    class destructor Destroy;
    destructor Destroy; override;
    procedure Run(const ARequest: ICrossHttpRequest; const AResponse: ICrossHttpResponse);
  end;

procedure TCrossSocketWebBrokerBridgeRequestHandler.Run(const ARequest: ICrossHttpRequest;
const AResponse: ICrossHttpResponse);
var
  lRequest: TCrossSocketHTTPAppRequest;
  lResponse: TCrossSocketHTTPAppResponse;
begin
  try
    lRequest := TCrossSocketHTTPAppRequest.Create(ARequest);
    try
      lResponse := TCrossSocketHTTPAppResponse.Create( { lRequest, } AResponse);
      try
        lResponse.FreeContentStream := True;
        HandleRequest(lRequest, lResponse);
      finally
        FreeAndNil(lResponse);
      end;
    finally
      FreeAndNil(lRequest);
    end;
  except
    // Let DMVCFramework handle this exception
    raise;
  end;
end;

constructor TCrossSocketWebBrokerBridgeRequestHandler.Create(AOwner: TComponent);
begin
  inherited;
  System.Classes.ApplicationHandleException := HandleException;
end;

destructor TCrossSocketWebBrokerBridgeRequestHandler.Destroy;
begin
  System.Classes.ApplicationHandleException := nil;
  inherited;
end;

class destructor TCrossSocketWebBrokerBridgeRequestHandler.Destroy;
begin
  FreeAndNil(FWebRequestHandler);
end;

function CrossSocketWebBrokerBridgeRequestHandler: TWebRequestHandler;
begin
  if not Assigned(TCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler) then
    TCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler :=
      TCrossSocketWebBrokerBridgeRequestHandler.Create(nil);
  Result := TCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler;
end;

// procedure TCrossSocketWebBrokerBridge.InternalHandleRequest(const ARequest: ICrossHttpRequest;
// const AResponse: ICrossHttpResponse);
// begin
// if fWebModuleClass <> nil then
// begin
// RunWebModuleClass(ARequest, AResponse)
// end
// else
// begin
// TCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler.Run(ARequest, AResponse);
// end;
// LogI(AResponse.Sent.ToString(TUseBoolStrs.True));
// end;

// procedure TCrossSocketWebBrokerBridge.CreateInternalRouter;
// begin
// fHttpServer.All('*',
// procedure(const ARequest: ICrossHttpRequest; const AResponse: ICrossHttpResponse; var AHandled: Boolean)
// begin
// // TCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler.Run(ARequest, AResponse);
// AResponse.Send('0123456789');
// end);
// end;

destructor TCrossSocketWebBrokerBridge.Destroy;
begin
  fHttpServer.Stop();
  inherited;
end;

procedure TCrossSocketWebBrokerBridge.SetActive(const Value: Boolean);
begin
  if fHttpServer.Active = Value then
  begin
    Exit;
  end;
  if Value then
  begin
    // {$IFDEF __CROSS_SSL__}
    // if FHttpServer.SSL then
    // begin
    // FHttpServer.SetCertificate(SSL_SERVER_CERT);
    // FHttpServer.SetPrivateKey(SSL_SERVER_PKEY);
    // end;
    // {$ENDIF}
    // FHttpServer.Addr := IPv4_ALL; // IPv4
    // FHttpServer.Addr := IPv4_LOCAL; // IPv4
    // FHttpServer.Addr := IPv6_ALL; // IPv6
    fHttpServer.Addr := IPv4v6_ALL; // IPv4v6
    fHttpServer.Port := fDefaultPort;
    fHttpServer.Compressible := False;
    fHttpServer.All('*',
      procedure(const ARequest: ICrossHttpRequest; const AResponse: ICrossHttpResponse; var AHandled: Boolean)
      begin
        TCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler.Run(ARequest, AResponse);
        AHandled := True;
      end).Start()
  end
  else
  begin
    fHttpServer.ClearRouter.Stop;
  end;
end;

procedure TCrossSocketWebBrokerBridge.SetDefaultPort(const Value: UInt16);
begin
  fDefaultPort := Value;
end;

constructor TCrossSocketWebBrokerBridge.Create(const UseSSL: Boolean);
begin
  inherited Create;
  fHttpServer := TCrossHttpServer.Create(0, UseSSL);
end;

initialization

WebReq.WebRequestHandlerProc := CrossSocketWebBrokerBridgeRequestHandler;

finalization

FreeAndNil(TCrossSocketWebBrokerBridgeRequestHandler.FWebRequestHandler);

end.
