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

% ESP.date = 230830;%【input】静電プローブ計測日
% % ESP.shotlist = [11 13 14 16 17 20 22 23];%【input】静電プローブ解析shotlist(同一オペレーション)
% ESP.shotlist = [11 13 14 16 17 20 22 23 26 29 32 34 37 41 42];%【input】静電プローブ解析shotlist(同一オペレーション)

ESP.date = 230828;%【input】静電プローブ計測日
% ESP.shotlist = [6 11 14 16 20 23 27 33 37 40 43 46 49 52 54 56 58 60 63];%【input】静電プローブ解析shotlist(同一オペレーション)
ESP.shot =14;

ESP.mesh = 50;%【input】静電プローブ補間メッシュ数
ESP.trange = 440:0.1:530;%【input】計算時間範囲(0.1刻み)
ESP.tate = 3;%【input】プロット枚数(縦)
ESP.yoko = 3;%【input】プロット枚数(横)
ESP.start_t = 460;%【input】プロット開始時刻[us]
ESP.dt = 2;%【input】プロット時間間隔[us]
ESP.vector = false;%【input】電場ベクトルをプロット

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,ESP.date);
ESP.rlist=T.ESProbeRPosition_mm_(ESP.shotlist);%静電プローブr座標[mm]

plot_Efield = false;
trange = 460:480;

n_ch = 21;%静電プローブCH数
% res_ratio = 50;%静電プローブ分圧比

% z = linspace(-0.15,0.15,ESP.mesh);%プロットメッシュZ座標[m]
% z_probe = linspace(-0.15,0.15,21);%静電プローブ計測点Z座標[m]
% % ng_ch = [4 6 16];%死んだCH
% z_probe(ng_ch) = [];
% r = linspace(min(ESP.rlist),max(ESP.rlist),ESP.mesh)*1E-3;%プロットメッシュR座標[m]
% r_probe = unique(ESP.rlist)*1E-3;%静電プローブ計測点R座標[m]

% phi = zeros(numel(ESP.trange),n_ch,numel(r_probe));
% cnt_r = zeros(numel(r_probe),1);
% for i = 1:numel(ESP.shotlist)
%     idx_r = find(r_probe==ESP.rlist(i)*1E-3);
%     cnt_r(idx_r) = cnt_r(idx_r) + 1;
%     filename = sprintf("%s%03d%s",[pathname.ESP '/' num2str(ESP.date) '/ES_' num2str(ESP.date)], ESP.shotlist(i), '.csv');
%     ESPdata_full = readmatrix(filename);
%     ESPdata = ESPdata_full(ismember(round(ESPdata_full(:,1),1),ESP.trange),2:end);
%     % ESPdata = readmatrix(filename,'Range',sprintf('B%d:V%d',ESP.trange(1)*10+2,ESP.trange(end)*10+2));
%     phi(:,:,idx_r) = (phi(:,:,idx_r)*(cnt_r(idx_r)-1) + ESPdata)/cnt_r(idx_r);
% end
% % phi(:,ng_ch,:) = [];%死んだCHを除去
% phi = fliplr(phi);%(CH1のZ座標)>(CH2のZ座標)>...のため、列を反転
% phi = phi.*res_ratio;%分圧比を掛ける

filename = sprintf("%s%03d%s",[pathname.ESP '/' num2str(ESP.date) '/ES_' num2str(ESP.date)], ESP.shot, '.csv');
ESPdata_full = readmatrix(filename);
phi = ESPdata_full(ismember(round(ESPdata_full(:,1),1),ESP.trange),2:end);

legendList = cell(7,1);
figure;
for i = 1:3
    subplot(3,1,i);hold on;
    for j = 1:7
        plot(ESP.trange,phi(:,j+7*(i-1)));
        legendList(j) = cellstr(['ch',num2str(j+7*(i-1))]);
    end
    legend(legendList);
end