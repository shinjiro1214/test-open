

addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
% t = 441:480;
t = 461:480;
% t = 461;
delta_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Et_t_tmp = -1*get_Et_time(grid2D,data2D,trange);
    % Et_t(j,:) = Et_t_tmp - Et_t_tmp(1);
    delta_t(j,:) = get_delta_time(grid2D,data2D,trange);
    % delta_t(j,:) = get_delta_down_time(grid2D,data2D,trange);
    plot(t,delta_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

deltaM40 = mean(delta_t(idxTF40,:),'omitmissing');
deltaD40 = std(delta_t(idxTF40,:),'omitmissing');
deltaM35 = mean(delta_t(idxTF35,:),'omitmissing');
deltaD35 = std(delta_t(idxTF35,:),'omitmissing');
deltaM30 = mean(delta_t(idxTF30,:),'omitmissing');
deltaD30 = std(delta_t(idxTF30,:),'omitmissing');
deltaM25 = mean(delta_t(idxTF25,:),'omitmissing');
deltaD25 = std(delta_t(idxTF25,:),'omitmissing');
figure;errorbar(t,deltaM25,deltaD25);hold on;
errorbar(t,deltaM30,deltaD30);
errorbar(t,deltaM35,deltaD35);
errorbar(t,deltaM40,deltaD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Current sheet width[m]');

TF = 2.5:0.5:4;
% 4.5583    5.2295    6.4095    7.6048 GFR
% 0.1367    0.1569    0.1923    0.2281 Bt
Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
GFR = Bt ./ 30;
% TF = [270 330 390 450]/10;
t_idx = find(t==470);
delta_M = [deltaM25(t_idx) deltaM30(t_idx) deltaM35(t_idx) deltaM40(t_idx)];
delta_D = [deltaD25(t_idx) deltaD30(t_idx) deltaD35(t_idx) deltaD40(t_idx)];
% figure;errorbar(Bt,delta_M,delta_D,'LineWidth',3);
% xlabel('Toroidal magnetic field [mT]');ylabel('Toroidal current density [A/m^3]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);
figure;errorbar(GFR,delta_M,delta_D,'LineWidth',3);
xlabel('Guide field ratio');ylabel('Current sheet width[m]');
ax=gca;ax.FontSize=18;
% xlim([2.3 4.2]);


function delta_t = get_delta_time(grid2D,data2D,trange)
% シート幅の時間発展を出す関数
% 半値全幅で計算？
% deltaをX点近傍で切り出し（0以上？）
% ガウスフィッティングをかける
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    delta_t = zeros(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        % idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        Jt_z = -1 * mean(data2D.Jt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),:,i));
        % idxZ = find(abs(grid2D.zq(1,:))<=0.05 & Jt_z>=0);
        idxZ = find(abs(grid2D.zq(1,:))<=0.1);
        % figure;plot(grid2D.zq(1,idxZ),Jt_z(idxZ),'*');
        f = fit(grid2D.zq(1,idxZ).',Jt_z(idxZ).','gauss1','Lower',[0 -0.08 0], 'Upper',[inf 0.08 inf]);
        % figure;plot(f,grid2D.zq(1,idxZ),Jt_z(idxZ),'*');
        delta_t(m) = 2 * sqrt(log(2)) * f.c1;
        m = m+1;
    end
end

function delta_t = get_delta_down_time(grid2D,data2D,trange)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    delta_t = zeros(1,numel(trange));
    % t = 461:480;
    % z_axis = grid2D.zq(1,:);
    % z_indices = abs(z_axis)<=0.01;
    m = 1;
    for i = trange
        % idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        J_r_tmp = mean(data2D.delta(:,max(1,idxZ-2):min(numel(grid2D.zq(1,:)),idxZ+2),i),2);
        % plot(grid2D.rq(:,1),J_r_tmp);
        % J_r_mean = mean(J_r_tmp,2);
        % J_r_std = std(J_r_tmp,0,2);
        delta_t(m) = max(mean(J_r_tmp,2));
        m = m+1;
    end
end