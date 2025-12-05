function [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D)

trange = data2D.trange;
% timeIndex = trange==time;
psi = data2D.psi;
% psi = psi(:,:,timeIndex);
Bt = data2D.Bt;
% Bt = Bt(:,:,timeIndex);
rq = grid2D.rq;
zq = grid2D.zq;
rqList = repmat(rq,1,1,numel(trange));
zqList = repmat(zq,1,1,numel(trange));

% ltdRangeZ = find(abs(zq(1,:))<=0.17);
% rq_ltd = rq(:,ltdRangeZ);
% zq_ltd = zq(:,ltdRangeZ);
% rqList_ltd = repmat(rq_ltd,1,1,numel(trange));
% zqList_ltd = repmat(zq_ltd,1,1,numel(trange));
% psi_ltd = psi(:,ltdRangeZ,:);
% 
% rqList = rqList_ltd;
% zqList = zqList_ltd;
% psi = psi_ltd;

% 各z座標について、r方向の最大値とそのインデックスを取得
% [M,I] = max(psi,[],1);
[psiRidge,psiRidgeIdx] = max(psi,[],1,'linear'); %1*40*401 double
% 取得されたr方向最大値ベクトルからの極大値（軸位置候補）を2つ取得
axisCandidate = islocalmax(psiRidge,'MaxNumExtrema',2); %1*40*401 logical

magAxisList.r = NaN(2,numel(trange));
magAxisList.z = NaN(2,numel(trange));
magAxisList.psi = NaN(2,numel(trange));
magAxisList.Bt = NaN(2,numel(trange));
xPointList.r = NaN(1,numel(trange));
xPointList.z = NaN(1,numel(trange));
xPointList.psi = NaN(1,numel(trange));
xPointList.Bt = NaN(1,numel(trange));

% magAxisList.r = rqList(I(TF));
% magAxisList.z = zqList(I(TF));
% magAxisList.psi = psi(I(TF));

rLim = [min(rq,[],'all'),max(rq,[],"all")];
% zLim = [min(zq,[],'all'),max(zq,[],"all")];

% ここから
% X点を探す
% 2つの極大値の間にある極小値を探索
% いちいち切り出すと配列のサイズが変わってしまう
% 極大値の外側は0か最大値（極大値の大きい方）で埋める？
% 外側の識別
for i=1:numel(trange)
    psiRidge_t = psiRidge(:,:,i);
    psiRidgeIdx_t = psiRidgeIdx(:,:,i);
    axisCandidate_t = axisCandidate(:,:,i);
    if ~isempty(psiRidgeIdx_t(axisCandidate_t))
        magAxisList.r(:,i) = rqList(psiRidgeIdx_t(axisCandidate_t));
        magAxisList.z(:,i) = zqList(psiRidgeIdx_t(axisCandidate_t));
        magAxisList.psi(:,i) = psi(psiRidgeIdx_t(axisCandidate_t));
        magAxisList.Bt(:,i) = Bt(psiRidgeIdx_t(axisCandidate_t));
        % M_x = psiRidge_t(find(axisCandidate_t,1):find(axisCandidate_t,1,'last'));
        % I_x = psiRidgeIdx_t(find(axisCandidate_t,1):find(axisCandidate_t,1,'last'));
        % TF_x = islocalmin(M_x,'MaxNumExtrema',1);
        % if ~isempty(I_x(TF_x))
        %     xPointList.r(i) = rqList(I_x(TF_x));
        %     xPointList.z(i) = zqList(I_x(TF_x));
        %     xPointList.psi(i) = psi(I_x(TF_x));
        % end
    end
    xpointIdx = islocalmin(smooth(psiRidge_t),'MaxNumExtrema', 1);
    if ~isempty(find(xpointIdx, 1))
        xPointList.r(i) = rqList(psiRidgeIdx_t(xpointIdx));
        xPointList.z(i) = zqList(psiRidgeIdx_t(xpointIdx));
        xPointList.psi(i) = psi(psiRidgeIdx_t(xpointIdx));
        xPointList.Bt(i) = Bt(psiRidgeIdx_t(xpointIdx));
    end
    if any(ismember(magAxisList.r(:,i),rLim))
        magAxisList.r(:,i) = NaN;
        magAxisList.z(:,i) = NaN;
        magAxisList.psi(:,i) = NaN;
        magAxisList.Bt(:,i) = NaN;
    end
    if any(ismember(xPointList.r(i),rLim))
        xPointList.r(i) = NaN;
        xPointList.z(i) = NaN;
        xPointList.psi(i) = NaN;
        xPointList.Bt(i) = NaN;
    end
    % if trange(i) == 467
    %     flag = true;
    % end
    if all(~isnan([magAxisList.r(:,i);xPointList.r(i)]))&&sum(magAxisList.z(:,i)>xPointList.z(i))~=1
        [~,smallAxis] = min(magAxisList.psi(i));
        maxAxis = 3-smallAxis;
        magAxisList.r(smallAxis,i) = magAxisList.r(maxAxis,i);
        magAxisList.z(smallAxis,i) = magAxisList.z(maxAxis,i);
        magAxisList.psi(smallAxis,i) = magAxisList.psi(maxAxis,i);
        magAxisList.Bt(smallAxis,i) = magAxisList.Bt(maxAxis,i);
    end
end

% % ここから条件分岐
% % 軸位置を2つ取得できた場合
% if numel(I(TF)) == 2
%     % 軸位置のrz座標を取得
%     magaxis.r = rq(I(TF));
%     magaxis.z = zq(I(TF));
%     magaxis.psi = psi(I(TF));
%     % 端なら除外
%     rLim = [min(rq,[],'all'),max(rq,[],"all")];
%     zLim = [min(zq,[],'all'),max(zq,[],"all")];
%     if any(ismember(magaxis.r,rLim)) || any(ismember(magaxis.z,zLim))
%         magaxis.r = NaN;
%         magaxis.z = NaN;
%         magaxis.psi = NaN;
%     end
% 
%     % 2つの軸の間でx点を検索
%     M_x = M(find(TF,1):find(TF,1,'last'));
%     I_x = I(find(TF,1):find(TF,1,'last'));
%     TF_x = islocalmin(M_x,'MaxNumExtrema',1);
%     if ~isempty(TF_x)
%         xpoint.r = rq(I_x(TF_x));
%         xpoint.z = zq(I_x(TF_x));
%         xpoint.psi = psi(I_x(TF_x));
%         xpoint.Bt = Bt(I_x(TF_x));
%         if any(ismember(xpoint.r,rLim)) || any(ismember(xpoint.z,zLim))
%             xpoint.r = NaN;
%             xpoint.z = NaN;
%             xpoint.psi = NaN;
%             xpoint.Bt = NaN;
%         end
%     else
%         xpoint.r = NaN;
%         xpoint.z = NaN;
%         xpoint.psi = NaN;
%         xpoint.Bt = NaN;
%     end
% elseif numel(I(TF)) == 1
%     % 軸位置のrz座標を取得
%     magaxis.r = rq(I(TF));
%     magaxis.z = zq(I(TF));
%     magaxis.psi = psi(I(TF));
%     rLim = [min(rq,[],'all'),max(rq,[],"all")];
%     zLim = [min(zq,[],'all'),max(zq,[],"all")];
%     if any(ismember(magaxis.r,rLim)) || any(ismember(magaxis.z,zLim))
%         magaxis.r = NaN;
%         magaxis.z = NaN;
%         magaxis.psi = NaN;
%     end
%     xpoint.r = NaN;
%     xpoint.z = NaN;
%     xpoint.psi = NaN;
%     xpoint.Bt = NaN;
% else
%     magaxis.r = NaN;
%     magaxis.z = NaN;
%     magaxis.psi = NaN;
%     xpoint.r = NaN;
%     xpoint.z = NaN;
%     xpoint.psi = NaN;
%     xpoint.Bt = NaN;
% end


end