close all
load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR_old2.mat')

idx_40 = [7:9,28:30];
idx_35 = [10:12,25:27];
idx_30 = [13:15,22:24];
idx_25 = 16:21;

timeList = sort([460:5:495,458:5:493]);
k = 2;

% TF3kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_30
% for n = idx_40
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
    % % k = 2;
    for j = 1:4
        if j ~= k
            maxList(i,j,timeIdx) = maxList(i,j,timeIdx)./maxList(i,k,timeIdx);
            meanList(i,j,timeIdx) = meanList(i,j,timeIdx)./meanList(i,k,timeIdx);
        end
    end
    i = i+1;
end
maxList(maxList==0)=nan;meanList(meanList==0)=nan;
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
% plot_time_evolution(k,3,timeList,sxrMaxList,sxrMaxList_err);

thomsonShotList = [14,15,16,17,19,21];
% magShotList = [20,26,27,37,38,46];
magShotList = 38;
thomsonTimeList = [465,466,467,468,469,470];

[ne_t,Te_t,ne_std,Te_std] = deal(nan(numel(thomsonTimeList),1));

i=1;
for time = thomsonTimeList
    thomsonIdx = thomsonShotList(thomsonTimeList==time);
    thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/241228',num2str(thomsonIdx,'%03i'),'-241228008_CIntvl_CDur_allfiber_TeNePe.csv'];
    T = readmatrix(thomsonPath);
    r = reshape(T(:,2),7,[]);
    z = reshape(T(:,3),7,[]);
    Te_mat = reshape(T(:,4),7,[]);
    ne_mat = reshape(T(:,6),7,[]);

    SD_Te_mat = reshape(T(:,5),7,[]);
    Te_mat(Te_mat<SD_Te_mat) = NaN;
    SD_ne_mat = reshape(T(:,7),7,[]);
    ne_mat(ne_mat<SD_ne_mat) = NaN;

    % 内挿（NaNが多いのでやらない方が良さげ）
    T(T(:,4)<T(:,5),2:4) = 0;
    % F = scatteredInterpolant(T(:,3),T(:,2),T(:,4));
    [rq,zq] = meshgrid(linspace(0.125,0.302,40),linspace(-0.078,0.078,40));
    % Te_q = F(zq,rq);
    Te_q = interp2(r,z,Te_mat,rq,zq);
    ne_q = interp2(r,z,ne_mat,rq,zq);

    % 磁場からX点座標を取得
    folderPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/241228';
    fileExtention = '.mat';
    % magIdx = magShotList(thomsonTimeList==time);
    magIdx = magShotList;
    path = [folderPath,num2str(magIdx,'%03i'),fileExtention];
    load(path,'data2D','grid2D');
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    % hold on;plot(xPointList.z(time-400),xPointList.r(time-400),'kx');
    % 最も近い点（上下左右で4点？）を検索
    z=zq;r=rq;Te_mat=Te_q;ne_mat=ne_q;
    timeIndex=time-400;
    z_idx = find(z(:,1)<=xPointList.z(timeIndex),1,'last');
    z_idx_list = z_idx-1:z_idx+1;
    % r_idx = find(r(1,:)<=xPointList.r(timeIndex),1,'last');
    r_idx_list = find(r(1,:)<=xPointList.r(timeIndex)+0.02&r(1,:)>=xPointList.r(timeIndex)-0.02);
    % その点の平均値を取得
    Te_x = mean([Te_mat(z_idx_list,r_idx_list)],'all','omitnan');
    Te_x_std = std([Te_mat(z_idx_list,r_idx_list)],0,'all','omitnan');
    ne_x = mean([ne_mat(z_idx_list,r_idx_list)],'all','omitnan');
    ne_x_std = std([ne_mat(z_idx_list,r_idx_list)],0,'all','omitnan');
    % disp(Te_x);
    ne_t(i)=ne_x;Te_t(i)=Te_x;
    ne_std(i)=ne_x_std;Te_std(i)=Te_x_std;
    i=i+1;
end

% figure;errorbar(thomsonTimeList([1,4,6]),ne_t([1,4,6]),ne_std([1,4,6]),'k','LineWidth',3);%title('Density');
% xlabel('time [us]');ylabel('Electron density [m^{-3}]');ax=gca;ax.FontSize=18;


dirPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed/240111';
shotList = 7:30;
t = 441:480;
Et_t = zeros(numel(shotList),numel(t));
trange = t-399;
j = 1;
% figure;hold on;
for i = shotList
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Et_t_tmp = -1*get_Et_time(grid2D,data2D,trange);
    % Et_t(j,:) = Et_t_tmp - Et_t_tmp(1);
    Et_t(j,:) = -1*get_Et_time(grid2D,data2D,trange);
    % plot(t,Et_t(j,:));
    j = j+1;
end
[~,idxTF40] = ismember([7:9,28:30],shotList);
[~,idxTF35] = ismember([10:12,25:27],shotList);
[~,idxTF30] = ismember([13:15,22:24],shotList);
[~,idxTF25] = ismember(16:21,shotList);

EtM40 = mean(Et_t(idxTF40,:),'omitmissing');
EtD40 = std(Et_t(idxTF40,:),'omitmissing');
EtM35 = mean(Et_t(idxTF35,:),'omitmissing');
EtD35 = std(Et_t(idxTF35,:),'omitmissing');
EtM30 = mean(Et_t(idxTF30,:),'omitmissing');
EtD30 = std(Et_t(idxTF30,:),'omitmissing');
EtM25 = mean(Et_t(idxTF25,:),'omitmissing');
EtD25 = std(Et_t(idxTF25,:),'omitmissing');
% figure;errorbar(t,EtM25,EtD25);hold on;
% errorbar(t,EtM30,EtD30);
% errorbar(t,EtM35,EtD35);
% errorbar(t,EtM40,EtD40);
% legend({'TF=2.5kV','TF=3kV','TF=3.5kV','TF=4kV'});

% xlabel('Time [us]');
% ax=gca;ax.FontSize=18;
% ylabel('Reconnection electric field [V/t]');

% % figure;tiledlayout(3,1);
% % figure;tiledlayout(2,2);
% figure;tiledlayout(4,1);
% ax3=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
% % xlabel('Time [us]');
% xticks([]);
% % ylabel('Intensity ratio [a.u.]');
% ax4=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
% % xlabel('Time [us]');
% xticks([]);
% % ylabel('Intensity ratio [a.u.]');
% ax1=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
% % xlabel('Time [us]');
% xticks([]);
% ylabel('-E_\theta [V/m]');
% ax2=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
% xlabel('Time [us]');
% ylabel('n_e [m^{-3}]');

% % sgtitle(['TF = ', num2str(TF), 'kV'],'FontSize',18);
% hold([ax1 ax2 ax3 ax4],'on');
% errorbar(ax1,t(t>=465&t<=470),EtM30(t>=464&t<=469),EtD30(t>=464&t<=469),'k-','LineWidth',3);
% % yticks([-4s00 -200 0]);xticks([460 465 470]);
% errorbar(ax2,thomsonTimeList([1,4,6]),ne_t([1,4,6]),ne_std([1,4,6]),'k','LineWidth',3);
% % yyaxis left
% errorbar(ax3,timeList(4:6),sxrMaxList(1,4:6),sxrMaxList_err(1,4:6),'-k','LineWidth',3);
% % errorbar(ax3,timeList(4:6),sxrMeanList(1,4:6),sxrMeanList_err(1,4:6),'-k','LineWidth',3);
% % yyaxis right
% errorbar(ax4,timeList(4:6),sxrMaxList(3,4:6),sxrMaxList_err(3,4:6),'-k','LineWidth',3);
% % errorbar(ax4,timeList(4:6),sxrMeanList(3,4:6),sxrMeanList_err(3,4:6),'-k','LineWidth',3);
% ax1.FontSize=18;
% ax2.FontSize=18;
% ax3.FontSize=18;
% ax4.FontSize=18;

% figure;hold on;
% RGB = orderedcolors("gem");
% x_data = [465, 468, 470];
% % I_plot = I_plot./I_plot(1,:);
% plot(x_data,I_plot(:,1)/max(I_plot(:,1)),'o-','LineWidth',2);
% plot(x_data,I_plot(:,2)/max(I_plot(:,2)),'o-','LineWidth',2);
% errorbar(timeList(4:6),sxrMaxList(1,4:6)/max(sxrMaxList(1,4:6)),sxrMaxList_err(1,4:6),'--','Color',RGB(1,:),'LineWidth',3);
% errorbar(timeList(4:6),sxrMaxList(3,4:6)/max(sxrMaxList(3,4:6)),sxrMaxList_err(3,4:6),'--','Color',RGB(2,:),'LineWidth',3);
% % errorbar(timeList(4:6),sxrMeanList(1,4:6)/max(sxrMeanList(1,4:6)),sxrMeanList_err(1,4:6),'--','Color',RGB(1,:),'LineWidth',3);
% % errorbar(timeList(4:6),sxrMeanList(3,4:6)/max(sxrMeanList(3,4:6)),sxrMeanList_err(3,4:6),'--','Color',RGB(2,:),'LineWidth',3);
% % plot(I_plot,'o-','LineWidth',2);
% ylabel('SXR intensity ratio [a.u.]');xlabel('Time [μs]');
% legend({'Low energy (simulation)','High energy (simulation)','Low energy (experiment)', 'High energy (experiment)'},'Location','southeast')
% % yticks([]);xticks([]);
% xlim([464.5 470.5]);ylim([0 inf]);
% ax = gca;ax.FontSize = 18;

figure;hold on;
ylim([0 inf]);xlim([464.5 470.5]);
ylabel('Relative intensity [a.u.]');xlabel('Time [us]');
errorbar(timeList(4:6),sxrMaxList(1,4:6)./max(sxrMaxList(1,4:6)),sxrMaxList_err(1,4:6)./max(sxrMaxList(1,4:6)),'LineWidth',3);
errorbar(timeList(4:6),sxrMaxList(3,4:6)./max(sxrMaxList(3,4:6)),sxrMaxList_err(3,4:6)./max(sxrMaxList(3,4:6)),'Color',"#EDB120",'LineWidth',3);
titleList = {'I_{20-80eV}/I_{50-80eV}','I_{100eV<}/I_{50-80eV}'};legend(titleList);
ax=gca;ax.FontSize=18;

figure;tiledlayout(2,1);
% figure;tiledlayout(2,2);
% figure;tiledlayout(4,1);
ax2=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
% ylabel('Intensity ratio [a.u.]');
ylabel('Relative intensity [a.u.]');
% ylabel('n_e [m^{-3}]');
% xlabel('Time [us]');
xticks([]);
% ylabel('Intensity ratio [a.u.]');
ax1=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
ylabel('n_e [m^{-3}]');
% xlabel('Time [us]');
% xticks([]);
% ylabel('Intensity ratio [a.u.]');
% ax1=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
% xlabel('Time [us]');
% xticks([]);
% ylabel('-E_\theta [V/m]');
% ax2=nexttile;ylim([0 inf]);xlim([464.5 470.5]);
% ylabel('Intensity ratio [a.u.]');
xlabel('Time [us]');
% ylabel('n_e [m^{-3}]');

% sgtitle(['TF = ', num2str(TF), 'kV'],'FontSize',18);
hold([ax1 ax2],'on');
% errorbar(ax1,t(t>=465&t<=470),EtM30(t>=464&t<=469),EtD30(t>=464&t<=469),'k-','LineWidth',3);
% yticks([-400 -200 0]);xticks([460 465 470]);
errorbar(ax1,thomsonTimeList([1,4,6]),ne_t([1,4,6]),ne_std([1,4,6]),'k','LineWidth',3);
% yyaxis left
errorbar(ax2,timeList(4:6),sxrMaxList(1,4:6)./max(sxrMaxList(1,4:6)),sxrMaxList_err(1,4:6)./max(sxrMaxList(1,4:6)),'LineWidth',3);
% errorbar(ax3,timeList(4:6),sxrMeanList(1,4:6),sxrMeanList_err(1,4:6),'-k','LineWidth',3);
% yyaxis right
errorbar(ax2,timeList(4:6),sxrMaxList(3,4:6)./max(sxrMaxList(3,4:6)),sxrMaxList_err(3,4:6)./max(sxrMaxList(3,4:6)),'Color',"#EDB120",'LineWidth',3);
% errorbar(ax4,timeList(4:6),sxrMeanList(3,4:6),sxrMeanList_err(3,4:6),'-k','LineWidth',3);
titleList = {'I_{20-80eV}/I_{50-80eV}','I_{100eV<}/I_{50-80eV}'};legend(ax2,titleList);
ax1.FontSize=18;
ax2.FontSize=18;
% ax3.FontSize=18;
% ax4.FontSize=18;

figure;tiledlayout(1,2);
nexttile;
errorbar(t(t>=465&t<=470),EtM30(t>=464&t<=469),EtD30(t>=464&t<=469),'k-','LineWidth',3);
ylim([-inf inf]);xlim([464.5 470.5]);
% xticks([]);
ylabel('-E_t [V/m]');
xlabel('Time [us]');
ax=gca;ax.FontSize=18;
nexttile;
errorbar(thomsonTimeList([1,4,6]),ne_t([1,4,6]),ne_std([1,4,6]),'k','LineWidth',3);
ylim([0 inf]);xlim([464.5 470.5]);
ylabel('n_e [m^{-3}]');
xlabel('Time [us]');
ax=gca;ax.FontSize=18;

function Et_t = get_Et_time(grid2D,data2D,trange)
    [~,xPointList] = get_axis_x_multi(grid2D,data2D);
    Et_t = zeros(1,numel(trange));
    % t = 461:480;
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1),xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).',xPointList.z(i));
        Et_t(m) = mean(data2D.Et(max(1,idxR-2):min(idxR+2,numel(grid2D.rq(:,1))),max(1,idxZ-1):min(numel(grid2D.zq(1,:)),idxZ+1),i),'all');
        m = m+1;
    end
end