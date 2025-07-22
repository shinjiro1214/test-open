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
i = 1;
for n = idx_25
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
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
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
% plot_time_evolution(k,2.5,timeList,sxrMaxList,sxrMaxList_err);

% TF3kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_30
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
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
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
plot_time_evolution(k,3,timeList,sxrMaxList,sxrMaxList_err);

% TF3.5kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_35
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
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
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
plot_time_evolution(k,3.5,timeList,sxrMaxList,sxrMaxList_err);

% TF4kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_40
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
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
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
plot_time_evolution(k,4,timeList,sxrMaxList,sxrMaxList_err);

function plot_time_evolution(k,TF,timeList,sxrMaxList,sxrMaxList_err)
    timeListPlot = find(timeList>=465&timeList<=470);
    timeList = timeList(timeListPlot);
    sxrMaxList = sxrMaxList([1,2,4],timeListPlot);
    sxrMaxList_err = sxrMaxList_err([1,2,4],timeListPlot);
    % titleList = {'1um Al','2.5um Al','1um Mylar'};
    titleList = {'20-80eV','50-80eV','100eV<'};
    plotList=[1,2];

    figure;
    yyaxis left
    errorbar(timeList,sxrMaxList(1,:),sxrMaxList_err(1,:),'Color',"#0072BD",'LineStyle','-','LineWidth',3);hold on;
    errorbar(timeList,sxrMaxList(2,:),sxrMaxList_err(2,:),'Color',"#0072BD",'LineStyle','--','LineWidth',3);
    ylabel('SXR intensity [a.u.]');
    yyaxis right
    errorbar(timeList,sxrMaxList(3,:),sxrMaxList_err(3,:),'Color',"#D95319",'LineStyle','-','LineWidth',3);
    xlabel('Time [us]');ylabel('SXR intensity [a.u.]');
    legend(titleList);
    ax=gca;ax.FontSize=18;
    
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

