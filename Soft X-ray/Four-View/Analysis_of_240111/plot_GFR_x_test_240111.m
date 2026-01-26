addpath('/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View');
dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 441:480;
GFR_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % GFR_t_tmp = -1*get_GFR_time(grid2D,data2D,trange);
    % GFR_t(j,:) = GFR_t_tmp - GFR_t_tmp(1);
    GFR_t(j,:) = -1*get_GFR_time(grid2D,data2D,trange);
    plot(t,GFR_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

GFRM40 = mean(GFR_t(idxTF40,:),'omitmissing');
GFRD40 = std(GFR_t(idxTF40,:),'omitmissing');
GFRM35 = mean(GFR_t(idxTF35,:),'omitmissing');
GFRD35 = std(GFR_t(idxTF35,:),'omitmissing');
GFRM30 = mean(GFR_t(idxTF30,:),'omitmissing');
GFRD30 = std(GFR_t(idxTF30,:),'omitmissing');
GFRM25 = mean(GFR_t(idxTF25,:),'omitmissing');
GFRD25 = std(GFR_t(idxTF25,:),'omitmissing');
figure;errorbar(t,GFRM25,GFRD25);hold on;
errorbar(t,GFRM30,GFRD30);
errorbar(t,GFRM35,GFRD35);
errorbar(t,GFRM40,GFRD40);
legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

xlabel('Time [us]');
ax=gca;ax.FontSize=18;
ylabel('Reconnection electric field [V/t]');

% TF = 2.5:0.5:4;
% 4.5583    5.2295    6.4095    7.6048 GFR
% 0.1367    0.1569    0.1923    0.2281 Bt
Bt = 1e3 * [0.1367    0.1569    0.1923    0.2281];
% TF = [270 330 390 450]/10;
t_idx = find(t==468);
GFR_M = [GFRM25(t_idx) GFRM30(t_idx) GFRM35(t_idx) GFRM40(t_idx)];
GFR_D = [GFRD25(t_idx) GFRD30(t_idx) GFRD35(t_idx) GFRD40(t_idx)];
figure;errorbar(Bt,GFR_M,GFR_D,'LineWidth',3);
xlabel('Toroidal magnetic field [mT]');ylabel('Reconnection electric field [V/m]');
ax=gca;ax.FontSize=18;
xlim([130 230]);
% xlim([2.3 4.2]);


function GFR_t = get_GFR_time(grid2D,data2D,trange)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    GFR_t = zeros(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        Br_tmp = data2D.Br(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i);
        Bz_tmp = data2D.Bz(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i);
        Bp_tmp = sqrt(Br_tmp.^2+Bz_tmp.^2);
        Bt_tmp = data2D.Bt(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i);
        GFR_t(m) = mean(Bt_tmp./Bp_tmp,'all');
        m = m+1;
    end
end