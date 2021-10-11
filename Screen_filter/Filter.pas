unit Filter;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Forms, Menus, Controls, ExtCtrls;

type
  TFormFilter = class(TForm)
    ImageBack: TImage;
    procedure FormCreate(Sender: TObject);
    procedure DrawFilter;
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject);
  private
    { Déclarations privées }
    Loupe:TBitmap;
    procedure ScreenCapture;
    procedure ScreenRelease;
    procedure WMActivateApp(var Msg: TWMActivateApp); message WM_ACTIVATEAPP;
    procedure WMNChitTest(var Msg: TWMNChitTest); message WM_NCHITTEST;
    procedure WMWindowPosChanged(var Msg: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure WMEraseBkGnd(var Msg: TWMEraseBkGnd); message WM_ERASEBKGND;
  public
    { Déclarations publiques }
    DeskDC : HDC;
    HDeskBmp : HBitmap;
  end;

const
  Diametre = 200;

var
  FormFilter: TFormFilter;

implementation

{$R *.DFM}

procedure TFormFilter.FormCreate(Sender: TObject);
var
  hRegion: HRgn;
begin
  Width := Diametre;
  Height := Width;
  // créer un Bitmap "off line"
  Loupe:= TBitmap.Create;
  Loupe.Width:= Width;
  Loupe.Height:= Height;
  // Fenetre ronde
  hRegion:= CreateEllipticRgn(0, 0, Width, Height);
  if hRegion<> 0 then SetWindowRgn(Handle, hRegion, TRUE);

  HDeskBmp:= 0;
  DeskDc:= 0;
  ScreenCapture;
  DrawFilter;
end;

procedure TFormFilter.FormDestroy(Sender: TObject);
begin
  ScreenRelease;
  Loupe.Free;
end;

procedure TFormFilter.ScreenCapture;
var
  MemDC: HDC;
  W, H: Integer;
begin
  if (HDeskBmp<> 0)or (DeskDC<> 0) then
    Exit;
  W:= GetSystemMetrics(SM_CXSCREEN);
  H:= GetSystemMetrics(SM_CYSCREEN);
  DeskDC:= GetDC(GetDesktopWindow);
  // Capture l'image de fond au démarrage
  // Crée en memoire un Handle de context de périphérique compatible
  MemDC:= CreateCompatibleDC(DeskDC);
  { Crée un handle de bitmap compatible avec le périphérique }
  HDeskBmp:= CreateCompatibleBitmap(DeskDC, W, H);
  { Sélectionne le bitmap }
  SelectObject(MemDC, HDeskBmp);
  { Copie le fond }
  BitBlt(MemDC, 0, 0, W, H, DeskDC, 0, 0, SRCCOPY);
  { Libère le context de périphérique }
  DeleteDC(MemDC);
end;

procedure TFormFilter.ScreenRelease;
begin
  if HDeskBmp<> 0 then
  begin
    DeleteObject(HDeskBmp);
    HDeskBmp:= 0;
  end;
  if DeskDC<> 0 then
  begin
    ReleaseDC(GetDesktopWindow, DeskDC);
    DeskDC:= 0;
  end;
end;

procedure TFormFilter.DrawFilter;
var
  DrawToDC: HDC;
  Row, Column: Integer;
  MemDC: HDC;
  OldBmp: HBitMap;
  OffsetX, OffsetY: Integer;
begin
  if Loupe= nil then
    Exit;
  DrawToDC:= Loupe.Canvas.Handle;
  // Copie l'image de fond
  MemDC:= CreateCompatibleDC(DeskDC);
  OldBmp:= SelectObject(MemDC, HDeskBmp);
  OffsetX:= Width div 4;
  OffsetY:= Height div 4;
  StretchBlt(DrawToDC, 0, 0, Width, Height, MemDC, Left + OffsetX, Top + OffsetY, Width div 2, Height div 2, SRCCOPY);
  SelectObject(MemDC, OldBmp);
  DeleteObject(MemDC);

  // Dessine ImageBack comme papier peint semi transparent
  if (ImageBack.Height<> 0)or (ImageBack.Width<> 0) then
    for Row:= 0 to Height div ImageBack.Height do
      for Column:= 0 to Width div ImageBack.Width do
        BitBlt(DrawToDC, Column*ImageBack.Width, Row*ImageBack.Height, ImageBack.Width, ImageBack.Height,
               ImageBack.Picture.Bitmap.Canvas.Handle, 0, 0, SRCAND);
  // Cadre OR
  with Loupe.Canvas do
  begin
    Brush.Color:= clYellow;
    Brush.Style:= bsClear;
    Pen.Width:= 2;
    Pen.Color:= clYellow;
    Pen.Style:= psSolid;
    Ellipse(1, 1, Width- 2, Height- 2);
    Pen.Color:= clOlive;
    Pen.Style:= psSolid;
    Ellipse(2, 2, Width- 1, Height- 1);
  end;
end;

procedure TFormFilter.WMActivateApp(var Msg: TWMActivateApp);
begin
  inherited;
  if Msg.Active then
    ScreenCapture
  else ScreenRelease;
  Msg.Result:= 0;
end;

procedure TFormFilter.WMNChitTest(var Msg: TWMNChitTest);
begin
  inherited;
  // Si le clic est sur la fiche, faire comme si il était dans la barre de titre
  if Msg.Result= htClient then
    Msg.Result:= htCaption;
end;

procedure TFormFilter.WMWindowPosChanged(var Msg: TWMWindowPosChanged);
begin
  inherited;
  DrawFilter; // réactualise la Loupe
  Invalidate;
end;

procedure TFormFilter.WMEraseBkGnd(var Msg: TWMEraseBkGnd);
begin
  Msg.Result:= 1;
end;

procedure TFormFilter.FormPaint(Sender: TObject);
begin
  Canvas.Draw(0, 0, Loupe);
end;

end.
