function data = get_guide_field_ratio3(PCB,pathname)

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
Et = -1*data2D.Et;
% Bt = data2D.Bt;
rq = grid2D.rq;
zq = grid2D.zq;

% PCB_ref = PCB;
% PCB_ref.shot = PCB.tfshot;
% PCB_ref.tfshot = [0,0];
% [~,data2D_ref] = process_PCBdata_280ch(PCB_ref,pathname);
% Bt_ref = data2D_ref.Bt;

trange = trange(newTimeRange);
Br = Br(:,:,newTimeRange);
% Bt = Bt(:,:,newTimeRange);

% B_reconnection = zeros(1,numel(trange));
% B_guide = zeros(1,numel(trange));
% B_guide_th = zeros(1,numel(trange));
% mergingRatio = zeros(1,numel(trange));
% Et_t = zeros(1,numel(trange));
B_reconnection = NaN(1,numel(trange));
B_guide = NaN(1,numel(trange));
B_guide_th = NaN(1,numel(trange));
mergingRatio = NaN(1,numel(trange));
Et_t = NaN(1,numel(trange));

[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D);
[I_TF,x,aquisition_rate] = get_TF_current(PCB,pathname);
% timing = x/aquisition_rate==time;
I_TF = smoothdata(I_TF,"gaussian");
m0 = 4*pi*10^(-7);
% r = xpoint.r;
% Bt = m0*I_TF(timing)*1e3*12/(2*pi()*r);


% 240117
% SPコイルの内側のプローブ（からのデータ）のみを使用するように修正が必要
for i = 1:numel(trange)
    time = trange(i);
    % [magaxis,xpoint] = get_axis_x(grid2D,data2D,time);
    magaxis.r = magAxisList.r(:,i);
    magaxis.z = magAxisList.z(:,i);
    xpoint.r = xPointList.r(:,i);
    xpoint.z = xPointList.z(:,i);
    % if numel(magaxis.r) == 2
    if magaxis.z(1)~=magaxis.z(2) && ~isnan(magaxis.r(1))
        range_r = rq(:,1)>=min(magaxis.r)&rq(:,1)<=max(magaxis.r);
        range_z = zq(1,:)>=min(magaxis.z)&zq(1,:)<=max(magaxis.z);
        % 値の取り方は考えた方がいい、Btは理論値でもよさそう
        Br_tmp = Br(:,:,i);
        % B_reconnection(1,i) = max(abs(Br_t(range)),[],'all');
        if sum(range_r) == 1
            Br_mean = Br_tmp(range_r,range_z);
        else
            Br_mean = mean(Br_tmp(range_r,range_z));
        end
        Br1 = max(Br_mean);
        Br2 = abs(min(Br_mean));
        B_reconnection(1,i) = min([Br1,Br2]);
        % diffusionRegion = (abs(rq-xpoint.r)+abs(zq-xpoint.z))<=0.02;
        % Bt_t = Bt_ref(:,:,i);
        % B_guide(1,i) = mean(Bt_t(diffusionRegion));
        % B_guide(1,i) = get_B_troidal(PCB,grid2D,data2D,pathname,time);
        timing = x/aquisition_rate==time;
        B_guide_th(1,i) = m0*I_TF(timing)*1e3*12/(2*pi()*xpoint.r);
        B_guide(1,i) = xPointList.Bt(i);
        mergingRatio(1,i) = xPointList.psi(i)/mean(magAxisList.psi(:,i));
        idxR = knnsearch(rq(:,1),xpoint.r);
        idxZ = knnsearch(zq(1,:).',xpoint.z);
        Et_t(1,i) = mean(Et(max(1,idxR-2):min(idxR+2,numel(rq(:,1))),max(1,idxZ-1):min(numel(zq(1,:)),idxZ+1),i),'all');
    elseif ~isnan(magaxis.r(1))
        range = rq>=min(magaxis.r(1),xpoint.r)&rq<=max(magaxis.r(1),xpoint.r)&zq>=min(magaxis.z(1),xpoint.z)&zq<=max(magaxis.z(1),xpoint.z);
        Br_tmp = Br(:,:,i);
        B_reconnection(1,i) = mean([max(Br_tmp(range),[],'all'),abs(min(Br_tmp(range),[],"all"))]);
        % timing = x/aquisition_rate==time;
        % B_guide(1,i) = m0*I_TF(timing)*1e3*12/(2*pi()*xPointList.r(1,i));
        B_guide(1,i) = xPointList.Bt(i);
        mergingRatio(1,i) = xPointList.psi(i)/mean(magAxisList.psi(:,i));
    else
        B_reconnection(1,i) = NaN;
        B_guide(1,i) = NaN;
        mergingRatio(1,i) = NaN;
    end
end

nanMask = isnan(B_reconnection);
nanMask(2:end-1) = nanMask(1:end-2)&nanMask(3:end);
B_reconnection(nanMask) = NaN;
B_guide(nanMask) = NaN;
B_guide_th(nanMask) = NaN;
mergingRatio(nanMask) = NaN;
Et_t(nanMask) = NaN;

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

timeRange = trange>=450&trange<=500;
t_tmp = trange(timeRange);
idx1 = find(mergingRatio(timeRange)<=0.5,1,'last');
idx2 = find(mergingRatio(timeRange)>=0.5,1);
mergingRatio_tmp = mergingRatio(timeRange);
mrRange = mergingRatio_tmp(idx2)-mergingRatio_tmp(idx1);
t_data = (t_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + t_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
B_r_tmp = B_reconnection(timeRange);
B_r = (B_r_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + B_r_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
B_t_tmp = B_guide(timeRange);
B_t_th_tmp = B_guide_th(timeRange);
B_t = (B_t_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + B_t_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
B_t_th = (B_t_th_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + B_t_th_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
E_t_tmp = Et_t(timeRange);
E_t = (E_t_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + E_t_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
if idx1 ~= idx2-1
    disp('Error in calculation of merging ratio!');
    t_data = mean(t_tmp);
    B_r = mean(B_r_tmp,'omintnan');
    B_t = mean(B_t_tmp,'omitnan');
    B_t_th = mean(B_t_th_tmp,'omitnan');
    E_t = max(E_t_tmp);
end

% t_data = mean(t_tmp);
% B_r = mean(B_r_tmp,'omitnan');
% B_t = mean(B_t_tmp,'omitnan');
% B_t_th = mean(B_t_th_tmp,'omitnan');
% E_t = max(E_t_tmp);

% B_r_max = maxk(B_reconnection(trange>=460&trange<=500),4);
% B_r = mean(B_r_max(2:4));


b = B_t/B_r;
b_th = B_t_th/B_r;

data.Br = B_r;
data.Bt = B_t;
data.Bt_th = B_t_th;
data.GFR = b;
data.GFR_th = b_th;
data.Et = E_t;
data.t = t_data;

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