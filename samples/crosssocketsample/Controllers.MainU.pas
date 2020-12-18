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
  System.SysUtils, MVCFramework.Logger, System.StrUtils;

procedure TMyController.Index;
begin
  // use Context property to access to the HTTP request and response
  Render('Hello DelphiMVCFramework World');
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
