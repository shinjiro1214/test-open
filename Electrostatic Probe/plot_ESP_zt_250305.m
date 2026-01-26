%% 1. 設定と準備
clear; clc;

% --- ショットリストの定義 ---
groups = struct();
groups(1).name = 'Group 4 (Shot 8-21)';
groups(1).shots = [8,9,18:21];

groups(2).name = 'Group 3 (Shot 23-46)';
groups(2).shots = [23:32, 34:46];

groups(3).name = 'Group 2 (Shot 47-69)';
groups(3).shots = [47, 49:51, 56, 58:65, 67:69];

% --- ファイル設定 ---
baseName = 'ES_250305';
dirPath = '/Volumes/experiment/results/ElectroStaticProbe/250305'; % ファイルがあるパス

% --- 空間軸の定義 ---
num_ch_total = 21;
z_vec_full = linspace(-0.15, 0.15, num_ch_total);

% 17ch以上は無視するので、1〜16chまでのZ座標とインデックスを使用
target_chs = 1:16; 
z_vec_target = z_vec_full(target_chs); % 補間後のZ座標 (16点)

% データが存在するチャンネル (10-12, 14を除外)
valid_chs = [1:9, 13, 15, 16]; 

% 有効なチャンネルに対応するZ座標 (補間の基準点X)
z_vec_valid = z_vec_full(valid_chs);

fprintf('有効チャンネル数: %d\n', length(valid_chs));

%% 2. データ処理とプロット
figure('Name', 'Z-T Distribution Comparison', 'Color', 'w', 'Position', [100, 100, 1200, 400]);
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

% 共通のカラー軸範囲を決めるための変数
global_min = inf;
global_max = -inf;
processed_data = cell(1, 3);
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
            raw = raw(1:10001,:);
            
            if isempty(stack_data)
                Nt = size(raw, 1);
                time_axis = raw(:, 1);
                stack_data = nan(Nt, num_ch_total, length(currentShots));
            end
            
            if size(raw, 1) == size(stack_data, 1)
                valid_shot_count = valid_shot_count + 1;
                stack_data(:, valid_chs, valid_shot_count) = raw(:, valid_chs + 1);
            end
        end
    end
    
    if valid_shot_count > 0
        % 平均をとる (Time x 21)
        mean_ZT = mean(stack_data(:, :, 1:valid_shot_count), 3, 'omitnan');
        
        % === 補間処理 (ループ内に移動) ===
        % interp1(x, v, xq)
        % x:  z_vec_valid (1x12)
        % v:  mean_ZTのうち有効な列だけ抽出したもの (Time x 12) -> 転置して (12 x Time)
        % xq: z_vec_target (1x16)
        
        % 【修正箇所】ここで valid_chs の列だけを抜き出します
        values_valid = mean_ZT(:, valid_chs).'; 
        
        % 補間実行 (結果は 16 x Time)
        % values_interp = interp1(z_vec_valid, values_valid, z_vec_target, 'pchip');
        % values_interp = interp1(z_vec_valid, values_valid, z_vec_target, 'makima');
        values_interp = interp1(z_vec_valid, values_valid, z_vec_target, 'linear');
        
        % 転置して (Time x 16) に戻して保存
        final_data = values_interp.';
        processed_data{g} = final_data;
        
        % カラー軸更新
        global_min = min(global_min, min(final_data(:)));
        global_max = max(global_max, max(final_data(:)));

        % --- B. 【追加】ショットごとの振幅差（Max-Min）の計算 ---
        
        % 結果を保存する行列: [Time x valid_shot_count]
        % 時間軸の長さは raw データのサイズに依存
        Nt = size(stack_data, 1);
        amp_diff_shots = nan(Nt, valid_shot_count);
        
        for k = 1:valid_shot_count
            % 1ショット分のデータ抽出 (Time x ValidChs)
            % stack_data から必要なチャンネルだけ抜き出し
            shot_data_valid = stack_data(:, valid_chs, k); 
            
            % --- 補間処理 (ショット単位) ---
            % 時間方向の欠損チェック
            % (データがある時刻だけ補間する)
            valid_t_mask = sum(~isnan(shot_data_valid), 2) >= 2; 
            
            % 補間後のデータを格納する変数 (Time x TargetChs)
            interp_shot = nan(Nt, length(z_vec_target));
            
            if any(valid_t_mask)
                % 転置して (ValidChs x Time) にしてから interp1
                v_in = shot_data_valid(valid_t_mask, :).';
                
                % 補間実行
                v_out = interp1(z_vec_valid, v_in, z_vec_target, 'pchip');
                
                % 結果を戻す (Time x TargetChs)
                interp_shot(valid_t_mask, :) = v_out.';
            end
            
            % --- Max - Min の計算 ---
            % 行(Z)方向の最大・最小
            row_max = max(interp_shot, [], 2);
            row_min = min(interp_shot, [], 2);
            
            % 差分を保存
            amp_diff_shots(:, k) = row_max - row_min;
        end
        
        % --- 統計量の計算 ---
        % 平均 (Mean)
        amp_mean = mean(amp_diff_shots, 2, 'omitnan');
        % 標準偏差 (Standard Deviation) -> これがエラーバーの幅になります
        amp_std  = std(amp_diff_shots, 0, 2, 'omitnan');
        
        % 結果を構造体に保存
        groups(g).amp_time = time_axis;
        groups(g).amp_mean = amp_mean;
        groups(g).amp_std  = amp_std;
    else
        warning('Group %d に有効なデータがありません。', g);
        processed_data{g} = [];
    end
end % ループ終了

%% 3. 描画
clim_val = [global_min, global_max]; 
z_plot = z_vec_target; % 1～16chの座標

for g = 1:length(groups)
    nexttile;
    
    data_to_plot = processed_data{g};
    
    if ~isempty(data_to_plot)
        % imagesc (Time, Z, Data')
        imagesc(time_axis, z_plot, data_to_plot.');
        
        set(gca, 'YDir', 'normal');
        colormap('jet');
        caxis(clim_val); 
        
        title(groups(g).name, 'FontSize', 12);
        xlabel('Time [\mus]', 'FontSize', 11);
        if g == 1
            ylabel('Z position [m]', 'FontSize', 11);
        end
        xlim([450 480]);
        grid on;
    end
end

cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'Signal Intensity (Avg)';

%% 4. 振幅（最大値 - 最小値）の時間発展プロット (エラーバー付き)

% --- 設定 ---
t_start = 450;
t_end   = 480;

figure('Name', 'Amplitude Difference with Error', 'Color', 'w', 'Position', [150, 150, 700, 500]);
hold on;

% 色の定義
colors = lines(length(groups)); 

for g = 1:length(groups)
    if ~isempty(groups(g).amp_mean)
        
        t_vec = groups(g).amp_time;
        y_mean = groups(g).amp_mean;
        y_std  = groups(g).amp_std;
        
        % 指定時間範囲のインデックス
        idx = find(t_vec >= t_start & t_vec <= t_end);
        
        if ~isempty(idx)
            t_plot = t_vec(idx);
            y_plot = y_mean(idx);
            err    = y_std(idx);
            
            % --- シェーディング (帯) の描画 ---
            % 上限と下限の計算
            upper_curve = y_plot + err;
            lower_curve = y_plot - err;
            
            % ポリゴン（多角形）として塗りつぶすための座標作成
            % X: [時間(正順), 時間(逆順)]
            % Y: [上限(正順), 下限(逆順)]
            x_poly = [t_plot; flipud(t_plot)];
            y_poly = [upper_curve; flipud(lower_curve)];
            
            % fill(X, Y, Color)
            % 'FaceAlpha': 透明度 (0.2くらいが丁度いい)
            % 'EdgeColor': 'none' (枠線なし)
            fill(x_poly, y_poly, colors(g,:), ...
                'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
                'HandleVisibility', 'off'); % 凡例には帯を表示しない
            
            % --- 平均値の線の描画 ---
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
ylabel('Amplitude Difference (Mean \pm \sigma)', 'FontSize', 14);
title(['Signal Amplitude Evolution (', num2str(t_start), '-', num2str(t_end), ' \mus)'], 'FontSize', 14);
xlim([t_start, t_end]);
set(gca, 'FontSize', 12);

%% 5. 特定時刻 (t=468) におけるグループ間比較 (エラーバー付き)

% --- 設定 ---
target_time = 468;

% グループ番号とデータの対応付け用配列
% 今回の定義順: groups(1)=Grp4, groups(2)=Grp3, groups(3)=Grp2
% なので、対応するX座標(グループ番号)を定義します
group_nums = [4, 3, 2]; 

% プロット用データの格納変数
x_vals = [];
y_vals = [];
y_errs = [];

fprintf('--- t = %.1f us におけるデータ抽出 ---\n', target_time);

for g = 1:length(groups)
    if ~isempty(groups(g).amp_mean)
        % 時間軸から target_time に最も近いインデックスを探す
        [~, t_idx] = min(abs(groups(g).amp_time - target_time));
        
        % その時刻の平均値と標準偏差を取得
        val_mean = groups(g).amp_mean(t_idx);
        val_std  = groups(g).amp_std(t_idx);
        
        % 配列に追加
        x_vals(end+1) = group_nums(g);
        y_vals(end+1) = val_mean;
        y_errs(end+1) = val_std;
        
        fprintf('Group %d: Mean = %.4f, Std = %.4f\n', group_nums(g), val_mean, val_std);
    end
end

% --- プロット ---
figure('Name', 'Group Comparison at t=468', 'Color', 'w', 'Position', [150, 150, 500, 400]);

% エラーバー付きプロット
% errorbar(x, y, y_error, 'スタイル')
e = errorbar(x_vals, y_vals, y_errs, 'o', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'b', 'LineWidth', 1.5, 'CapSize', 10);

% 見た目の調整
grid on;
xlabel('TF', 'FontSize', 12);
ylabel('Amplitude Difference (Max - Min)', 'FontSize', 12);
title(sprintf('Signal Amplitude at t = %.1f \\mus', target_time), 'FontSize', 14);

% X軸の設定 (整数値のみ表示)
xticks([2 3 4]);
xlim([1.5 4.5]); % 余白を持たせる
% xlim([0 4.5]); % 余白を持たせる

% データ値のラベル表示 (オプション)
text(x_vals, y_vals, string(round(y_vals, 3)), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
    'FontSize', 10, 'Color', 'k', 'Position', [0 0.005 0]); % 位置微調整