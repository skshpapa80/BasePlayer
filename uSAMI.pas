// 자막 처리 클래스
// 인터넷에서 가져온 소스 입니다.

unit uSAMI;

interface

uses
    Winapi.Windows, Winapi.ActiveX, Winapi.DirectShow9;

type
    TSmSAMI = class
        constructor Create;
        procedure Free;

    private

        pGraph: IGraphBuilder;
        pMediaControl: IMediaControl;
        pEv: IMediaEventEx;
        pMp: IMediaPosition;
        procedure Initialize;
        procedure Finalize;
        procedure GetRawCaption(const SourStr: String; out DestStr: String);

    public
        IsOpened: Boolean;

        procedure Open(FileName: String);
        procedure Run;
        function GetCaption(var Caption: String; AllCaption: Boolean): Boolean;

        procedure SetPosition(Pos: int64);
        procedure Close;
        procedure Pause;

    end;

implementation

constructor TSmSAMI.Create;
begin
    IsOpened := FALSE;
    CoInitialize(nil);
    Initialize;
end;

procedure TSmSAMI.Free;
begin
    Finalize;
    CoUninitialize();
end;

procedure TSmSAMI.Initialize;
begin
    // 설명 안해줄꺼야.. Direct X SDK help 에 잘 나와 있으니까..
    CoCreateInstance(CLSID_FilterGraph, nil, CLSCTX_INPROC,
      IID_IGraphBuilder, pGraph);
    pGraph.QueryInterface(IID_IMediaControl, pMediaControl);
    pGraph.QueryInterface(IID_IMediaEventEx, pEv);
    pGraph.QueryInterface(IID_IMediaPosition, pMp);
end;

procedure TSmSAMI.Finalize;
begin
    pEv := nil;
    pMediaControl := nil;
    pGraph := nil;
end;

procedure TSmSAMI.Open(FileName: String);
var
    hr: HRESULT;
    wFileName: array [0 .. 256] of WideChar;
begin
    if not Assigned(pGraph) then
        Exit;

    StringToWideChar(FileName, wFileName, sizeof(wFileName));
    hr := pGraph.RenderFile(@wFileName, nil);

    if Failed(hr) then
        Exit;

    IsOpened := TRUE;
end;

procedure TSmSAMI.Run;
begin
    if not Assigned(pMediaControl) then
        Exit;

    if not IsOpened then
        Exit;

    pMediaControl.Run;
end;

procedure TSmSAMI.SetPosition(Pos: int64);
begin
    pMp.put_CurrentPosition(Pos);
end;

procedure TSmSAMI.GetRawCaption(const SourStr: String; out DestStr: String);
const
    TAG_BEGIN = '<';
    TAG_END = '>';
var
    TagBegin, TagEnd: Integer;
begin
    DestStr := SourStr;

    // 허접 파서
    if Pos(TAG_END, SourStr) > 0 then
    begin

        while (TRUE) do
        begin

            TagBegin := Pos(TAG_BEGIN, DestStr);
            TagEnd := Pos(TAG_END, DestStr);

            if (TagBegin = 0) or (TagEnd = 0) then
                break;

            if (TagBegin < TagEnd) then
            begin
                Delete(DestStr, TagBegin, TagEnd - TagBegin + 1);
            end
            else
            begin
                DestStr := Copy(DestStr, TagEnd + 1, 65000);
            end;
        end;
    end;
end;

function TSmSAMI.GetCaption(var Caption: String; AllCaption: Boolean): Boolean;
var
    evCode: LongInt;
    lParam1, lParam2: LONG_PTR;
begin
    GetCaption := FALSE;
    Caption := '';

    if not Assigned(pEv) then
        Exit;

    if not IsOpened then
        Exit;

    pEv.GetEvent(evCode, lParam1, lParam2, 100);

    if evCode = EC_OLE_EVENT then
    begin

        if AllCaption then
        begin
            WideCharToStrVar(PWideChar(lParam2), Caption);
        end
        else
        begin
            GetRawCaption(WideCharToString(PWideChar(lParam2)), Caption);
        end;

        if Caption = '&nbsp;' then
            Caption := ' ';
    end;

    pEv.FreeEventParams(evCode, lParam1, lParam2);

    GetCaption := not((evCode = EC_USERABORT) or (evCode = EC_COMPLETE) or
      (evCode = EC_ERRORABORT));
end;

procedure TSmSAMI.Close;
begin
    pMediaControl.Stop;
end;

procedure TSmSAMI.Pause;
begin
    pMediaControl.Pause;
end;

end.
