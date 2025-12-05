load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat')
% load('/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR_old3.mat')

idx_40 = [7:9,28:30];
idx_35 = [10:12,25:27];
idx_30 = [13:15,22:24];
idx_25 = 16:21;

idxLists = {idx_25,idx_30,idx_35,idx_40};

timeList = sort([460:5:495,458:5:493]);

for i = 1:numel(idxLists)
    idxList = cell2mat(idxLists(i));
    lists = get_time_lists(xpointList,timeList,idxList);
    plot_time_evolution(timeList,lists.mean,lists.mean_err);
    % plot_time_evolution(timeList,lists.x,lists.x_err);
    % plot_time_single(3,timeList,lists.x,lists.x_err);
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

function plot_time_evolution(timeList,sxrMaxList,sxrMaxList_err)
    % timeListPlot = find(timeList>=465&timeList<=470);
    timeListPlot = find(timeList>=458&timeList<=480);
    timeList = timeList(timeListPlot);
    sxrMaxList = sxrMaxList([1,2,4],timeListPlot);
    % sxrMaxList = sxrMaxList - min(sxrMaxList,[],2);
    sxrMaxList(isnan(sxrMaxList))=0;
    sxrMaxList_err = sxrMaxList_err([1,2,4],timeListPlot);
    sxrMaxList_err(isnan(sxrMaxList_err))=0;
    titleList = {'I_{20-80eV}','I_{50-80eV}','I_{100eV<}'};

    sxrMaxList(:,[1:3,7]) = sxrMaxList(:,[1:3,7])./5;
    % sxrMaxList_err(:,7) = sxrMaxList_err(:,7)/5;
    sxrMaxList_err([1:3,7]) = sxrMaxList_err([1:3,7])/5;

    figure;
    % errorbar(timeList,sxrMaxList(1,:)*1.5,sxrMaxList_err(1,:),'LineWidth',3);hold on;
    % errorbar(timeList,sxrMaxList(2,:)*1.5,sxrMaxList_err(2,:),'LineWidth',3);
    % errorbar(timeList,sxrMaxList(3,:),sxrMaxList_err(3,:),'LineWidth',3);
    errorbar(timeList,sxrMaxList(1,:)./max(sxrMaxList(1,:)),sxrMaxList_err(1,:)./max(sxrMaxList(1,:)),'LineWidth',3);hold on;
    errorbar(timeList,sxrMaxList(2,:)./max(sxrMaxList(2,:)),sxrMaxList_err(2,:)./max(sxrMaxList(2,:)),'LineWidth',3);
    errorbar(timeList,sxrMaxList(3,:)./max(sxrMaxList(3,:)),sxrMaxList_err(3,:)./max(sxrMaxList(3,:)),'LineWidth',3);
    xlabel('Time [us]');ylabel('SXR intensity [a.u.]');
    legend(titleList);
    ax=gca;ax.FontSize=18;
    ylim([0 Inf]);xlim([450 480]);
end

function plot_time_single(k,timeList,sxrMaxList,sxrMaxList_err)
    % timeListPlot = find(timeList>=465&timeList<=470);
    timeListPlot = find(timeList>=450&timeList<=480);
    timeList = timeList(timeListPlot);
    sxrMaxList = sxrMaxList([1,2,4],timeListPlot);
    sxrMaxList_err = sxrMaxList_err([1,2,4],timeListPlot);
    sxrMaxList = sxrMaxList(k,timeListPlot);
    % sxrMaxList = sxrMaxList - min(sxrMaxList,[],2);
    sxrMaxList(isnan(sxrMaxList))=0;
    sxrMaxList_err = sxrMaxList_err(k,timeListPlot);
    sxrMaxList_err(isnan(sxrMaxList_err))=0;
    sxrMaxList([1:3,7]) = sxrMaxList([1:3,7])./5;
    sxrMaxList_err(7) = sxrMaxList_err(7)/5;

    figure;
    errorbar(timeList,sxrMaxList./max(sxrMaxList),sxrMaxList_err./max(sxrMaxList),'k-','LineWidth',3);
    xlabel('Time [us]');ylabel('SXR intensity [a.u.]');
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
