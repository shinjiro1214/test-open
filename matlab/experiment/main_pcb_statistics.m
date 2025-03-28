%%磁気プローブデータの再現性チェック

clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common'
run define_path.m

% SEP合体、X点R=0.26m、ExBアウトフロー大。IDSP->230830,230831
date = [230830;230831];%【input】磁気プローブ計測日
PCB.shotlist1 = [13 14 16 17 20 22 23 25 26 32 37 41:45 47 49 51 54 55 57];%【input】磁気プローブ統計解析shotlist(同一オペレーション)(Day1)
PCB.shotlist2 = [11 12 14 16 21 28 29 36 37:49];%【input】磁気プローブ統計解析shotlist(同一オペレーション)(Day2)
PCB_STA.start = 450;%【input】統計計算開始時刻[us]
PCB_STA.end = 500;%【input】統計計算開始時刻[us]
FIG.start = 462;%【input】プロット開始時刻[us]
FIG.dt = 4;%【input】プロット時間間隔[us]

% % 同極性スフェロマック合体 + 外部TF4kV
% date = 240827;%【input】磁気プローブ計測日
% PCB.shotlist = [11:20 22:45 47:51];%【input】磁気プローブ統計解析shotlist(同一オペレーション)
% PCB_STA.start = 450;%【input】統計計算開始時刻[us]
% PCB_STA.end = 500;%【input】統計計算開始時刻[us]
% FIG.start = 476;%【input】プロット開始時刻[us]
% FIG.dt = 10;%【input】プロット時間間隔[us]

% % 同極性スフェロマック合体 + 外部TF5kV
% date = 240828;%【input】磁気プローブ計測日
% PCB.shotlist = [30:41 43:46 48:54];%【input】磁気プローブ統計解析shotlist(同一オペレーション)
% PCB_STA.start = 450;%【input】統計計算開始時刻[us]
% PCB_STA.end = 500;%【input】統計計算開始時刻[us]
% FIG.start = 479;%【input】プロット開始時刻[us]
% FIG.dt = 10;%【input】プロット時間間隔[us]

% % 同極性スフェロマック合体 + 外部TF6kV
% date = 240828;%【input】磁気プローブ計測日
% PCB.shotlist = [3:12 14:22 25:29];%【input】磁気プローブ解析shotlist(同一オペレーション)
% PCB_STA.start = 450;%【input】統計計算開始時刻[us]
% PCB_STA.end = 500;%【input】統計計算開始時刻[us]
% FIG.start = 450;%【input】プロット開始時刻[us]
% FIG.dt = 10;%【input】プロット時間間隔[us]

PCB.mesh = 40; %【input】psiのrz方向メッシュ数
PCB.trange = 400:800;%【input】psi計算時間範囲

plot_type = 'mean';%【input】プロット種類('mean','std','both')
color_type = 'Jt';%【input】カラープロット種類('psi','Et',...
% 'Bz','Br','Bt','Bt_plasma','Bt_ext','Jt')
FIG.tate = 2;%【input】プロット枚数(縦)
FIG.yoko = 4;%【input】プロット枚数(横)

%計算rz範囲オプション
z_min = 1;%【input】PCBメッシュ計算範囲の列番号下限
z_max = 40;%【input】PCBメッシュ計算範囲の列番号上限
r_min = 1;%【input】PCBメッシュ計算範囲の行番号下限
r_max = 40;%【input】PCBメッシュ計算範囲の行番号上限

num_z = z_max - z_min +1;
num_r = r_max - r_min +1;
num_t = PCB_STA.end - PCB_STA.start + 1;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
%--------実験ログ取得(day1)---------
T1=searchlog(T,node,date(1));
PCB.shotlist1(ismember(PCB.shotlist1,T1.shot)==0) = [];
PCB.datelist = date(1)*ones(numel(PCB.shotlist1),1);
PCB.shotlist = PCB.shotlist1;
n_data=numel(PCB.shotlist1);%計測shot数
PCBshotlist_a039 =T1.a039(PCB.shotlist1);
PCBshotlist_a040 = T1.a040(PCB.shotlist1);
PCBshotlist = [PCBshotlist_a039, PCBshotlist_a040];
PCBtfshotlist_a039 =T1.a039_TF(PCB.shotlist1);
PCBtfshotlist_a040 =T1.a040_TF(PCB.shotlist1);
PCBtfshotlist = [PCBtfshotlist_a039, PCBtfshotlist_a040];
PF1list=T1.CB1_kV_(PCB.shotlist1);
PF2list=T1.CB2_kV_(PCB.shotlist1);
TFlist=T1.TF_kV_(PCB.shotlist1);
EFlist=T1.EF_A_(PCB.shotlist1);
shotlistname = [num2str(date(1)),'_shot'];

if numel(date) > 1
    %--------実験ログ取得(day2)---------
    T2=searchlog(T,node,date(2));
    PCB.shotlist2(ismember(PCB.shotlist2,T2.shot)==0) = [];
    PCB.datelist = [PCB.datelist;date(2)*ones(numel(PCB.shotlist2),1)];
    PCB.shotlist = [PCB.shotlist,PCB.shotlist2];
    n_data=n_data+numel(PCB.shotlist2);%計測shot数
    PCBshotlist_a039 = [PCBshotlist_a039;T2.a039(PCB.shotlist2)];
    PCBshotlist_a040 = [PCBshotlist_a040;T2.a040(PCB.shotlist2)];
    PCBshotlist = [PCBshotlist_a039, PCBshotlist_a040];
    PCBtfshotlist_a039 =[PCBtfshotlist_a039;T2.a039_TF(PCB.shotlist2)];
    PCBtfshotlist_a040 =[PCBtfshotlist_a040;T2.a040_TF(PCB.shotlist2)];
    PCBtfshotlist = [PCBtfshotlist_a039, PCBtfshotlist_a040];
    PF1list=[PF1list;T2.CB1_kV_(PCB.shotlist2)];
    PF2list=[PF2list;T2.CB2_kV_(PCB.shotlist2)];
    TFlist=[TFlist;T2.TF_kV_(PCB.shotlist2)];
    EFlist=[EFlist;T2.EF_A_(PCB.shotlist2)];
    shotlistname = [num2str(date(1)),'-',num2str(date(2)),'_shot'];
end

%ファイル名をshot番号リストに対応して命名
dirname = [pathname.mat,'/PCB_STA/'];
for i_shot = 1:numel(PCB.shotlist)
    if i_shot == 1
        shotlistname =[shotlistname,num2str(PCB.shotlist(i_shot))];
    else
        if PCB.shotlist(i_shot) == PCB.shotlist(i_shot-1)+1%連番の場合間の番号をファイル名に含まない
            if i_shot < numel(PCB.shotlist)
                if PCB.shotlist(i_shot+1) > PCB.shotlist(i_shot)+1
                    shotlistname =[shotlistname,'-',num2str(PCB.shotlist(i_shot))];
                end
            else
                shotlistname =[shotlistname,'-',num2str(PCB.shotlist(i_shot))];
            end
        else%連番でない場合ファイル名に含む
            shotlistname =[shotlistname,'_',num2str(PCB.shotlist(i_shot))];
        end
    end
end
savename = [dirname,shotlistname,'_',num2str(PCB_STA.start),'-',num2str(PCB_STA.end),'.mat'];

if exist(savename,"file")
    load(savename)
else
    PCB_STAdata2D=struct(...
        'trange',PCB_STA.start:PCB_STA.end,...
        'psi',zeros(num_r,num_z,num_t),...
        'Bz',zeros(num_r,num_z,num_t),...
        'Bt',zeros(num_r,num_z,num_t),...
        'Bt_plasma',zeros(num_r,num_z,num_t),...
        'Bt_ext',zeros(num_r,num_z,num_t),...
        'Br',zeros(num_r,num_z,num_t),...
        'Jt',zeros(num_r,num_z,num_t),...
        'Jz',zeros(num_r,num_z,num_t),...
        'Jr',zeros(num_r,num_z,num_t),...
        'Et',zeros(num_r,num_z,num_t), ...
        'psi_std',zeros(num_r,num_z,num_t),...
        'Bz_std',zeros(num_r,num_z,num_t),...
        'Bt_std',zeros(num_r,num_z,num_t),...
        'Bt_plasma_std',zeros(num_r,num_z,num_t),...
        'Bt_ext_std',zeros(num_r,num_z,num_t),...
        'Br_std',zeros(num_r,num_z,num_t),...
        'Jt_std',zeros(num_r,num_z,num_t),...
        'Jz_std',zeros(num_r,num_z,num_t),...
        'Jr_std',zeros(num_r,num_z,num_t),...
        'Et_std',zeros(num_r,num_z,num_t));
    for i_t = 1:num_t
        buf_psi = zeros(num_r,num_z,numel(PCB.shotlist));
        buf_Bz = buf_psi;
        buf_Bt = buf_psi;
        buf_Bt_plasma = buf_psi;
        buf_Bt_ext = buf_psi;
        buf_Br = buf_psi;
        buf_Jt = buf_psi;
        buf_Jz = buf_psi;
        buf_Jr = buf_psi;
        buf_Et = buf_psi;
        ng_rogo_shotlist = [];
        for i_shot = 1:numel(PCB.shotlist)
            PCB.date = PCB.datelist(i_shot);
            PCB.IDX = PCB.shotlist(i_shot);
            PCB.shot = PCBshotlist(i_shot,:);
            PCB.tfshot = PCBtfshotlist(i_shot,:);
            PCB.i_EF=EFlist(i_shot);
            %磁気プローブ計算
            [PCBgrid2D,PCBdata2D] = cal_psi(PCB,pathname);
            if i_shot == 1
                PCB_STAgrid2D = PCBgrid2D;
                PCB_STAgrid2D.zq = PCB_STAgrid2D.zq(r_min:r_max,z_min:z_max);
                PCB_STAgrid2D.rq = PCB_STAgrid2D.rq(r_min:r_max,z_min:z_max);
            end
            idx_PCB_t = knnsearch(PCBdata2D.trange',PCB_STA.start+i_t-1);
            buf_psi(:,:,i_shot) = PCBdata2D.psi(r_min:r_max,z_min:z_max,idx_PCB_t);
            buf_Bz(:,:,i_shot) = PCBdata2D.Bz(r_min:r_max,z_min:z_max,idx_PCB_t);
            buf_Bt(:,:,i_shot) = PCBdata2D.Bt(r_min:r_max,z_min:z_max,idx_PCB_t);
            buf_Bt_plasma(:,:,i_shot) = PCBdata2D.Bt_plasma(r_min:r_max,z_min:z_max,idx_PCB_t);
            if not(isempty(PCBdata2D.Bt_ext))
                buf_Bt_ext(:,:,i_shot) = PCBdata2D.Bt_ext(r_min:r_max,z_min:z_max,idx_PCB_t);
            else
                ng_rogo_shotlist = [ng_rogo_shotlist i_shot];
            end
            buf_Br(:,:,i_shot) = PCBdata2D.Br(r_min:r_max,z_min:z_max,idx_PCB_t);
            buf_Jt(:,:,i_shot) = PCBdata2D.Jt(r_min:r_max,z_min:z_max,idx_PCB_t);
            buf_Jz(:,:,i_shot) = PCBdata2D.Jz(r_min:r_max,z_min:z_max,idx_PCB_t);
            buf_Jr(:,:,i_shot) = PCBdata2D.Jr(r_min:r_max,z_min:z_max,idx_PCB_t);
            buf_Et(:,:,i_shot) = PCBdata2D.Et(r_min:r_max,z_min:z_max,idx_PCB_t);
        end
        buf_Bt_ext(:,:,ng_rogo_shotlist) = [];
        PCB_STAdata2D.psi(:,:,i_t) = mean(buf_psi,3);
        PCB_STAdata2D.psi_std(:,:,i_t) = std(buf_psi,0,3);
        PCB_STAdata2D.Bz(:,:,i_t) = mean(buf_Bz,3);
        PCB_STAdata2D.Bz_std(:,:,i_t) = std(buf_Bz,0,3);
        PCB_STAdata2D.Bt(:,:,i_t) = mean(buf_Bt,3);
        PCB_STAdata2D.Bt_std(:,:,i_t) = std(buf_Bt,0,3);
        PCB_STAdata2D.Bt_plasma(:,:,i_t) = mean(buf_Bt_plasma,3);
        PCB_STAdata2D.Bt_plasma_std(:,:,i_t) = std(buf_Bt_plasma,0,3);
        PCB_STAdata2D.Bt_ext(:,:,i_t) = mean(buf_Bt_ext,3);
        PCB_STAdata2D.Bt_ext_std(:,:,i_t) = std(buf_Bt_ext,0,3);
        PCB_STAdata2D.Br(:,:,i_t) = mean(buf_Br,3);
        PCB_STAdata2D.Br_std(:,:,i_t) = std(buf_Br,0,3);
        PCB_STAdata2D.Jt(:,:,i_t) = mean(buf_Jt,3);
        PCB_STAdata2D.Jt_std(:,:,i_t) = std(buf_Jt,0,3);
        PCB_STAdata2D.Jz(:,:,i_t) = mean(buf_Jz,3);
        PCB_STAdata2D.Jz_std(:,:,i_t) = std(buf_Jz,0,3);
        PCB_STAdata2D.Jr(:,:,i_t) = mean(buf_Jr,3);
        PCB_STAdata2D.Jr_std(:,:,i_t) = std(buf_Jr,0,3);
        PCB_STAdata2D.Et(:,:,i_t) = mean(buf_Et,3);
        PCB_STAdata2D.Et_std(:,:,i_t) = std(buf_Et,0,3);
    end
    save(savename,'PCB_STAgrid2D','PCB_STAdata2D')
end

plot_pcb_statistics(PCB_STAgrid2D,PCB_STAdata2D,FIG,plot_type,color_type,shotlistname)
