clearvars -except saved_answer

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m

% --- 基本設定 ---
doCheck = 0;
dataType = 1;
PCB.chtype = 1;
threshold_ratio = 0.1;

% 240611 110:111 113:115 117:141                        500:530
% 241110 18 19 22:33                                    500:515
% 241124 24:26 28:30 32:36 38:53                        500:530
% 241225 9:11 14:26 28:34 36:42 47:57 59:61             500:530
% 250205 2 5:7 9 15 16 23:31 33:38 40:45                490:520
% 250206 2:23                                           490:510
% 251220 5:10 12:23                                     500:530


%%%% 入力ダイアログ
name = 'FRC vs Spheromak Check & Save';
prompt = {'Date:', 'Shot number:', 'Restart:', 'Analysis Start [us]:', 'Analysis End [us]:'};
formats = struct('type', {}, 'style', {}, 'items', {}, 'format', {}, 'limits', {}, 'size', {});

if exist('saved_answer', 'var')
    defaultanswer = saved_answer;
else
    defaultanswer = {[], '', [], 470, 550}; 
end

formats(1,1).type = 'edit'; formats(1,1).format = 'integer'; formats(1,1).size = [100 20];
formats(2,1).type = 'edit'; formats(2,1).format = 'text'; formats(2,1).size = [100 20];
formats(3,1).type = 'list'; formats(3,1).style = 'popupmenu'; formats(3,1).items = {'false', 'true'}; formats(3,1).format = 'integer';
formats(4,1).type = 'edit'; formats(4,1).format = 'float'; formats(4,1).size = [100 20];
formats(5,1).type = 'edit'; formats(5,1).format = 'float'; formats(5,1).size = [100 20];
% formats(6,1).type = 'edit'; formats(6,1).format = 'float'; formats(6,1).size = [100 20];

[answer, canceled] = inputsdlg(prompt, name, formats);

if isempty(answer) || canceled
    return
end

date = answer{1};
IDXlist_str = answer{2};
IDXlist = str2num(IDXlist_str);
PCB.restart = answer{3}-1;
t_start = answer{4};
t_end = answer{5};
% threshold_ratio = answer{6};
saved_answer = answer;

% === プロット用マスタ時間軸の設定 ===
PCB.trange = 300:600; 
PCB.n = 40;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
T=getTS6log(DOCID);
T=searchlog(T,'date',date);

if isnan(T.shot(1))
    T(1, :) = [];
end

n_data = numel(IDXlist);
shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
EFlist = T.EF_A_(IDXlist);
TFlist = T.TF_kV_(IDXlist);

% 結果格納用（時系列）
results_ratio = nan(n_data, numel(PCB.trange));
results_Bt_opoint = nan(n_data, numel(PCB.trange));
results_Bp_max = nan(n_data, numel(PCB.trange));

summary_data = struct('Date', [], 'Shot', [], 'Time_Start', [], 'Time_End', [], ...
                      'Mean_Ratio', [], 'Mean_Bt_Axis', [], 'Mean_Bp_Max', [], 'Classification', []);

% === データ処理ループ ===
for i=1:n_data
    PCB.date = date;
    PCB.idx = IDXlist(i);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    PCB.dataType = dataType;
    if all(PCB.shot == PCB.tfshot)
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.TF=TFlist(i);
    
    [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
    
    % 【改修点】提示された関数を使用して磁気軸リストを取得
    [magAxisList, ~] = get_axis_x_multi(grid2D, data2D, PCB);
    
    actual_time = data2D.trange; 
    
    for k = 1:length(actual_time)
        t_cur = actual_time(k);
        if t_cur < t_start || t_cur > t_end, continue; end
        
        store_idx = find(PCB.trange == t_cur);
        if isempty(store_idx), continue; end

        % 磁気軸座標の抽出 (2つある場合は平均、1つの場合はその値、NaNは無視)
        r_axes = magAxisList.r(:, k);
        z_axes = magAxisList.z(:, k);
        
        r_axis = mean(r_axes, 'omitnan');
        z_axis = mean(z_axes, 'omitnan');
        
        if isnan(r_axis) || isnan(z_axis)
            continue; 
        end

        % 最も近いグリッドインデックスを探す
        [~, r_idx] = min(abs(grid2D.rq(:,1) - r_axis));
        [~, z_idx] = min(abs(grid2D.zq(1,:) - z_axis));
        
        if isfield(data2D, 'Br') && isfield(data2D, 'Bz') && isfield(data2D, 'Bt')
            Bt_val = data2D.Bt(r_idx, z_idx, k);
            Br = data2D.Br(:,:,k);
            Bz = data2D.Bz(:,:,k);
            Bp = sqrt(Br.^2 + Bz.^2);
            
            % 規格化用のBp最大値（軸周辺または全体）
            % ここでは検索範囲内(R>0.15)の最大値を使用
            R_grid = grid2D.rq(:,1);
            search_mask = R_grid > 0.15;
            Bp_max = max(Bp(search_mask, :), [], 'all', 'omitnan');
            
            if Bp_max == 0, Bp_max = eps; end
            
            ratio = abs(Bt_val) / Bp_max;
            
            results_ratio(i, store_idx) = ratio;
            results_Bt_opoint(i, store_idx) = Bt_val;
            results_Bp_max(i, store_idx) = Bp_max;
        end
    end
    
    % 平均値計算と判定
    valid_mask = ~isnan(results_ratio(i, :));
    if any(valid_mask)
        mean_ratio = mean(results_ratio(i, valid_mask));
        mean_bt = mean(results_Bt_opoint(i, valid_mask));
        mean_bp = mean(results_Bp_max(i, valid_mask));
        class_str = 'Spheromak';
        if mean_ratio <= threshold_ratio, class_str = 'FRC'; end
    else
        mean_ratio = NaN; mean_bt = NaN; mean_bp = NaN; class_str = 'No Data';
    end
    
    summary_data(i).Date = date;
    summary_data(i).Shot = IDXlist(i);
    summary_data(i).Time_Start = t_start;
    summary_data(i).Time_End = t_end;
    summary_data(i).Mean_Ratio = mean_ratio;
    summary_data(i).Mean_Bt_Axis = mean_bt;
    summary_data(i).Mean_Bp_Max = mean_bp;
    summary_data(i).Classification = class_str;
end

% === プロット表示 (前回同様) ===
figure('Name', 'FRC vs Spheromak (Using get_axis_x_multi)', 'Color', 'w', 'Position', [100, 100, 1100, 500]);
colors = lines(n_data);
subplot(1, 2, 1); hold on; box on; grid on;
fill([t_start t_end t_end t_start], [0 0 threshold_ratio threshold_ratio], [0.8 1 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
fill([t_start t_end t_end t_start], [threshold_ratio threshold_ratio 2.0 2.0], [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.3);
yline(threshold_ratio, '--k', sprintf('Limit (%.2f)', threshold_ratio), 'LineWidth', 1.5);
legend_str = {};
for i = 1:n_data
    valid_idx = ~isnan(results_ratio(i, :));
    if any(valid_idx)
        x_data = PCB.trange(valid_idx);
        y_data = results_ratio(i, valid_idx);
        plot(x_data, smoothdata(y_data, 'movmean', 3), 'Color', colors(i,:), 'LineWidth', 2);
        legend_str{end+1} = sprintf('Shot %d (%s)', IDXlist(i), summary_data(i).Classification);
    end
end
xlim([t_start, t_end]); ylim([0, 1.2]); xlabel('Time [\mu s]'); ylabel('|B_{t,axis}| / B_{p,max}');
title('Classification Ratio'); if ~isempty(legend_str), legend(legend_str); end

subplot(1, 2, 2); hold on; box on; grid on;
yyaxis left; ylabel('B_{t} at Axis [T]');
for i = 1:n_data
    v = ~isnan(results_Bt_opoint(i, :));
    if any(v), plot(PCB.trange(v), smoothdata(results_Bt_opoint(i, v), 'movmean', 3), '-', 'Color', colors(i,:)); end
end
yyaxis right; ylabel('Max B_{p} [T]');
for i = 1:n_data
    v = ~isnan(results_Bp_max(i, :));
    if any(v), plot(PCB.trange(v), smoothdata(results_Bp_max(i, v), 'movmean', 3), '--', 'Color', colors(i,:)); end
end
xlim([t_start, t_end]); title('Field Components');

% === Excel保存処理 (前回同様) ===
excel_filename = fullfile('/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/analysis/FRC_Classification_Summary.csv');
T_new = struct2table(summary_data);
T_new.Classification = string(T_new.Classification);

if exist(excel_filename, 'file')
    try
        T_existing = readtable(excel_filename);
        if iscell(T_existing.Classification), T_existing.Classification = string(T_existing.Classification); end
        for i = 1:height(T_new)
            idx_match = find(T_existing.Date == T_new.Date(i) & T_existing.Shot == T_new.Shot(i));
            if ~isempty(idx_match), T_existing(idx_match(1), :) = T_new(i, :);
            else, T_existing = [T_existing; T_new(i, :)]; end
        end
        writetable(T_existing, excel_filename);
        fprintf('Updated Excel: %s\n', excel_filename);
    catch, writetable(T_new, excel_filename); end
else
    writetable(T_new, excel_filename);
    fprintf('Created Excel: %s\n', excel_filename);
end

% --- 提示された関数 (末尾に配置) ---
function [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D,PCB)
    if PCB.tfshot(1) == 0, spheromak = 1; else, spheromak = 0; end
    trange = data2D.trange;
    psi = data2D.psi;
    if spheromak == 1, Bt = data2D.Bt; else, Bt = data2D.Bt_th; end
    rq = grid2D.rq; zq = grid2D.zq;
    rqList = repmat(rq,1,1,numel(trange));
    zqList = repmat(zq,1,1,numel(trange));

    [psiRidge,psiRidgeIdx] = max(psi,[],1,'linear');
    axisCandidate = islocalmax(psiRidge,'MaxNumExtrema',2);

    magAxisList.r = NaN(2,numel(trange));
    magAxisList.z = NaN(2,numel(trange));
    magAxisList.psi = NaN(2,numel(trange));
    xPointList.r = NaN(1,numel(trange));
    xPointList.z = NaN(1,numel(trange));
    xPointList.psi = NaN(1,numel(trange));
    xPointList.Bt = NaN(1,numel(trange));

    rLim = [min(rq,[],'all'),max(rq,[],"all")];

    for i=1:numel(trange)
        psiRidge_t = psiRidge(:,:,i);
        psiRidgeIdx_t = psiRidgeIdx(:,:,i);
        axisCandidate_t = axisCandidate(:,:,i);
        if ~isempty(psiRidgeIdx_t(axisCandidate_t))
            magAxisList.r(:,i) = rqList(psiRidgeIdx_t(axisCandidate_t));
            magAxisList.z(:,i) = zqList(psiRidgeIdx_t(axisCandidate_t));
            magAxisList.psi(:,i) = psi(psiRidgeIdx_t(axisCandidate_t));
        end

        axisIdx = find(axisCandidate_t);
        searchPsiRidge = psiRidge_t;
        if numel(axisIdx) == 2
            z_idx_1 = min(axisIdx); z_idx_2 = max(axisIdx);
            searchPsiRidge(1:z_idx_1) = Inf; searchPsiRidge(z_idx_2:end) = Inf;
        end

        xpointIdx = islocalmin(smooth(searchPsiRidge),'MaxNumExtrema', 1);

        if ~isempty(find(xpointIdx, 1))
            xPointList.r(i) = rqList(psiRidgeIdx_t(xpointIdx));
            xPointList.z(i) = zqList(psiRidgeIdx_t(xpointIdx));
            xPointList.psi(i) = psi(psiRidgeIdx_t(xpointIdx));
            xPointList.Bt(i) = Bt(psiRidgeIdx_t(xpointIdx));
        end
        if any(ismember(magAxisList.r(:,i),rLim))
            magAxisList.r(:,i) = NaN; magAxisList.z(:,i) = NaN; magAxisList.psi(:,i) = NaN;
        end
        if any(ismember(xPointList.r(i),rLim))
            xPointList.r(i) = NaN; xPointList.z(i) = NaN; xPointList.psi(i) = NaN; xPointList.Bt(i) = NaN;
        end
        if all(~isnan([magAxisList.r(:,i);xPointList.r(i)]))&&sum(magAxisList.z(:,i)>xPointList.z(i))~=1
            [~,smallAxis] = min(magAxisList.psi(i));
            maxAxis = 3-smallAxis;
            magAxisList.r(smallAxis,i) = magAxisList.r(maxAxis,i);
            magAxisList.z(smallAxis,i) = magAxisList.z(maxAxis,i);
            magAxisList.psi(smallAxis,i) = magAxisList.psi(maxAxis,i);
        end
    end
end