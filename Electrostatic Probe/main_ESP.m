%%% cal & plot ExB drift velocity %%%
% clear all
% addpath '/Users/rsomeya/Documents/lab/matlab/common';

% run define_path.m
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
pathname.MAGDATA = getenv('MAGDATA_DIR');
pathname.ESP = getenv('NIFS_ESP');
pathname.github = getenv('GITHUB_DIR');

ESP.date = 230830;%【input】静電プローブ計測日
% ESP.shotlist = [11 13 14 16 17 20 22 23];%【input】静電プローブ解析shotlist(同一オペレーション)
ESP.shotlist = [11 13 14 16 17 20 22 23 26 29 32 34 37 41 42];%【input】静電プローブ解析shotlist(同一オペレーション)
ESP.mesh = 50;%【input】静電プローブ補間メッシュ数
ESP.trange = 440:0.1:530;%【input】計算時間範囲(0.1刻み)
ESP.tate = 3;%【input】プロット枚数(縦)
ESP.yoko = 3;%【input】プロット枚数(横)
ESP.start_t = 440;%【input】プロット開始時刻[us]
ESP.dt = 2;%【input】プロット時間間隔[us]
ESP.vector = false;%【input】電場ベクトルをプロット

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,ESP.date);
ESP.rlist=T.ESProbeRPosition_mm_(ESP.shotlist);%静電プローブr座標[mm]

plot_Efield = false;
trange = 460:480;

ESPdata2D = cal_ESP(pathname,ESP);
% plot_ESP(ESP,ESPdata2D)
% movie_ESP(plot_Efield,trange,ESPdata2D)
% plot_ESP_on_PCB(ESP,ESPdata2D,pathname);

dphi = max(ESPdata2D.phi_grid,[],[2 3])-min(ESPdata2D.phi_grid,[],[2 3]);
figure;plot(ESP.trange,dphi,'k','LineWidth',2);xlim([455 475]);
ylabel("Potential difference [V]");xlabel("time [us]");ax=gca;ax.FontSize=18;