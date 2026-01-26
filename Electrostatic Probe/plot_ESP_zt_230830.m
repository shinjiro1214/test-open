%% 1. 設定と準備
clear; clc;

% --- ショットリストの定義 (Shot 24のみ) ---
groups = struct();
groups(1).name = 'Shot 24';
groups(1).shots = [24];

% --- ファイル設定 ---
baseName = 'ES_230830'; % 日付変更
dirPath = '/Volumes/experiment/results/ElectroStaticProbe/230830'; % パス変更

% --- 空間軸の定義 ---
num_ch_total = 21;
z_vec_full = linspace(-0.15, 0.15, num_ch_total);

% 17ch以上は無視するので、1〜16chまでのZ座標とインデックスを使用
target_chs = 1:16; 
z_vec_target = z_vec_full(target_chs); % 補間後のZ座標 (16点)

% --- 有効なチャンネルの選定 ---
% ターゲット(1-16)のうち、以下のチャンネルを除外
% 既存の除外: 10, 11, 12, 14
% 新規の除外: 4, 6, 16
bad_chs = [4, 6, 10, 11, 12, 14, 16]; 

% setdiffで有効なチャンネルを抽出 (1〜16の中からbad_chsを除いたもの)
valid_chs = setdiff(target_chs, bad_chs);

% 有効なチャンネルに対応するZ座標 (補間の基準点X)
z_vec_valid = z_vec_full(valid_chs);

fprintf('有効チャンネル数: %d\n', length(valid_chs));
disp(['使用するチャンネル: ', num2str(valid_chs)]);

%% 2. データ処理とプロット
figure('Name', 'Z-T Distribution', 'Color', 'w', 'Position', [100, 100, 600, 400]);
tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact'); % 1つだけなので1x1

% 共通のカラー軸範囲を決めるための変数
global_min = inf;
global_max = -inf;
processed_data = cell(1, length(groups));
time_axis = [];

for g = 1:length(groups)
    currentShots = groups(g).shots;
    fprintf('Processing %s (%d shots)...\n', groups(g).name, length(currentShots));
    
    % --- 平均データの計算 ---
    stack_data = [];
    valid_shot_count = 0;
    
    for i = 1:length(currentShots)
        shotNo = currentShots(i);
        fileName = fullfile(dirPath, sprintf('%s%03d.csv', baseName, shotNo));
        
        if exist(fileName, 'file')
            raw = readmatrix(fileName, 'NumHeaderLines', 1);
            
            % データ長チェック (念のため)
            if size(raw, 1) > 10000
                raw = raw(1:10001,:);
            end
            
            if isempty(stack_data)
                Nt = size(raw, 1);
                time_axis = raw(:, 1);
                stack_data = nan(Nt, num_ch_total, length(currentShots));
            end
            
            if size(raw, 1) == size(stack_data, 1)
                valid_shot_count = valid_shot_count + 1;
                stack_data(:, valid_chs, valid_shot_count) = raw(:, valid_chs + 1);
            end
        else
            fprintf('  File not found: %s\n', fileName);
        end
    end
    
    if valid_shot_count > 0
        % 平均をとる (Time x 21)
        mean_ZT = mean(stack_data(:, :, 1:valid_shot_count), 3, 'omitnan');
        
        % === 補間処理 ===
        % values_valid: (ValidChs x Time)
        values_valid = mean_ZT(:, valid_chs).'; 
        
        % 補間実行 (linear, pchip, makima 等)
        values_interp = interp1(z_vec_valid, values_valid, z_vec_target, 'linear');
        
        % 転置して (Time x 16) に戻して保存
        final_data = values_interp.';
        processed_data{g} = final_data;
        
        % カラー軸更新
        if any(~isnan(final_data(:)))
            global_min = min(global_min, min(final_data(:)));
            global_max = max(global_max, max(final_data(:)));
        end

        % --- B. ショットごとの振幅差（Max-Min）の計算 ---
        
        Nt = size(stack_data, 1);
        amp_diff_shots = nan(Nt, valid_shot_count);
        
        for k = 1:valid_shot_count
            % 1ショット分のデータ抽出
            shot_data_valid = stack_data(:, valid_chs, k); 
            
            % 時間方向の欠損チェック
            valid_t_mask = sum(~isnan(shot_data_valid), 2) >= 2; 
            
            interp_shot = nan(Nt, length(z_vec_target));
            
            if any(valid_t_mask)
                v_in = shot_data_valid(valid_t_mask, :).';
                v_out = interp1(z_vec_valid, v_in, z_vec_target, 'pchip');
                interp_shot(valid_t_mask, :) = v_out.';
            end
            
            % Max - Min の計算
            row_max = max(interp_shot, [], 2);
            row_min = min(interp_shot, [], 2);
            amp_diff_shots(:, k) = row_max - row_min;
        end
        
        % --- 統計量の計算 ---
        % 平均 (Mean)
        amp_mean = mean(amp_diff_shots, 2, 'omitnan');
        
        % 標準偏差 (Std)
        % ショット数が1の場合、stdはNaNになるため0にする
        if valid_shot_count > 1
            amp_std = std(amp_diff_shots, 0, 2, 'omitnan');
        else
            amp_std = zeros(size(amp_mean));
        end
        
        % 結果を構造体に保存
        groups(g).amp_time = time_axis;
        groups(g).amp_mean = amp_mean;
        groups(g).amp_std  = amp_std;
    else
        warning('Group %d (%s) に有効なデータがありません。', g, groups(g).name);
        processed_data{g} = [];
        groups(g).amp_mean = [];
    end
end 

%% 3. Z-Tプロット描画
if isinf(global_min), global_min = 0; end
if isinf(global_max), global_max = 1; end
clim_val = [global_min, global_max]; 
z_plot = z_vec_target; 

for g = 1:length(groups)
    nexttile;
    data_to_plot = processed_data{g};
    
    if ~isempty(data_to_plot)
        imagesc(time_axis, z_plot, data_to_plot.');
        
        set(gca, 'YDir', 'normal');
        colormap('jet');
        caxis(clim_val); 
        
        title(groups(g).name, 'FontSize', 12);
        xlabel('Time [\mus]', 'FontSize', 11);
        ylabel('Z position [m]', 'FontSize', 11);
        xlim([450 480]);
        grid on;
    end
end

cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'Signal Intensity (Avg)';

%% 4. 振幅（最大値 - 最小値）の時間発展プロット
t_start = 450;
t_end   = 480;

figure('Name', 'Amplitude Difference', 'Color', 'w', 'Position', [150, 150, 700, 500]);
hold on;

colors = lines(max(length(groups), 2)); % 色配列確保

for g = 1:length(groups)
    if ~isempty(groups(g).amp_mean)
        t_vec = groups(g).amp_time;
        y_mean = groups(g).amp_mean;
        y_std  = groups(g).amp_std;
        
        idx = find(t_vec >= t_start & t_vec <= t_end);
        
        if ~isempty(idx)
            t_plot = t_vec(idx);
            y_plot = y_mean(idx);
            err    = y_std(idx);
            
            % エラーバー（帯）の描画（stdが0なら線と重なるだけ）
            upper_curve = y_plot + err;
            lower_curve = y_plot - err;
            
            x_poly = [t_plot; flipud(t_plot)];
            y_poly = [upper_curve; flipud(lower_curve)];
            
            fill(x_poly, y_poly, colors(g,:), ...
                'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
                'HandleVisibility', 'off');
            
            plot(t_plot, y_plot, 'LineWidth', 2, ...
                 'Color', colors(g,:), ...
                 'DisplayName', groups(g).name);
        end
    end
end

hold off;
grid on;
legend('Location', 'best', 'FontSize', 12);
xlabel('Time [\mus]', 'FontSize', 14);
ylabel('Amplitude Difference (Max - Min)', 'FontSize', 14);
title(['Signal Amplitude Evolution (', num2str(t_start), '-', num2str(t_end), ' \mus)'], 'FontSize', 14);
xlim([t_start, t_end]);
set(gca, 'FontSize', 12);

%% 5. 特定時刻 (t=468) における値の表示
% ショット24だけなので「比較」ではなく「値の確認」になります

target_time = 468;
x_vals = [];
y_vals = [];
y_errs = [];

fprintf('--- t = %.1f us におけるデータ抽出 ---\n', target_time);

for g = 1:length(groups)
    if ~isempty(groups(g).amp_mean)
        [~, t_idx] = min(abs(groups(g).amp_time - target_time));
        val_mean = groups(g).amp_mean(t_idx);
        val_std  = groups(g).amp_std(t_idx);
        
        x_vals(end+1) = g; % グループ番号の代わりにインデックス1を使用
        y_vals(end+1) = val_mean;
        y_errs(end+1) = val_std;
        
        fprintf('%s: Mean = %.4f, Std = %.4f\n', groups(g).name, val_mean, val_std);
    end
end

% プロット
figure('Name', 'Value at t=468', 'Color', 'w', 'Position', [150, 150, 300, 400]);
errorbar(x_vals, y_vals, y_errs, 'o', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'b', 'LineWidth', 1.5, 'CapSize', 10);

grid on;
xlabel('Index', 'FontSize', 12);
ylabel('Amplitude Difference', 'FontSize', 12);
title(sprintf('Value at t = %.1f \\mus', target_time), 'FontSize', 14);
xticks(x_vals);
xticklabels({groups.name});
xlim([0.5, 1.5]); % 1点だけなので範囲を狭く
text(x_vals, y_vals, string(round(y_vals, 3)), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', ...
    'FontSize', 10, 'Color', 'k', 'Position', [x_vals, y_vals+0.005, 0]);