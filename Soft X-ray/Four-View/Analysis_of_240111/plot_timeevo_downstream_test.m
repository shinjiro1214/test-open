load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat')

idx_40 = [7:9,28:30];
idx_35 = [10:12,25:27];
idx_30 = [13:15,22:24];
idx_25 = 16:21;

timeList = sort([460:5:495,458:5:493]);
k = 2;

% TF2.5kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
errorList = zeros(6,4,16);
xList = zeros(6,4,16);
i = 1;
for n = idx_25
    [~,timeIdx] = ismember(downstreamList(n).t,timeList);
    maxList(i,:,timeIdx) = downstreamList(n).max_l;
    meanList(i,:,timeIdx) = downstreamList(n).mean_l;
    errorList(i,:,timeIdx) = downstreamList(n).std_l;
    % xList(i,:,timeIdx) = downstreamList(n).x;
    % % % k = 2;
    % for j = 1:4
    %     if j ~= k
    %         maxList(i,j,timeIdx) = maxList(i,j,timeIdx)./maxList(i,k,timeIdx);
    %         meanList(i,j,timeIdx) = meanList(i,j,timeIdx)./meanList(i,k,timeIdx);
    %     end
    % end
    i = i+1;
end
maxList(maxList==0)=nan;meanList(meanList==0)=nan;
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
% sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMeanList_err = squeeze(mean(errorList,'omitnan'));
% sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
% sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
% plot_time_evolution(k,2.5,timeList,sxrMaxList,sxrMaxList_err);
plot_time_evolution(k,2.5,timeList,sxrMeanList,sxrMeanList_err);

% TF3kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
errorList = zeros(6,4,16);
xList = zeros(6,4,16);
i = 1;
for n = idx_30
    [~,timeIdx] = ismember(downstreamList(n).t,timeList);
    maxList(i,:,timeIdx) = downstreamList(n).max_l;
    meanList(i,:,timeIdx) = downstreamList(n).mean_l;
    errorList(i,:,timeIdx) = downstreamList(n).std_l;
    % xList(i,:,timeIdx) = downstreamList(n).x;
    % % % k = 2;
    % for j = 1:4
    %     if j ~= k
    %         maxList(i,j,timeIdx) = maxList(i,j,timeIdx)./maxList(i,k,timeIdx);
    %         meanList(i,j,timeIdx) = meanList(i,j,timeIdx)./meanList(i,k,timeIdx);
    %     end
    % end
    i = i+1;
end
% maxList(maxList==0)=nan;meanList(meanList==0)=nan;
maxList=zero2nan(maxList);meanList=zero2nan(meanList);
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
% sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMeanList_err = squeeze(mean(errorList,'omitnan'));
% sxrMaxList = squeeze(mean(meanList,'omitnan'));
% sxrMaxList_err = squeeze(std(meanList,'omitnan'));
% sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
% sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
% plot_time_evolution(k,3,timeList,sxrMaxList,sxrMaxList_err);

% plot_time_single(k,3,timeList,sxrMeanList,sxrMeanList_err);
% plot_time_evolution(k,3,timeList,sxrMeanList,sxrMeanList_err);
plot_time_evolution(k,3,timeList,sxrMeanList,sxrMeanList_err);

% TF3.5kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
errorList = zeros(6,4,16);
xList = zeros(6,4,16);
i = 1;
for n = idx_35
    [~,timeIdx] = ismember(downstreamList(n).t,timeList);
    maxList(i,:,timeIdx) = downstreamList(n).max_l;
    meanList(i,:,timeIdx) = downstreamList(n).mean_l;
    errorList(i,:,timeIdx) = downstreamList(n).std_l;
    % xList(i,:,timeIdx) = downstreamList(n).x;
    % % % k = 2;
    % for j = 1:4
    %     if j ~= k
    %         maxList(i,j,timeIdx) = maxList(i,j,timeIdx)./maxList(i,k,timeIdx);
    %         meanList(i,j,timeIdx) = meanList(i,j,timeIdx)./meanList(i,k,timeIdx);
    %     end
    % end
    i = i+1;
end
% maxList(maxList==0)=nan;meanList(meanList==0)=nan;
maxList=zero2nan(maxList);meanList=zero2nan(meanList);
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
% sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMeanList_err = squeeze(mean(errorList,'omitnan'));
% sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
% sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
plot_time_evolution(k,3.5,timeList,sxrMaxList,sxrMaxList_err);
% plot_time_evolution(k,3.5,timeList,sxrMeanList,sxrMeanList_err);

% TF4kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
errorList = zeros(6,4,16);
xList = zeros(6,4,16);
i = 1;
for n = idx_40
    [~,timeIdx] = ismember(downstreamList(n).t,timeList);
    maxList(i,:,timeIdx) = downstreamList(n).max_l;
    meanList(i,:,timeIdx) = downstreamList(n).mean_l;
    errorList(i,:,timeIdx) = downstreamList(n).std_l;
    % xList(i,:,timeIdx) = downstreamList(n).x;
    % % % k = 2;
    % for j = 1:4
    %     if j ~= k
    %         maxList(i,j,timeIdx) = maxList(i,j,timeIdx)./maxList(i,k,timeIdx);
    %         meanList(i,j,timeIdx) = meanList(i,j,timeIdx)./meanList(i,k,timeIdx);
    %     end
    % end
    i = i+1;
end
% maxList(maxList==0)=nan;meanList(meanList==0)=nan;maxList(4:5,4,7) = nan;
maxList=zero2nan(maxList);meanList=zero2nan(meanList);
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
% sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMeanList_err = squeeze(mean(errorList,'omitnan'));
% sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
% sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;

plot_time_evolution(k,4,timeList,sxrMaxList,sxrMaxList_err);
% plot_time_evolution(k,4,timeList,sxrMeanList,sxrMeanList_err);

function plot_time_evolution(k,TF,timeList,sxrMaxList,sxrMaxList_err)
    % timeListPlot = find(timeList>=465&timeList<=470);
    timeListPlot = find(timeList>=458&timeList<=480);
    timeList = timeList(timeListPlot);
    sxrMaxList = sxrMaxList([1,2,4],timeListPlot);
    % sxrMaxList = sxrMaxList - min(sxrMaxList,[],2);
    sxrMaxList(isnan(sxrMaxList))=0;
    sxrMaxList_err = sxrMaxList_err([1,2,4],timeListPlot);
    sxrMaxList_err(isnan(sxrMaxList_err))=0;
    % titleList = {'1um Al','2.5um Al','1um Mylar'};
    titleList = {'I_{20-80eV}','I_{50-80eV}','I_{100eV<}'};
    plotList=[1,2];

    % figure;
    % yyaxis left
    % errorbar(timeList,sxrMaxList(1,:),sxrMaxList_err(1,:),'Color',"#0072BD",'LineStyle','-','LineWidth',3);hold on;
    % errorbar(timeList,sxrMaxList(2,:),sxrMaxList_err(2,:),'Color',"#0072BD",'LineStyle','--','LineWidth',3);
    % ylabel('SXR intensity [a.u.]');
    % yyaxis right
    % errorbar(timeList,sxrMaxList(3,:),sxrMaxList_err(3,:),'Color',"#D95319",'LineStyle','-','LineWidth',3);
    % xlabel('Time [us]');ylabel('SXR intensity [a.u.]');
    % legend(titleList);
    % ax=gca;ax.FontSize=18;

    figure;
    % errorbar(timeList,sxrMaxList(1,:)*1.5,sxrMaxList_err(1,:),'LineWidth',3);hold on;
    % errorbar(timeList,sxrMaxList(2,:)*1.5,sxrMaxList_err(2,:),'LineWidth',3);
    % errorbar(timeList,sxrMaxList(3,:),sxrMaxList_err(3,:),'LineWidth',3);
    errorbar(timeList,sxrMaxList(1,:)./max(sxrMaxList(1,:)),sxrMaxList_err(1,:)./max(sxrMaxList(1,:)),'LineWidth',3);hold on;
    % errorbar(timeList,sxrMaxList(2,:)./max(sxrMaxList(2,:)),sxrMaxList_err(2,:)./max(sxrMaxList(2,:)),'LineWidth',3);
    % errorbar(timeList,sxrMaxList(3,:)./max(sxrMaxList(3,:)),sxrMaxList_err(3,:)./max(sxrMaxList(3,:)),'LineWidth',3);
    xlabel('Time [us]');ylabel('SXR intensity [a.u.]');
    % legend(titleList);
    ax=gca;ax.FontSize=18;
    ylim([0 Inf]);
    
    % figure;tiledlayout(1,3);
    % ax1=nexttile;title(titleList(plotList(1)));ylim([0 inf]);xlim([464.5 470.5]);
    % xlabel('Time [us]');ylabel('SXR intensity [a.u.]');
    % ax2=nexttile;title(titleList(plotList(2)));ylim([0 inf]);xlim([464.5 470.5]);
    % xlabel('Time [us]');%ylabel('SXR intensity [a.u.]');
    % ax3=nexttile;title(titleList(plotList(3)));ylim([0 inf]);xlim([464.5 470.5]);
    % xlabel('Time [us]');%ylabel('SXR intensity [a.u.]');
    % sgtitle(['TF = ', num2str(TF), 'kV'],'FontSize',18);
    % hold([ax1 ax2 ax3],'on');
    % errorbar(ax1,timeList,sxrMaxList(plotList(1),:),sxrMaxList_err(plotList(1),:),'-k','LineWidth',3);
    % errorbar(ax2,timeList,sxrMaxList(plotList(2),:),sxrMaxList_err(plotList(2),:),'-k','LineWidth',3);
    % errorbar(ax3,timeList,sxrMaxList(plotList(3),:),sxrMaxList_err(plotList(3),:),'-k','LineWidth',3);
    % ax1.FontSize=18;
    % ax2.FontSize=18;
    % ax3.FontSize=18;
end

function plot_time_single(k,TF,timeList,sxrMaxList,sxrMaxList_err)
    % timeListPlot = find(timeList>=465&timeList<=470);
    timeListPlot = find(timeList>=450&timeList<=480);
    timeList = timeList(timeListPlot);
    sxrMaxList = sxrMaxList(4,timeListPlot);
    % sxrMaxList = sxrMaxList - min(sxrMaxList,[],2);
    sxrMaxList(isnan(sxrMaxList))=0;
    sxrMaxList_err = sxrMaxList_err(4,timeListPlot);
    sxrMaxList_err(isnan(sxrMaxList_err))=0;
    % titleList = {'1um Al','2.5um Al','1um Mylar'};
    % titleList = {'I_{20-80eV}','I_{50-80eV}','I_{100eV<}'};
    sxrMaxList([1:3,7]) = sxrMaxList([1:3,7])./10;
    sxrMaxList_err(7) = sxrMaxList_err(7)/10;

    figure;
    % errorbar(timeList,sxrMaxList(1,:),sxrMaxList_err(1,:),'LineWidth',3);hold on;
    % errorbar(timeList,sxrMaxList(2,:),sxrMaxList_err(2,:),'LineWidth',3);
    % errorbar(timeList,sxrMaxList(3,:),sxrMaxList_err(3,:),'LineWidth',3);
    errorbar(timeList,sxrMaxList./max(sxrMaxList),sxrMaxList_err./max(sxrMaxList),'k-','LineWidth',3);
    xlabel('Time [us]');ylabel('SXR intensity [a.u.]');
    % legend(titleList);
    ax=gca;ax.FontSize=18;
    ylim([-0.3 1.3]);xlim([450 480]);
    
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
