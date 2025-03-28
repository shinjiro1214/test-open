%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 磁気プローブ、静電プローブによる
% 磁気面、静電ポテンシャル、ExBドリフトをプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

% ESP.date = 230826;%計測日
% ESP.shotlist = [6 8 10 11 12 16 17 19 20 22 24 25 26 29 32 34 35 37 38 43 45 47 49 51 53 55];%shot番号
% PCB.date = 230826;%【input】重ねる磁気面計測日
% PCB.IDX = 22;

% ESP.date = 230826;%計測日
% ESP.shotlist = [7 9 13 15 18 21 23 27 28 30 31 33 36 39 40 41 42 44 46 48 50 52 54 56:60];%shot番号
% PCB.date = 230826;%【input】重ねる磁気面計測日
% PCB.IDX = 21;

% % FC合体、X点R=0.2m、ExBアウトフロー小。IDSP->230828,230829(delay=480,484,488us)
% ESP.date = 230828;%【input】静電プローブ計測日
% ESP.shotlist = [5 6 8:12 15:17 19:23 25:27 31:61 63];
% FIG.start = 480;%【input】プロット開始時刻[us]
% FIG.dt = 1;%【input】プロット時間間隔[us]
% PCB.date = 230828;%【input】重ねる磁気面計測日
% PCB.IDX = 15;

% %SEP合体、X点R=0.26m、ExBアウトフロー大。IDSP->230830,230831(delay=468, 472, 476us)
ESP.date = 230830;%【input】静電プローブ計測日
ESP.shotlist = [13 14 16 17 20 22 23 25 26 32 37 41:45 47 49 51 54 55 57];%[11 13 14 16 17 20 22:26 28 29 32 34 37 41:45 47 49 51 54 55 57 59 60]【input】静電プローブ解析shotlist(同一オペレーション)
ESP.ng_ch = [4 6 16];
FIG.start = 478;%【input】プロット開始時刻[us]
FIG.dt = 4;%【input】プロット時間間隔[us]
PCB.date = 230830;%【input】重ねる磁気面計測日
PCB.IDX = 22;%【input】重ねる磁気面shot番号

% % 同極性スフェロマック合体 + 外部TF4kV
% ESP.date = 240827;%【input】静電プローブ計測日
% ESP.shotlist = [11:20 22:45 47:51];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.ng_ch = [4 11 12 14:21];
% FIG.start = 470;%【input】プロット開始時刻[us]
% FIG.dt = 4;%【input】プロット時間間隔[us]
% PCB.date = 240827;%【input】重ねる磁気面計測日
% PCB.IDX = 22;%【input】重ねる磁気面shot番号

% % 同極性スフェロマック合体 + 外部TF5kV
% ESP.date = 240828;%【input】静電プローブ計測日
% ESP.shotlist = [30:41 43:46 48:54];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.ng_ch = [14:21];
% FIG.start = 470;%【input】プロット開始時刻[us]
% FIG.dt = 4;%【input】プロット時間間隔[us]
% PCB.date = 240828;%【input】重ねる磁気面計測日
% PCB.IDX = 30;%【input】重ねる磁気面shot番号

% % 同極性スフェロマック合体 + 外部TF6kV
% ESP.date = 240828;%【input】静電プローブ計測日
% ESP.shotlist = [3:12 14:22 25:29];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.ng_ch = [14:21];
% FIG.start = 470;%【input】プロット開始時刻[us]
% FIG.dt = 4;%【input】プロット時間間隔[us]
% PCB.date = 240828;%【input】重ねる磁気面計測日
% PCB.IDX = 12;%【input】重ねる磁気面shot番号

FIG.tate = 1;%【input】プロット枚数(縦)
FIG.yoko = 1;%【input】プロット枚数(横)

ESP.mesh = 21;%【input】静電プローブ補間メッシュ数(21)
% ESP.mesh = 40;%【input】静電プローブ補間メッシュ数
ESP.trange = 450:0.1:500;%【input】静電プローブ計算時間範囲(0.1us刻み)
ExB.trange = 450:500;%【input】ExB計算時間範囲(1us刻み)
% ESP.vector = true;%【input】電場ベクトルをプロット

color_type = 'Jt';%【input】カラープロット種類('phi','psi','Ez','Er','Et',...
% 'Bz','Br','Bt_plasma','absB','absB2','Jt','VExBr','VExBz','|VExB|',...
% 'EdotB','absE','absE2','cosEB','angleEB')
vector_type = '';%【input】ベクトルプロット種類('Ep','VExB')

% profileplot = 'VExBz';%【input】一次元プロット種類('VExBr','VExBz','|VExB|')

PCB.mesh = 40; %【input】psiのrz方向メッシュ数
PCB.trange = 400:800;%【input】psi計算時間範囲

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,ESP.date);
ESP.rlist=T.ESProbeRPosition_mm_(ESP.shotlist);%静電プローブr座標[mm]
shot_a039 =T.a039(PCB.IDX);
shot_a040 = T.a040(PCB.IDX);
PCB.shot = [shot_a039, shot_a040];
tfshot_a039 =T.a039_TF(PCB.IDX);
tfshot_a040 =T.a040_TF(PCB.IDX);
PCB.tfshot = [tfshot_a039, tfshot_a040];
PCB.i_EF=T.EF_A_(PCB.IDX);
IDSPminZlist=T.IDSPZ_cm_(PCB.IDX);
IDSPminRlist=T.IDSPMinR_cm_(PCB.IDX);

IDSP.z = IDSPminZlist*ones(7,1)*1E-2;
IDSP.r = (IDSPminRlist:2.5:IDSPminRlist+6*2.5)*1E-2;

%静電プローブ計算
ESPdata2D = cal_ESP(pathname,ESP);
%磁気プローブ計算
[PCBgrid2D,PCBdata2D] = cal_psi(PCB,pathname);
% ExBドリフト計算
[ExBdata2D,newPCBdata2D] = cal_ExB(pathname,PCBgrid2D,PCBdata2D,ESPdata2D,ESP,PCB,ExB.trange);

% 磁気面、ExBドリフト2次元プロット
plot_ExB(PCBgrid2D,PCBdata2D,ESPdata2D,ExBdata2D,newPCBdata2D,IDSP,FIG,color_type,vector_type,false)

% %磁気面、ExBドリフト2次元プロット
% movie_ExB(PCBgrid2D,PCBdata2D,ESPdata2D,ExBdata2D,newPCBdata2D,IDSP,FIG,color_type,vector_type)
%ExBドリフト1次元プロット
% plot_flow_profile(ExBdata2D,IDSP,FIG,profileplot)
