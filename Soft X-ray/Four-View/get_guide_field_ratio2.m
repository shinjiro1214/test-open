function [B_r,B_t,B_rt,b] = get_guide_field_ratio2(PCB,pathname)

% magDataDir = pathname.MAGDATA;
% magDataFile = strcat(magDataDir,'/',num2str(PCB.data),'.mat');
% if exist(magDataFile,'file')
%     load(magDataFile,'idxList','BrList','BtList','bList');
% end

trange = PCB.trange;
% newTimeRange = find(trange>=440&trange<=500);
newTimeRange = 1:numel(trange);
% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
[grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
Br = data2D.Br;
Bt = data2D.Bt;
rq = grid2D.rq;
zq = grid2D.zq;

% PCB_ref = PCB;
% PCB_ref.shot = PCB.tfshot;
% PCB_ref.tfshot = [0,0];
% [~,data2D_ref] = process_PCBdata_280ch(PCB_ref,pathname);
% Bt_ref = data2D_ref.Bt;

trange = trange(newTimeRange);
Br = Br(:,:,newTimeRange);
Bt = Bt(:,:,newTimeRange);

B_reconnection = zeros(1,numel(trange));
B_reconnection_t = zeros(1,numel(trange));

B_guide = zeros(1,numel(trange));
mergingRatio = zeros(1,numel(trange));




[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D,PCB);
% [I_TF,x,aquisition_rate] = get_TF_current(PCB,pathname);
% timing = x/aquisition_rate==time;
% m0 = 4*pi*10^(-7);
% r = xpoint.r;
% Bt = m0*I_TF(timing)*1e3*12/(2*pi()*r);


% 240117
% SPコイルの内側のプローブ（からのデータ）のみを使用するように修正が必要
for i = 1:numel(trange)
    % time = trange(i);
    % [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
    magaxis.r = magAxisList.r(:,i);
    magaxis.z = magAxisList.z(:,i);
    xpoint.r = xPointList.r(:,i);
    xpoint.z = xPointList.z(:,i);
    % if numel(magaxis.r) == 2
    if magaxis.z(1)~=magaxis.z(2) && ~isnan(magaxis.r(1))
        range = rq>=min(magaxis.r)&rq<=max(magaxis.r)&zq>=min(magaxis.z)&zq<=max(magaxis.z);
        % 値の取り方は考えた方がいい、Btは理論値でもよさそう
        Br_tmp = Br(:,:,i);
        Bt_tmp = Bt(:,:,i);

        % B_reconnection(1,i) = max(abs(Br_t(range)),[],'all');
        B_reconnection(1,i) = min([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        B_reconnection_t(1,i) = min([max(Bt_tmp(range),[],'all'),abs(min(Bt_tmp(range),[],"all"))]);

        % diffusionRegion = (abs(rq-xpoint.r)+abs(zq-xpoint.z))<=0.02;
        % Bt_t = Bt_ref(:,:,i);
        % B_guide(1,i) = mean(Bt_t(diffusionRegion));
        % B_guide(1,i) = get_B_troidal(PCB,grid2D,data2D,pathname,time);
        % timing = x/aquisition_rate==time;
        % B_guide(1,i) = m0*I_TF(timing)*1e3*12/(2*pi()*xPointList.r(1,i));
        B_guide(1,i) = xPointList.Bt(i);
        mergingRatio(1,i) = xPointList.psi(i)/mean(magAxisList.psi(:,i));
    elseif ~isnan(magaxis.r(1))
        range = rq>=min(magaxis.r(1),xpoint.r)&rq<=max(magaxis.r(1),xpoint.r)&zq>=min(magaxis.z(1),xpoint.z)&zq<=max(magaxis.z(1),xpoint.z);
        Br_tmp = Br(:,:,i);
        Bt_tmp = Bt(:,:,i);

        B_reconnection(1,i) = mean([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        B_reconnection_t(1,i) = mean([max(Bt_tmp(range),[],'all'),abs(min(Bt_tmp(range),[],"all"))]);
        
        % timing = x/aquisition_rate==time;
        % B_guide(1,i) = m0*I_TF(timing)*1e3*12/(2*pi()*xPointList.r(1,i));
        B_guide(1,i) = xPointList.Bt(i);
        mergingRatio(1,i) = xPointList.psi(i)/mean(magAxisList.psi(:,i));
    else
        B_reconnection(1,i) = NaN;
        B_reconnection_t(1,i) = NaN;

        B_guide(1,i) = NaN;
        mergingRatio(1,i) = NaN;
    end
end

nanMask = isnan(B_reconnection);
nanMask(2:end-1) = nanMask(1:end-2)&nanMask(3:end);
B_reconnection(nanMask) = NaN;

nanMask_t = isnan(B_reconnection_t);
nanMask_t(2:end-1) = nanMask_t(1:end-2)&nanMask_t(3:end);
B_reconnection_t(nanMask_t) = NaN;

B_guide(nanMask) = NaN;
mergingRatio(nanMask) = NaN;

% % x点psiの時間発展を表示
% figure;plot(trange,xPointList.psi);xlim([455 485]);
% plot(trange,xPointList.psi);xlim([455 485]);hold on;

% % 合体率・Br・Btの時間発展を表示
% plotRange = find(trange>=430&trange<=510);
% figure('Position', [0 0 1500 1500],'visible','on');
% subplot(1,3,1);plot(trange(plotRange),mergingRatio(plotRange));xlabel('time');ylabel('merging ratio');
% subplot(1,3,2);plot(trange(plotRange),B_reconnection(plotRange));xlabel('time');ylabel('B_r');
% subplot(1,3,3);plot(trange(plotRange),B_guide(plotRange));xlabel('time');ylabel('B_g');

% figure;plot(trange,mergingRatio);xlim([450 500]);

% timing = knnsearch(mergingRatio(plotRange).',0.5);
% timing = find(mergingRatio==0,1,'last');

% timing = find(trange>=460&trange<=500&mergingRatio>=0.5,1);
% timing = find(trange>=460&trange<=500&mergingRatio>=0,1);
% B_r = B_reconnection(1,timing);
% B_t = B_guide(1,timing);

B_r_max = maxk(B_reconnection(trange>=460&trange<=500),4);
B_r = mean(B_r_max(2:4));

B_r_max_t = maxk(B_reconnection_t(trange>=460&trange<=500),4);
B_rt = mean(B_r_max_t(2:4));

B_t = mean(B_guide(trange>=460&trange<=500),'omitnan');

b = B_t/B_r;

% % ガイド磁場比の計算に使用した磁気面を表示
% time = trange(timing);
% PCB.time = time;
% plot_psi280ch_at_t(PCB,pathname);

% if exist(magDataFile,'file')
%     idxList(end+1) = PCB.idx;
%     BrList(end+1) = B_r;
%     BtList(end+1) = B_t;
%     bList(end+1) = b;
% else
%     idxList = PCB.idx;
%     BrList = B_r;
%     BtList = B_t;
%     bList = b;
% end
% 
% save(magDataFile,'idxList','BrList','BtList','bList');

end