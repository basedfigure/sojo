unit game3d;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LCLType, LCLIntf, OpenGLContext, gl,
  // Hood
  typmath, glport, iniutil,
  // Juju
  typutil, apputil;

type

  { cam_t - root cam }

  cam_t = object
    pos, dir, rot, up:  xyz_t;
    view, proj:  m16_t;
    near, far:  double;
  private
    procedure set_dir ();
    procedure set_m16 ();
  public
    port:  virt_view_t;
    fov:  int;
    constructor init (win: TOpenGLControl;  const fov_: int=FOV_FPV_INI);
    { Proc }
  end;


  { cam_1st_pers_t - spectator cam }

  cam_1st_pers_t = object (cam_t)
    move_rate,
    turn_rate:  f32;
    in_fly_mode:  bool;
  public
    constructor init ();
    { Proc }
    procedure move ();
    procedure turn (mx:int=0;  my:int=0;  mxy_rate:double=0);
  end;


  { cam_3rd_pers_t - player shoulder cam }

  cam_3rd_pers_t = object (cam_1st_pers_t)
    pos_was:  xyz_t;
    ang_y, ang_y_upto:  double;
  public
    constructor init ();
    { Proc }
    procedure steer ();
    procedure strafe ();
  end;


var
  fst_pers_cam:  cam_1st_pers_t;
  thd_pers_cam:  cam_3rd_pers_t;

implementation



{ cam_t . }



constructor cam_t.init (win: TOpenGLControl;  const fov_: int=FOV_FPV_INI);
{ [x] }
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

procedure cam_t.set_dir ();
{ [x] }
begin
  dir.x:=Cos (rot.x) * Sin (rot.y);
  dir.y:=Sin (rot.x);
  dir.z:=Cos (rot.x) * Cos (rot.y);
  dir.norm ();
  view.look (dir, pos, up);
end;

procedure cam_t.set_m16 ();
{ [x] }
var
  p, v:  m16_a;
begin
  glEnable (GL_DEPTH_TEST);

  p:=proj.col ();
  glMatrixMode (GL_PROJECTION);
  glLoadMatrixf (@p[0]);

  v:=view.col ();
  glMatrixMode (GL_MODELVIEW);
  glLoadMatrixf (@v[0]);
end;



{ cam_1st_pers_t . }



constructor cam_1st_pers_t.init ();
{ [x] }
begin
  inherited init (hood_port);
  move_rate:=0.3;
  turn_rate:=0.1;
end;

procedure cam_1st_pers_t.move ();
{ [x] }
var
  v, targ: xyz_t;
begin
  // WASD or ULDR
  if (GetKeyState (VK_W) < 0) or (GetKeyState (VK_UP) < 0) then begin
    v:=dir;
    v.sca (move_rate);
    pos.add (v);
  end;

  if (GetKeyState (VK_A) < 0) or (GetKeyState (VK_LEFT) < 0) then begin
    v:=up;
    v.cross (dir);
    v.norm ();
    v.sca (turn_rate);
    pos.add (v);
  end;

  if (GetKeyState (VK_S) < 0) or (GetKeyState (VK_DOWN) < 0) then begin
    v:=dir;
    v.sca (move_rate);
    pos.sub (v);
  end;

  if (GetKeyState (VK_D) < 0) or (GetKeyState (VK_RIGHT) < 0) then begin
    v:=up;
    v.cross (dir);
    v.norm ();
    v.sca (move_rate);
    pos.sub (v);
  end;

  targ:=pos;
  targ.add (dir);

  view.look (targ, pos, up);
end;

procedure cam_1st_pers_t.turn (mx:int=0;  my:int=0;  mxy_rate:double=0);
{ [x] }
const
  MAX_ROLL = 89.0 * (PI/180);
begin
  // mouse (mx, my)
  rot.y:=rot.y - mx * mxy_rate;
  rot.x:=rot.x - my * mxy_rate;

  // ULDR - works, but needs key remapping between move & turn (conflict)
  //if GetKeyState (VK_LEFT)  < 0 then rot.y:=rot.y + turn_rate;
  //if GetKeyState (VK_RIGHT) < 0 then rot.y:=rot.y - turn_rate;
  //if GetKeyState (VK_UP)    < 0 then rot.x:=rot.x + turn_rate;
  //if GetKeyState (VK_DOWN)  < 0 then rot.x:=rot.x - turn_rate;
  //
  if rot.x > MAX_ROLL then rot.x:=MAX_ROLL;
  if rot.x < -MAX_ROLL then rot.x:=-MAX_ROLL;

  set_dir ();
end;



{ cam_3rd_pers_t . }



constructor cam_3rd_pers_t.init();
begin
  inherited init ();
end;

procedure cam_3rd_pers_t.steer ();
begin

end;

procedure cam_3rd_pers_t.strafe ();
begin

end;

end.

