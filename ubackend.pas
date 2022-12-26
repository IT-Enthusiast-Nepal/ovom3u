{
This file is part of OvoM3U
Copyright (C) 2020 Marco Caselli

OvoPlayer is free software; you can redistribute it and/or
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
unit uBackEnd;

interface

uses
  Classes, SysUtils, fptimer, um3uloader, epg, Config, MPV_Engine, LoggerUnit,
  GeneralFunc, BaseTypes, OpenGLContext, cec_intf;

type
  ExternalInput = procedure(Sender: TObject; var Key: Word) of Object;

  { TPluginsProperties }

  TPluginsProperties = Class(TConfigParam)
  private
    FEnableCEC: boolean;
    procedure SetEnableCEC(AValue: boolean);
  Protected
    Procedure InternalSave; override;
  public
    Property EnableCEC: boolean read FEnableCEC write SetEnableCEC;

    Procedure Load; override;

  end;

  { TBackend }

  TBackend = class
  private
    FOnExternalInput: ExternalInput;
    procedure OSDTimerTimer(Sender: TObject);
    procedure SetOnExternalInput(AValue: ExternalInput);
    procedure CecKey(Sender: TObject; var Key: word);
  public
    List: TM3ULoader;
    EpgData: TEpg;

    HDMI_CEC: THDMI_CEC;
    MpvEngine: TMPVEngine;
    OSDTimer: TFPTimer;
    Loading: boolean;
    PreviousIndex, CurrentIndex:integer;
    ShowingInfo: boolean;

  public
    PluginsProperties: TPluginsProperties;
    procedure ShowEpg;
    procedure OsdMessage(Message: string; TimeOut: boolean=True);
    procedure LoadList;
    function InitializeEngine(Renderer: TOpenGLControl): boolean;
    procedure Play(index:integer);
    Procedure SwapChannel;
  public
    Property OnExternalInput: ExternalInput read FOnExternalInput write SetOnExternalInput;
    constructor Create;
    destructor Destroy; override;
  end;

function BackEnd: TBackend;

implementation

var
  fBackend: TBackend;

function BackEnd: TBackend;
begin
  if not Assigned(fBackend) then
    fBackend := TBackend.Create;
  Result := fBackend;
end;
{ TPluginsProperties }

procedure TPluginsProperties.SetEnableCEC(AValue: boolean);
begin
  if FEnableCEC=AValue then Exit;
  FEnableCEC:=AValue;
  Dirty := true;
end;

procedure TPluginsProperties.InternalSave;
begin
 Owner.WriteBoolean('Plugins/HDMI-CEC/Enabled', EnableCEC);
end;

procedure TPluginsProperties.Load;
begin
 EnableCEC := Owner.ReadBoolean('Plugins/HDMI-CEC/Enabled', false);
 Dirty:=false;
end;

{ TBackend }
procedure TBackend.LoadList;
var
  CacheDir, IPTVList: string;
  Kind: TProviderKind;

begin

  Kind := List.ListProperties.ChannelsKind;

  if Kind = URL then
  begin
    CacheDir := ConfigObj.CacheDir;
    IPTVList := List.ListProperties.ChannelsUrl;
    try
      if (epgData.LastScan('channels') + 12 / 24 < now) or List.ListProperties.Dirty then
      begin
        try
          OvoLogger.Log(llINFO, 'Downloding channels list from ' + IPTVList);
          DownloadFromUrl(IPTVList, CacheDir + 'current-iptv.m3u');
          epgData.SetLastScan('channels', now);
        except
          on e: Exception do
            OvoLogger.Log(llERROR, 'Can''t download list at: ' +
              IPTVList + ' error:' +
              E.Message);
        end;
      end
      else
        OvoLogger.Log(llINFO, 'Using cached channels list');

      IPTVList := CacheDir + 'current-iptv.m3u';
    finally
    end;
  end
  else
    IPTVList := list.ListProperties.ChannelsFileName;

  if FileExists(IPTVList) then
    list.Load(IPTVList);

  OvoLogger.Log(llINFO, 'Found %d channels', [BackEnd.List.Count]);

  if List.ListProperties.UseChno then
  begin
    List.FixChannelNumbering;
    OvoLogger.Log(llINFO, 'Renumber channels using tvg-chno');
  end;

  if BackEnd.List.ListMd5 <> BackEnd.epgData.LastChannelMd5 then
  begin
    OvoLogger.Log(llINFO, 'Channels list changed, reloading EPG');
    epgData.LoadChannelList(List);
    epgData.SetLastChannelMd5(List.ListMd5);
    epgData.SetLastScan('epg', 0);
  end;

  if List.ListProperties.ChannelsDownloadLogo then
    List.UpdateLogo;

  if not EpgData.EpgProperties.EPGUrl.IsEmpty or not EpgData.EpgProperties.EpgFileName.IsEmpty then
    epgData.Scan
  else
    OvoLogger.Log(llINFO, 'No EPG configuration, skipping');

end;


function TBackend.InitializeEngine(Renderer: TOpenGLControl): boolean;
begin
  mpvengine := TMPVEngine.Create;
  Result := MpvEngine.Initialize(Renderer);
end;

procedure TBackend.OsdMessage(Message: string; TimeOut: boolean = True);
begin

  if MpvEngine.GLRenderControl.Visible then
  begin
    mpvengine.OsdMessage(message);
    OSDTimer.Enabled := TimeOut;
  end;

end;

procedure TBackend.Play(index: integer);
var
  fLastMessage: String;
begin

    if (Index > List.Count) or (Index < 0) then
    begin
      OsdMessage('No Channel', True);
      exit;
    end;

    if (CurrentIndex = Index) and not mpvengine.IsIdle then
      exit;

    if list[Index].Mrl.IsEmpty then
    begin
      OsdMessage('Missing Channel Address', True);
      exit;
    end;

    OvoLogger.Log(llINFO, 'Tuning to %s',[list[Index].Title]);


    PreviousIndex := CurrentIndex;
    CurrentIndex := Index;
    mpvengine.Play(BackEnd.list[CurrentIndex].Mrl);
    Loading := True;
    fLastMessage := 'Loading: ' + BackEnd.list[CurrentIndex].title;
    OsdMessage(fLastMessage);
end;

procedure TBackend.SwapChannel;
begin
    if PreviousIndex <> -1 then
      Play(PreviousIndex);
end;


procedure TBackend.ShowEpg;
var
  Info: REpgInfo;
begin
  if not ShowingInfo and (currentIndex <> -1) then
  begin
    Info := epgData.GetEpgInfo(CurrentIndex, now);
    mpvengine.OsdEpg(Format('%3.3d: %s', [List[CurrentIndex].Number, BackEnd.List[CurrentIndex].title]), info, True);
    ShowingInfo := True;
    OSDTimer.Enabled := True;
  end
  else
  begin
    OSDTimerTimer(self);
  end;

end;

procedure TBackend.OSDTimerTimer(Sender: TObject);
begin

  if MpvEngine.GLRenderControl.Visible then
  begin
    mpvengine.OsdEpg('', Default(REpgInfo), False);
    mpvengine.OsdMessage();
    ShowingInfo:= false;
  end;
  OSDTimer.Enabled := False;
end;

procedure TBackend.SetOnExternalInput(AValue: ExternalInput);
begin
  FOnExternalInput:=AValue;
end;

procedure TBackend.CecKey(Sender: TObject; var Key: word);
begin
  if Assigned(FOnExternalInput) then
   FOnExternalInput(Sender, key);
end;


constructor TBackend.Create;
begin
  PluginsProperties:= TPluginsProperties.Create(ConfigObj);

  List := TM3ULoader.Create;
  EpgData := TEpg.Create;

  if PluginsProperties.EnableCEC then
    try
      HDMI_CEC:= THDMI_CEC.create;
      HDMI_CEC.OnCecKey:= CecKey;
    Except
      on e: exception do
        begin
          OvoLogger.Log(llERROR, 'CEC ->'+ e.Message);
          HDMI_CEC := nil;
        end;
    end
  else
    HDMI_CEC := nil;

  OSDTimer:= TFPTimer.Create(nil);
  OSDTimer.Enabled := False;
  OSDTimer.Interval := 8000;
  OSDTimer.OnTimer := OSDTimerTimer;
  CurrentIndex := -1;
  PreviousIndex := -1;
  ShowingInfo := False;

end;

destructor TBackend.Destroy;
begin
  MpvEngine.Free;
  OsdTimer.Free;
  EpgData.Free;
  List.Free;
  HDMI_CEC.free;
  inherited Destroy;
end;


initialization
  fBackend := nil;

finalization
  fBackend.Free;
end.
