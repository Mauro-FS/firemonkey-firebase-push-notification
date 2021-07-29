unit unMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Platform,

  {$IFDEF ANDROID}
  FMX.PushNotification.Android,
  {$ENDIF}
  {$IFDEF IOS}
  FMX.PushNotification.FCM.iOS,
  {$ENDIF}

  System.PushNotification, System.Notification;

type
  TfrmMain = class(TForm)
    memoLog: TMemo;
    NotificationCenter1: TNotificationCenter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    FPushService: TPushService;
    FPushServiceConnection: TPushServiceConnection;
    procedure registerDevice(token: string);
    procedure clearNotifications;
    procedure OnServiceConnectionChange(Sender: TObject;
      PushChanges: TPushService.TChanges);
    { Private declarations }
    procedure OnServiceConnectionReceiveNotification(Sender: TObject;
      const ServiceNotification: TPushServiceNotification);
    function AppEventProc(AAppEvent: TApplicationEvent;
      AContext: TObject): Boolean;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

function TfrmMain.AppEventProc(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin
  if (AAppEvent = TApplicationEvent.BecameActive) then
    clearNotifications;
end;

procedure TfrmMain.clearNotifications;
begin
  NotificationCenter1.CancelAll;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
var
  Notifications : TArray<TPushServiceNotification>;
  x : integer;
  msg : string;
begin
// receive notification with the app closed
  Notifications := FPushService.StartupNotifications; // notifications that opened the app

  if Length(Notifications) > 0 then
  begin
    for x := 0 to Notifications[0].DataObject.Count - 1 do
    begin
      memoLog.lines.Add(Notifications[0].DataObject.Pairs[x].JsonString.Value + ' = ' +
                       Notifications[0].DataObject.Pairs[x].JsonValue.Value);

       //pair manually added to the firebase
      if Notifications[0].DataObject.Pairs[x].JsonString.Value = 'mensagem' then
          msg := Notifications[0].DataObject.Pairs[x].JsonValue.Value;
    end;
  end;

  if msg <> '' then
      ShowMessage(msg);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  AppEvent : IFMXApplicationEventService;
begin
  // Events of the app (para exclusao das notificacoes)...
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(AppEvent)) then
      AppEvent.SetApplicationEventHandler(AppEventProc);

  FPushService := TPushServiceManager.Instance.GetServiceByName(TPushService.TServiceNames.FCM);
  FPushServiceConnection := TPushServiceConnection.Create(FPushService);

  FPushServiceConnection.OnChange := OnServiceConnectionChange;
  FPushServiceConnection.OnReceiveNotification := OnServiceConnectionReceiveNotification;

  FPushServiceConnection.Active := True;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FPushServiceConnection.Free;
end;

procedure TfrmMain.OnServiceConnectionChange(Sender: TObject;
  PushChanges: TPushService.TChanges);
var
  token : string;
begin
  if TPushService.TChange.Status in PushChanges then
  begin
    if FPushService.Status = TPushService.TStatus.Started then
    begin
      memoLog.Lines.Add('push service started successfully ');
      memoLog.Lines.Add('----');
    end
    else
    if FPushService.Status = TPushService.TStatus.StartupError then
    begin
      FPushServiceConnection.Active := False;

      memoLog.Lines.Add('push service failed to start');
      memoLog.Lines.Add(FPushService.StartupError);
      memoLog.Lines.Add('----');
    end;
  end;

  if TPushService.TChange.DeviceToken in PushChanges then
  begin
    token := FPushService.DeviceTokenValue[TPushService.TDeviceTokenNames.DeviceToken];

    memoLog.Lines.Add('Token do aparelho recebido');
    memoLog.Lines.Add('Token: ' + token);
    memoLog.Lines.Add('---');
    memoLog.Lines.EndUpdate;

    RegisterDevice(token);
  end;
end;

procedure TfrmMain.OnServiceConnectionReceiveNotification(Sender: TObject;
  const ServiceNotification: TPushServiceNotification);
var
  x: integer;
  msg: string;
begin
  // receive notifciations with the app open...
  memoLog.Lines.Add('Push received');
  memoLog.Lines.Add('DataKey: ' + ServiceNotification.DataKey);
  memoLog.Lines.Add('Json: ' + ServiceNotification.Json.ToString);
  memoLog.Lines.Add('DataObject: ' + ServiceNotification.DataObject.ToString);
  memoLog.Lines.Add('---');

  {
  for x := 0 to ServiceNotification.DataObject.Count - 1 do
  begin
      memLog.lines.Add(ServiceNotification.DataObject.Pairs[x].JsonString.Value + ' = ' +
                       ServiceNotification.DataObject.Pairs[x].JsonValue.Value);

      if ServiceNotification.DataObject.Pairs[x].JsonString.Value = 'mensagem' then
              msg := ServiceNotification.DataObject.Pairs[x].JsonValue.Value;
  end;

  if msg <> '' then
      ShowMessage(msg);
  }
end;

procedure TfrmMain.registerDevice(token: string);
begin
  // save token from the device on your server
  // send the token to the server and save it
end;

end.
