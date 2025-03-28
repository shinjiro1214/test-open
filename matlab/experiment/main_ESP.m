%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 静電プローブによる
% 静電ポテンシャル、電場ベクトルをプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';

run define_path.m

% % FC合体、X点R=0.2m、ExBアウトフロー小。IDSP->230828,230829(delay=480,484,488us)
% ESP.date = 230828;%【input】静電プローブ計測日
% ESP.shotlist = [5 6 8:12 15:17 19:23 25:27 31:61 63];
% ESP.start = 482;%【input】プロット開始時刻[us]

% %SEP合体、X点R=0.26m、ExBアウトフロー大。IDSP->230830,230831(delay=468, 472, 476us)
% ESP.date = 230830;%【input】静電プローブ計測日
% ESP.shotlist = [11:20 22:36];%[11 13 14 16 17 20 22:26 28 29 32 34 37 41:45 47 49 51 54 55 57 59 60];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.start = 460;%【input】プロット開始時刻[us]

ESP.date = 230830;%【input】静電プローブ計測日
ESP.shotlist = [9 12 15 18 19 21 27 30 31 33 35 36 38 40 46 48 52 53];
ESP.start = 462;%【input】プロット開始時刻[us]
ESP.ng_ch = [4 6 16];

% % 同極性スフェロマック合体 + 外部TF4kV
% ESP.date = 240827;%【input】静電プローブ計測日
% ESP.shotlist = [11:20 22:45 47:51];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.ng_ch = [4 11 12 14:21];
% ESP.start = 450;%【input】プロット開始時刻[us]

% % 同極性スフェロマック合体 + 外部TF5kV
% ESP.date = 240828;%【input】静電プローブ計測日
% ESP.shotlist = [30:41 43:46 48:54];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.ng_ch = [14:21];
% ESP.start = 450;%【input】プロット開始時刻[us]

% % 同極性スフェロマック合体 + 外部TF6kV
% ESP.date = 240828;%【input】静電プローブ計測日
% ESP.shotlist = [3:12 14:22 25:29];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.ng_ch = [14:21];
% ESP.start = 450;%【input】プロット開始時刻[us]

ESP.mesh = 21;%【input】静電プローブ補間メッシュ数
ESP.trange = 450:0.1:500;%【input】計算時間範囲(0.1刻み)
ESP.tate = 2;%【input】プロット枚数(縦)
ESP.yoko = 4;%【input】プロット枚数(横)
ESP.dt = 4;%【input】プロット時間間隔[us]
ESP.vector = true;%【input】電場ベクトルをプロット
colorplot = 'phi';%【input】カラープロット種類('phi','Er','Ez')

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,ESP.date);
ESP.rlist=T.ESProbeRPosition_mm_(ESP.shotlist);%静電プローブr座標[mm]

ESPdata2D = cal_ESP(pathname,ESP);

plot_ESP(ESP,ESPdata2D,colorplot)
% movie_ESP(ESP,ESPdata2D,colorplot)