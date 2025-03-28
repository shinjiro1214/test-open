%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ダイアログボックス入力で
% 磁気プローブによる磁気面をプロット
% カラープロット選択肢
% psi,Br,Bz,Bt,Bt_ext,Bt_plasma,Et,Jt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close all
clearvars -except PCB colorplot FIG doCheck
addpath '/Users/rsomeya/Documents/lab/matlab/common'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
run define_path.m

% [9 12 15 18 19 21 27 30 31 33 35 36 38 40 46 48 52 53]
% psi小[4 5 7 8 13 15 18 20 22 23 26 30] [54 58 59:60 62]
% psi大[11 12 14 16 21 28 29 36 37:49] [50:53 55:57 61 63]

prompt = {'Date:','Shot Num.:','Colorplot Type:','Num. Plot (Vertical):','Num. Plot (Horizontal):','Start [us]:','dt [us]:','Check Signal (1):'};
dlgtitle = 'Input';
dims = [1 35];
if exist('PCB','var') && exist('colorplot','var') && exist('FIG','var') && exist('doCheck','var')
    definput = {num2str(PCB.date),num2str(PCB.IDXlist(1)+1),colorplot,num2str(FIG.tate),num2str(FIG.yoko),num2str(FIG.start),num2str(FIG.dt),num2str(doCheck)};
else
    % definput = {'230831','35','psi','2','4','462','4','0'};
    % definput = {'240827','11','psi','2','4','474','2','0'};
    definput = {'230830','22','Et','2','2','470','4','0'};
end
answer = inputdlg(prompt,dlgtitle,dims,definput);
if isempty(answer)
   % User clicked cancel. Bail out.
   return;
end
PCB.date = str2double(cell2mat(answer(1)));
PCB.IDXlist = str2double(cell2mat(answer(2)));
% PCB.IDXlist = [13 14 16 17 20 22 23 25 26 32 37 41:45 47 49 51 54 55 57];%複数解析の場合
colorplot = cell2mat(answer(3));
FIG.tate = str2double(cell2mat(answer(4)));
FIG.yoko = str2double(cell2mat(answer(5)));
FIG.start = str2double(cell2mat(answer(6)));
FIG.dt = str2double(cell2mat(answer(7)));
doCheck = str2double(cell2mat(answer(8)));

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,PCB.date);
n_data=numel(PCB.IDXlist);%計測データ数
shotlist_a039 =T.a039(PCB.IDXlist);
shotlist_a040 = T.a040(PCB.IDXlist);
shotlist = [shotlist_a039, shotlist_a040];
tfshotlist_a039 =T.a039_TF(PCB.IDXlist);
tfshotlist_a040 =T.a040_TF(PCB.IDXlist);
tfshotlist = [tfshotlist_a039, tfshotlist_a040];
EFlist=T.EF_A_(PCB.IDXlist);
TFlist=T.TF_kV_(PCB.IDXlist);
IDSPminZlist=T.IDSPZ_cm_(PCB.IDXlist);
IDSPminRlist=T.IDSPMinR_cm_(PCB.IDXlist);

PCB.trange=400:800;%【input】計算時間範囲
PCB.mesh=40; %【input】rz方向のメッシュ数

for i=1:n_data
    PCB.IDX = PCB.IDXlist(i);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    if PCB.tfshot == PCB.shot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    IDSP.z = IDSPminZlist(i)*ones(7,1)*1E-2;
    IDSP.r = (IDSPminRlist(i):2.5:IDSPminRlist(i)+6*2.5)*1E-2;
    if doCheck == 1
        check_signal(PCB,pathname);
    else
        [PCBgrid2D,PCBdata2D] = cal_psi(PCB,pathname);
        plot_psi(PCBgrid2D,PCBdata2D,IDSP,FIG,colorplot);
    end
end
