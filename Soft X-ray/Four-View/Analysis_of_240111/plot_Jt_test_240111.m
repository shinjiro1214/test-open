addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
% t = 441:480;
t = 461:480;
Jt_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Et_t_tmp = -1*get_Et_time(grid2D,data2D,trange);
    % Et_t(j,:) = Et_t_tmp - Et_t_tmp(1);
    % Jt_t(j,:) = -1*get_Jt_time(grid2D,data2D,trange);
    Jt_t(j,:) = get_Jt_down_time(grid2D,data2D,trange);
    plot(t,Jt_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

JtM40 = mean(Jt_t(idxTF40,:),'omitmissing');
JtD40 = std(Jt_t(idxTF40,:),'omitmissing');
JtM35 = mean(Jt_t(idxTF35,:),'omitmissing');
JtD35 = std(Jt_t(idxTF35,:),'omitmissing');
JtM30 = mean(Jt_t(idxTF30,:),'omitmissing');
JtD30 = std(Jt_t(idxTF30,:),'omitmissing');
JtM25 = mean(Jt_t(idxTF25,:),'omitmissing');
JtD25 = std(Jt_t(idxTF25,:),'omitmissing');
figure;errorbar(t,JtM25,JtD25);hold on;
errorbar(t,JtM30,JtD30);
errorbar(t,JtM35,JtD35);
errorbar(t,JtM40,JtD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Toroidal current density [A/m^2]');

TF = 2.5:0.5:4;
% 4.5583    5.2295    6.4095    7.6048 GFR
% 0.1367    0.1569    0.1923    0.2281 Bt
Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
GFR = Bt ./ 30;
% TF = [270 330 390 450]/10;
t_idx = find(t==470);
Jt_M = [JtM25(t_idx) JtM30(t_idx) JtM35(t_idx) JtM40(t_idx)];
Jt_D = [JtD25(t_idx) JtD30(t_idx) JtD35(t_idx) JtD40(t_idx)];
% figure;errorbar(Bt,Jt_M,Jt_D,'LineWidth',3);
% xlabel('Toroidal magnetic field [mT]');ylabel('Toroidal current density [A/m^3]');
% ax=gca;ax.FontSize=18;
% xlim([130 230]);
figure;errorbar(GFR,Jt_M,Jt_D,'LineWidth',3);
xlabel('Guide field ratio');ylabel('Toroidal current density [A/m^3]');
ax=gca;ax.FontSize=18;
% xlim([2.3 4.2]);


function Jt_t = get_Jt_time(grid2D,data2D,trange)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    Jt_t = zeros(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        Jt_t(m) = mean(data2D.Jt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
        m = m+1;
    end
end

function Jt_t = get_Jt_down_time(grid2D,data2D,trange)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    Jt_t = zeros(1,numel(trange));
    % t = 461:480;
    % z_axis = grid2D.zq(1,:);
    % z_indices = abs(z_axis)<=0.01;
    m = 1;
    for i = trange
        % idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        J_r_tmp = mean(data2D.Jt(:,max(1,idxZ-2):min(numel(grid2D.zq(1,:)),idxZ+2),i),2);
        % plot(grid2D.rq(:,1),J_r_tmp);
        % J_r_mean = mean(J_r_tmp,2);
        % J_r_std = std(J_r_tmp,0,2);
        Jt_t(m) = max(mean(J_r_tmp,2));
        m = m+1;
    end
end