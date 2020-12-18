unit Controllers.MainU;

interface

uses
  MVCFramework, MVCFramework.Commons, MVCFramework.Serializer.Commons;

type

  [MVCPath('/api')]
  TMyController = class(TMVCController)
  public
    [MVCPath]
    [MVCHTTPMethod([httpGET])]
    procedure Index;

    [MVCPath('/reversedstrings/($Value)')]
    [MVCHTTPMethod([httpGET])]
    procedure GetReversedString(const Value: String);

    [MVCPath('/entities')]
    [MVCHTTPMethod([httpPOST])]
    procedure CreateEntity;

    [MVCPath('/entities')]
    [MVCHTTPMethod([httpGET])]
    procedure GetEntities;

    [MVCPath('/setcookie')]
    [MVCHTTPMethod([httpGET])]
    procedure SetCookie;
  end;

  TEntity = class
  private
    FLastName: String;
    FFirstName: String;
    procedure SetFirstName(const Value: String);
    procedure SetLastName(const Value: String);
  public
    property FirstName: String read FFirstName write SetFirstName;
    property LastName: String read FLastName write SetLastName;
  end;

implementation

uses
  System.SysUtils, MVCFramework.Logger, System.StrUtils, System.Generics.Collections,
  Web.HTTPApp, System.DateUtils;

procedure TMyController.Index;
begin
  // use Context property to access to the HTTP request and response
  Render('Hello DelphiMVCFramework World');
end;

procedure TMyController.SetCookie;
var
  lCookie: TCookie;
begin
  lCookie := Context.Response.Cookies.Add;
  lCookie.Name := 'cookiename';
  lCookie.Value := 'cookievalue';
  lCookie.Domain := '/domain';
  lCookie.Path := '/path';
  lCookie.Path := '/path';
  lCookie.Expires := Now;
  lCookie.HttpOnly := True;

  lCookie := Context.Response.Cookies.Add;
  lCookie.Name := 'cookiename2';
  lCookie.Value := 'cookievalue2';
  lCookie.Domain := '/domain2';
  lCookie.Path := '/path2';
  lCookie.Path := '/path2';
  lCookie.Expires := Now + OneSecond;
  lCookie.HttpOnly := False;

end;

procedure TMyController.CreateEntity;
var
  lEntity: TEntity;
begin
  lEntity := Context.Request.BodyAs<TEntity>();
  try
    lEntity.FirstName := lEntity.FirstName + ' CHANGED';
    Render(lEntity, False);
  finally
    lEntity.Free;
  end;
end;

procedure TMyController.GetEntities;
var
  lEntity: TEntity;
  I: Integer;
  lList: TObjectList<TEntity>;
begin
  lList := TObjectList<TEntity>.Create(True);
  try
    for I := 1 to 10 do
    begin
      lEntity := TEntity.Create;
      lList.Add(lEntity);
      lList.Last.LastName := 'Teti' + I.ToString;
      lList.Last.FirstName := 'Daniele' + I.ToString;
    end;
    Render(ObjectDict(False).Add('data', lList))
  finally
    lList.Free;
  end;

end;

procedure TMyController.GetReversedString(const Value: String);
begin
  Render(System.StrUtils.ReverseString(Value.Trim));
end;

{ TEntity }

procedure TEntity.SetFirstName(const Value: String);
begin
  FFirstName := Value;
end;

procedure TEntity.SetLastName(const Value: String);
begin
  FLastName := Value;
end;

end.
