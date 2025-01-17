{
This file is part of OvoM3U
Copyright (C) 2020 Marco Caselli

OvoM3U is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

}
{$I codegen.inc}
unit umain;

interface

uses
  Classes, Forms, Controls, Graphics, Dialogs, ExtCtrls, Grids, LCLIntf,
  lcltype, ComCtrls, Menus, ActnList, Buttons, StdCtrls, IniPropStorage,
  um3uloader, OpenGLContext, Types, Math, SysUtils, MPV_Engine, Config,
  {$IFDEF LINUX} clocale,{$endif}
  GeneralFunc, System.UITypes, epg, uMyDialog, uEPGFOrm, uBackEnd, BaseTypes, mouseandkeyinput;

type

  { TGuiProperties }

  TGuiProperties = class(TConfigParam)
    fViewLogo: boolean;
    fViewCurrentProgram: boolean;
  private
    FBoundsRect: TRect;
    FChannelGridWidth: integer;
    procedure SetBoundRect(AValue: TRect);
    procedure SetChannelGridWidth(AValue: integer);
    procedure SetViewCurrentProgram(AValue: boolean);
    procedure SetViewLogo(AValue: boolean);
  protected
    procedure InternalSave; override;
  public
    property ViewLogo: boolean read fViewLogo write SetViewLogo;
    property ViewCurrentProgram: boolean read fViewCurrentProgram write SetViewCurrentProgram;
    property ChannelGridWidth: integer read FChannelGridWidth write SetChannelGridWidth;
    property BoundsRect: TRect read FBoundsRect write SetBoundRect;
    procedure Load; override;
    constructor Create(aOwner: TConfig; ABoundsRect: TRect); reintroduce;
  end;


{ TfPlayer }
type

  TfPlayer = class(TForm)
    actShowList: TAction;
    actShowConfig: TAction;
    actShowEpg: TAction;
    actViewLogo: TAction;
    actViewCurrentProgram: TAction;
    actList: TActionList;
    ApplicationProperties1: TApplicationProperties;
    AppProperties: TApplicationProperties;
    ChannelList: TDrawGrid;
    cbGroups: TComboBox;
    EPGList: TDrawGrid;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    N1: TMenuItem;
    mnuSub: TMenuItem;
    mnuAudio: TMenuItem;
    mnuVideo: TMenuItem;
    GLRenderer: TOpenGLControl;
    ChannelTimer: TTimer;
    Panel1: TPanel;
    pnlEpg: TPanel;
    pnlSubForm: TPanel;
    pnlChannel: TPanel;
    pnlContainer: TPanel;
    pmPlayer: TPopupMenu;
    HideMouse: TTimer;
    LoadingTimer: TTimer;
    pmuView: TPopupMenu;
    ChannelSplitter: TSplitter;
    ToolButton1: TSpeedButton;
    ToolButton2: TSpeedButton;
    ToolButton5: TSpeedButton;
    procedure actListUpdate(AAction: TBasicAction; var Handled: boolean);
    procedure actShowEpgExecute(Sender: TObject);
    procedure actShowConfigExecute(Sender: TObject);
    procedure actShowListExecute(Sender: TObject);
    procedure actViewCurrentProgramExecute(Sender: TObject);
    procedure actViewLogoExecute(Sender: TObject);
    procedure AppPropertiesException(Sender: TObject; E: Exception);
    procedure cbGroupsChange(Sender: TObject);
    procedure ChannelListDblClick(Sender: TObject);
    procedure ChannelListDrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure ChannelListGetCellHint(Sender: TObject; ACol, ARow: integer; var HintText: string);
    procedure ChannelListKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure ChannelSplitterMoved(Sender: TObject);
    procedure ChannelTimerTimer(Sender: TObject);
    procedure EPGListDrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure FormChangeBounds(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure GLRendererChangeBounds(Sender: TObject);
    procedure LoadingTimerStartTimer(Sender: TObject);
    procedure LoadingTimerTimer(Sender: TObject);
    procedure GLRendererDblClick(Sender: TObject);
    procedure GLRendererMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure HideMouseTimer(Sender: TObject);
    procedure pmPlayerClose(Sender: TObject);
    procedure pmPlayerPopup(Sender: TObject);
    procedure pnlContainerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure pnlContainerPaint(Sender: TObject);
    procedure ToolButton5MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
  private
    ChannelInfo: AREpgInfo;
    GuiProperties: TGuiProperties;
    FLoading: boolean;
    ChannelSelecting: boolean;
    fLastMessage: string;
    IPTVList: string;
    Kind: TProviderKind;
    fFilteredList: TFilteredList;
    SubForm: TForm;
    SubFormVisible: boolean;
    function CheckConfigAndSystem: boolean;
    procedure CloseSubForm;
    procedure ComputeGridCellSize;
    function ComputeTrackTitle(Track: TTrack): string;
    procedure ConfigDone(Sender: TObject);
    procedure DebugLnHook(Sender: TObject; S: string; var Handled: boolean);
    procedure DoExternalInput(Data: PtrInt);
    procedure EmbedSubForm(AForm: TForm);
    procedure ExternalInput(Sender: TObject; var Key: word);
    procedure InitializeGui(Data: ptrint);
    procedure LoadDailyEpg;
    procedure OnListChanged(Sender: TObject);
    procedure OnLoadingState(Sender: TObject);
    procedure OnTrackChange(Sender: TObject);
    procedure Play(Row: integer);
    procedure SetLoading(AValue: boolean);
    procedure OnPlay(Sender: TObject);

  private
    ChannelSelected: integer;
    flgFullScreen: boolean;
    RestoredBorderStyle: TFormBorderStyle;
    RestoredWindowState: TWindowState;
    Progress: integer;
    property Loading: boolean read FLoading write SetLoading;
    procedure LoadTracks;
    procedure mnuTrackClick(Sender: TObject);
    procedure SetFullScreen;
    procedure LoadList;
  public
  end;

var
  fPlayer: TfPlayer;
  openglHandle: Thandle;

implementation

uses uconfig, LoggerUnit, AppConsts, uChannels, LazUTF8, LazLogger;

var
  f: Text;

{$R *.lfm}

{ TGuiProperties }

procedure TGuiProperties.SetChannelGridWidth(AValue: integer);
begin
  if FChannelGridWidth = AValue then Exit;
  FChannelGridWidth := AValue;
  Dirty := True;
end;

procedure TGuiProperties.SetBoundRect(AValue: TRect);
begin
  if FBoundsRect = AValue then Exit;
  FBoundsRect := AValue;
  Dirty := True;
end;

procedure TGuiProperties.SetViewCurrentProgram(AValue: boolean);
begin
  if fViewCurrentProgram = AValue then Exit;
  fViewCurrentProgram := AValue;
  Dirty := True;
end;

procedure TGuiProperties.SetViewLogo(AValue: boolean);
begin
  if fViewLogo = AValue then Exit;
  fViewLogo := AValue;
  Dirty := True;
end;

procedure TGuiProperties.InternalSave;
begin
  Owner.WriteBoolean('gui/ViewLogo', ViewLogo);
  Owner.WriteBoolean('gui/ViewCurrentProgram', ViewCurrentProgram);
  Owner.WriteInteger('gui/ChannelGridWidth', ChannelGridWidth);
  Owner.WriteRect('gui/MainForm/Position', BoundsRect);
end;

procedure TGuiProperties.Load;
begin
  ViewLogo := Owner.ReadBoolean('gui/ViewLogo', False);
  ViewCurrentProgram := Owner.ReadBoolean('gui/ViewCurrentProgram', False);
  ChannelGridWidth := Owner.ReadInteger('gui/ChannelGridWidth', 215);
  BoundsRect := Owner.ReadRect('gui/MainForm/Position', BoundsRect);

  Dirty := False;
end;

constructor TGuiProperties.Create(aOwner: TConfig; ABoundsRect: TRect);
begin
  FBoundsRect := ABoundsRect;
  inherited Create(aOwner);
  Dirty := False;
end;

{ TfPlayer }

function TfPlayer.CheckConfigAndSystem: boolean;
var
  Retry: boolean;
begin
  repeat
    Retry := False;
    if not Tmpvengine.CheckMPV then
    begin
      OvoLogger.Log(llERROR, 'Cannot initialize libMPV');
      case ShowMyDialog(mtWarning, 'Can''t initialize libMPV',
          'LibMPV shared library is missing or could not be initialized.' + #10 +
          'OvoM3U uses this library to decode and play video.' + #10 +
          'Click the following link to open a wiki page with information on' + #10 +
          'how to install libMPV on your platform', [mbRetry, mbClose],
          [WIKI_MPV_LINK]) of

        mrClose:
        begin
          Result := False;
          Retry := False;
          exit;
        end;
        mrRetry:
          Retry := True;
        100:
          OpenURL(WIKI_MPV_LINK);
        else
          Retry := False;
      end;

    end;
  until Retry = False;


  Result := True;
  Kind := BackEnd.List.ListProperties.ChannelsKind;
  case Kind of
    Local:
      IPTVList := BackEnd.List.ListProperties.ChannelsFileName;
    URL:
      IPTVList := BackEnd.List.ListProperties.ChannelsUrl;
  end;

  if IPTVList.IsEmpty then
    case ShowMyDialog(mtWarning, 'Welcome to OvoM3U',
        'No list configured' + #10 +
        'Message for configuration', [mbClose],
        ['Open Config']) of
      mrClose:
      begin
        Result := False;
        exit;
      end;
      100:
        actShowConfig.Execute;
    end
  else
    Loadlist;

end;

procedure TfPlayer.LoadList;
var
  CacheDir: string;
begin

  BackEnd.LoadList;
  fFilteredList := BackEnd.List.Filter(Default(TFilterParam));

  if (BackEnd.list.Groups.Count > 1) then
  begin
    cbGroups.Items.Clear;
    cbGroups.items.add(um3uloader.RSAnyGroup);
    cbGroups.Items.AddStrings(BackEnd.List.Groups, False);
    cbGroups.ItemIndex := 0;
    cbGroups.Visible := True;
  end
  else
    cbGroups.Visible := False;

  ChannelList.RowCount := BackEnd.List.Count;

end;

procedure TfPlayer.OnListChanged(Sender: TObject);
begin
  ChannelList.invalidate;
end;

procedure TfPlayer.DoExternalInput(Data: PtrInt);
var
  key: word;
begin
  Key := word(PtrInt(Data));
  if key > $1ff then
    FormKeyDown(self, Key, [])
  else
    KeyInput.Press(Key);
end;

procedure TfPlayer.ExternalInput(Sender: TObject; var Key: word);
begin
  Application.QueueAsyncCall(DoExternalInput, PtrInt(key));
end;

procedure TfPlayer.FormCreate(Sender: TObject);
begin
  SetLength(ChannelInfo, 0);
  SubFormVisible := False;
  OvoLogger.Log(llINFO, 'Load configuration from %s', [ConfigObj.ConfigFile]);

  Progress := 0;
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  flgFullScreen := False;
  OvoLogger.Log(llINFO, 'Create main GUI');
  BackEnd.OnExternalInput := ExternalInput;
  BackEnd.OnPlay := OnPlay;
  BackEnd.list.OnListChanged := OnListChanged;
  ChannelList.RowCount := 0;

  ChannelSelecting := False;
  fLoading := False;
  ChannelSelected := 0;
  Application.QueueAsyncCall(InitializeGui, 0);

  if CheckConfigAndSystem then
  begin
    backend.InitializeEngine(GLRenderer);
    backend.mpvengine.OnLoadingState := OnLoadingState;
    backend.mpvengine.OnTrackChange := OnTrackChange;
  end
  else
    OvoLogger.Log(llWARN, 'Invalid config');

end;

procedure TfPlayer.FormDestroy(Sender: TObject);
begin
  Application.ProcessMessages;
  OvoLogger.Log(llINFO, 'Closed main GUI');
end;

procedure TfPlayer.OnLoadingState(Sender: TObject);
begin
  if Loading then
    Loading := backend.mpvengine.IsIdle;
  if not Loading then
  begin
    Backend.OsdMessage('', False);
  end;
end;

procedure TfPlayer.OnTrackChange(Sender: TObject);
begin
  LoadTracks;
end;

procedure TfPlayer.OnPlay(Sender: TObject);
var
  Idx: integer;
begin
  Idx := fFilteredList.IndexOf(BackEnd.CurrentIndex);
  if Idx <> -1 then
    ChannelList.Row := Idx
  else
    ChannelList.Selection := Rect(-1, -1, -1, -1);
end;


procedure TfPlayer.FormKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
var
  Pass: boolean;
  channel: integer;
  ExtendedKey: boolean;
begin
  Pass := False;
  Application.ProcessMessages;
  if (key and $300) =$300 then
   begin
     hide;
     application.ProcessMessages;
     Application.Terminate;
   end;

  if (Key and $200) <> 0 then
  begin
    ExtendedKey := True;
    Key := key and $1FF;
  end
  else
    ExtendedKey := False;

  case key of
    VK_ESCAPE:
    begin
      if SubFormVisible then
      begin
        CloseSubForm;
      end
      else
      if flgFullScreen then
        SetFullScreen;
      Key := 0;
    end;

    VK_MEDIA_NEXT_TRACK:
    begin
        channel := fFilteredList.IndexOf(BackEnd.CurrentIndex);
        play(fFilteredList.Map(channel + 1));
    end;
    VK_MEDIA_PREV_TRACK:
    begin
        channel := fFilteredList.IndexOf(BackEnd.CurrentIndex);
        play(fFilteredList.Map(channel - 1));
     end;
    VK_MEDIA_STOP:
    begin
      backend.mpvengine.Stop;
      Backend.OsdMessage('Stop', True);
    end;

  end;

  if (not SubFormVisible) or ExtendedKey then
  begin
    case key of
      VK_RETURN:
        if ChannelSelecting then
        begin
          if BackEnd.List.ListProperties.UseChno then
            ChannelSelected := BackEnd.List.ItemByChno(ChannelSelected)
          else
            ChannelSelected := ChannelSelected - 1;
          play(ChannelSelected);
          ChannelSelecting := False;
          key := 0;
        end
        else
          pass := True;
      VK_C:
      begin
        pnlChannel.Visible := not pnlChannel.Visible;
        ChannelSplitter.Visible := pnlChannel.Visible;
        HideMouse.Enabled := (not pnlChannel.Visible) and flgFullScreen;
        if pnlChannel.Visible then
          ChannelList.SetFocus;;
      end;

      VK_I:
        Backend.ShowEpg;
      VK_O:
        backend.mpvengine.ShowStats();
      VK_P:
        if not pnlEpg.Visible then
        begin
          LoadDailyEpg;
          pnlEpg.Visible := True;
        end
        else
          pnlEpg.Visible := False;
      VK_S:
      begin
        backend.mpvengine.Stop;
        Backend.OsdMessage('Stop', True);
      end;
      VK_T:
      begin
        Backend.OsdMessage(FormatDateTime('t', now), True);
      end;
      VK_SPACE:
      begin
        if backend.mpvengine.Pause then
        begin
          backend.mpvengine.OsdEpg('', Default(REpgInfo), False);
          Backend.OsdMessage('Pause', False);
        end
        else
          backend.mpvengine.OsdMessage();
      end;
      VK_F:
        SetFullScreen;
      VK_L:
        actShowList.Execute;
      VK_M:
      begin
        backend.mpvengine.Mute;
      end;
      VK_E:
      begin
        actShowEpg.Execute;
      end;
      VK_B:
      begin
        BackEnd.SwapChannel;
      end;

      VK_RIGHT:
      begin
        backend.mpvengine.Seek(5);
      end;
      VK_LEFT:
      begin
        backend.mpvengine.Seek(-5);
      end;

      VK_0..VK_9, VK_NUMPAD0..VK_NUMPAD9:
      begin
        if not ChannelSelecting then
        begin
          ChannelSelecting := True;
          ChannelSelected := Key - $30;
          if Key >= $60 then
            ChannelSelected := ChannelSelected - $30;
        end
        else
        begin
          ChannelSelected := (ChannelSelected * 10) + Key - $30;
          if Key >= $60 then
            ChannelSelected := ChannelSelected - $30;

        end;
        Backend.OsdMessage(IntToStr(ChannelSelected), False);
        ChannelTimer.Enabled := True;
      end;
      else
        Pass := True;
    end;
  end
  else
    Pass := True;
  if not pass then
    key := 0;
end;

procedure TfPlayer.GLRendererChangeBounds(Sender: TObject);
begin
  BackEnd.MpvEngine.Refresh;
end;

procedure TfPlayer.LoadingTimerStartTimer(Sender: TObject);
begin
  Progress := 10;
end;

procedure TfPlayer.LoadingTimerTimer(Sender: TObject);
begin
  Inc(progress, 10);
  if progress mod 50 = 0 then
  begin
    Loading := backend.mpvengine.isIdle;
    if not loading then
    begin
      Backend.OsdMessage('');
      LoadingTimer.Enabled := False;
    end;
  end;

  if progress > 720 then
    Progress := 10;
  pnlContainer.Invalidate;
end;

procedure TfPlayer.ChannelListDrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
var
  cv: TCanvas;
  Element: TM3UItem;
  bmp: TPicture;
  r: Trect;
  Scale: double;
  H: integer;
  Spacing: integer;
  epgInfo: REpgInfo;
begin
  if not Assigned(GuiProperties) then
    exit;
  Element := fFilteredList[Arow];
  h := 0;
  cv := ChannelList.Canvas;
  if GuiProperties.ViewLogo then
  begin
    h := ChannelList.RowHeights[aRow];
    if Element.IconAvailable then
    begin
      bmp := TPicture.Create;
      bmp.LoadFromFile(element.IconLocal);
      if bmp.Height > bmp.Width then
      begin
        scale := bmp.Width / bmp.Height;
        r := rect(arect.left, arect.Top, arect.Left + round(h * scale), aRect.Top + round(h));
      end
      else
      begin
        scale := bmp.Height / bmp.Width;
        r := rect(arect.left, arect.Top, arect.Left + round(h), aRect.Top + round(h * scale));
      end;
      cv.StretchDraw(r, bmp.Graphic);
      bmp.Free;
    end
    else
    begin
      bmp := TPicture.Create;
      bmp.LoadFromFile(ConfigObj.GetResourcesPath + 'no-logo.png');
      cv.StretchDraw(rect(arect.left, arect.Top, arect.Left + h, aRect.Top + h), bmp.Graphic);
      bmp.Free;
    end;

  end;

  cv.Font.Height := Scale96Toscreen(-14);
  if Backend.CurrentIndex = fFilteredList.Map(aRow) then
  begin
    cv.Font.Style := [fsBold, fsUnderline];
    cv.Font.color := clHighlightText;
    cv.Brush.color := clHighlight;
    cv.Rectangle(aRect);
  end
  else
    cv.Font.Style := [fsBold];

  Spacing := Scale96ToScreen(2);
  cv.TextRect(aRect, h + Spacing * 2, aRect.top + Spacing * 2, Format('%3.3d: %s', [Element.Number, Element.title]));
  if GuiProperties.ViewCurrentProgram then
  begin
    epgInfo := BackEnd.epgdata.GetEpgInfo(fFilteredList.Map(arow), now);
    if epgInfo.HaveData then
    begin
      cv.Font.Height := Scale96ToScreen(-12);
      cv.Font.Style := [];
      Element.CurrProgram := FormatTimeRange(EpgInfo.StartTime, EpgInfo.EndTime, True);
      cv.TextRect(aRect, h + Spacing, aRect.top + scale96toscreen(25), Element.CurrProgram);
      cv.TextRect(aRect, h + spacing, aRect.top + scale96toscreen(37), EpgInfo.Title);

    end;
  end;
end;

procedure TfPlayer.ChannelListGetCellHint(Sender: TObject; ACol, ARow: integer; var HintText: string);
var
  Element: TM3UItem;
  epgInfo: REpgInfo;
begin
  Element := fFilteredList[arow];
  epgInfo := BackEnd.epgdata.GetEpgInfo(fFilteredList.Map(arow), now);

  HintText := Format('%3.3d: %s', [Element.Number, Element.title]) + sLineBreak +
    FormatTimeRange(EpgInfo.StartTime, EpgInfo.EndTime, True) + sLineBreak +
    EpgInfo.Title;

end;

procedure TfPlayer.ChannelListKeyDown(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if (key) = VK_RETURN then
    Play(fFilteredList.Map(ChannelList.Row));
end;

procedure TfPlayer.ChannelSplitterMoved(Sender: TObject);
begin
  GuiProperties.ChannelGridWidth := ScaleScreenTo96(ChannelSplitter.Left);
end;

procedure TfPlayer.ChannelTimerTimer(Sender: TObject);
begin
  if ChannelSelecting then
  begin
    if BackEnd.List.ListProperties.UseChno then
      ChannelSelected := BackEnd.List.ItemByChno(ChannelSelected)
    else
      ChannelSelected := ChannelSelected - 1;

    ChannelSelecting := False;
    Backend.OsdMessage('', False);
    Play(ChannelSelected);

  end;
  ChannelTimer.Enabled := False;
end;

procedure TfPlayer.LoadDailyEpg;
var
  StartTime, EndTime: TDateTime;
  i: integer;
begin
  StartTime := Trunc(now);
  EndTime := Trunc(now) + 1;
  ChannelInfo := BackEnd.EpgData.GetEpgInfo(BackEnd.CurrentIndex, StartTime, EndTime);
  if Length(ChannelInfo) > 0 then
  begin
    EPGList.RowCount := Length(ChannelInfo);
    EPGList.Visible := True;
  end
  else
    EPGList.Visible := False;

end;

procedure TfPlayer.EPGListDrawCell(Sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
var
  i, Spacing: integer;
  epgInfo: REpgInfo;
  cv: TCanvas;
  CurrProgram: string;
begin
  epgInfo := ChannelInfo[Arow];
  cv := EPGList.Canvas;
  if epgInfo.HaveData then
  begin
    cv.Font.Height := Scale96ToScreen(-12);
    cv.Font.Style := [];
    Spacing := Scale96ToScreen(5);
    CurrProgram := FormatTimeRange(EpgInfo.StartTime, EpgInfo.EndTime, True);
    cv.TextRect(aRect, aRect.Left + Spacing, aRect.top + Spacing, CurrProgram);
    cv.TextRect(aRect, aRect.Left + spacing, aRect.top + Spacing + scale96toscreen(12), EpgInfo.Title);
  end;

end;

procedure TfPlayer.FormChangeBounds(Sender: TObject);
begin
  if SubFormVisible then
  begin
    pnlsubform.Height := min(600, pnlcontainer.Height - 100);
  end;
  GuiProperties.BoundsRect := BoundsRect;
end;

procedure TfPlayer.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  hide;
  if Assigned(backend.mpvengine) then
  begin
    backend.mpvengine.isRenderActive := False;
    BackEnd.MpvEngine.Stop;
  end;

  Application.ProcessMessages;
  CloseAction := caFree;
end;

procedure TfPlayer.ChannelListDblClick(Sender: TObject);
begin
  Play(fFilteredList.Map(ChannelList.Row));
end;

procedure TfPlayer.AppPropertiesException(Sender: TObject; E: Exception);
begin
  try
    OvoLogger.Log(llERROR, 'EXCEPTION : %s' + LineEnding +
      '%s', [e.message, BackTraceStrFunc(ExceptAddr)]);

  except
    Halt(999);
    // avoid exception on exception
  end;
end;

procedure TfPlayer.cbGroupsChange(Sender: TObject);
var
  Filter: TFilterParam;
begin
  Filter := Default(TFilterParam);
  if cbGroups.ItemIndex <> 0 then
    Filter.Group := cbGroups.Items[cbGroups.ItemIndex];

  fFilteredList := BackEnd.List.Filter(Filter);

  ChannelList.RowCount := fFilteredList.Count;
  ChannelList.Invalidate;

end;

procedure TfPlayer.EmbedSubForm(AForm: TForm);
begin
  if Assigned(SubForm) then
    CloseSubForm;

  AForm.Parent := pnlSubForm;
  pnlSubForm.Height := min(600, pnlcontainer.Height - 100);
  AForm.Align := alclient;
  SubFormVisible := True;
  SubForm := AForm;
  AForm.Show;

end;

procedure TfPlayer.CloseSubForm;
begin
  SubForm.Hide;
  pnlSubForm.Height := 0;
  BackEnd.MpvEngine.Refresh;
  SubForm.Parent := nil;
  SubForm.Close;
  SubFormVisible := False;
  SubForm := nil;

end;

procedure TfPlayer.actShowEpgExecute(Sender: TObject);
begin
  if not Assigned(EPGForm) then
    Application.CreateForm(TEPGForm, EPGForm);
  EpgForm.EpgData := BackEnd.epgData;
  EmbedSubForm(EPGForm);

end;

procedure TfPlayer.actListUpdate(AAction: TBasicAction; var Handled: boolean);
begin
  if not Assigned(GuiProperties) then
    exit;
  actViewLogo.Checked := GuiProperties.ViewLogo;
  actViewCurrentProgram.Checked := GuiProperties.ViewCurrentProgram;
end;

procedure TfPlayer.ConfigDone(Sender: TObject);
begin
  if fConfig.ModalResult = mrOk then
  begin
    if BackEnd.List.ListProperties.Dirty then
    begin
      OvoLogger.Log(llINFO, 'List configuration changed, reloading');
      BackEnd.EpgData.SetLastScan('Channels', 0);
      LoadList;
    end;
    if BackEnd.EpgData.EpgProperties.Dirty then
    begin
      OvoLogger.Log(llINFO, 'EPG configuration changed, reloading');
      BackEnd.EpgData.SetLastScan('epg', 0);
      BackEnd.EpgData.Scan;
    end;

  end;

  CloseSubForm();
end;

procedure TfPlayer.actShowConfigExecute(Sender: TObject);
begin
  if not Assigned(fConfig) then
    Application.CreateForm(TfConfig, fConfig);

  fConfig.OnWorkDone := ConfigDone;

  EmbedSubForm(fConfig);

end;

procedure TfPlayer.actShowListExecute(Sender: TObject);
begin
  if not Assigned(fChannels) then
    Application.CreateForm(TfChannels, fChannels);
  fChannels.Init;
  EmbedSubForm(fChannels);
end;

procedure TfPlayer.actViewCurrentProgramExecute(Sender: TObject);
begin
  actViewCurrentProgram.Checked := not actViewCurrentProgram.Checked;
  GuiProperties.ViewCurrentProgram := actViewCurrentProgram.Checked;
  ComputeGridCellSize;
end;

procedure TfPlayer.actViewLogoExecute(Sender: TObject);
begin
  actViewLogo.Checked := not actViewLogo.Checked;
  GuiProperties.ViewLogo := actViewLogo.Checked;
  ComputeGridCellSize;
  if actViewLogo.Checked then
    BackEnd.list.UpdateLogo;
end;

procedure TfPlayer.InitializeGui(Data: ptrint);
begin
  GuiProperties := TGuiProperties.Create(ConfigObj, BoundsRect);
  ChannelSplitter.Left := Scale96ToScreen(GuiProperties.ChannelGridWidth);
  BoundsRect := GuiProperties.BoundsRect;
  ComputeGridCellSize;

end;

procedure TfPlayer.ComputeGridCellSize;
begin
  if GuiProperties.ViewCurrentProgram then
    ChannelList.DefaultRowHeight := Scale96ToScreen(64)
  else
  if GuiProperties.ViewLogo then
    ChannelList.DefaultRowHeight := Scale96ToScreen(48)
  else
    ChannelList.DefaultRowHeight := Scale96ToScreen(32);
  ChannelList.Invalidate;

end;

procedure TfPlayer.DebugLnHook(Sender: TObject; S: string; var Handled: boolean);
begin
  if (TextRec(f).mode <> fmClosed) and (IOResult = 0) then
    WriteLn(f, S);

end;

procedure TfPlayer.Play(Row: integer);
begin
  BackEnd.Play(Row);
  ChannelList.Invalidate;
  Caption := BackEnd.list[Backend.CurrentIndex].title;
  if pnlEpg.Visible then
  begin
    LoadDailyEpg;
    EPGList.Invalidate;
  end;
  Loading := True;

end;

procedure TfPlayer.GLRendererDblClick(Sender: TObject);
begin
  SetFullScreen;
end;

procedure TfPlayer.GLRendererMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  if flgFullScreen then
  begin
    Screen.Cursor := crdefault;
    HideMouse.Enabled := flgFullScreen and not pnlChannel.Visible;
  end;
end;

procedure TfPlayer.HideMouseTimer(Sender: TObject);
begin
  screen.cursor := crNone;
end;

procedure TfPlayer.pmPlayerClose(Sender: TObject);
begin
  if flgFullScreen then
  begin
    HideMouse.Enabled := True;
  end;
end;

procedure TfPlayer.pmPlayerPopup(Sender: TObject);
begin
  if mnuVideo.Count = 0 then
    mnuVideo.Enabled := False;
  if mnuAudio.Count = 0 then
    mnuAudio.Enabled := False;
  if mnuSub.Count = 0 then
    mnuSub.Enabled := False;
  if flgFullScreen then
  begin
    HideMouse.Enabled := False;
  end;
end;

procedure TfPlayer.pnlContainerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
begin
  GLRendererMouseMove(Sender, Shift, x, y);
end;

procedure TfPlayer.pnlContainerPaint(Sender: TObject);
var
  cv: Tcanvas;
  a, b: integer;
  p: tpoint;
  Scaling: double;
begin
  if GLRenderer.Visible then
    exit;
  cv := pnlContainer.Canvas;
  if floading then
  begin

    cv.Brush.Color := clblack;
    cv.Clear;
    cv.Pen.Color := clwhite;
    cv.pen.Width := 10;
    if progress < 360 then
    begin
      A := progress * 16;
      b := 0;
    end
    else
    begin
      A := (progress - 720) * 16 + 10;
      b := -360 * 16;
    end;
    p.X := pnlcontainer.Width div 2;
    p.y := pnlcontainer.Height div 2;
    cv.Arc(p.x - 50, p.y - 50, p.x + 50, p.y + 50, b, a);
  end;
  cv.font.Color := clwhite;
  // MPV use a default font of 55 pixel for a 720 pixel high window
  // try to replicate same scaling
  Scaling := (pnlcontainer.Height / 720);
  cv.font.Height := trunc(55 * scaling);
  cv.TextOut(trunc(scaling * 25), trunc(scaling * 22), fLastMessage);

end;

procedure TfPlayer.ToolButton5MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
var
  p: Tpoint;
begin
  p := ToolButton5.ClientToScreen(Point(x, y));
  pmuView.PopUp(p.x, p.y);
end;

procedure TfPlayer.SetLoading(AValue: boolean);
begin

  FLoading := AValue;
  LoadingTimer.Enabled := FLoading;
  if not loading then
  begin
    GLRenderer.Visible := True;
    fLastMessage := '';
    backend.mpvengine.LoadTracks;
    LoadTracks;
  end;
end;

function TfPlayer.ComputeTrackTitle(Track: TTrack): string;
begin
  Result := '';
  if not trim(Track.Title).IsEmpty then
    Result := QuotedStr(Track.Title) + ' ';
  case track.Kind of
    trkVideo:
    begin
      Result := Result + '(' + Track.Codec + ' ';
      if (Track.w <> 0) or (Track.h <> 0) then
        Result := Result + format('%dx%d ', [Track.W, track.h]);
      if track.Fps <> 0 then
        Result := Result + format('%2.3ffps ', [Track.Fps]);
      Result := trim(Result) + ') ';
      if track.BitRate <> 0 then
        Result := Result + format('(%d kbps) ', [trunc(Track.BitRate / 1024)]);
    end;
    trkAudio:
    begin
      if not trim(Track.Title).IsEmpty then
        Result := QuotedStr(Track.Title) + ' ';
      if not trim(Track.Lang).IsEmpty then
        Result := Track.Lang + ' ';

      Result := Result + '(' + Track.Codec + ' ';

      if (Track.Channels <> 0) then
        Result := Result + format('%dch ', [Track.Channels]);
      if track.SampleRate <> 0 then
        Result := Result + format('%dHz ', [Track.SampleRate]);
      Result := trim(Result) + ') ';
      if track.BitRate <> 0 then
        Result := Result + format('(%d kbps) ', [trunc(Track.BitRate / 1024)]);
    end;
    trkSub:
    begin
      if not trim(Track.Title).IsEmpty then
        Result := QuotedStr(Track.Title) + ' ';
      if not trim(Track.Lang).IsEmpty then
        Result := Track.Lang + ' ';

      Result := Result + '(' + Track.Codec + ')';

    end;

  end;
  Result := trim(Result);
end;

procedure TfPlayer.LoadTracks;
var
  Track: TTrack;
  mnu: TMenuItem;
  i: integer;
begin
  OvoLogger.Log(llDEBUG, 'Loading tracks');
  mnuAudio.Clear;
  mnuVideo.Clear;
  mnuAudio.Clear;
  for i := 0 to Length(backend.mpvengine.TrackList) - 1 do
  begin
    Track := backend.mpvengine.TrackList[i];
    if track.Id <> 0 then
      case Track.Kind of
        trkVideo:
        begin
          mnu := tmenuitem.Create(mnuVideo);
          mnu.RadioItem := True;
          mnu.Checked := Track.Selected;
          mnu.Caption := ComputeTrackTitle(track);
          mnu.Tag := i;
          mnu.GroupIndex := 2;
          mnu.OnClick := mnuTrackClick;
          mnuVideo.Add(mnu);
        end;
        trkAudio:
        begin
          mnu := tmenuitem.Create(mnuAudio);
          mnu.RadioItem := True;
          mnu.Checked := Track.Selected;
          mnu.Caption := ComputeTrackTitle(track);
          mnu.Tag := i;
          mnu.GroupIndex := 1;
          mnu.OnClick := mnuTrackClick;
          mnuAudio.Add(mnu);
        end;
        trkSub:
        begin
          mnu := tmenuitem.Create(mnuSub);
          mnu.RadioItem := True;
          mnu.Checked := Track.Selected;
          mnu.Caption := ComputeTrackTitle(track);
          mnu.Tag := i;
          mnu.GroupIndex := 3;
          mnu.OnClick := mnuTrackClick;
          mnuSub.Add(mnu);
        end;
      end;
  end;

end;

procedure TfPlayer.mnuTrackClick(Sender: TObject);
var
  mnu: TMenuItem;
begin
  mnu := TMenuItem(Sender);
  backend.mpvengine.SetTrack(mnu.Tag);
  mnu.Checked := True;

end;


procedure TfPlayer.SetFullScreen;
const
  ShowCommands: array[TWindowState] of integer =
    (SW_SHOWNORMAL, SW_MINIMIZE, SW_SHOWMAXIMIZED, SW_SHOWFULLSCREEN);
begin
  flgFullScreen := not flgFullScreen;
  if flgFullScreen then
  try
    OvoLogger.Log(llDEBUG, 'Going fullscreen');
    backend.mpvengine.isRenderActive := False;
    Application.ProcessMessages;
    pnlChannel.Visible := False;
    ChannelSplitter.Visible := False;
    RestoredBorderStyle := BorderStyle;
    RestoredWindowState := WindowState;
    {$IFDEF WINDOWS}
    // On windows this is required to go fullscreen
    // but there is a bug in LCL and I get only a black screen!!
    // BorderStyle := bsNone;
    {$ENDIF}
    //      WindowState := wsFullScreen;
    ShowWindow(Handle, SW_SHOWFULLSCREEN);
    HideMouse.Enabled := True;
    GLRenderer.SetFocus;
  finally
    backend.mpvengine.isRenderActive := True;
  end
  else
  begin
    OvoLogger.Log(llDEBUG, 'Going windowed');
    backend.mpvengine.isRenderActive := False;
    Application.ProcessMessages;
    pnlChannel.Visible := True;
    ChannelSplitter.Visible := True;
    ShowWindow(Handle, ShowCommands[RestoredWindowState]);
    BorderStyle := RestoredBorderStyle;
    screen.cursor := crdefauLt;
    HideMouse.Enabled := False;
    backend.mpvengine.isRenderActive := True;
  end;

end;

end.
