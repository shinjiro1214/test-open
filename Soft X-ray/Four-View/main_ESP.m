addpath '/Users/shohgookazaki/Documents/matlab/common';
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
run define_path.m

ESP.date = 241230;
TF = 4;
Case = 'I';
%【input】重ねる磁気面shot番号
color_type = 'fermi';%【input】カラープロット種類('phi','psi','Ez','Er','Et',...
% 'Bz','Br','Bt_ext','Bt_plasma','absB','absB2','Jt','VExBr','VExBz','|VExB|', 'betatron', 'fermi')
vector_type = '';%【input】ベクトルプロット種類('Ep','VExB')
ESP.restart = 0;

%【input】静電プローブ解析shotlist(同一オペレーション)

if ESP.date ==  240828 %【input】静電プローブ計測日 %TF6V
    ESP.probe = 1; % 1: Someyasan, 2: Uebosan
    if TF == 6
        PCB.idx = 28;
        ESP.shotlist = [3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29];
    elseif TF == 5
        PCB.idx = 30;
        ESP.shotlist = [30 31 32 33 34 35 36 37 38 39 40 41 43 44 45 46 48 49 50 51 52 53 54];
    end
elseif ESP.date == 240827 % TF4V
    ESP.probe = 1; % 1: Someyasan, 2: Uebosan
    PCB.idx = 28;
    ESP.shotlist = [11 12 13 14 15 16 17 18 19 20 22 23 24 25 26 27 28 29 30 31 32 34 35 36 37 38 39 40 41 42 43 44 45 47 48 49 50 51];% PCBはshot12
elseif ESP.date == 230830
    ESP.probe = 1; % 1: Someyasan, 2: Uebosan
    ESP.shotlist = [6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 59 60];
elseif ESP.date == 230826 % TF4V
    ESP.probe = 1; % 1: Someyasan, 2: Uebosan
    ESP.shotlist = [6 7 8 9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60];
elseif ESP.date == 241230%異極性
    
    ESP.probe = 2;
    if Case == 'I'
        PCB.idx = 56;
        % ESP.shotlist = [41:42, 54:57, 60:64]; %case-I
        ESP.shotlist = [41, 44, 45, 47,58, 51, 52, 54:57, 59, 60, 62, 64];
        % ESP.shotlist = [41:64];
    elseif Case == 'O'
        PCB.idx = 103;
        ESP.shotlist = [65, 67, 68, 70, 72:75, 77:84, 86:89]; % Case-O
    end
end



FIG.start = 465;%【input】プロット開始時刻[us]
FIG.dt = 1;%【input】プロット時間間隔[us]
PCB.date = ESP.date;%【input】重ねる磁気面計測日


FIG.tate = 6;%【input】プロット枚数(縦) 
FIG.yoko = 6;%【input】プロット枚数(横)

ESP.mesh = 21;%【input】静電プローブ補間メッシュ数(21)
% ESP.mesh = 40;%【input】静電プローブ補間メッシュ数
ESP.trange = 400:0.1:550;%【input】計算時間範囲(0.1刻み)
ESP.vector = false;%【input】電場ベクトルをプロット


% profileplot = 'VExBz';%【input】一次元プロット種類('VExBr','VExBz','|VExB|')

PCB.mesh = 40; %【input】psiのrz方向メッシュ数
PCB.trange = 400:600;%【input】psi計算時間範囲
PCB.date = ESP.date;
PCB.n=PCB.mesh;
PCB.restart = 0;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,PCB.date);

if ESP.probe == 1
    ESP.rlist=T.ESProbeRPosition_mm_(ESP.shotlist);%静電プローブr座標[mm] % someyasan
elseif ESP.probe == 2
    ESP.rlist=T.MachProbeRPosition_cm_(ESP.shotlist)*10;%静電プローブr座標[mm] % Uebosan
end

shot_a039 =T.a039(PCB.idx);
shot_a040 = T.a040(PCB.idx);
PCB.shot = [shot_a039, shot_a040];
tfshot_a039 =T.a039_TF(PCB.idx);
tfshot_a040 =T.a040_TF(PCB.idx);
PCB.tfshot = [tfshot_a039, tfshot_a040];
PCB.i_EF=T.EF_A_(PCB.idx);
IDSPminZlist=T.IDSPZ_cm_(PCB.idx);
IDSPminRlist=T.IDSPMinR_cm_(PCB.idx);

IDSP.z = IDSPminZlist*ones(7,1)*1E-2;
IDSP.r = (IDSPminRlist:2.5:IDSPminRlist+6*2.5)*1E-2;

%静電プローブ計算
if ESP.probe == 1
    ESPdata2D = cal_ESP(pathname,ESP); % Someyasan
elseif ESP.probe == 2
    ESPdata2D = cal_ESP_Uebosan(pathname, ESP); % Uebosan
end

%磁気プローブ計算
[PCBgrid2D,PCBdata2D] = process_PCBdata_280ch(PCB, pathname);

%ExBドリフト計算
[ExBdata2D,newPCBdata2D] = cal_ExB(pathname,PCBgrid2D,PCBdata2D,ESPdata2D,ESP,PCB,FIG);

%磁気面、ExBドリフト2次元プロット
plot_ESP(PCBgrid2D,PCBdata2D,ESPdata2D,ExBdata2D,newPCBdata2D,IDSP,FIG,color_type,vector_type,false, ESP,PCB)

%磁気面、ExBドリフト2次元プロット
% movie_ExB(PCBgrid2D,PCBdata2D,ESPdata2D,ExBdata2D,newPCBdata2D,IDSP,FIG,colorplot)
%ExBドリフト1次元プロット
% plot_flow_profile(ExBdata2D,IDSP,FIG,profileplot)

% [dBxBdata2D] = cal_dBxB(pathname,PCBgrid2D,PCBdata2D,PCB,FIG);