%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ドップラープローブによるイオン温度、フローをプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% close all
clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

%------【input】-------
% % FC合体、X点R=0.2m、ExBアウトフロー小。IDSP->230828,230829(delay=480,484,488us)
% IDSP.date = 230828;%【input】IDSP実験日
% IDSPshotlist = [5 6 8:12 15:17 19:23 25:27 31:61 63];
% cal_time = 482;%【input】プロット時間[us]482,486

% SEP合体、X点R=0.26m、ExBアウトフロー大。IDSP->230830,230831(delay=468, 472, 476us)
% IDSP.date = 230830;%【input】IDSP実験日
% IDSPshotlist = [13:60];%[13 14 16 17 20 22 23 25 26 32 37 41:45 47 49 51 54 55 57];%【input】IDSPshot番号リスト
IDSP.date = 230830;%【input】IDSP実験日
IDSPshotlist = [9 12];%[13 14 16 17 20 22 23 25 26 32 37 41:45 47 49 51 54 55 57];%【input】IDSPshot番号リスト
cal_time = 'all';%【input】プロット時間[us]470,474

% % 同極性スフェロマック合体 + 外部TF4kV
% IDSP.date = 240828;%【input】静電プローブ計測日
% IDSPshotlist = [49];%[11:20 22:45 47:51]【input】IDSPshot番号リスト
% cal_time = 'all';%【input】プロット時間[us]470,474,'all'

IDSP.n_CH = 28;%【input】ドップラープローブファイバーCH数(28)
IDSP.n_r = 7;%【input】ドップラープローブr方向データ数(数値)(7)
IDSP.n_z = 1;%【input】ドップラープローブz方向データ数(数値)(1)

%------詳細設定【input】------
plot_fit = true;%【input】ガウスフィッティングを表示(true,false)
save_fit = true;%【input】ガウスフィッティングpngを保存(true,false)
save_fig = true;%【input】流速pngを保存(true,false)
show_offset = false;%【input】分光offsetを表示(true,false)
factor = 0.001;%【input】イオンフロー矢印サイズ(数値:0.001など)

%--------実験ログ取得---------
DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,IDSP.date);
IDSPshotlist(ismember(IDSPshotlist,T.shot)==0) = [];
n_data=numel(IDSPshotlist);%計測データ数
PF1list=T.CB1_kV_(IDSPshotlist);
PF2list=T.CB2_kV_(IDSPshotlist);
TFlist=T.TF_kV_(IDSPshotlist);
EFlist=T.EF_A_(IDSPshotlist);
Gaslist=T.gas(IDSPshotlist);
IDSPminZlist=T.IDSPZ_cm_(IDSPshotlist);
IDSPminRlist=T.IDSPMinR_cm_(IDSPshotlist);
IDSPdelaylist=T.IDSPDelay_us_(IDSPshotlist);
IDSPwidthlist=T.IDSPWidth_us_(IDSPshotlist);
IDSPgainlist=T.IDSPGain(IDSPshotlist);
IDSPtimelist=round(IDSPdelaylist+IDSPwidthlist/2);

for i=1:n_data
    IDSP.shot=IDSPshotlist(i);
    IDSP.line=Gaslist(i);
    IDSP.delay=IDSPdelaylist(i);
    IDSP.width=IDSPwidthlist(i);
    IDSP.gain=IDSPgainlist(i);
    IDSP.time=IDSPtimelist(i);
    IDSP.z = IDSPminZlist(i)*ones(7,1)*1E-2;
    IDSP.r = ((IDSPminRlist(i):2.5:IDSPminRlist(i)+(IDSP.n_r-1)*2.5)*1E-2)';
    EXP.PF1=PF1list(i);
    EXP.PF2=PF2list(i);
    EXP.TF=TFlist(i);
    EXP.EF=EFlist(i);
    FIG.start = IDSP.time;%プロット開始時刻[us]
    if not(isnan(IDSP.delay))
        switch cal_time
            case 'all'
                %IDSP計算
                IDSPdata = cal_ionflow(IDSP,pathname,show_offset,plot_fit,save_fit);
                %イオン流速プロット
                plot_ionflow(IDSPdata,EXP,IDSP,pathname,factor,false,save_fig,'ionflow')
            otherwise
                if IDSP.time == cal_time
                    %IDSP計算
                    IDSPdata = cal_ionflow(IDSP,pathname,show_offset,plot_fit,save_fit);
                    %イオン流速プロット
                    plot_ionflow(IDSPdata,EXP,IDSP,pathname,factor,false,save_fig,'ionflow')
                end
        end
    end
end

