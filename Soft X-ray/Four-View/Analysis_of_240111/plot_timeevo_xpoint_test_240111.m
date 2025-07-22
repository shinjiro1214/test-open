load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat')

idx_40 = [7:9,28:30];
idx_35 = [10:12,25:27];
idx_30 = [13:15,22:24];
idx_25 = 16:21;

timeList = sort([460:5:495,458:5:493]);

% TF2.5kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_25
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
    i = i+1;
end
maxList(maxList==0)=nan;meanList(meanList==0)=nan;
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
figure;tiledlayout(2,2);
ax1=nexttile;title('1um Al');
ax2=nexttile;title('2.5um Al');
ax3=nexttile;title('2um Mylar');
ax4=nexttile;title('1um Mylar');
sgtitle('TF = 2.5kV');
hold([ax1 ax2 ax3 ax4],'on');
errorbar(ax1,timeList,sxrMaxList(1,:),sxrMaxList_err(1,:));
errorbar(ax2,timeList,sxrMaxList(2,:),sxrMaxList_err(2,:));
errorbar(ax3,timeList,sxrMaxList(3,:),sxrMaxList_err(3,:));
errorbar(ax4,timeList,sxrMaxList(4,:),sxrMaxList_err(4,:));

% TF3kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_30
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
    i = i+1;
end
maxList(maxList==0)=nan;meanList(meanList==0)=nan;
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
figure;tiledlayout(2,2);
ax1=nexttile;title('1um Al');
ax2=nexttile;title('2.5um Al');
ax3=nexttile;title('2um Mylar');
ax4=nexttile;title('1um Mylar');
sgtitle('TF = 3kV');
hold([ax1 ax2 ax3 ax4],'on');
errorbar(ax1,timeList,sxrMaxList(1,:),sxrMaxList_err(1,:));
errorbar(ax2,timeList,sxrMaxList(2,:),sxrMaxList_err(2,:));
errorbar(ax3,timeList,sxrMaxList(3,:),sxrMaxList_err(3,:));
errorbar(ax4,timeList,sxrMaxList(4,:),sxrMaxList_err(4,:));

% TF3.5kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_35
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
    i = i+1;
end
maxList(maxList==0)=nan;meanList(meanList==0)=nan;
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
figure;tiledlayout(2,2);
ax1=nexttile;title('1um Al');
ax2=nexttile;title('2.5um Al');
ax3=nexttile;title('2um Mylar');
ax4=nexttile;title('1um Mylar');
sgtitle('TF = 3.5kV');
hold([ax1 ax2 ax3 ax4],'on');
errorbar(ax1,timeList,sxrMaxList(1,:),sxrMaxList_err(1,:));
errorbar(ax2,timeList,sxrMaxList(2,:),sxrMaxList_err(2,:));
errorbar(ax3,timeList,sxrMaxList(3,:),sxrMaxList_err(3,:));
errorbar(ax4,timeList,sxrMaxList(4,:),sxrMaxList_err(4,:));

% TF4kV
maxList = zeros(6,4,16);
meanList = zeros(6,4,16);
i = 1;
for n = idx_40
    [~,timeIdx] = ismember(xpointList(n).t,timeList);
    maxList(i,:,timeIdx) = xpointList(n).max;
    meanList(i,:,timeIdx) = xpointList(n).mean;
    i = i+1;
end
maxList(maxList==0)=nan;meanList(meanList==0)=nan;
sxrMaxList = squeeze(mean(maxList,'omitnan'));
sxrMaxList_err = squeeze(std(maxList,'omitnan'));
sxrMeanList = squeeze(mean(meanList,'omitnan'));
sxrMeanList_err = squeeze(std(meanList,'omitnan'));
sxrMaxList(isnan(sxrMaxList))=0;sxrMeanList(isnan(sxrMeanList))=0;
sxrMaxList_err(isnan(sxrMaxList_err))=0;sxrMeanList_err(isnan(sxrMeanList_err))=0;
% figure;tiledlayout(2,2);
% ax1=nexttile;title('1um Al');
% ax2=nexttile;title('2.5um Al');
% ax3=nexttile;title('2um Mylar');
% ax4=nexttile;title('1um Mylar');
% sgtitle('TF = 4kV');
% hold([ax1 ax2 ax3 ax4],'on');
% errorbar(ax1,timeList,sxrMaxList(1,:),sxrMaxList_err(1,:));
% errorbar(ax2,timeList,sxrMaxList(2,:),sxrMaxList_err(2,:));
% errorbar(ax3,timeList,sxrMaxList(3,:),sxrMaxList_err(3,:));
% errorbar(ax4,timeList,sxrMaxList(4,:),sxrMaxList_err(4,:));
figure;tiledlayout(3,1);
ax1=nexttile;title('1um Al');xlim([455,475]);
ax2=nexttile;title('2.5um Al');xlim([455,475]);
% ax3=nexttile;title('2um Mylar');
ax3=nexttile;title('1um Mylar');xlim([455,475]);
sgtitle('TF = 4kV');
hold([ax1 ax2 ax3],'on');
errorbar(ax1,timeList,sxrMaxList(1,:),sxrMaxList_err(1,:),'LineWidth',3);
errorbar(ax2,timeList,sxrMaxList(2,:),sxrMaxList_err(2,:),'LineWidth',3);
errorbar(ax3,timeList,sxrMaxList(4,:),sxrMaxList_err(4,:),'LineWidth',3);
ax1.FontSize=18;ax2.FontSize=18;ax3.FontSize=18;