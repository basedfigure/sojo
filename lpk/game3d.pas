unit game3d;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, OpenGLContext,
  // Hood
  typmath, gl1draw, iniutil,
  // Juju
  typutil, apputil;

type

  { cam_t - root cam }

  cam_t = object
    pos, dir, rot, up:  xyz_t;
    view, proj:  m16_t;
    near, far:  double;
  private
    procedure set_dir;
    procedure set_m16;
  public
    port:  virt_view_t;
    fov:  int;
    constructor init (win: TOpenGLControl;  const fov_: int=FOV_FPV_INI);
    { Proc }
  end;


  { cam_1st_pers - spectator cam }

  cam_1st_pers = object(cam_t)
    move_rate,
    turn_rate:  f32;
    in_fly_mode:  bool;
  public
    constructor init ();
    { Proc }
    procedure move ();
    procedure turn (mx:int=0;  my:int=0;  mxy_rate:single=0);
  end;


  { cam_3rd_pers - shoulder cam }

  cam_3rd_pers = object (cam_1st_pers)
    pos_was:  xyz_t;
    ang_y, ang_y_upto:  double;
  public
    constructor init ();
    { Proc }
    procedure steer ();
    procedure strafe ();
  end;


implementation



{ cam_t . }



constructor cam_t.init (win: TOpenGLControl;  const fov_: int=FOV_FPV_INI);
var
  rat:  f32;
begin
  rat:=win.Width / win.Height;
  port.win.rat:=rat;
  fov:=fov_;
  near:=0.1;
  far:=1000;
  proj.id ();  // () = visibility,
               //with certain gl calls you do need them, or you get weird errors
  proj.pers (fov_, rat, near, far);
  view.id ();
  pos:=xyz (0,5,-20);
  dir:=xyz (0,0,0);
  up:=xyz (0,1,0);
end;

procedure cam_t.set_dir;
begin

end;

procedure cam_t.set_m16;
begin

end;



{ cam_1st_pers . }



constructor cam_1st_pers.init ();
begin
  inherited init (hood_port);
  move_rate:=0.3;
  turn_rate:=0.1;
end;

procedure cam_1st_pers.move ();
begin

end;

procedure cam_1st_pers.turn (mx:int;  my:int;  mxy_rate:single);
begin

end;



{ cam_3rd_pers . }



constructor cam_3rd_pers.init();
begin
  inherited init ();
end;

procedure cam_3rd_pers.steer ();
begin

end;

procedure cam_3rd_pers.strafe ();
begin

end;

end.

