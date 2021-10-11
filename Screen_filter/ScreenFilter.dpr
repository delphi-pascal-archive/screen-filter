{
Objet       : Lentille teintée pour le fun
Auteur      : Fabrice FOUQUET
e-mail      : services@cfp47.inba.fr
Version     : 1.0.b
Date        : 09/98
}

program ScreenFilter;

uses
  Forms,
  Filter in 'Filter.pas' {FormFilter};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Screen Filter Lens';
  Application.CreateForm(TFormFilter, FormFilter);
  Application.Run;
end.
