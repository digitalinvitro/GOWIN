unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Grids, synaser, inifiles, strutils;

type

  { TMainForm }

  TMainForm = class(TForm)
    StatusBar: TStatusBar;
    DumpRAM: TStringGrid;
    DebugTimer: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure DebugTimerTimer(Sender: TObject);
  private

  public
    settings           :              TIniFile;
    serial             :              TBlockSerial;
    buff               :              String;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.DebugTimerTimer(Sender: TObject);
var
  address,
  i       :                     integer;
begin
  Enabled := false;

  buff := '';
  buff := serial.RecvBufferStr(150, 200);

  while buff <> '' do begin  // Recive data, parse him

    with StatusBar.Panels[1] do begin
      text := text + '*';
      if length(text) > 8 then text := '';
    end;

    if buff[1] = '$' then begin
      if length(buff) < (6+2) then break;

      // start token for ADDRESS
      address := Hex2Dec(copy(buff,2,4));
      DumpRAM.Cells[0, 1 + (address SHR 4)] := copy(buff,2,4);
      delete(buff,1,6);  // $XXXX#
      i := 1;
      while length(buff) >= 2 do begin
        DumpRAM.Cells[i, 1 + (address SHR 4)] := copy(buff,1,2);
        inc(i);
        delete(buff,1,2);
        if length(buff) < 3 then break;
        delete(buff,1,1);
        if buff[1] = #13 then break;
      end;

    end else delete(buff, 1, 1);
  end;

  Enabled := true;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  port    :                            string;
  i       :                            integer;
begin
  settings := TIniFile.Create('settings.ini');
  if settings <> NIL then begin
    port := settings.ReadString('interfaces', 'serial', 'COM1');
    StatusBar.Panels[0].text := 'serial : ' + port;

    serial:=TBlockSerial.Create;
    serial.Connect(port);
    sleep(100);
    serial.config(115200, 8, 'N', SB1, False, False);
    sleep(100);

    DebugTimer.Enabled := true;
  end;
  for i:=0 to 15 do DumpRAM.Cells[i+1, 0] := IntToHex(i,2);
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  DebugTimer.Enabled := false;
  sleep(500);
  serial.CloseSocket;
  serial.Free;
end;

end.

