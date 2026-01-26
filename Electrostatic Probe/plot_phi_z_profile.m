date = '240827';
load(fullfile(getenv("NIFS_ESP"),date,'ESPdata.mat'));
% load(fullfile(getenv("NIFS_ESP"),date,'ESPdata_6kV.mat'));
time_info = 470;
target_r_list = [0.1, 0.2, 0.3];
plot_phi_z(ESPdata2D, time_info, target_r_list);

function plot_phi_z(ESPdata2D, time_info, target_r_list)
% plot_phi_z_profile
%
% Inputs:
%   ESPdata2D     : 構造体
%   time_info     : プロットしたい時間（数値） または 時間インデックス（整数）
%                   ※別途 time_vec がある場合はコード内の time_vec 定義を書き換えてください
%   target_r_list : プロットしたいr位置のリスト（例: [0.1, 0.15, 0.2]）

    % time_info = 470;
    % target_r_list = [0.1, 0.15, 0.2];
    % =========================================================
    % 1. 時間インデックスの特定
    % =========================================================
    % もし構造体の中に時間ベクトルが含まれていない場合、ここに定義してください
    % 例: time_vec = linspace(400, 800, 1001); 
    % ここでは仮に、引数 time_info が「インデックスそのもの」だと仮定します。
    % もし time_info が「物理時間(us)」なら、time_vecとの比較でidxを求めてください。
    
    % time_vec = ESP.trange;
    time_vec = 400:0.1:500;
    % t_idx = time_info; % 仮置き
    [~, t_idx] = min(abs(time_vec - time_info));
    
    
    % (例: 時間ベクトルがある場合の処理)
    % if exist('time_vec', 'var')
    %    [~, t_idx] = min(abs(time_vec - time_info));
    %    fprintf('Target Time: %.1f -> Index: %d\n', time_info, t_idx);
    % end

    if t_idx < 1 || t_idx > size(ESPdata2D.phi_grid, 1)
        error('時間インデックスが範囲外です。');
    end

    fprintf('Plotting frame index: %d\n', t_idx);

    % =========================================================
    % 2. データの抽出（指定時間の2Dスライス）
    % =========================================================
    % phi_grid: [1001 x 50 x 50] -> [50 x 50] に絞る
    phi_slice = squeeze(ESPdata2D.phi_grid(t_idx, :, :));
    
    % メッシュ情報の取得
    R_mesh = ESPdata2D.phi_mesh_r; % [50x50]
    Z_mesh = ESPdata2D.phi_mesh_z; % [50x50]

    % =========================================================
    % 3. Z方向分布の抽出とプロット
    % =========================================================
    figure('Name', 'Phi Z-profile', 'Color', 'w');
    hold on;
    colors = lines(length(target_r_list));

    % メッシュの向きを判定（Rが一定となる方向を探す）
    % 通常 meshgrid(r, z) なら、列ごとにRが同じか、行ごとにRが同じか確認します。
    
    % ここでは「R_meshの各列 または 各行 の平均をとって、代表R値とする」方式で探します
    % Rが一様に並んでいる方向を軸として扱います
    
    % 仮定: 1行目を見るとRが変化しているか確認
    if std(R_mesh(1, :)) > std(R_mesh(:, 1))
        % 行方向（横）にRが変化している -> Z分布を見るには「列（縦）」を固定する
        mode = 'col_fixed'; 
        axis_vec = R_mesh(1, :); % Rの代表ベクトル
    else
        % 列方向（縦）にRが変化している -> Z分布を見るには「行（横）」を固定する
        mode = 'row_fixed';
        axis_vec = R_mesh(:, 1); % Rの代表ベクトル
    end

    for i = 1:length(target_r_list)
        r_target = target_r_list(i);
        
        % 最も近いRのインデックスを探す
        [~, idx_r] = min(abs(axis_vec - r_target));
        actual_r = axis_vec(idx_r);
        
        % データの抽出
        if strcmp(mode, 'col_fixed')
            % 列を固定（R固定）、行に沿ってZが変化する場合
            z_line = Z_mesh(:, idx_r);
            phi_line = phi_slice(:, idx_r);
        else
            % 行を固定（R固定）、列に沿ってZが変化する場合
            z_line = Z_mesh(idx_r, :);
            phi_line = phi_slice(idx_r, :);
        end
        
        % プロット
        plot(z_line, phi_line, 'LineWidth', 2, 'Color', colors(i,:), ...
             'DisplayName', sprintf('r \\approx %.3f m', actual_r));
    end

    % =========================================================
    % 4. 装飾
    % =========================================================
    grid on;
    xlabel('z [m]', 'FontSize', 14);
    ylabel('\phi [V]', 'FontSize', 14); % 単位は適宜修正してください
    title(sprintf('Phi Z-profile (Time Index: %d)', t_idx), 'FontSize', 16);
    legend('Location', 'best');
    
    hold off;
end