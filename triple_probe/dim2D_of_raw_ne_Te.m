
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2次元プロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ファイルのパス設定
date = 251218; 

filepath_mat = fullfile(getenv('PROBE_DATA_DIR'),'tripleProbe',[num2str(date),'.mat']);
if exist(filepath_mat,"file")
    load(filepath_mat);
else
    disp('計算データがありません。計算を始めます。')
    filepath = getenv('NIFS_TRIPLE');
    shotlist = [2:13,16:18,21,22,43:56]; % Ar ST

    % スプレッドシートからR方向データを取得
    DOCID = '1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw'; % スプレッドシートのID
    T = getTS6log(DOCID);
    node = 'date';
    T = searchlog(T, node, date);

    % ショット番号に対応するインデックスを取得
    shot_indices = arrayfun(@(x) find(T.shot == x, 1), shotlist);

    % r_list を取得し、サイズを shotlist と一致させる
    r_list = T.tripleProbeRPosition_cm_(shot_indices) * 1e-3; % R座標[m]


    % パラメータ設定
    V2 = 20;
    V3 = 40; % 電位設定
    A = 39.95; % Arガスの原子量
    % A = 1.0;
    % S_probe = 2.89e-5; % 電極表面積 [m^2]
    S_probe = 1.4e-5;
    q = 1.60217663e-19; % 電子電荷
    kb = 1.380649e-23; % ボルツマン定数
    K2ev = 11604.5250061657; % kelvin to eV
    mi = A * 1.66054e-27; % イオン質量


    % 時間データの統一と行列初期化
    num_shots = length(shotlist);
    time_us = linspace(450, 600, 301); % 統一された時間軸 (450-600 μs, 301点)
    Te_matrix = zeros(num_shots, length(time_us)); % Teデータ格納
    ne_matrix = zeros(num_shots, length(time_us)); % neデータ格納

    % シンボリック変数宣言
    syms I1 I2 I3 Te ne

    % Te解法
    eqn_Te = (I1 + I2) / (I1 + I3) == (1 - exp(-q * V2 / (kb * Te))) / (1 - exp(-q * V3 / (kb * Te)));
    Te_symbolic = solve(eqn_Te, Te);

    % ne解法
    eqn_ne = exp(-0.5) * S_probe * ne * q * sqrt(kb * Te / mi) == ...
        (I3 - I2 * exp(-q * (V3 - V2) / (kb * Te))) / (1 - exp(-q * (V3 - V2) / (kb * Te)));
    ne_symbolic = solve(eqn_ne, ne);

    % ショットごとのデータ読み込みと計算
    valid_idx = 0; % 有効なショット数カウンタ
    for idx = 1:num_shots
        shot = shotlist(idx);
        if shot < 10
            shotnum = ['00', num2str(shot)];
        else 
            shotnum = ['0', num2str(shot)];
        end
        % filename = strcat(filepath, '\', num2str(date), '\ES_', num2str(date), shotnum, '.csv');
        filename = fullfile(filepath,num2str(date), ['ES_', num2str(date), shotnum, '.csv']);
        
        if exist(filename, 'file')
            valid_idx = valid_idx + 1; % 有効なデータのカウンタを増やす
            % データ読み込み
            data = readmatrix(filename);
            time = data(4500:7500, 1); % 時間データ
            I2_values = data(4500:7500, 36); % 列36のデータ
            I3_values = data(4500:7500, 37); % 列37のデータ
            
            % 欠損データの補完とスムージング
            I2_values = fillmissing(I2_values, 'linear');
            I3_values = fillmissing(I3_values, 'linear');
            I2_values = smoothdata(I2_values, 'movmean', 7);
            I3_values = smoothdata(I3_values, 'movmean', 7);
            I1_values = I2_values + I3_values;

            % Te 計算
            try
                Te_values = real(double(subs(Te_symbolic, {I1, I2, I3}, {I1_values, I2_values, I3_values})));
            catch
                Te_values = zeros(size(I1_values));
            end

            % ne 計算
            try
                ne_values = real(double(subs(ne_symbolic, {Te, I2, I3}, {Te_values, I2_values, I3_values})));
            catch
                ne_values = zeros(size(I2_values));
            end

            % 補間して時間軸を統一
            Te_matrix(valid_idx, :) = interp1(time, Te_values, time_us, 'linear', 0);
            ne_matrix(valid_idx, :) = interp1(time, ne_values, time_us, 'linear', 0);
        else
            warning('File %s not found. Skipping this shot.', filename);
        end
    end
    %%

    % 有効データのみを使用
    Te_matrix = Te_matrix(1:valid_idx, :);
    ne_matrix = ne_matrix(1:valid_idx, :);
    r_list = r_list(1:valid_idx);

    % 0をNaNに置き換え
    Te_matrix(Te_matrix == 0) = NaN;
    ne_matrix(ne_matrix == 0) = NaN;

    % NaN値を補完 (線形補完)
    Te_matrix = fillmissing(Te_matrix, 'linear', 1); % 時間方向で補完
    ne_matrix = fillmissing(ne_matrix, 'linear', 1); % 時間方向で補完


    % ----------------------------
    % 同じr_listの値でTeとneの平均値を計算
    % ----------------------------
    unique_r = unique(r_list); % 一意なR値
    Te_avg_matrix = zeros(length(unique_r), length(time_us));
    ne_avg_matrix = zeros(length(unique_r), length(time_us));
    Te_std_matrix = zeros(length(unique_r), length(time_us)); % 追加
    ne_std_matrix = zeros(length(unique_r), length(time_us)); % 追加

    for i = 1:length(unique_r)
        idx_r = (r_list == unique_r(i)); % 現在のR値に対応するインデックス
        Te_avg_matrix(i, :) = mean(Te_matrix(idx_r, :), 1, 'omitnan'); % 平均
        ne_avg_matrix(i, :) = mean(ne_matrix(idx_r, :), 1, 'omitnan'); % 平均
        % 標準偏差も計算して保存
        Te_std_matrix(i, :) = std(Te_matrix(idx_r, :), 0, 1, 'omitnan'); 
        ne_std_matrix(i, :) = std(ne_matrix(idx_r, :), 0, 1, 'omitnan');
    end



    %%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % matファイルの作製
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 必要なデータを準備
    R_values = unique_r;             % R方向の値 (10個)
    time_values = time_us;           % 時間軸 (300点)
    Te_data_2D = Te_avg_matrix ./ K2ev; % Teデータを[eV]に変換した2次元データ (10×300)
    ne_data_2D = ne_avg_matrix;       % neデータ (10×300)

    % 3次元データ構造を作成
    triple_data2D = struct(); % 空のストラクトを作成

    % Teデータを格納 (サイズ: 10×1×300)
    triple_data2D.Te = zeros(length(R_values), 1, length(time_values));
    triple_data2D.Te(:, 1, :) = reshape(Te_data_2D, [length(R_values), 1, length(time_values)]);

    % neデータを格納 (サイズ: 10×2×300)
    triple_data2D.ne = zeros(length(R_values), 1, length(time_values));
    triple_data2D.ne(:, 1, :) = reshape(ne_data_2D, [length(R_values), 1, length(time_values)]);

    % 3次元データ構造に std も含める
    triple_data2D.Te_std = zeros(length(R_values), 1, length(time_values));
    triple_data2D.Te_std(:, 1, :) = reshape(Te_std_matrix ./ K2ev, [length(R_values), 1, length(time_values)]); % eVに変換
    
    triple_data2D.ne_std = zeros(length(R_values), 1, length(time_values));
    triple_data2D.ne_std(:, 1, :) = reshape(ne_std_matrix, [length(R_values), 1, length(time_values)]);


    % MATファイルとして保存
    save(filepath_mat, 'triple_data2D', 'R_values', 'time_values');
    disp('MATファイルを保存しました');
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% conturfのプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % MATファイルを読み込む
% load('triple_data2D_case-I.mat'); % triple_data2D, R_values, time_values を読み込む

% 必要なデータを取り出す
Te_data_2D = squeeze(triple_data2D.Te(:, 1, :)); % 3次元データから2次元データに変換 (10×300)
ne_data_2D = squeeze(triple_data2D.ne(:, 1, :)); % 3次元データから2次元データに変換 (10×300)


% % グリッドデータを作成
[T_grid, R_grid] = meshgrid(time_values, R_values); % 時間 (X軸) と R方向 (Y軸) のグリッド

% % プロット作成
figure;
contourf(T_grid, R_grid, Te_data_2D, 10000, 'LineColor', 'none');
clim([0, 30]);
xlim([460, 475]);
% カラーバーを追加してタイトルを設定
cb = colorbar;
cb.Title.String = 'T_{e} [eV]';
% 個別に文字サイズを設定
xlabel('Time [\mus]', 'FontSize', 12);     % X軸ラベル
ylabel('R [m]', 'FontSize', 14);           % Y軸ラベル
title('Case - I plot of Te [eV]', 'FontSize', 16); % グラフタイトル
cb.Title.FontSize = 10;                    % カラーバーのタイトル
cb.FontSize = 10;                          % カラーバーの目盛りフォントサイズ
% 軸目盛りフォントサイズを設定
ax = gca; % 現在の座標軸を取得
ax.FontSize = 12; % 軸目盛りフォントサイズを設定
% カラーマップ設定
colormap('jet');


% % % プロット作成
figure;
contourf(T_grid, R_grid, ne_data_2D, 1000, 'LineColor', 'none');
% clim([0, 10e+19]); % カラーマップの範囲設定
clim([0, 5e20]); % カラーマップの範囲設定
xlim([460, 475]);
% カラーバーを追加してタイトルを設定
cb = colorbar;
cb.Title.String = 'n_{e} [m^{-3}]';
% 各要素の文字サイズを設定
xlabel('Time [\mus]', 'FontSize', 12);     % X軸ラベル
ylabel('R [m]', 'FontSize', 14); % Y軸ラベル
title('Case (a) plot of ne [m^{-3}]', 'FontSize', 16); % グラフタイトル
cb.Title.FontSize = 10;                    % カラーバーのタイトル文字サイズ
cb.FontSize = 10;                          % カラーバーの目盛りフォントサイズ
% 軸目盛りフォントサイズを設定
ax = gca; % 現在の座標軸を取得
ax.FontSize = 12; % 軸目盛りフォントサイズを設定
% カラーマップ設定
colormap('jet');


% %%
% % 結果の保存
% saveDir = "G:\My Drive\lab\lab_data\triple_probe\figure";
% date = 240610;
% % フォルダが存在するかを確認し、存在しない場合にのみ作成
% if ~exist(saveDir, 'dir')
%     mkdir(saveDir);
% end

% saveas(gcf, strcat(saveDir, '\', num2str(date), '\case_I_Te'), 'png')
% fprintf("save your file %s", num2str(date))


%%
% % ----------------------------
% % エラーバー付きプロット
% % ----------------------------
% selected_r = 2.5; % プロットしたいR値
% idx_selected = (r_list == selected_r);
% 
% % 平均値と標準偏差を計算
% Te_mean = mean(Te_matrix(idx_selected, :), 1, 'omitnan');
% Te_std = std(Te_matrix(idx_selected, :), 0, 1, 'omitnan');
% ne_mean = mean(ne_matrix(idx_selected, :), 1, 'omitnan');
% ne_std = std(ne_matrix(idx_selected, :), 0, 1, 'omitnan');
% 
% % Teのエラーバー付きプロット
% figure;
% errorbar(time_us, Te_mean ./ K2ev, Te_std./ K2ev);
% xlim([450, 500])
% xlabel('Time [\mus]');
% ylabel('Te [eV]');
% title(['Te vs Time at R = ', num2str(selected_r)]);
% grid on;
% 
% % neのエラーバー付きプロット
% figure;
% errorbar(time_us, ne_mean, ne_std);
% xlabel('Time [\mus]');
% ylabel('ne [m^{-3}]');
% title(['ne vs Time at R = ', num2str(selected_r)]);
% grid on;
% 
% 
% 
% %%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % t = 470 us における ne の R 方向分布のプロット
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % --- 1. プロットしたい時間の設定 ---
% target_time = 470; % [us]

% % --- 2. 指定時間に対応するインデックスを取得 ---
% % time_values の中から target_time に最も近いインデックスを探す
% [~, time_idx] = min(abs(time_values - target_time));
% actual_time = time_values(time_idx); % 実際に使用する最も近い時間

% fprintf('指定時間: %.2f [us]\n', target_time);
% fprintf('実際のプロット時間: %.2f [us] (インデックス: %d)\n', actual_time, time_idx);

% % --- 3. 指定時間の ne データを抽出 ---
% % ne_data_2D は [Rの要素数 x 時間の要素数] の行列
% ne_at_target_time = ne_data_2D(:, time_idx);

% % --- 4. プロット作成 ---
% figure;
% % R_values を横軸、抽出した ne データを縦軸にプロット
% plot(R_values, ne_at_target_time, '-o', 'LineWidth', 1.5, 'MarkerSize', 6, 'MarkerFaceColor', 'b');

% % --- 5. グラフの装飾 ---
% xlabel('R [m]', 'FontSize', 12);
% ylabel('n_e [m^{-3}]', 'FontSize', 12);
% title(sprintf('Electron Density Radial Distribution at t = %.2f \\mus', actual_time), 'FontSize', 14);
% grid on;
% ax = gca;
% ax.FontSize = 12;

% % Y軸の範囲設定（必要に応じて調整してください）
% % ylim([0, max(ne_data_2D(:)) * 1.1]); % 全体の最大値の1.1倍まで表示など
% % ylim([0, 6e20]); % contourfと同じスケールに合わせる場合