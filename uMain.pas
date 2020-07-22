// �ۼ���: ����ȣ (skshpapa80@gmail.com)
// ���α׷��� : DirectShow ��������� ������ �÷��̾�
// �ۼ��� : 2015-11-11
// ������ : 2017-04-26
// ��α� : https://skshpapa80.tistory.com/
//
// Delphi XE ��ݿ��� �ۼ��Ǿ����� DirectShow9�� ����Ͽ�
// �������� �����Ű�� ������ �ҽ� �Դϴ�.
//
// 2016-01-26
// �ڸ� ��� �߰� TSmSAMI Ŭ������ �ڸ���� �߰� lbl_subtitle �� �ڸ� ǥ��
// TSmSAMI ���ͳݿ��� ���� �ҽ�

unit uMain;

interface

uses
    Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
    System.Classes, Vcl.Graphics,
    Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
    Vcl.ExtCtrls, uSAMI,
    {DirectShow ����� ActiveX ��� �߰�}
    Winapi.ActiveX, Winapi.DirectShow9, Winapi.DirectDraw, Vcl.Menus;

const
    WM_GRAPHEVENT = WM_APP + 1;

type
    TfrmMain = class(TForm)
        paScreen: TPanel;
        paControl: TPanel;
        btnOpen: TButton;
        btnPlay: TButton;
        btnStop: TButton;
        TrackBar1: TTrackBar;
        Timer1: TTimer;
        lbl_Subtitle: TLabel;
        Timer_Subtitle: TTimer;
        btnUp: TButton;
        btnDown: TButton;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
        procedure FormCreate(Sender: TObject);
        procedure FormDestroy(Sender: TObject);
        procedure btnOpenClick(Sender: TObject);
        procedure btnPlayClick(Sender: TObject);
        procedure btnStopClick(Sender: TObject);
        procedure FormShow(Sender: TObject);
        procedure FormClose(Sender: TObject; var Action: TCloseAction);
        procedure TrackBar1Change(Sender: TObject);
        procedure Timer1Timer(Sender: TObject);
        procedure Timer_SubtitleTimer(Sender: TObject);
        procedure FormResize(Sender: TObject);
        procedure btnDownClick(Sender: TObject);
        procedure btnUpClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    private
        { Private declarations }
        { DShow ���� }
        FilterGraph: IGraphBuilder; // ���ͱ׷���
        MediaControl: IMediaControl; // ������ ���, ����, ����
        MediaSeeking: IMediaSeeking; // ������ ���� ���� ����
        MediaPosition: IMediaPosition; // ������ ��� ��ġ
        VideoWindow: IVideoWindow; // �������� ����� ������
        MediaEvent: IMediaEventEx; // DSHOW �̺�Ʈ ����
        AvailableDS: Boolean;
        MediaLength: Double;
        LockTrack: Boolean;
        BasicAudio      : IBasicAudio; // Volume/Balance control.

        CurVol   : Integer;

        // ���� Ŭ���̿�
        VideoRenderOrgMethod: TWndMethod;
        procedure VideoRenderWndProc(var Msg: TMessage);

        Function SetupDs: Boolean;
        Function ShutDownDs: Boolean;

        procedure SetVolume(Value : Integer);
        Function  GetVolume:Integer;
    public
        { Public declarations }
    end;

var
    frmMain: TfrmMain;
    SmSAMI: TSmSAMI;

implementation

{$R *.dfm}
{ TfrmMain }

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    paScreen.WindowProc := VideoRenderOrgMethod;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
    // COM�� �ʱ�ȭ�Ѵ�.
    CoInitialize(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
    // COM�� �˴ٿ��Ų��.
    CoUninitialize;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
    if AvailableDS then
        VideoWindow.SetWindowPosition(0, 0, paScreen.Width, paScreen.Height);
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
    // ���� Ŭ���̿� �̺�Ʈ �Լ��� ������
    VideoRenderOrgMethod := paScreen.WindowProc;
    paScreen.WindowProc := VideoRenderWndProc;
end;

function TfrmMain.GetVolume: Integer;
var
    Vol : Integer;
begin
    // ���� ��� 0 �� �ִ� -10,000�� ����
    BasicAudio.get_Volume(Vol);
    Result := 100 - (Vol * -1);
end;

procedure TfrmMain.N1Click(Sender: TObject);
var
    ScreenState : LongBool;
begin
    if AvailableDS then begin
	    VideoWindow.get_FullScreenMode(ScreenState);
	    if ScreenState then begin
		    VideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
		    VideoWindow.put_WindowStyleEx(0);
		    VideoWindow.put_FullScreenMode(False);
		    VideoWindow.SetWindowPosition(0,0,paScreen.Width,paScreen.Height);
            N1.Checked := false;
	    end
        else begin
		    VideoWindow.put_WindowStyle(not(WS_BORDER or WS_CAPTION or WS_THICKFRAME));
		    VideoWindow.put_WindowStyleEx(not(WS_EX_CLIENTEDGE or WS_EX_STATICEDGE or WS_EX_WINDOWEDGE or WS_EX_DLGMODALFRAME) or WS_EX_TOPMOST);
		    VideoWindow.put_FullScreenMode(True);
		    VideoWindow.SetWindowPosition(0,0,Screen.Width,Screen.Height);
            N1.Checked := true;
	    end;
    end;
end;

procedure TfrmMain.SetVolume(Value: Integer);
var
    Vol : Integer;
begin
    // ���� ��� 0 �� �ִ� -10,000�� ����
    Vol := (100 - Value) * -100;
    BasicAudio.put_Volume(Vol);
end;

function TfrmMain.SetupDs: Boolean;
begin
    // DShow �� �ʱ�ȭ��
    Result := False;

    if Failed(CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC_SERVER,
      IID_IFilterGraph, FilterGraph)) then
        Exit; // ���ͱ׷����� �����Ѵ�.

    FilterGraph.QueryInterface(IID_IMediaControl, MediaControl);
    // ���ͱ׷����� �������̽�.
    FilterGraph.QueryInterface(IID_IVideoWindow, VideoWindow);

    // ������ �ʿ��� ��ü ����
    if Failed(FilterGraph.QueryInterface(IID_IMediaSeeking, MediaSeeking)) then
        Exit;
    if Failed(FilterGraph.QueryInterface(IID_IMediaPosition, MediaPosition)) then
        Exit;
    if Failed(FilterGraph.QueryInterface(IID_IMediaEventEx, MediaEvent)) then
        Exit;
    if Failed(FilterGraph.QueryInterface(IID_IBasicAudio, BasicAudio)) then
        Exit;

    AvailableDS := true;
    Result := true;
end;

function TfrmMain.ShutDownDs: Boolean;
begin
    // DShow �� ����
    if Assigned(MediaControl) then
        MediaControl.Stop;

    If Assigned(VideoWindow) then
    Begin
        VideoWindow.put_Visible(False);
        VideoWindow.put_Owner(0);
    End;

    if Assigned(SmSAMI) then
        SmSAMI.Free;

    VideoWindow := nil;
    MediaControl := nil;
    MediaSeeking := nil;
    MediaPosition := nil;
    MediaEvent := nil;
    BasicAudio := nil;
    FilterGraph := nil;

    Result := true;
end;

procedure TfrmMain.Timer1Timer(Sender: TObject);
var
    CurPos: Double;
begin
    // Ÿ�̸�ó������� Ʈ���� ������ �̵�
    if Assigned(MediaSeeking) then
    Begin
        MediaPosition.get_CurrentPosition(CurPos);

        LockTrack := true;
        TrackBar1.Position := trunc(CurPos);
        LockTrack := False;
    End;
end;

procedure TfrmMain.Timer_SubtitleTimer(Sender: TObject);
var
    Caption: String;
begin
    if SmSAMI.GetCaption(Caption, False) then
    begin
        if Caption <> '' then
            lbl_Subtitle.Caption := Caption;
    end;
end;

procedure TfrmMain.TrackBar1Change(Sender: TObject);
begin
    if AvailableDS then begin
        if not LockTrack then begin
            MediaPosition.put_CurrentPosition(TrackBar1.Position);
            //SetMediaPosition(TrackBar1.Position, true);

            if Assigned(SmSAMI) then
                SmSAMI.SetPosition(TrackBar1.Position);
        end;
    end;
end;

procedure TfrmMain.VideoRenderWndProc(var Msg: TMessage);
var
    iEventCode: LongInt;
    iParam1, iParam2: LONG_PTR;
begin
    case Msg.Msg of
        WM_GRAPHEVENT:
            begin
                MediaEvent.GetEvent(iEventCode, iParam1, iParam2,
                  100 { dwTimeout } );
                // �̵� �Ϸ�ǰų� �����϶� ó��
                if (iEventCode = EC_COMPLETE) or (iEventCode = EC_USERABORT)
                then
                begin
                    MediaControl.Stop;
                end;

                MediaEvent.FreeEventParams(iEventCode, iParam1, iParam2);
            end;
        WM_LBUTTONDOWN:
            begin
                // ����� ȭ�� �巡�׷� ���� �� �̵�
                ReleaseCapture;
                SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
            end;
        WM_LBUTTONDBLCLK:
            begin
                PopupMenu1.Popup(Mouse.CursorPos.x,Mouse.CursorPos.y);
            end;
        WM_RBUTTONDOWN:
            begin

            end;
        WM_KEYDOWN:
            begin

            end;
    else
        VideoRenderOrgMethod(Msg);
    end;
end;

procedure TfrmMain.btnDownClick(Sender: TObject);
begin
    // �Ҹ�����
    if CurVol >= 5 then
	    CurVol := CurVol - 5;
    SetVolume(CurVol);
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
var
    WFileName: Array [0 .. 255] of WideChar;
    PFileName: PWideChar;
begin
    // ���� ����
    with TOpenDialog.Create(Self) do
        try
            Filter := 'Media Files(*.avi;*.mpg;*.wmv;*.mp4;*.mkv)|*.avi;*.mpg;*.wmv;*.mp4;*.mkv;|All Files(*.*)|*.*;';
            Title := 'Open Media Files..';

            if Execute then
            begin

                Caption := 'Base Player ' + FileName;

                StringToWideChar(FileName, WFileName, 255);
                PFileName := @WFileName[0];

                // DSHOW �ʱ�ȭ
                ShutDownDs;

                // DSHOW ����
                if SetupDs = False then
                    Exit;

                // �ڸ� ���� �ִ� �� Ȯ��
                FileName := ChangeFileExt(FileName, '.smi');
                if FileExists(FileName) then
                begin
                    SmSAMI := TSmSAMI.Create;
                    SmSAMI.Open(FileName);
                end;

                // ������ ������ Render �ϱ�
                if FilterGraph.RenderFile(PFileName, nil) = S_OK then
                begin

                    // �̵�� ���� ��������
                    MediaPosition.get_Duration(MediaLength);
                    TrackBar1.Max := trunc(MediaLength);
                    TrackBar1.Min := 0;

                    // ������ �÷����� �г� ���� Screen = Panel
                    VideoWindow.put_Owner(OAHWND(paScreen.Handle));
                    VideoWindow.put_WindowStyle(WS_CHILD or WS_CLIPSIBLINGS);
                    VideoWindow.put_Width(paScreen.Width);
                    VideoWindow.put_Height(paScreen.Height);
                    VideoWindow.put_Top(0);
                    VideoWindow.put_Left(0);

                    // �̺�Ʈ ���� �����ϱ�
                    MediaEvent.SetNotifyWindow(OAHWND(paScreen.Handle),
                      WM_GRAPHEVENT, 0);
                    MediaEvent.SetNotifyFlags(0);

                    // ���
                    MediaControl.Run;

                    CurVol := GetVolume;

                    if Assigned(SmSAMI) then
                    begin
                        SmSAMI.Run;
                        Timer_Subtitle.Enabled := true;
                    end;
                end
                else
                begin
                    Caption := 'Base Player';
                    // Render Fail
                    // �ڵ��� �ʿ���
                    ShowMessage('Render Fail!');
                end;

            end;
        finally
            Free;
        end;
end;

procedure TfrmMain.btnPlayClick(Sender: TObject);
begin
    // ���
    if Assigned(MediaControl) then
        MediaControl.Run;

    if Assigned(SmSAMI) then
        SmSAMI.Run;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
    // ����
    if Assigned(MediaControl) then
        MediaControl.Pause;

    if Assigned(SmSAMI) then
        SmSAMI.Pause;
end;

procedure TfrmMain.btnUpClick(Sender: TObject);
begin
    // �Ҹ�Ű��
    if CurVol <= 95 then
	    CurVol := CurVol + 5;
    SetVolume(CurVol);
end;

end.
