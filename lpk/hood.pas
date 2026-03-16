{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit hood;

{$warn 5023 off : no warning about unused units}
interface

uses
  fmt2d, fmtmod, game3d, gl1draw, typmath, iniutil, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('hood', @Register);
end.
