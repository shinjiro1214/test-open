%% 1. 設定と準備
clear; clc;

% --- ショットリストの定義 ---
groups = struct();
% 定義順序に対応するTF電圧(グループ番号)を指定
% Group 1 (Shot 8-21) -> TF = 4
groups(1).name = 'Group 4';
groups(1).shots = [8,9,18:21];
groups(1).tf_val = 4; 

% Group 2 (Shot 23-46) -> TF = 3
groups(2).name = 'Group 3';
groups(2).shots = [23:32, 34:46];
groups(2).tf_val = 3;

% Group 3 (Shot 47-69) -> TF = 2
groups(3).name = 'Group 2';
groups(3).shots = [47, 49:51, 56, 58:65, 67:69];
groups(3).tf_val = 2;

% --- ファイル設定 ---
baseName = 'ES_250305';
dirPath = '/Volumes/experiment/results/ElectroStaticProbe/250305'; 

% --- 物理定数・パラメータ ---
V_factor = 50;  % 分圧比
dz_calc = 0.01; % 電場計算用の微小距離 (m) -> z=0を中心に ±1cm で計算

% --- 空間軸の定義 ---
num_ch_total = 21;
% 条件: Ch1 = 0.15m, Ch21 = -0.15m
z_vec_full = linspace(0.15, -0.15, num_ch_total);

% データが存在する有効なチャンネル (10-12, 14などを除外)
valid_chs = [1:9, 13, 15, 16]; 

% 有効なチャンネルに対応するZ座標
z_vec_valid = z_vec_full(valid_chs);

fprintf('有効チャンネル数: %d\n', length(valid_chs));

%% 2. データ処理 (Ezの計算)
% 各グループ、各ショットごとにEzを計算して平均化します

for g = 1:length(groups)
    currentShots = groups(g).shots;
    fprintf('Processing %s (TF=%d, %d shots)...\n', groups(g).name, groups(g).tf_val, length(currentShots));
    
    Ez_shots = [];
    time_axis = [];
    valid_shot_count = 0;
    
    for i = 1:length(currentShots)
        shotNo = currentShots(i);
        fileName = fullfile(dirPath, sprintf('%s%03d.csv', baseName, shotNo));
        
        if exist(fileName, 'file')
            raw = readmatrix(fileName, 'NumHeaderLines', 1);
            
            % データ長制限
            if size(raw, 1) > 10000
                raw = raw(1:10001,:);
            end
            
            if isempty(time_axis)
                time_axis = raw(:, 1);
            end
            
            if size(raw, 1) == length(time_axis)
                valid_shot_count = valid_shot_count + 1;
                
                % --- A. 電圧への変換 ---
                % raw(:, 2:end) がデータ部分。x50倍する。
                V_all = raw(:, 2:end) * V_factor;
                V_valid = V_all(:, valid_chs); % [Time x ValidChs]
                
                % --- B. z=0付近の電場計算 ---
                % 転置して (Space x Time) にする
                V_in = V_valid.';
                
                % 補間したいZ座標: 0 + dz と 0 - dz
                z_query = [dz_calc, -dz_calc];
                
                % 空間補間 (pchip: 滑らか)
                V_interp = interp1(z_vec_valid, V_in, z_query, 'pchip');
                
                % V_interp は [2 x Time]
                V_plus  = V_interp(1, :).'; % z = +1cm
                V_minus = V_interp(2, :).'; % z = -1cm
                
                % 電場 Ez = - dV/dz
                % dV = V_plus - V_minus
                % dist = 2 * dz
                Ez_inst = - (V_plus - V_minus) / (2 * dz_calc);
                
                % 結果を蓄積 [Time x Shot]
                if isempty(Ez_shots)
                    Ez_shots = Ez_inst;
                else
                    Ez_shots(:, valid_shot_count) = Ez_inst;
                end
            end
        end
    end
    
    % --- 統計処理 ---
    if valid_shot_count > 0
        % 平均と標準偏差
        groups(g).time = time_axis;
        groups(g).Ez_mean = mean(Ez_shots, 2, 'omitnan');
        groups(g).Ez_std  = std(Ez_shots, 0, 2, 'omitnan');
    else
        groups(g).time = [];
        groups(g).Ez_mean = [];
        groups(g).Ez_std  = [];
    end
end

%% 3. Ezの時間発展プロット (確認用)
t_start = 450;
t_end   = 480;

figure('Name', 'Ez Evolution by TF Group', 'Color', 'w', 'Position', [100, 100, 600, 400]);
hold on;
colors = lines(length(groups));

for g = 1:length(groups)
    if ~isempty(groups(g).Ez_mean)
        t_vec = groups(g).time;
        y_mean = groups(g).Ez_mean;
        idx = t_vec >= t_start & t_vec <= t_end;
        
        plot(t_vec(idx), y_mean(idx), 'LineWidth', 2, ...
            'Color', colors(g,:), ...
            'DisplayName', sprintf('TF=%d (%s)', groups(g).tf_val, groups(g).name));
    end
end
hold off; grid on;
legend('Location', 'best');
xlabel('Time [\mus]'); ylabel('E_z [V/m]');
title('Ez Time Evolution');
xlim([t_start, t_end]);


%% 4. 特定時刻 (t=468) における TF電圧 vs Ez 比較

% --- 設定 ---
target_time = 468;

% プロット用データの準備
tf_vals = [];
ez_vals = [];
ez_errs = [];

fprintf('\n--- t = %.1f us における Ez 比較 ---\n', target_time);

for g = 1:length(groups)
    if ~isempty(groups(g).Ez_mean)
        % 指定時刻に最も近いインデックスを取得
        [~, t_idx] = min(abs(groups(g).time - target_time));
        
        val_mean = groups(g).Ez_mean(t_idx);
        val_std  = groups(g).Ez_std(t_idx);
        
        % 配列に追加
        tf_vals(end+1) = groups(g).tf_val;
        ez_vals(end+1) = val_mean;
        ez_errs(end+1) = val_std;
        
        fprintf('TF=%d: Ez = %.2f +/- %.2f [V/m]\n', groups(g).tf_val, val_mean, val_std);
    end
end

% --- プロット ---
figure('Name', 'Ez vs TF Voltage', 'Color', 'w', 'Position', [150, 150, 500, 400]);

% エラーバー付きプロット
errorbar(tf_vals, ez_vals, ez_errs, '-o', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'b', ...
    'LineWidth', 1.5, 'CapSize', 10, 'Color', 'k', 'MarkerEdgeColor', 'k');

% 見た目の調整
grid on;
xlabel('TF Voltage (Group Number)', 'FontSize', 12);
ylabel('E_z [V/m] (at z \approx 0)', 'FontSize', 12);
title(sprintf('Electric Field E_z vs TF Voltage (t = %.1f \\mus)', target_time), 'FontSize', 14);

% 軸設定
xticks([2 3 4]); % 整数値のみ表示
xlim([1.5 4.5]); % 左右に余白

% 値のラベル表示
text(tf_vals, ez_vals, string(round(ez_vals, 1)), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', ...
    'FontSize', 10, 'Color', 'b', 'Position', [0 10 0]); % 微調整用オフセット
    
% y=0ライン
yline(0, 'k--', 'HandleVisibility', 'off');