load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat')

idx_40 = [7:9,28:30];
idx_35 = [10:12,25:27];
idx_30 = [13:15,22:24];
idx_25 = 16:21;

timeList = sort([460:5:495,458:5:493]);
k = 2;

idxList =  [13:15,22:24];
lists = get_time_lists(xpointList,timeList,idxList);
[plotTimeList, plotData, plotError] = plot_time_evolution(timeList,lists.mean,lists.mean_err);

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
% shotList = 7:30;
t = 441:480;
Et_t = zeros(numel([13:15,22:24]),numel(t));
trange = t-399;
j = 1;
% figure;hold on;
for i = [13:15,22:24]
    load([dirPath,num2str(i,'%03i'),'.mat'],'data2D','grid2D');
    % Et_t_tmp = -1*get_Et_time(grid2D,data2D,trange);
    % Et_t(j,:) = Et_t_tmp - Et_t_tmp(1);
    Et_t(j,:) = -1*get_Et_time(grid2D,data2D,trange);
    % plot(t,Et_t(j,:));
    j = j+1;
end


EtM30 = mean(Et_t,'omitmissing');
EtD30 = std(Et_t,'omitmissing');


figure;tiledlayout(2,1);
ax1=nexttile;ylim([-inf inf]);xlim([454.5 475.5]);
xticks([]);
ylabel('-E_t [V/m]');
ax2=nexttile;ylim([0 inf]);xlim([454.5 475.5]);
ylabel('SXR intensity [a.u.]');
xlabel('Time [us]');

hold([ax1 ax2],'on');
errorbar(ax1,t(t>=450&t<=480),EtM30(t>=449&t<=479),EtD30(t>=449&t<=479),'k-','LineWidth',3);
errorbar(ax2,plotTimeList,plotData(1,:),plotError(1,:),'LineWidth',3);
errorbar(ax2,plotTimeList,plotData(2,:),plotError(2,:),'LineWidth',3);
errorbar(ax2,plotTimeList,plotData(3,:),plotError(3,:),'LineWidth',3);
titleList = {'I_{20-80eV}','I_{50-80eV}','I_{100eV<}'};legend(ax2,titleList);
ax1.FontSize=18;
ax2.FontSize=18;


if exist('I_plot','var')
    sxrMaxList = plotData./plotData(2,:); sxrMaxList_err = plotError;
    figure;hold on;
    RGB = orderedcolors("gem");
    x_data = [465, 468, 470];
    % I_plot = I_plot./I_plot(1,:);
    plot(x_data,I_plot(:,1)/max(I_plot(:,1)),'o-','LineWidth',2);
    plot(x_data,I_plot(:,2)/max(I_plot(:,2)),'o-','LineWidth',2);
    errorbar(timeList(4:6),sxrMaxList(1,4:6)/max(sxrMaxList(1,4:6)),sxrMaxList_err(1,4:6),'--','Color',RGB(1,:),'LineWidth',3);
    errorbar(timeList(4:6),sxrMaxList(3,4:6)/max(sxrMaxList(3,4:6)),sxrMaxList_err(3,4:6),'--','Color',RGB(2,:),'LineWidth',3);
    % errorbar(timeList(4:6),sxrMeanList(1,4:6)/max(sxrMeanList(1,4:6)),sxrMeanList_err(1,4:6),'--','Color',RGB(1,:),'LineWidth',3);
    % errorbar(timeList(4:6),sxrMeanList(3,4:6)/max(sxrMeanList(3,4:6)),sxrMeanList_err(3,4:6),'--','Color',RGB(2,:),'LineWidth',3);
    % plot(I_plot,'o-','LineWidth',2);
    ylabel('SXR intensity ratio [a.u.]');xlabel('Time [μs]');
    legend({'Low energy (simulation)','High energy (simulation)','Low energy (experiment)', 'High energy (experiment)'},'Location','southeast')
    % yticks([]);xticks([]);
    xlim([464.5 470.5]);ylim([0 inf]);
    ax = gca;ax.FontSize = 18;
end


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

function lists = get_time_lists(xpointList,timeList,idxList)
    maxList = zeros(6,4,16);
    meanList = zeros(6,4,16);
    errorList = zeros(6,4,16);
    xList = zeros(6,4,16);
    i = 1;
    for n = idxList
        [~,timeIdx] = ismember(xpointList(n).t,timeList);
        maxList(i,:,timeIdx) = xpointList(n).max;
        meanList(i,:,timeIdx) = xpointList(n).mean;
        errorList(i,:,timeIdx) = xpointList(n).std;
        xList(i,:,timeIdx) = xpointList(n).x;
        i = i+1;
    end
    % maxList(maxList==0)=nan;meanList(meanList==0)=nan;
    maxList=zero2nan(maxList);meanList=zero2nan(meanList);xList=zero2nan(xList);
    lists.max = squeeze(mean(maxList,'omitnan'));
    lists.max_err = squeeze(std(maxList,'omitnan'));
    lists.mean = squeeze(mean(meanList,'omitnan'));
    % lists.mean_err = squeeze(std(meanList,'omitnan'));
    lists.mean_err = squeeze(mean(errorList,'omitnan'));
    lists.x = squeeze(mean(xList,'omitnan'));
    lists.x_err = squeeze(std(xList,'omitnan'));
end

function [plotTimeList, plotData, plotError] = plot_time_evolution(timeList,sxrDataList,sxrDataList_err)
    % timeListPlot = find(timeList>=465&timeList<=470);
    timeListPlot = find(timeList>=458&timeList<=480);
    plotTimeList = timeList(timeListPlot);
    sxrDataList = sxrDataList([1,2,4],timeListPlot);
    % sxrDataList = sxrDataList - min(sxrDataList,[],2);
    sxrDataList(isnan(sxrDataList))=0;
    sxrDataList_err = sxrDataList_err([1,2,4],timeListPlot);
    sxrDataList_err(isnan(sxrDataList_err))=0;
    % titleList = {'I_{20-80eV}','I_{50-80eV}','I_{100eV<}'};

    sxrDataList(:,[1:3,7]) = sxrDataList(:,[1:3,7])./5;
    % sxrDataList_err(:,7) = sxrDataList_err(:,7)/5;
    sxrDataList_err([1:3,7]) = sxrDataList_err([1:3,7])/5;

    plotData1 = sxrDataList(1,:)./max(sxrDataList(1,:));
    plotData2 = sxrDataList(2,:)./max(sxrDataList(2,:));
    plotData3 = sxrDataList(3,:)./max(sxrDataList(3,:));
    plotError1 = sxrDataList_err(1,:)./max(sxrDataList(1,:));
    plotError2 = sxrDataList_err(2,:)./max(sxrDataList(2,:));
    plotError3 = sxrDataList_err(3,:)./max(sxrDataList(3,:));
    plotData = [plotData1;plotData2;plotData3];
    plotError = [plotError1;plotError2;plotError3];
end

function B = zero2nan(A)
    % A: 6x4x16 行列
    B = A;   % 結果を格納する配列

    % まず単純にゼロを 負の値 に変換
    B(B==0) = -1;

    % --- ブロック1 (行1～3) ---
    % j,kごとに「ブロック1に非ゼロがあるか」を判定
    mask1 = any(A(1:3,:,:),1);        % 1x4x16 論理配列
    mask1 = repmat(mask1, [3,1,1]);   % 3x4x16 に拡張
    % ブロック1で非ゼロがある場所はゼロを残す → 負の値 を元に戻す
    B(1:3,:,:) = A(1:3,:,:).*(mask1) + B(1:3,:,:).*(~mask1);

    % --- ブロック2 (行4～6) ---
    mask2 = any(A(4:6,:,:),1);        % 1x4x16
    mask2 = repmat(mask2, [3,1,1]);   % 3x4x16
    B(4:6,:,:) = A(4:6,:,:).*(mask2) + B(4:6,:,:).*(~mask2);

    % 負の値の部分をNaNに変換
    B(B<0) = NaN;
end