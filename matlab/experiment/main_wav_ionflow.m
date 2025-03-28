%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ショット番号、撮影パラメータなどを実験ログから自動取得して
%ドップラープローブによるイオン温度、フローとその瞬間の磁気面をプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

%------【input】-------
% % FC合体、X点R=0.2m、ExBアウトフロー小。IDSP->230828,230829(delay=480,484,488us)
% experiment = 1;
% IDSP.date = 230828;%【input】IDSP実験日
% IDSP.shotlist = [5 6 8:12 15:17 19:23 25:27 31:61 63];
% plot_time = 482;%【input】プロット時間[us]482,486

% SEP合体、X点R=0.26m、ExBアウトフロー大。IDSP->230830,230831(470usでアウトフロー最大)psi大
experiment = 2;
IDSP.date = [230830;230831];%【input】IDSP実験日
IDSP.shotlist1 = [13 14 16 17 20 22 23 25 26 32 37 41:45 47 49 51 54 55 57];%【input】IDSPshot番号リスト(Day1)
IDSP.shotlist2 = [11 12 14 16 21 28 29 36 37:49];%【input】IDSPshot番号リスト(Day2)
plot_time = 470;%【input】プロット時間[us]470,474,478
single_range = [1:4 6 7];%【input】プロットCH([1:4 7])
wav_range = [1:12 16:21];%【input】プロットr([1:21],[1:12 19:21])

% % SEP合体、X点R=0.26m、ExBアウトフロー大。IDSP->230830,230831(470usでアウトフロー最大)psi小
% experiment = 10;
% IDSP.date = [230830;230831];%【input】IDSP実験日
% IDSP.shotlist1 = [9 12 15 18 19 21 27 30 31 33 35 36 38 40 46 48 52 53];%【input】IDSPshot番号リスト(Day1)
% IDSP.shotlist2 = [4:67];%【input】IDSPshot番号リスト(Day2)
% plot_time = 466;%【input】プロット時間[us]470,474,478
% single_range = [1:4 6 7];%【input】プロットCH([1:4 7])
% wav_range = [1:12 16:21];%【input】プロットr([1:21],[1:12 19:21])

% % % 同極性スフェロマック合体 + 外部TF4kV
% experiment = 3;
% % ESP.date = 240827;%【input】静電プローブ計測日
% % ESP.shotlist = [11:20 22:45 47:51];%【input】静電プローブ解析shotlist(同一オペレーション)]
% plot_time = 474;%【input】プロット時間[us]482,486

% % 同極性スフェロマック合体 + 外部TF5kV
% experiment = 4;
% ESP.date = 240828;%【input】静電プローブ計測日
% ESP.shotlist = [30:41 43:46 48:54];%【input】静電プローブ解析shotlist(同一オペレーション)

% 同極性スフェロマック合体 + 外部TF6kV
% experiment = 5;
% ESP.date = 240828;%【input】静電プローブ計測日
% ESP.shotlist = [3:12 14:22 25:29];%【input】静電プローブ解析shotlist(同一オペレーション)

switch experiment
    case 1
        savename.ExB = [pathname.mat,'/ExB/','230828_shot5-63-a039_2301_', num2str(plot_time - 2), '_1_5.mat'];
        savename.curve = [pathname.mat,'/curve/','230828_a039_2301_', num2str(plot_time - 2), '_1_5.mat'];
        savename.nablaB = [pathname.mat,'/nablaB/','230828_a039_2301_', num2str(plot_time - 2), '_1_5.mat'];
    case 2
        savename.ExB = [pathname.mat,'/ExB/','230830_shot11_13-14_16-17_20_22-26_28-29_32_34_37_41-45_47_49_51_54-55_57_59-60-a039_2437_450_1_500.mat'];
        savename.curve = [pathname.mat,'/curve/','230830_a039_2437_', num2str(plot_time - 2), '_1_5_movmean5.mat'];
        savename.nablaB = [pathname.mat,'/nablaB/','230830_a039_2437_', num2str(plot_time - 2), '_1_5.mat'];
        savename.magline = [pathname.mat,'/magline/','230830_a039_2437_', num2str(plot_time - 2), '_1_5.mat'];
        savename.contop = [pathname.mat,'/contourtop/','230830_a039_2437_', num2str(plot_time - 2), '_1_5.mat'];
    case 10
        savename.ExB = [pathname.mat,'/ExB/','230830_shot9_12_15_18-19_21_27_30-31_33_35-36_38_40_46_48_52-53-a039_2429_450_1_500.mat'];
    case 3
        % filename_STA(1) = [pathname.mat,'/PCB_STA/240827_shot11-20_22-45_47-51_450-500.mat'];%【input】磁気プローブ統計data1
        % filename_ESP(1) = [pathname.mat,'/ESP/240827_shot11-20_22-45_47-51_mesh21.mat'];%【input】ESPdata1
        savename.ExB = [pathname.mat,'/ExB/240827_shot11-20_22-45_47-51-a039_4851_450_1_500.mat'];%【input】ExBdata1
    case 4
        % filename_STA(2) = [pathname.mat,'/PCB_STA/240828_shot30-41_43-46_48-54_450-500.mat'];%【input】磁気プローブ統計data2
        % filename_ESP(2) = [pathname.mat,'/ESP/240828_shot30-41_43-46_48-54_mesh21.mat'];%【input】ESPdata2
        savename.ExB = [pathname.mat,'/ExB/240828_shot30-41_43-46_48-54-a039_4912_450_1_500.mat'];%【input】ExBdata2
    case 5
        % filename_STA(3) = [pathname.mat,'/PCB_STA/240828_shot3-12_14-22_25-29_450-500.mat'];%【input】磁気プローブ統計data3
        % filename_ESP(3) = [pathname.mat,'/ESP/240828_shot3-12_14-22_25-29_mesh21.mat'];%【input】ESPdata3
        savename.ExB = [pathname.mat,'/ExB/240828_shot3-12_14-22_25-29-a039_4893_450_1_500.mat'];%【input】ExBdata3
end

IDSP.n_CH = 28;%【input】IDSPファイバーCH数(28)
IDSP.n_r = 7;%【input】IDSPr方向データ数(7)
IDSP.n_z = 1;%【input】IDSPz方向データ数(1)
IDSP.int_r = 2.5;%【input】IDSPr方向計測点間隔[cm](2.5)
profileplot = 'Vr';%【input】プロット種類('Vr','Vz','T','offset')
cal_type = 'ionflow';%【input】IDSP計算法('ionflow','ionvdist')
ExB_mean = true;
nablaB_mean = false;
curve_mean = false;
magline_mean = true;
contop_mean = false;
magpresplot = 'Pz';%【input】プロット種類('Pr','Pz','Pt','Pzt','Pall')
magpres_mean = false;
plot_single = false;%【input】IDSPシングルショットをプロット
plot_WAV = true;%【input】IDSP重み付き平均をプロット
plot_VExB = true;%【input】ExBをプロット
plot_VnablaB = false;%【input】∇B driftをプロット
plot_Vcurve = false;%【input】curve driftをプロット
plot_Vmagline = true;%【input】磁力線ドリフトをプロット
plot_Vcontop = false;%【input】磁力線ドリフトをプロット
plot_magpres = false;%【input】磁気圧をプロット

%------IDSP詳細設定【input】------
plot_fit = false;%【input】ガウスフィッティングを表示(true,false)
save_fit = false;%【input】ガウスフィッティングpngを保存(true,false)
show_offset = false;%【input】分光offsetを表示(true,false)
plot_spectra = false;%【input】スペクトルをプロット(true,false)
plot_analisis = false;%【input】逆変換解析をプロット(true,false)
Ti_type = 'dispersion';%【input】イオン温度計算法('dispersion')
inversion_method = 5;%【input】速度分布逆変換手法(1~6)

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
%--------実験ログ取得(day1)---------
T1=searchlog(T,node,IDSP.date(1));
IDSP.shotlist1(ismember(IDSP.shotlist1,T1.shot)==0) = [];
IDSP.datelist = IDSP.date(1)*ones(numel(IDSP.shotlist1),1);
IDSP.shotlist = IDSP.shotlist1;
n_data=numel(IDSP.shotlist1);%計測shot数
PCBshotlist_a039 =T1.a039(IDSP.shotlist1);
PCBshotlist_a040 = T1.a040(IDSP.shotlist1);
PCBshotlist = [PCBshotlist_a039, PCBshotlist_a040];
PCBtfshotlist_a039 =T1.a039_TF(IDSP.shotlist1);
PCBtfshotlist_a040 =T1.a040_TF(IDSP.shotlist1);
PCBtfshotlist = [PCBtfshotlist_a039, PCBtfshotlist_a040];
PF1list=T1.CB1_kV_(IDSP.shotlist1);
PF2list=T1.CB2_kV_(IDSP.shotlist1);
TFlist=T1.TF_kV_(IDSP.shotlist1);
EFlist=T1.EF_A_(IDSP.shotlist1);
Gaslist=T1.gas(IDSP.shotlist1);
IDSPminZlist=T1.IDSPZ_cm_(IDSP.shotlist1);
IDSPminRlist=T1.IDSPMinR_cm_(IDSP.shotlist1);
IDSPdelaylist=T1.IDSPDelay_us_(IDSP.shotlist1);
IDSPwidthlist=T1.IDSPWidth_us_(IDSP.shotlist1);
IDSPgainlist=T1.IDSPGain(IDSP.shotlist1);
IDSPtimelist=round(IDSPdelaylist+IDSPwidthlist/2);

if numel(IDSP.date) > 1
    %--------実験ログ取得(day2)---------
    T2=searchlog(T,node,IDSP.date(2));
    IDSP.shotlist2(ismember(IDSP.shotlist2,T2.shot)==0) = [];
    IDSP.datelist = [IDSP.datelist;IDSP.date(2)*ones(numel(IDSP.shotlist2),1)];
    IDSP.shotlist = [IDSP.shotlist,IDSP.shotlist2];
    n_data=n_data+numel(IDSP.shotlist2);%計測shot数
    PCBshotlist_a039 = [PCBshotlist_a039;T2.a039(IDSP.shotlist2)];
    PCBshotlist_a040 = [PCBshotlist_a040;T2.a040(IDSP.shotlist2)];
    PCBshotlist = [PCBshotlist_a039, PCBshotlist_a040];
    PCBtfshotlist_a039 =[PCBtfshotlist_a039;T2.a039_TF(IDSP.shotlist2)];
    PCBtfshotlist_a040 =[PCBtfshotlist_a040;T2.a040_TF(IDSP.shotlist2)];
    PCBtfshotlist = [PCBtfshotlist_a039, PCBtfshotlist_a040];
    PF1list=[PF1list;T2.CB1_kV_(IDSP.shotlist2)];
    PF2list=[PF2list;T2.CB2_kV_(IDSP.shotlist2)];
    TFlist=[TFlist;T2.TF_kV_(IDSP.shotlist2)];
    EFlist=[EFlist;T2.EF_A_(IDSP.shotlist2)];
    Gaslist=[Gaslist;T2.gas(IDSP.shotlist2)];
    IDSPminZlist=[IDSPminZlist;T2.IDSPZ_cm_(IDSP.shotlist2)];
    IDSPminRlist=[IDSPminRlist;T2.IDSPMinR_cm_(IDSP.shotlist2)];
    IDSPdelaylist=[IDSPdelaylist;T2.IDSPDelay_us_(IDSP.shotlist2)];
    IDSPwidthlist=[IDSPwidthlist;T2.IDSPWidth_us_(IDSP.shotlist2)];
    IDSPgainlist=[IDSPgainlist;T2.IDSPGain(IDSP.shotlist2)];
    IDSPtimelist=round(IDSPdelaylist+IDSPwidthlist/2);
end

FIG.tate = 1;%プロット枚数(縦)
FIG.yoko = 1;%プロット枚数(横)
FIG.dt = 0;%プロット時間間隔[us]

buf_minR = sort(rmmissing(unique(IDSPminRlist)));
for i=1:size(buf_minR,1)
    buf_r = ((buf_minR(i):IDSP.int_r:buf_minR(i)+(IDSP.n_r-1)*IDSP.int_r)*1E-2)';
    if i == 1
        WAV_IDSPdata.r = buf_r;
    else
        WAV_IDSPdata.r = cat(1,WAV_IDSPdata.r,buf_r);%統合後IDSPdata R座標[m]
    end
end
WAV_IDSPdata.z = sort(rmmissing(unique(IDSPminZlist)))*1E-2;%統合後IDSPdata Z座標[m]
WAV_IDSPdata.time = sort(rmmissing(unique(IDSPtimelist)));%統合後IDSPdata 時間[us]
WAV_IDSPdata.V_i = zeros(size(WAV_IDSPdata.r,1),size(WAV_IDSPdata.z,1)*2,size(WAV_IDSPdata.time,1));%V_i重み付き平均
WAV_IDSPdata.err_V_i = zeros(size(WAV_IDSPdata.r,1),size(WAV_IDSPdata.z,1)*2,size(WAV_IDSPdata.time,1));%V_i重み付き平均の誤差分散
WAV_IDSPdata.T_i = zeros(size(WAV_IDSPdata.r,1),size(WAV_IDSPdata.z,1),size(WAV_IDSPdata.time,1));%T_i重み付き平均
WAV_IDSPdata.err_T_i = zeros(size(WAV_IDSPdata.r,1),size(WAV_IDSPdata.z,1),size(WAV_IDSPdata.time,1));%T_i重み付き平均の誤差分散
sum_weight_V_i = zeros(size(WAV_IDSPdata.r,1),size(WAV_IDSPdata.z,1)*2,size(WAV_IDSPdata.time,1));
sum_weight_T_i = zeros(size(WAV_IDSPdata.r,1),size(WAV_IDSPdata.z,1),size(WAV_IDSPdata.time,1));
cnt = zeros(size(WAV_IDSPdata.r,1),size(WAV_IDSPdata.z,1),size(WAV_IDSPdata.time,1));
legendStrings = "";
hs = char.empty;

figure('Position', [0 0 500 500],'visible','on');
if plot_magpres
    yyaxis left
end
for i=1:n_data
    IDSP.date=IDSP.datelist(i);
    IDSP.shot=IDSP.shotlist(i);
    IDSP.line=Gaslist(i);
    IDSP.delay=IDSPdelaylist(i);
    IDSP.width=IDSPwidthlist(i);
    IDSP.gain=IDSPgainlist(i);
    IDSP.time=IDSPtimelist(i);
    IDSP.z = IDSPminZlist(i)*ones(7,1)*1E-2;%IDSP計測点Z座標[m]
    IDSP.r = ((IDSPminRlist(i):IDSP.int_r:IDSPminRlist(i)+(IDSP.n_r-1)*IDSP.int_r)*1E-2)';%IDSP計測点R座標[m]
    EXP.PF1=PF1list(i);
    EXP.PF2=PF2list(i);
    EXP.TF=TFlist(i);
    EXP.EF=EFlist(i);
    FIG.start = IDSP.time;%プロット開始時刻[us]
    if not(isnan(IDSP.delay)) && (IDSP.time == plot_time)
        %IDSP計算
        switch cal_type
            case 'ionflow'
                IDSPdata = cal_ionflow(IDSP,pathname,show_offset,plot_fit,save_fit);
            case 'ionvdist'
                IDSPdata = cal_ionvdist(IDSP,pathname,show_offset,plot_spectra,inversion_method,plot_analisis,Ti_type);
        end
        if plot_single
            if IDSP.time == plot_time
                switch cal_type
                    case 'ionflow'
                        switch profileplot
                            case 'Vz'
                                errorbar(IDSPdata.r(single_range),IDSPdata.V_i(single_range,1),IDSPdata.err_V_i(single_range,1),'k*-')
                            case 'Vr'
                                errorbar(IDSPdata.r(single_range),IDSPdata.V_i(single_range,2),IDSPdata.err_V_i(single_range,2),'k*-')
                            case 'T'
                                errorbar(IDSPdata.r(single_range),IDSPdata.T_i(single_range,1),IDSPdata.err_T_i(single_range,1),'k*-')
                            case 'offset'
                                plot(single_range,IDSPdata.offset(single_range,1),'*-')
                                % IDSPdata.offset(6,1) - IDSPdata.offset(3,1)
                        end
                    case 'ionvdist'
                        switch profileplot
                            case 'Vz'
                                plot(IDSPdata.r(single_range),IDSPdata.V_i(single_range,1),'k*-')
                            case 'Vr'
                                plot(IDSPdata.r(single_range),IDSPdata.V_i(single_range,2),'k*-')
                            case 'T'
                                plot(IDSPdata.r(single_range),IDSPdata.T_i(single_range,1),'k*-')
                        end
                end
            end
            hold on
        end
        switch cal_type
            case 'ionflow'
                %加重平均計算
                idx_r = find(WAV_IDSPdata.r==IDSPdata.r(1,1));
                idx_z = find(WAV_IDSPdata.z==IDSPdata.z(1,1));
                IDSPdata.time = round(IDSPdata.delay+IDSPdata.width/2);
                idx_time = find(WAV_IDSPdata.time==IDSPdata.time);
                weight_V_i = 1./IDSPdata.err_V_i.^2;%重み1/σ^2
                WAV_IDSPdata.V_i(idx_r:idx_r+IDSP.n_r-1,2*(idx_z-1)+1:2*(idx_z-1)+2,idx_time) = WAV_IDSPdata.V_i(idx_r:idx_r+IDSP.n_r-1,2*(idx_z-1)+1:2*(idx_z-1)+2,idx_time) + IDSPdata.V_i.*weight_V_i;
                sum_weight_V_i(idx_r:idx_r+IDSP.n_r-1,2*(idx_z-1)+1:2*(idx_z-1)+2,idx_time) = sum_weight_V_i(idx_r:idx_r+IDSP.n_r-1,2*(idx_z-1)+1:2*(idx_z-1)+2,idx_time) + weight_V_i;
                weight_T_i = 1./IDSPdata.err_T_i.^2;%重み1/σ^2
                WAV_IDSPdata.T_i(idx_r:idx_r+IDSP.n_r-1,idx_z,idx_time) = WAV_IDSPdata.T_i(idx_r:idx_r+IDSP.n_r-1,idx_z,idx_time) + IDSPdata.T_i.*weight_T_i;
                sum_weight_T_i(idx_r:idx_r+IDSP.n_r-1,idx_z,idx_time) = sum_weight_T_i(idx_r:idx_r+IDSP.n_r-1,idx_z,idx_time) + weight_T_i;
                cnt(idx_r:idx_r+IDSP.n_r-1,idx_z,idx_time) = cnt(idx_r:idx_r+IDSP.n_r-1,idx_z,idx_time) +1;
            case 'ionvdist'
        end
    end
end
switch cal_type
    case 'ionflow'
        WAV_IDSPdata.V_i = WAV_IDSPdata.V_i./sum_weight_V_i;
        WAV_IDSPdata.err_V_i = 1./sqrt(sum_weight_V_i);
        WAV_IDSPdata.T_i = WAV_IDSPdata.T_i./sum_weight_T_i;
        WAV_IDSPdata.err_T_i = 1./sqrt(sum_weight_T_i);
    case 'ionvdist'
end

if plot_WAV
    idx_WAV_time = knnsearch(WAV_IDSPdata.time,plot_time);
    switch profileplot
        case 'Vz'
            buf = cat(2,WAV_IDSPdata.r,WAV_IDSPdata.V_i(:,1,idx_WAV_time));
            buf = sortrows(cat(2,buf,WAV_IDSPdata.err_V_i(:,1,idx_WAV_time)));
        case 'Vr'
            buf = cat(2,WAV_IDSPdata.r,WAV_IDSPdata.V_i(:,2,idx_WAV_time));
            buf = sortrows(cat(2,buf,WAV_IDSPdata.err_V_i(:,2,idx_WAV_time)));
        case 'T'
            buf = cat(2,WAV_IDSPdata.r,WAV_IDSPdata.T_i(:,1,idx_WAV_time));
            buf = sortrows(cat(2,buf,WAV_IDSPdata.err_T_i(:,1,idx_WAV_time)));
    end
    buf = buf(wav_range,:);
    id_NAN = isnan(buf(:,2));
    buf(id_NAN, :) = [];
    buf(:,2) = movmean(buf(:,2),round(2*size(buf,1)/numel(single_range)),1);
    buf(:,3) = movmean(buf(:,3),round(2*size(buf,1)/numel(single_range)),1);
    switch profileplot
        case 'Vz'
            err_WAV_y = buf(:,3)*6;
        case 'Vr'
            err_WAV_y = buf(:,3)*6;
        case 'T'
            err_WAV_y = buf(:,3);
    end
    err_WAV_xpos = 0.01;
    err_WAV_xneg = 0.015;
    errorbar(buf(:,1),buf(:,2),err_WAV_y,err_WAV_y,err_WAV_xneg,err_WAV_xpos,'r+','LineWidth',3)
    hold on
    h = plot(nan,nan,'ro-','LineWidth',3);
    hold on
    if isempty(hs)
        hs = h;
    else
        hs = [hs h];
    end
    if legendStrings == ""
        legendStrings = "Ion Flow";
    else
        legendStrings = [legendStrings "Ion Flow"];
    end
end

if plot_VExB
    if exist(savename.ExB,"file")
        load(savename.ExB,'ExBdata2D')
        idx_IDSP_z = knnsearch(ExBdata2D.zq(1,:)',IDSP.z(1));
        idx_IDSP_z_min = knnsearch(ExBdata2D.zq(1,:)',IDSP.z(1)-0.016);
        idx_IDSP_z_max = knnsearch(ExBdata2D.zq(1,:)',IDSP.z(1)+0.016);
        % idx_ExB_time = knnsearch(ExBdata2D.time,plot_time);
        idx_ExB_time = knnsearch(ExBdata2D.trange',plot_time);
        VExB_z_mean = mean(ExBdata2D.VExB_z(:,idx_IDSP_z_min:idx_IDSP_z_max,idx_ExB_time-2:idx_ExB_time+2),3);
        VExB_z_mean = mean(VExB_z_mean,2);
        VExB_r_mean = mean(ExBdata2D.VExB_r(:,idx_IDSP_z_min:idx_IDSP_z_max,idx_ExB_time-2:idx_ExB_time+2),3);
        VExB_r_mean = mean(VExB_r_mean,2);
        err_ExB_z_y = 4;
        err_ExB_r_y = 4;
        err_ExB_x = 0.01;
        if ExB_mean
            switch profileplot
                case 'Vz'
                    errorbar(ExBdata2D.rq(:,idx_IDSP_z),VExB_z_mean,err_ExB_z_y,err_ExB_z_y,err_ExB_x,err_ExB_x,'bo','LineWidth',3)
                    % %平均値表示
                    % plot(ExBdata2D.rq(:,idx_IDSP_z),VExB_z_mean,'b','LineWidth',3)
                    % hold on
                    % %標準偏差表示
                    % errarea_ExB_z_y = err_ExB_z_y*ones(size(VExB_z_mean,1),1);
                    % ar_ExB=area(ExBdata2D.rq(:,idx_IDSP_z),[VExB_z_mean-errarea_ExB_z_y errarea_ExB_z_y+errarea_ExB_z_y]);
                    % set(ar_ExB(1),'FaceColor','None','LineStyle',':','EdgeColor','b')
                    % set(ar_ExB(2),'FaceColor','b','FaceAlpha',0.2,'LineStyle',':','EdgeColor','b')
                case 'Vr'
                    errorbar(ExBdata2D.rq(:,idx_IDSP_z),VExB_r_mean,err_ExB_r_y,err_ExB_r_y,err_ExB_x,err_ExB_x,'bo','LineWidth',3)
                    % %平均値表示
                    % plot(ExBdata2D.rq(:,idx_IDSP_z),VExB_r_mean,'b','LineWidth',3)
                    % hold on
                    % %標準偏差表示
                    % errarea_ExB_r_y = err_ExB_r_y*ones(size(VExB_r_mean,1),1);
                    % ar_ExB=area(ExBdata2D.rq(:,idx_IDSP_z),[VExB_r_mean-errarea_ExB_r_y errarea_ExB_r_y+errarea_ExB_r_y]);
                    % set(ar_ExB(1),'FaceColor','None','LineStyle',':','EdgeColor','b')
                    % set(ar_ExB(2),'FaceColor','b','FaceAlpha',0.2,'LineStyle',':','EdgeColor','b')
            end
        else
            switch profileplot
                case 'Vz'
                    errorbar(ExBdata2D.rq(:,idx_IDSP_z),ExBdata2D.VExB_z(:,idx_IDSP_z,idx_ExB_time),err_ExB_z_y,err_ExB_z_y,err_ExB_x,err_ExB_x,'bo','LineWidth',3)
                case 'Vr'
                    errorbar(ExBdata2D.rq(:,idx_IDSP_z),ExBdata2D.VExB_r(:,idx_IDSP_z,idx_ExB_time),err_ExB_r_y,err_ExB_r_y,err_ExB_x,err_ExB_x,'bo','LineWidth',3)
            end
        end
        hold on
        h = plot(nan,nan,'bo-','LineWidth',3);
        hold on
        if isempty(hs)
            hs = h;
        else
            hs = [hs h];
        end
        if legendStrings == ""
            legendStrings = "ExB";
        else
            legendStrings = [legendStrings "ExB"];
        end
    else
        warning([savename.ExB, 'does not exist.'])
    end
end

if plot_VnablaB
    if exist(savename.nablaB,"file")
        load(savename.nablaB,'NablaBdata2D')
        idx_IDSP_z = knnsearch(NablaBdata2D.zq(1,:)',IDSP.z(1));
        idx_IDSP_z_min = knnsearch(NablaBdata2D.zq(1,:)',IDSP.z(1)-0.016);
        idx_IDSP_z_max = knnsearch(NablaBdata2D.zq(1,:)',IDSP.z(1)+0.016);
        idx_nablaB_time = knnsearch(NablaBdata2D.trange,plot_time);
        VnablaB_z_mean = mean(NablaBdata2D.VnablaB_z(:,idx_IDSP_z_min:idx_IDSP_z_max,:),3);
        VnablaB_z_mean = mean(VnablaB_z_mean,2);
        VnablaB_r_mean = mean(NablaBdata2D.VnablaB_r(:,idx_IDSP_z_min:idx_IDSP_z_max,:),3);
        VnablaB_r_mean = mean(VnablaB_r_mean,2);
        err_nablaB_z_y = 2E-2;
        err_nablaB_r_y = 4E-3;
        err_nablaB_x = 0.01;
        switch plot_time
            case {470,482}
                if nablaB_mean
                    switch profileplot
                        case 'Vz'
                            % errorbar(NablaBdata2D.rq(:,idx_IDSP_z),VnablaB_z_mean,err_nablaB_z_y,err_nablaB_z_y,err_nablaB_x,err_nablaB_x,'co','LineWidth',3)
                            %平均値表示
                            plot(NablaBdata2D.rq(:,idx_IDSP_z),VnablaB_z_mean,'c','LineWidth',3)
                            hold on
                            %標準偏差表示
                            errarea_nablaB_z_y = err_nablaB_z_y*ones(size(VnablaB_z_mean,1),1);
                            ar_nablaB=area(NablaBdata2D.rq(:,idx_IDSP_z),[VnablaB_z_mean-errarea_nablaB_z_y errarea_nablaB_z_y+errarea_nablaB_z_y]);
                            set(ar_nablaB(1),'FaceColor','None','LineStyle',':','EdgeColor','c')
                            set(ar_nablaB(2),'FaceColor','c','FaceAlpha',0.2,'LineStyle',':','EdgeColor','c')
                        case 'Vr'
                            % errorbar(NablaBdata2D.rq(:,idx_IDSP_z),VnablaB_r_mean,err_nablaB_r_y,err_nablaB_r_y,err_nablaB_x,err_nablaB_x,'co','LineWidth',3)
                            %平均値表示
                            plot(NablaBdata2D.rq(:,idx_IDSP_z),VnablaB_r_mean,'c','LineWidth',3)
                            hold on
                            %標準偏差表示
                            errarea_nablaB_r_y = err_nablaB_r_y*ones(size(VnablaB_r_mean,1),1);
                            ar_nablaB=area(NablaBdata2D.rq(:,idx_IDSP_z),[VnablaB_r_mean-errarea_nablaB_r_y errarea_nablaB_r_y+errarea_nablaB_r_y]);
                            set(ar_nablaB(1),'FaceColor','None','LineStyle',':','EdgeColor','c')
                            set(ar_nablaB(2),'FaceColor','c','FaceAlpha',0.2,'LineStyle',':','EdgeColor','c')
                    end
                else
                    switch profileplot
                        case 'Vz'
                            errorbar(NablaBdata2D.rq(:,idx_IDSP_z),NablaBdata2D.VnablaB_z(:,idx_IDSP_z,idx_nablaB_time),err_nablaB_z_y,err_nablaB_z_y,err_nablaB_x,err_nablaB_x,'co','LineWidth',3)
                        case 'Vr'
                            errorbar(NablaBdata2D.rq(:,idx_IDSP_z),NablaBdata2D.VnablaB_r(:,idx_IDSP_z,idx_nablaB_time),err_nablaB_r_y,err_nablaB_r_y,err_nablaB_x,err_nablaB_x,'co','LineWidth',3)
                    end
                end
        end
        hold on
        h = plot(nan,nan,'c-','LineWidth',3);
        hold on
        if isempty(hs)
            hs = h;
        else
            hs = [hs h];
        end
        if legendStrings == ""
            legendStrings = "GradB";
        else
            legendStrings = [legendStrings "GradB"];
        end
    else
        warning([savename.nablaB, 'does not exist.'])
    end
end

if plot_Vcurve
    if exist(savename.curve,"file")
        load(savename.curve,'Curvedata2D')
        idx_IDSP_z = knnsearch(Curvedata2D.zq(1,:)',IDSP.z(1));
        idx_IDSP_z_min = knnsearch(Curvedata2D.zq(1,:)',IDSP.z(1)-0.016);
        idx_IDSP_z_max = knnsearch(Curvedata2D.zq(1,:)',IDSP.z(1)+0.016);
        idx_curve_time = knnsearch(Curvedata2D.trange,plot_time);
        Vcurve_z_mean = mean(Curvedata2D.Vcurve_z(:,idx_IDSP_z_min:idx_IDSP_z_max,:),3);
        Vcurve_z_mean = mean(Vcurve_z_mean,2);
        Vcurve_r_mean = mean(Curvedata2D.Vcurve_r(:,idx_IDSP_z_min:idx_IDSP_z_max,:),3);
        Vcurve_r_mean = mean(Vcurve_r_mean,2);
        err_curve_z_y = 4E-2;
        err_curve_r_y = 4E-3;
        err_curve_x = 0.01;
        switch plot_time
            case {470,482}
                if curve_mean
                    switch profileplot
                        case 'Vz'
                            % errorbar(Curvedata2D.rq(:,idx_IDSP_z),Vcurve_z_mean,err_curve_z_y,err_curve_z_y,err_curve_x,err_curve_x,'mo','LineWidth',3)
                            %平均値表示
                            plot(Curvedata2D.rq(:,idx_IDSP_z),Vcurve_z_mean,'m','LineWidth',3)
                            hold on
                            %標準偏差表示
                            errarea_curve_z_y = err_curve_z_y*ones(size(Vcurve_z_mean,1),1);
                            ar_curve=area(Curvedata2D.rq(:,idx_IDSP_z),[Vcurve_z_mean-errarea_curve_z_y errarea_curve_z_y+errarea_curve_z_y]);
                            set(ar_curve(1),'FaceColor','None','LineStyle',':','EdgeColor','m')
                            set(ar_curve(2),'FaceColor','m','FaceAlpha',0.2,'LineStyle',':','EdgeColor','m')
                        case 'Vr'
                            % errorbar(Curvedata2D.rq(:,idx_IDSP_z),Vcurve_r_mean,err_curve_r_y,err_curve_r_y,err_curve_x,err_curve_x,'mo','LineWidth',3)
                            %平均値表示
                            plot(Curvedata2D.rq(:,idx_IDSP_z),Vcurve_r_mean,'m','LineWidth',3)
                            hold on
                            %標準偏差表示
                            errarea_curve_r_y = err_curve_r_y*ones(size(Vcurve_r_mean,1),1);
                            ar_curve=area(Curvedata2D.rq(:,idx_IDSP_z),[Vcurve_r_mean-errarea_curve_r_y errarea_curve_r_y+errarea_curve_r_y]);
                            set(ar_curve(1),'FaceColor','None','LineStyle',':','EdgeColor','m')
                            set(ar_curve(2),'FaceColor','m','FaceAlpha',0.2,'LineStyle',':','EdgeColor','m')
                    end
                else
                    switch profileplot
                        case 'Vz'
                            errorbar(Curvedata2D.rq(:,idx_IDSP_z),Curvedata2D.Vcurve_z(:,idx_IDSP_z,idx_curve_time),err_curve_z_y,err_curve_z_y,err_curve_x,err_curve_x,'mo','LineWidth',3)
                        case 'Vr'
                            errorbar(Curvedata2D.rq(:,idx_IDSP_z),Curvedata2D.Vcurve_r(:,idx_IDSP_z,idx_curve_time),err_curve_r_y,err_curve_r_y,err_curve_x,err_curve_x,'mo','LineWidth',3)
                    end
                end
        end
        hold on
        h = plot(nan,nan,'m-','LineWidth',3);
        hold on
        if isempty(hs)
            hs = h;
        else
            hs = [hs h];
        end
        if legendStrings == ""
            legendStrings = "Curvature";
        else
            legendStrings = [legendStrings "Curvature"];
        end
    else
        warning([savename.curve, 'does not exist.'])
    end
end

title([num2str(plot_time),'us'])
xlabel('R [m]')
switch profileplot
    case 'Vz'
        ylabel('V_Z [km/s]')
        yline(0,'--k','LineWidth',2)
    case 'Vr'
        ylabel('V_R [km/s]')
        yline(0,'--k','LineWidth',2)
    case 'T'
        ylabel('T_i [eV]')
end

if plot_Vmagline
    if exist(savename.magline,"file")
        load(savename.magline,'Maglinedata2D')
        idx_IDSP_z = knnsearch(Maglinedata2D.zq(1,:)',IDSP.z(1));
        idx_IDSP_z_min = knnsearch(Maglinedata2D.zq(1,:)',IDSP.z(1)-0.016);
        idx_IDSP_z_max = knnsearch(Maglinedata2D.zq(1,:)',IDSP.z(1)+0.016);
        idx_magline_time = knnsearch(Maglinedata2D.trange,plot_time);
        Vmagline_z_mean = mean(Maglinedata2D.Vmagline_z(:,idx_IDSP_z_min:idx_IDSP_z_max,:),3);
        Vmagline_z_mean = mean(Vmagline_z_mean,2);
        Vmagline_r_mean = mean(Maglinedata2D.Vmagline_r(:,idx_IDSP_z_min:idx_IDSP_z_max,:),3);
        Vmagline_r_mean = mean(Vmagline_r_mean,2);
        err_magline_z_y = 2;
        err_magline_r_y = 2;
        err_magline_x = 0.01;
        if magline_mean
            switch profileplot
                case 'Vr'
                    % errorbar(Maglinedata2D.rq(:,idx_IDSP_z),Vmagline_r_mean,err_magline_r_y,err_magline_r_y,err_magline_x,err_magline_x,'go','LineWidth',3)
                    %平均値表示
                    plot(Maglinedata2D.rq(:,idx_IDSP_z),Vmagline_r_mean,'g','LineWidth',3)
                    hold on
                    %標準偏差表示
                    errarea_magline_r_y = err_magline_r_y*ones(size(Vmagline_r_mean,1),1);
                    ar_magline=area(Maglinedata2D.rq(:,idx_IDSP_z),[Vmagline_r_mean-errarea_magline_r_y errarea_magline_r_y+errarea_magline_r_y]);
                    set(ar_magline(1),'FaceColor','None','LineStyle',':','EdgeColor','g')
                    set(ar_magline(2),'FaceColor','g','FaceAlpha',0.2,'LineStyle',':','EdgeColor','g')
            end
        else
            switch profileplot
                case 'Vr'
                    % errorbar(Maglinedata2D.rq(:,idx_IDSP_z),Maglinedata2D.Vmagline_r(:,idx_IDSP_z,idx_magline_time),err_magline_r_y,err_magline_r_y,err_magline_x,err_magline_x,'go','LineWidth',3)
                    %平均値表示
                    plot(Maglinedata2D.rq(:,idx_IDSP_z),Maglinedata2D.Vmagline_r(:,idx_IDSP_z,idx_magline_time),'g','LineWidth',3)
                    hold on
                    %標準偏差表示
                    errarea_magline_r_y = err_magline_r_y*ones(size(Maglinedata2D.Vmagline_r(:,idx_IDSP_z,idx_magline_time),1),1);
                    ar_magline=area(Maglinedata2D.rq(:,idx_IDSP_z),[Maglinedata2D.Vmagline_r(:,idx_IDSP_z,idx_magline_time)-errarea_magline_r_y errarea_magline_r_y+errarea_magline_r_y]);
                    set(ar_magline(1),'FaceColor','None','LineStyle',':','EdgeColor','g')
                    set(ar_magline(2),'FaceColor','g','FaceAlpha',0.2,'LineStyle',':','EdgeColor','g')
            end
        end
        hold on
        h = plot(nan,nan,'g-','LineWidth',3);
        hold on
        if isempty(hs)
            hs = h;
        else
            hs = [hs h];
        end
        if legendStrings == ""
            legendStrings = "Magnetic Line";
        else
            legendStrings = [legendStrings "Magnetic Line"];
        end
    else
        warning([savename.magline, 'does not exist.'])
    end
end

if plot_Vcontop
    if exist(savename.contop,"file")
        load(savename.contop,'Contopdata')
        idx_contop_time = knnsearch(Contopdata.trange,plot_time);
        Vcontop_r_mean = mean(Contopdata.Vcontop_r,2);
        err_contop_r_y = 3;
        if contop_mean
            switch profileplot
                case 'Vr'
                    % errorbar(Contopdata.rq(:,idx_IDSP_z),Vcontop_r_mean,err_contop_r_y,err_contop_r_y,err_contop_x,err_contop_x,'go','LineWidth',3)
                    %平均値表示
                    plot(Contopdata.rq,Vcontop_r_mean,'g','LineWidth',3)
                    hold on
                    %標準偏差表示
                    errarea_contop_r_y = err_contop_r_y*ones(size(Vcontop_r_mean,1),1);
                    ar_contop=area(Contopdata.rq,[Vcontop_r_mean-errarea_contop_r_y errarea_contop_r_y+errarea_contop_r_y]);
                    set(ar_contop(1),'FaceColor','None','LineStyle',':','EdgeColor','g')
                    set(ar_contop(2),'FaceColor','g','FaceAlpha',0.2,'LineStyle',':','EdgeColor','g')
            end
        else
            switch profileplot
                case 'Vr'
                    % errorbar(Contopdata.rq(:,idx_IDSP_z),Contopdata.Vcontop_r(:,idx_IDSP_z,idx_contop_time),err_contop_r_y,err_contop_r_y,err_contop_x,err_contop_x,'go','LineWidth',3)
                    %平均値表示
                    plot(Contopdata.rq,Contopdata.Vcontop_r(:,idx_contop_time),'g','LineWidth',3)
                    hold on
                    %標準偏差表示
                    errarea_contop_r_y = err_contop_r_y*ones(size(Contopdata.Vcontop_r(:,idx_contop_time),1),1);
                    ar_contop=area(Contopdata.rq,[Contopdata.Vcontop_r(:,idx_contop_time)-errarea_contop_r_y errarea_contop_r_y+errarea_contop_r_y]);
                    set(ar_contop(1),'FaceColor','None','LineStyle',':','EdgeColor','g')
                    set(ar_contop(2),'FaceColor','g','FaceAlpha',0.2,'LineStyle',':','EdgeColor','g')
            end
        end
        hold on
        h = plot(nan,nan,'g-','LineWidth',3);
        hold on
        if isempty(hs)
            hs = h;
        else
            hs = [hs h];
        end
        if legendStrings == ""
            legendStrings = "Magnetic Line";
        else
            legendStrings = [legendStrings "Magnetic Line"];
        end
    else
        warning([savename.contop, 'does not exist.'])
    end
end

if plot_magpres
    if exist(savename.ExB,"file")
        load(savename.ExB,'newPCBdata2D')
        mu0 = 4*pi*1E-7;
        idx_IDSP_z = knnsearch(newPCBdata2D.zq(1,:)',IDSP.z(1));
        idx_IDSP_z_min = knnsearch(newPCBdata2D.zq(1,:)',IDSP.z(1)-0.016);
        idx_IDSP_z_max = knnsearch(newPCBdata2D.zq(1,:)',IDSP.z(1)+0.016);
        idx_pcb_time = knnsearch(newPCBdata2D.trange',plot_time);
        magpres_z = newPCBdata2D.Bz(:,idx_IDSP_z,idx_pcb_time).^2/(2*mu0);
        magpres_r = newPCBdata2D.Br(:,idx_IDSP_z,idx_pcb_time).^2/(2*mu0);
        magpres_t = newPCBdata2D.Bt(:,idx_IDSP_z,idx_pcb_time).^2/(2*mu0);
        magpres_all = magpres_z + magpres_r + magpres_t;
        magpres_z_mean = mean(newPCBdata2D.Bz(:,idx_IDSP_z_min:idx_IDSP_z_max,idx_pcb_time-2:idx_pcb_time+2).^2/(2*mu0),3);
        magpres_z_mean = mean(magpres_z_mean,2);
        magpres_r_mean = mean(newPCBdata2D.Br(:,idx_IDSP_z_min:idx_IDSP_z_max,idx_pcb_time-2:idx_pcb_time+2).^2/(2*mu0),3);
        magpres_r_mean = mean(magpres_r_mean,2);
        magpres_t_mean = mean(newPCBdata2D.Bt_ext(:,idx_IDSP_z_min:idx_IDSP_z_max,idx_pcb_time-2:idx_pcb_time+2).^2/(2*mu0),3);
        magpres_t_mean = mean(magpres_t_mean,2);
        magpres_zt_mean = magpres_z_mean + magpres_t_mean;
        magpres_all_mean = magpres_z_mean + magpres_r_mean + magpres_t_mean;
        yyaxis right
        err_magpres_z_y = 2E2;
        err_magpres_r_y = 1E1;
        err_magpres_t_y = 3E3;
        err_magpres_x = 0.01;
        if magpres_mean
            switch magpresplot
                case 'Pz'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_z_mean,err_magpres_z_y,err_magpres_z_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pr'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_r_mean,err_magpres_r_y,err_magpres_r_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pt'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_t_mean,err_magpres_t_y,err_magpres_t_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pzt'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_zt_mean,err_magpres_t_y,err_magpres_t_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pall'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_all_mean,err_magpres_t_y,err_magpres_t_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
            end
        else
            switch magpresplot
                case 'Pz'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_z,err_magpres_z_y,err_magpres_z_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pr'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_r,err_magpres_r_y,err_magpres_r_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pt'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_t,err_magpres_t_y,err_magpres_t_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pzt'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_zt,err_magpres_t_y,err_magpres_t_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
                case 'Pall'
                    errorbar(newPCBdata2D.rq(:,idx_IDSP_z),magpres_all,err_magpres_t_y,err_magpres_t_y,err_magpres_x,err_magpres_x,'g^','LineWidth',3)
            end
        end
        switch magpresplot
            case 'Pz'
                ylabel('B_Z^2/2\mu_0 [Pa]')
            case 'Pr'
                ylabel('B_R^2/2\mu_0 [Pa]')
            case 'Pt'
                ylabel('B_t^2/2\mu_0 [Pa]')
            case 'Pzt'
                ylabel('(B_z^2+B_t^2)/2\mu_0 [Pa]')
            case 'Pall'
                ylabel('B^2/2\mu_0 [Pa]')
        end
        hold on
        h = plot(nan,nan,'g^-','LineWidth',3);
        if isempty(hs)
            hs = h;
        else
            hs = [hs h];
        end
        if legendStrings == ""
            legendStrings = "Magnetic Pressure";
        else
            legendStrings = [legendStrings "Magnetic Pressure"];
        end
    else
        warning([savename.ExB, 'does not exist.'])
    end
    ax = gca;
    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = 'g';
end

fontsize(20,"points")

xlim([0.07 0.27])
ylim([-20 20])
% xlabel('R [m]')
% switch profileplot
%     case 'Vz'
%         ylabel('V_Z [km/s]')
%     case 'Vr'
%         ylabel('V_R [km/s]')
% end
% legendStrings = string(WAV_IDSPdata.time(1:2)) +"us";
legend(hs,legendStrings,'Location','northeast')

% grid on


