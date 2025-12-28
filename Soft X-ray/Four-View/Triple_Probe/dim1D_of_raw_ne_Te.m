%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1次元のプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% データの読み込み
date = 251220;
prompt = 'Enter the shot number: ';
dlgtitle = 'Shot Number';
dims = [1 30];
definput = {''};
shotnum = inputdlg(prompt, dlgtitle, dims, definput);
shotnum = str2double(shotnum{1});

if shotnum < 10
    shotnum = ['00', num2str(shotnum)];
else 
    shotnum = ['0', num2str(shotnum)];
end

save_filepath = "/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/triple_probe";

% 研究室内にいる場合のファイルパス
% filepath = "//NIFS/experiment/results/MachProbe/";
% 研究室外のファイルパス
filepath = "/Users/shohgookazaki/Documents/UTokyo/OnoTanabeLab/koala/home/pub/mnt/data/TripleProbe";

filename = strcat(filepath, '/', num2str(date), '/ES_', num2str(date), shotnum, '.csv');

% ファイルの読み込み
test = readmatrix(filename);
index_start = 4500;
index_end = 7500;
V2 = 30; % 奇数のやつを入れる
V3 = 15; % 偶数のやつを入れる

% if you use H gas. The A is 1.00.
% A = 1.00; % atomic weight
% if you use Ar gas. The A is 39.95.
A = 39.95;
% S_probe = 2.89*10^-5; % probe surface area [m2] Φ0.45mm electrode
S_probe = 1.4e-5;
I2_values = test(index_start:index_end, 36);
I3_values = test(index_start:index_end, 37);

time = test(index_start:index_end, 1);

q = 1.60217663 * 10^(-19); % electron charge
kb = 1.380649 * 10^(-23); % boltzmann const
K2ev = 11604.5250061657; % kelvin to eV
mi = A * 1.66054 * 10^(-27); % ion mass

% =========================================================
%  高速・安定化のための Look-up Table (LUT) 法への変更
% =========================================================
% 1. スムージングとI1定義
window_size = 50; 
I2_values = smoothdata(I2_values, 'movmean', window_size);
I3_values = smoothdata(I3_values, 'movmean', window_size);
I1_values = I2_values + I3_values;

% 2. 閾値設定（信号がない部分は計算しない）
current_threshold = 0.05; 
valid_indices = (I2_values > current_threshold) & (I3_values > current_threshold);

% 3. 理論テーブル作成 (Te: 0.1eV ~ 150eV)
Te_range = 0.1:0.05:150; 
% RHS = (1 - exp(-V2/Te)) / (1 - exp(-V3/Te))
RHS_table = (1 - exp(-q*V2./(kb*Te_range*K2ev)))./(1 - exp(-q*V3./(kb*Te_range*K2ev)));

% 数値計算用にユニーク化
[RHS_table, unique_idx] = unique(RHS_table);
Te_lookup = Te_range(unique_idx) * K2ev; 

% 4. 実験データの比率計算
LHS_data = (I1_values + I2_values) ./ (I1_values + I3_values);

% 5. 【重要】データの強制補正 (0.9818 -> 1.0001 に対処)
min_RHS = min(RHS_table) + 0.0001;
max_RHS = max(RHS_table) - 0.0001;

% 範囲外の値をクリップする
LHS_data_clamped = LHS_data;
LHS_data_clamped(LHS_data < min_RHS) = min_RHS; 
LHS_data_clamped(LHS_data > max_RHS) = max_RHS;

% 6. Teの計算 (高速ルックアップ)
Te_values = nan(size(I1_values));
try
    Te_values(valid_indices) = interp1(RHS_table, Te_lookup, LHS_data_clamped(valid_indices), 'linear', 'extrap');
catch ME
    warning('Interpolation error: %s', ME.message);
end

% 7. neの計算
ne_values = nan(size(I2_values));
valid_Te = ~isnan(Te_values);

if any(valid_Te)
    const_ne = exp(-0.5) * S_probe * q * sqrt(kb / mi);
    
    Te_valid = Te_values(valid_Te);
    I2_valid = I2_values(valid_Te);
    I3_valid = I3_values(valid_Te);
    
    exp_factor = exp(-q * (V3 - V2) ./ (kb * Te_valid));
    numerator_ne = (I3_valid - I2_valid .* exp_factor);
    denominator_ne = (1 - exp_factor);
    
    % ne計算実行
    ne_temp = (numerator_ne ./ denominator_ne) ./ (const_ne * sqrt(Te_valid));
    ne_values(valid_Te) = ne_temp;
end

% 負の値など異常値を除去
Te_values(Te_values < 0) = NaN;
ne_values(ne_values < 0) = NaN;

% % solve for Te
% syms I1 I2 I3 Te
% eqn = (I1+I2)/(I1+I3) == (1 - exp(-q*V2/(kb*Te)))/(1 - exp(-q*V3/(kb*Te)));
% Te_symbolic = solve(eqn,Te);
% % Calculate Te_values and check for division by zero
% try
%     Te_values = real(double(subs(Te_symbolic, {I1 I2 I3}, {I1_values I2_values I3_values})));
% catch
%     % Handle division by zero error
%     warning('Division by zero occurred while solving for Te. Applying previous valid value as fallback.');
%     Te_values = zeros(size(I1_values));
%     for i = 2:length(I1_values)
%         try
%             Te_values(i) = real(double(subs(Te_symbolic, {I1 I2 I3}, {I1_values(i) I2_values(i) I3_values(i)})));
%         catch
%             if i > 1
%                 Te_values(i) = Te_values(i - 1);
%             end
%         end
%     end
% end




% % solve for ne
% syms ne Te I2 I3
% eqn = exp(-0.5) * S_probe * ne * q * (kb * Te / mi)^0.5 == (I3 - I2*exp(-q*(V3-V2)/(kb*Te)))/(1-exp(-q*(V3-V2)/(kb*Te)));
% ne_symbolic = solve(eqn,ne);
% % Calculate ne_values and check for division by zero
% try
%     ne_values = real(double(subs(ne_symbolic, {Te I2 I3}, {Te_values I2_values I3_values})));
% catch
%     % Handle division by zero error
%     warning('Division by zero occurred while solving for ne. Applying previous valid value as fallback.');
%     ne_values = zeros(size(I2_values));
%     for i = 2:length(I2_values)
%         try
%             ne_values(i) = real(double(subs(ne_symbolic, {Te I2 I3}, {Te_values(i) I2_values(i) I3_values(i)})));
%         catch
%             if i > 1
%                 ne_values(i) = ne_values(i - 1);
%             end
%         end
%     end
% end

% === 診断用コード ===

% 1. 左辺（実験データからの計算値）を確認
LHS_data = (I1_values + I2_values) ./ (I1_values + I3_values);

% 2. 右辺（理論値テーブル）の範囲を確認
% Te = 0.1 ~ 100 eV の範囲で作成
Te_range = 0.1:0.1:100;
RHS_table = (1 - exp(-q*V2./(kb*Te_range*K2ev)))./(1 - exp(-q*V3./(kb*Te_range*K2ev)));

% 表示
fprintf('--- 診断レポート ---\n');
fprintf('理論値(RHS)の最小値: %.4f\n', min(RHS_table));
fprintf('理論値(RHS)の最大値: %.4f\n', max(RHS_table));
fprintf('実験値(LHS)の平均値(有効部分): %.4f\n', mean(LHS_data(valid_indices)));
fprintf('実験値(LHS)の範囲: %.4f ～ %.4f\n', min(LHS_data(valid_indices)), max(LHS_data(valid_indices)));
fprintf('----------------------\n');

% もし LHS が RHS の範囲外にあると、interp1 は NaN を返します。

% plot
figure;
sgtitle('Triple probe data of Ar ST')

subplot(3,1,1)
hold on;
plot(time, I2_values);
plot(time, I3_values);
legend({['I2 (V_p=', num2str(V2), 'V)'], ['I3 (V_p=', num2str(V3), 'V)']})
ylabel('Probe current [A]')
xlim([450, 500])
ylim([-1 5]);
hold off
grid on

subplot(3,1,2)
scatter(time, Te_values / K2ev, 5, "black");
% plot(time, Te_values/K2ev)
xlim([450, 500]);
ylim([0 40]);
ylabel('Te [eV]')
grid on

subplot(3,1,3)
scatter(time, ne_values, 3, "black");
xlim([450, 500]);
ylim([0 4e20]);
xlabel('time [us]')
ylabel('ne [m^{-3}]')
grid on

mkdir(strcat(save_filepath, '/', num2str(date), '/figure/triple_probe'));
saveas(gcf, strcat(save_filepath, '/', num2str(date), '/figure/triple_probe/', shotnum, '_', num2str(index_start), '-', num2str(index_end), 'us'), 'png');
fprintf("saved your file %s", shotnum)



% %%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 2次元プロット
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % ファイルのパス設定
% % date = 240610; % case-I
% date = 240611; % case-O
% filepath = "G:/My Drive/lab/lab_data/mach_probe_rawdata/"; % ファイルパス
% % shotlist = [18, 21, 24, 27, 33, 35, 38, 41, 47]; % case-I
% shotlist = [46, 49, 52, 55, 58, 61, 66, 69, 72]; % case-O

% % スプレッドシートからR方向データを取得
% DOCID = '1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw'; % スプレッドシートのID
% T = getTS6log(DOCID);
% node = 'date';
% T = searchlog(T, node, date);

% % ショット番号に対応するインデックスを取得
% shot_indices = arrayfun(@(x) find(T.shot == x, 1), shotlist);

% % r_list を取得し、サイズを shotlist と一致させる
% r_list = T.tripleProbeRPosition_cm_(shot_indices) * 1e-1; % R座標[m]

% % パラメータ設定
% V2 = 20;
% V3 = 10; % 電位設定
% % A = 39.95; % Arガスの原子量
% A = 1.0;
% % S_probe = 2.89e-5; % 電極表面積 [m^2]
% S_probe = 1.4e-5;
% q = 1.60217663e-19; % 電子電荷
% kb = 1.380649e-23; % ボルツマン定数
% K2ev = 11604.5250061657; % kelvin to eV
% mi = A * 1.66054e-27; % イオン質量


% % 時間データの統一と行列初期化
% num_shots = length(shotlist);
% time_us = linspace(450, 600, 300); % 統一された時間軸 (450-600 μs, 300点)
% Te_matrix = zeros(num_shots, length(time_us)); % Teデータ格納
% ne_matrix = zeros(num_shots, length(time_us)); % neデータ格納

% % シンボリック変数宣言
% syms I1 I2 I3 Te ne

% % Te解法
% eqn_Te = (I1 + I2) / (I1 + I3) == (1 - exp(-q * V2 / (kb * Te))) / (1 - exp(-q * V3 / (kb * Te)));
% Te_symbolic = solve(eqn_Te, Te);

% % ne解法
% eqn_ne = exp(-0.5) * S_probe * ne * q * sqrt(kb * Te / mi) == ...
%     (I3 - I2 * exp(-q * (V3 - V2) / (kb * Te))) / (1 - exp(-q * (V3 - V2) / (kb * Te)));
% ne_symbolic = solve(eqn_ne, ne);

% % ショットごとのデータ読み込みと計算
% valid_idx = 0; % 有効なショット数カウンタ
% for idx = 1:num_shots
%     shot = shotlist(idx);
%     filename = strcat(filepath, num2str(date), '/ES_', num2str(date), sprintf('%03d', shot), '.csv');
    
%     if exist(filename, 'file')
%         valid_idx = valid_idx + 1; % 有効なデータのカウンタを増やす
%         % データ読み込み
%         data = readmatrix(filename);
%         time = data(4500:7500, 1); % 時間データ
%         I2_values = data(4500:7500, 36); % 列36のデータ
%         I3_values = data(4500:7500, 37); % 列37のデータ
        
%         % 欠損データの補完とスムージング
%         I2_values = fillmissing(I2_values, 'linear');
%         I3_values = fillmissing(I3_values, 'linear');
%         I2_values = smoothdata(I2_values, 'movmean', 10);
%         I3_values = smoothdata(I3_values, 'movmean', 10);
%         I1_values = I2_values + I3_values;

%         % Te 計算
%         try
%             Te_values = real(double(subs(Te_symbolic, {I1, I2, I3}, {I1_values, I2_values, I3_values})));
%         catch
%             Te_values = zeros(size(I1_values));
%         end

%         % ne 計算
%         try
%             ne_values = real(double(subs(ne_symbolic, {Te, I2, I3}, {Te_values, I2_values, I3_values})));
%         catch
%             ne_values = zeros(size(I2_values));
%         end

%         % 補間して時間軸を統一
%         Te_matrix(valid_idx, :) = interp1(time, Te_values, time_us, 'linear', 0);
%         ne_matrix(valid_idx, :) = interp1(time, ne_values, time_us, 'linear', 0);
%     else
%         warning('File %s not found. Skipping this shot.', filename);
%     end
% end
% %%

% % 有効データのみを使用
% Te_matrix = Te_matrix(1:valid_idx, :);
% ne_matrix = ne_matrix(1:valid_idx, :);
% r_list = r_list(1:valid_idx);

% % 0をNaNに置き換え
% Te_matrix(Te_matrix == 0) = NaN;
% ne_matrix(ne_matrix == 0) = NaN;

% % NaN値を補完 (線形補完)
% Te_matrix = fillmissing(Te_matrix, 'linear', 1); % 時間方向で補完
% ne_matrix = fillmissing(ne_matrix, 'linear', 1); % 時間方向で補完


% % ----------------------------
% % 同じr_listの値でTeとneの平均値を計算
% % ----------------------------
% unique_r = unique(r_list); % 一意なR値
% Te_avg_matrix = zeros(length(unique_r), length(time_us));
% ne_avg_matrix = zeros(length(unique_r), length(time_us));

% for i = 1:length(unique_r)
%     idx_r = (r_list == unique_r(i)); % 現在のR値に対応するインデックス
%     Te_avg_matrix(i, :) = mean(Te_matrix(idx_r, :), 1, 'omitnan'); % 平均
%     ne_avg_matrix(i, :) = mean(ne_matrix(idx_r, :), 1, 'omitnan'); % 平均
% end



% %%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % matファイルの作製
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % 必要なデータを準備
% R_values = unique_r;             % R方向の値 (10個)
% time_values = time_us;           % 時間軸 (300点)
% Te_data_2D = Te_avg_matrix ./ K2ev; % Teデータを[eV]に変換した2次元データ (10×300)
% ne_data_2D = ne_avg_matrix;       % neデータ (10×300)

% % 3次元データ構造を作成
% triple_data2D = struct(); % 空のストラクトを作成

% % Teデータを格納 (サイズ: 10×1×300)
% triple_data2D.Te = zeros(length(R_values), 1, length(time_values));
% triple_data2D.Te(:, 1, :) = reshape(Te_data_2D, [length(R_values), 1, length(time_values)]);

% % neデータを格納 (サイズ: 10×2×300)
% triple_data2D.ne = zeros(length(R_values), 1, length(time_values));
% triple_data2D.ne(:, 1, :) = reshape(ne_data_2D, [length(R_values), 1, length(time_values)]);


% % MATファイルとして保存
% save('triple_data2D_case-O.mat', 'triple_data2D', 'R_values', 'time_values');
% disp('MATファイル triple_data2D.mat を保存しました');

% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % conturfのプロット
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % MATファイルを読み込む
% load('triple_data2D_case-O.mat'); % triple_data2D, R_values, time_values を読み込む

% % 必要なデータを取り出す
% Te_data_2D = squeeze(triple_data2D.Te(:, 1, :)); % 3次元データから2次元データに変換 (10×300)
% ne_data_2D = squeeze(triple_data2D.ne(:, 1, :)); % 3次元データから2次元データに変換 (10×300)


% % グリッドデータを作成
% [R_grid, T_grid] = meshgrid(time_values, R_values); % 時間 (X軸) と R方向 (Y軸) のグリッド

% % contourf を使ってプロット
% % figure;
% % contourf(R_grid, T_grid, Te_data_2D, 10000, 'LineColor', 'none');
% % clim([0, 10])
% % colorbar; % カラーバーを表示
% % xlabel('Time [/mus]'); % X軸ラベル
% % xlim([475, 520])
% % ylabel('R position [m]'); % Y軸ラベル
% % title('Case - O plot of Te [eV]'); % グラフタイトル
% % colormap('jet'); % カラーマップをjetに設定

% figure;
% contourf(R_grid, T_grid, ne_data_2D, 10000, 'LineColor', 'none');
% colorbar; % カラーバーを表示
% xlabel('Time [/mus]'); % X軸ラベル
% xlim([475, 520])
% ylabel('R position [m]'); % Y軸ラベル
% title('Case - O plot of ne [m^{-3}]'); % グラフタイトル
% clim([0, 2e+20])
% colormap('jet'); % カラーマップをjetに設定

% %%
% % 結果の保存
% saveDir = "G:/My Drive/lab/lab_data/triple_probe/figure";

% % フォルダが存在するかを確認し、存在しない場合にのみ作成
% if ~exist(saveDir, 'dir')
%     mkdir(saveDir);
% end

% saveas(gcf, strcat(saveDir, '/', num2str(date), '/case_O_Te'), 'png')

% fprintf("save your file %s", num2str(date))


% %%
% % ----------------------------
% % エラーバー付きプロット
% % ----------------------------
% selected_r = 2.5; % プロットしたいR値
% idx_selected = (r_list == selected_r);

% % 平均値と標準偏差を計算
% Te_mean = mean(Te_matrix(idx_selected, :), 1, 'omitnan');
% Te_std = std(Te_matrix(idx_selected, :), 0, 1, 'omitnan');
% ne_mean = mean(ne_matrix(idx_selected, :), 1, 'omitnan');
% ne_std = std(ne_matrix(idx_selected, :), 0, 1, 'omitnan');

% % Teのエラーバー付きプロット
% figure;
% errorbar(time_us, Te_mean ./ K2ev, Te_std./ K2ev);
% xlim([450, 500])
% xlabel('Time [/mus]');
% ylabel('Te [eV]');
% title(['Te vs Time at R = ', num2str(selected_r)]);
% grid on;

% % neのエラーバー付きプロット
% figure;
% errorbar(time_us, ne_mean, ne_std);
% xlabel('Time [/mus]');
% ylabel('ne [m^{-3}]');
% title(['ne vs Time at R = ', num2str(selected_r)]);
% grid on;



