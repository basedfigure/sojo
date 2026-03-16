unit fmtmod;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, gl,
  // Juju:
  typutil,
  // Hood:
  typmath;

type

  { mod_t }

  mod_t = record
  // For JTF, for now
    fa: face_a;
  end;
  mod_a  = array of mod_t;

  tri_t = record
    a, b, c:  xyz_t;
  end;
  tri_a = array of tri_t;

  { mesh_t }

  mesh_t = record
  // For ART, for now
    lvert, lnorm, luv:  f32_a;
    idx:  int_a;
    nvert, nface:  int;
    quad_or_tri:  GLenum;
    ltri:  tri_a;
  end;

  { art_t }

  art_t = object
    id:  str;
  private
    file_pos:  int;
    procedure load_vmap (var o:  mesh_t;  is_quad:  bool = false);
  public
    procedure load_mesh (const path:  str;  var o:  mesh_t);
  end;

  { Func }
  function load_jtf_files_from_dsk (lpath: TStrings): mod_a;

implementation


function load_jtf_files_from_dsk (lpath: TStrings): mod_a;
var
  fs: TFileStream;
  i,j: int;
  m: mod_t;
begin
  // Original, export script for Blender at: http://runtimeterror.com/tech/jtf/
  // Blender compatibles at: io/link.txt

  // Mem OBJ to JTF converter
  SetLength (result, lpath.Count);

  for i:=0 to lpath.Count-1 do begin
    fs:=nil;
    try
      fs:=TFileStream.Create (lpath[i], fmOpenRead);
      if (fs.ReadByte <> 74) or
         (fs.ReadByte <> 84) or
         (fs.ReadByte <> 70) or
         (fs.ReadByte <> 33) then

         raise Exception.Create ('Invalid file format');

      if fs.ReadDWord <> 0 then
        raise Exception.Create ('Unknown vertex format');

      SetLength (m.fa, fs.ReadDWord);

      for j:=0 to High (m.fa) do fs.Read (m.fa[j], SizeOf (face_t));

      result[i]:=m;
    except
      on e: Exception do ShowMessage ('Error loading ' + lpath[i] + ': ' +
        e.Message);
    end;

    FreeAndNil (fs);
  end;
end;



{ art_t }



procedure art_t.load_mesh (const path: str;  var o:  mesh_t);
type
  _face_t = record
    nvert:  int;
    lidx:  int_a;
  end;
const
  SIZE_NAME = 4;
  SIZE_INT = 4;
  SIZE_VPOS = 12;
  SIZE_VNRM = 12;
  SIZE_VERT = SIZE_VPOS + SIZE_VNRM;
var
  f:  file;
  sect:  array[1..4] of char;
  s:  str;
  i, j, at_vert, at_idx, nidx, now_at:  int;
  lface:  array of _face_t;
begin
  id:=path;
  AssignFile (f, id);
  {$I-}
  Reset (f,1);
  {$I+}
  if IOResult<>0 then begin
    WriteLn ('Failed to load');
    Exit ();
  end;
  try

    while not EOF (f) do begin
      BlockRead (f, sect, SizeOf (sect));
      s:='';
      for i:=1 to Length (sect) do s:=s + sect[i];
      if s='MESH' then begin
        BlockRead (f, o.nvert, SizeOf (int));
        BlockRead (f, o.nface, SizeOf (int));
        SetLength (lface, o.nface);
        SetLength (o.lvert, o.nvert * 3);
        SetLength (o.lnorm, o.nvert * 3);

        for i:=0 to o.nvert-1 do begin
          at_vert:=i * 3;
          // vertex
          BlockRead (f, o.lvert[at_vert], SizeOf (f32));
          BlockRead (f, o.lvert[at_vert+1], SizeOf (f32));
          BlockRead (f, o.lvert[at_vert+2], SizeOf (f32));
          // ..normals
          BlockRead (f, o.lnorm[at_vert], SizeOf (f32));
          BlockRead (f, o.lnorm[at_vert+1], SizeOf (f32));
          BlockRead (f, o.lnorm[at_vert+2], SizeOf (f32));
        end;

        for i:=0 to o.nface-1 do begin
          BlockRead (f, lface[i].nvert, SizeOf (int));
          SetLength (lface[i].lidx, lface[i].nvert);

          for j:=0 to lface[i].nvert-1 do begin
            BlockRead (f, lface[i].lidx[j], SizeOf (int));
          end;

        end;

      end;
    end;

    now_at:=SIZE_NAME + SIZE_INT + SIZE_INT;
    now_at:=now_at + o.nvert * SIZE_VERT;

    for i:=0 to o.nface-1 do begin
      now_at:=now_at + SIZE_INT;
      now_at:=now_at + lface[i].nvert * SIZE_INT;
      file_pos:=now_at;
    end;

  finally
    CloseFile (f);
  end;

  if o.nface > 0 then begin
    if lface[o.nface-1].nvert = 4 then begin
      load_vmap (o, true);
      o.quad_or_tri:=GL_QUADS;
    end
    else if lface[o.nface-1].nvert = 3 then begin
      load_vmap (o, false);
      o.quad_or_tri:=GL_TRIANGLES;
    end;
  end;

  SetLength (o.lvert, o.nvert * 3);
  SetLength (o.lnorm, o.nvert * 3);
  nidx:=0;

  for i:=0 to High (lface) do begin
    nidx:=nidx + lface[i].nvert;
  end;

  SetLength (o.idx, nidx);
  at_idx:=0;

  for i:=0 to High (lface) do begin
    for j:=0 to lface[i].nvert-1 do begin
      o.idx[at_idx]:=lface[i].lidx[j];
      Inc (at_idx);
    end;
  end;

end;

procedure art_t.load_vmap (var o:  mesh_t;  is_quad:  bool = false);
var
  f:  file;
  i, j, nface, nvert, vert_idx, uv_pos_idx:  int;
  sect:  array[1..4] of char;
  s:  str;
  u, v, x, y, z:  f32;
begin
  AssignFile (f, id);
  FileMode:=fmOpenRead;
  Reset(f, 1);
  Seek (f, file_pos);
  BlockRead (f, sect, SizeOf (sect));

  s:='';
  for i:=1 to 4 do s:=s + sect[i];

  if s <> 'VMAP' then begin
    WriteLn ('VMAP not found');
    CloseFile (f);
    Exit ();
  end;

  BlockRead (f, nface, SizeOf (int));
  if is_quad then nvert:=4 else nvert:=3;

  if Length (o.luv) < o.nvert * 2 then
    SetLength (o.luv, o.nvert * 2);

  for i:=0 to nface - 1 do begin
    for j:=0 to nvert - 1 do begin
      BlockRead (f, vert_idx, SizeOf (int));
      BlockRead (f, x, SizeOf (f32));
      BlockRead (f, y, SizeOf (f32));
      BlockRead (f, z, SizeOf (f32));
      BlockRead (f, u, SizeOf (f32));
      BlockRead (f, v, SizeOf (f32));

      uv_pos_idx:=vert_idx * 2;

      if uv_pos_idx + 1 < Length (o.luv) then begin
        o.luv[uv_pos_idx]:=1.0 - u;
        o.luv[uv_pos_idx + 1]:=1.0 - (1.0 - v);

      end else begin

        WriteLn ('Out of bounds error: ', uv_pos_idx);
        CloseFile (f);
        Exit ();
      end;

    end;

  end;

  CloseFile (f);
end;

end.

