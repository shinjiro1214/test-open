%%% plot raw ESP data %%%
% close all
clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

% %直接入力の場合
ESP.date = 240827;%230830;%計測日
ESP.shotlist = 11;%[11 13 14 16 17 20 22:26 28 29 32 34 37 41:45 47 49 51 54 55 57 59 60];%【input】静電プローブ解析shotlist(同一オペレーション)
n_ch = 21;%静電プローブCH数
ch = linspace(1,n_ch,n_ch);
trange = 0:0.1:600;%【input】計算時間範囲(0.1刻み)

res_ratio = 50;%静電プローブ分圧比

ng_ch = [4 11 12 14:21];%[1:3 5 6 7:10 13][4 11 12 14:21][4 6 16 21];%死んだCH
if ng_ch
    ch(ng_ch) = [];%死んだCHを除去
end
DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,ESP.date);
ESP.rlist=T.ESProbeRPosition_mm_(ESP.shotlist);%静電プローブr座標[mm]

figure('Position', [0 0 1500 1500],'visible','on');
for i_shot = 1:numel(ESP.shotlist)
    phi = zeros(numel(trange),n_ch);
    filename = sprintf("%s%03d%s",[pathname.ESP '/' num2str(ESP.date) '/ES_' num2str(ESP.date)], ESP.shotlist(i_shot), '.csv');
    ESPdata = readmatrix(filename,'Range',sprintf('A%d:V%d',trange(1)*10+2,trange(end)*10+2));
    time = ESPdata(:,1);
    phi(:,:) = ESPdata(:,2:end);
    if ng_ch
        phi(:,ng_ch) = [];%死んだCHを除去
    end
    phi = phi.*res_ratio;%分圧比を掛ける
    [~,raw_phi] = size(phi);

    % figure('Position', [0 300 700 500],'visible','on');
    % for i = 1:raw_phi
    %     plot(trange,phi(:,i))
    %     hold on
    % end
    % title('Raw ESP data')
    % xlabel('Time [us]')
    % ylabel('Floating Potential [V]')
    % xlim([460 490])
    % ylim([-200 200])
    % legendStrings = "CH" + string(ch);
    % legend(legendStrings)

    %Low pass filtered
    % figure('Position', [800 300 700 500],'visible','on');
    if numel(ESP.shotlist)>1
        subplot(6,5,i_shot)
    end
    for i = 1:raw_phi
        % plot(time,lowpass(phi(:,i),1E-4))
        plot(time,phi(:,i))
        hold on
    end
    % title('Low pass filtered ESP data')
    title(['Shot',num2str(ESP.shotlist(i_shot)),': R=',num2str(ESP.rlist(i_shot)),'mm'])
    xlabel('Time [us]')
    ylabel('Floating Potential [V]')
    % xlim([420 700])
    % xlim([390 410])
    xlim([45 55])
    % xlim([100 500])
    % ylim([-200 300])
    if numel(ESP.shotlist) == 1
        legendStrings = "CH" + string(ch);
        legend(legendStrings)
    end
end