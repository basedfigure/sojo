unit gl1draw;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, gl, OpenGLContext,
  // Juju:
  typutil,
  // Hood:
  typmath, fmtmod;

  procedure gl1_draw_tris (const fa: face_a);
  procedure gl1_draw_mods (const ma: mod_a);

var
  hood_port:  TOpenGLControl;


implementation

procedure gl1_draw_tris (const fa: face_a);

  procedure draw_v(const v: vert_t);
  begin
    glVertex3f(v.x, v.y, v.z);
  end;

  procedure draw_f(const f: face_t);
  begin
    draw_v(f.a);
    draw_v(f.b);
    draw_v(f.c);
  end;

var
  i: int;
begin
  glBegin(GL_TRIANGLES);
  for i:=0 to High(fa) do draw_f(fa[i]);
  glEnd();
end;

procedure gl1_draw_mods (const ma: mod_a);
var
  i: int;
begin
  for i:=0 to High(ma) do gl1_draw_tris(ma[i].fa);
end;

end.

