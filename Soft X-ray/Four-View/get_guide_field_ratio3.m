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
% % plotRange = find(trange>=430&trange<=510);
% plotRange = find(trange>=450&trange<=480);
% figure('Position', [0 0 1500 1500],'visible','on');
% subplot(1,3,1);plot(trange(plotRange),mergingRatio(plotRange));xlabel('time');ylabel('merging ratio');
% subplot(1,3,2);plot(trange(plotRange),B_reconnection(plotRange));xlabel('time');ylabel('B_r');
% subplot(1,3,3);plot(trange(plotRange),B_guide(plotRange));xlabel('time');ylabel('B_g');

figure;plot(trange,mergingRatio);xlim([460 480]);

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
% B_r = B_reconnection(trange==464);
B_t_tmp = B_guide(timeRange);
B_t_th_tmp = B_guide_th(timeRange);
B_t = (B_t_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + B_t_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
B_t_th = (B_t_th_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + B_t_th_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
E_t_tmp = Et_t(timeRange);
E_t = (E_t_tmp(idx1)*(mergingRatio_tmp(idx2)-0.5) + E_t_tmp(idx2)*(0.5-mergingRatio_tmp(idx1)))/mrRange;
if idx1 ~= idx2-1
    disp('Error in calculation of merging ratio!');
    t_data = mean(t_tmp);
    B_r = mean(B_r_tmp,'omitnan');
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

% ガイド磁場比の計算に使用した磁気面を表示
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

% =========================================================================
% 追加プロット処理: 合体率0.5 (t = t_data) における Br の Z方向分布
% =========================================================================
if ~isnan(t_data)
    % 1. t_data を挟む元の時間軸のインデックスを探す
    % (trange は既に newTimeRange でスライスされている前提)
    idx_floor = find(trange <= t_data, 1, 'last');
    idx_ceil = find(trange >= t_data, 1, 'first');
    
    if isempty(idx_floor) || isempty(idx_ceil)
        warning('t_data が trange の範囲外です。プロットをスキップします。');
    else
        % 時間方向の補間重みを計算
        if idx_floor == idx_ceil
            w_t = 0; % 完全に同じ時刻の場合
        else
            w_t = (t_data - trange(idx_floor)) / (trange(idx_ceil) - trange(idx_floor));
        end

        % 2. 2次元 Br 場を時間補間して作成
        Br2D_floor = Br(:,:,idx_floor);
        Br2D_ceil  = Br(:,:,idx_ceil);
        % 時刻 t_data における推定 2D Br 場
        Br2D_at_tdata = Br2D_floor * (1 - w_t) + Br2D_ceil * w_t;
        
        % 3. X点のR, Z座標も時間補間する
        % xPointList.r が [複数候補 x 時間] の場合、最初の候補(1行目)を使用
        rx_floor = xPointList.r(1, idx_floor);
        rx_ceil  = xPointList.r(1, idx_ceil);
        zx_floor = xPointList.z(1, idx_floor);
        zx_ceil  = xPointList.z(1, idx_ceil);
        
        Rx_at_tdata = rx_floor * (1 - w_t) + rx_ceil * w_t;
        Zx_at_tdata = zx_floor * (1 - w_t) + zx_ceil * w_t;

        % 4. Zプロファイルの抽出とプロット
        % グリッド軸の取得 (rq, zq の構造に依存します。通常 rq(:,1) がR軸、zq(1,:) がZ軸)
        r_axis = rq(:,1);
        z_axis = zq(1,:).'; % 列ベクトルにしておく

        % 補間された X点の R座標 に最も近いグリッドのインデックスを探す
        [~, idxR_closest] = min(abs(r_axis - Rx_at_tdata));
        R_closest_val = r_axis(idxR_closest);

        % そのR位置における Z方向の Br 分布を抽出 (Br2D は [R x Z] と仮定)
        Br_z_profile = Br2D_at_tdata(idxR_closest, :);

        % --- プロット作成 ---
        figure('Name', 'Br Z-profile at Merging Ratio 0.5');
        plot(z_axis, Br_z_profile, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 10); hold on;
        
        % X点のZ位置を赤破線で表示
        xline(Zx_at_tdata, 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('X-point Z (%.3f m)', Zx_at_tdata));
        % ゼロ点を黒線で表示
        yline(0, 'k-', 'HandleVisibility', 'off'); 
        
        grid on;
        xlabel('Z [m]', 'FontSize', 12);
        ylabel('B_r [T]', 'FontSize', 12);
        % title({sprintf('B_r Z-profile at t = %.2f $\\mu s$ (MR=0.5)', t_data); ...
            %    sprintf('at R $\\approx$ %.3f m (X-point R: %.3f m)', R_closest_val, Rx_at_tdata)}, ...
            %    'Interpreter', 'latex', 'FontSize', 12);
        legend('B_r(z)', 'Location', 'best');
        set(gca, 'FontSize', 10);
    end
end
% =========================================================================

end