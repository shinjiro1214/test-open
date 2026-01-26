% function [] = plot_SXR_ne(pathname)

    % --- 1. 基本設定 ---
    % SXRデータのパス生成等に必要な設定
    PCB.type = 1;
    PCB.trange = 400:800;
    PCB.start = 70;  % プロット開始点のインデックス
    PCB.date = 240111;
    
    % プロットする時間を決定 [us]
    t_plot_idx = PCB.start;
    t_plot = PCB.trange(t_plot_idx); 

    fprintf('Plotting for t = %.0f us\n', t_plot);

    % =========================================================================
    % --- 2. SXR (軟X線) データの取得 ---
    % =========================================================================
    % ※パスはご自身の環境のままにしています
    pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
    pathLastHalf = '/3.mat';
    nshot_1 = 17;
    path_1 = strcat(pathFirstHalf, num2str(nshot_1), pathLastHalf);
    
    if exist(path_1, 'file')
        load(path_1, 'EE1');
        
        % 座標設定
        rmin = 70/1000; rmax = 375/1000;
        zmin2 = -200/1000; zmax2 = 200/1000;
        r_space_SXR = linspace(rmin, rmax, 50);
        z_space_SXR2 = linspace(zmin2, zmax2, 50);
        
        % z=0付近のデータを抽出して平均化
        z_indices_SXR = abs(z_space_SXR2) <= 0.01;
        SXR_r_tmp = EE1(:, z_indices_SXR);
        SXR_r_mean = mean(SXR_r_tmp, 2);
        SXR_r_std = std(SXR_r_tmp, 0, 2);
    else
        warning('SXR data file not found: %s', path_1);
        % データがない場合のダミーデータ
        SXR_r_mean = zeros(50, 1);
        SXR_r_std = zeros(50, 1);
        r_space_SXR = linspace(0.07, 0.375, 50);
    end

    % =========================================================================
    % --- 3. ne (電子密度) データの取得 ---
    % =========================================================================
    probe_date = 251218; % トリプルプローブのデータ日付
    probe_dir = getenv('PROBE_DATA_DIR');
    
    if isempty(probe_dir)
        probe_path = fullfile(pwd, [num2str(probe_date), '.mat']);
    else
        probe_path = fullfile(probe_dir, [num2str(probe_date), '.mat']);
    end

    ne_data_ready = false;
    if exist(probe_path, 'file')
        load(probe_path, 'triple_data2D', 'R_values', 'time_values');
        R_values = R_values * 0.1;
        
        % 指定時間(t_plot)に最も近いneデータを抽出
        [~, t_idx_ne] = min(abs(time_values - t_plot));
        ne_mean = squeeze(triple_data2D.ne(:, 1, t_idx_ne)); % R x 1
        
        ne_data_ready = true;
        fprintf('ne data loaded for t = %.1f us (Index: %d)\n', time_values(t_idx_ne), t_idx_ne);
    else
        warning('Triple probe data not found: %s', probe_path);
        ne_mean = zeros(10, 1);
        R_values = linspace(0.1, 0.3, 10);
    end

    % =========================================================================
    % --- 4. プロット (2軸) ---
    % =========================================================================
    figure('Color', 'w', 'Position', [100, 100, 800, 600]);
    
    % 色設定
    color_SXR = [0.9290, 0.6940, 0.1250]; % ゴールド/黄色
    color_ne = [0, 0.4470, 0.7410];       % 青色

    % --- 左軸: SXR ---
    yyaxis left
    errorbar(r_space_SXR, SXR_r_mean, SXR_r_std, 'LineWidth', 2, ...
        'Marker', 'o', 'MarkerSize', 6, 'CapSize', 0, 'Color', color_SXR, ...
        'MarkerFaceColor', color_SXR);
    ylabel('SXR intensity [a.u.]', 'FontSize', 14);
    xlabel('R [m]', 'FontSize', 14);
    
    % 左軸の色調整
    ax = gca;
    ax.YColor = color_SXR;
    ax.FontSize = 14;
    xlim([0.1 0.28]); % X軸範囲の指定
    ylim([0, max(SXR_r_mean) * 1.1]); % Y軸範囲調整
    
    % --- 右軸: ne ---
    yyaxis right
    if ne_data_ready
        plot(R_values, ne_mean, '-s', 'LineWidth', 2, ...
            'MarkerSize', 8, 'MarkerFaceColor', color_ne, 'Color', color_ne);
    else
        plot(nan, nan);
    end
    ylabel('n_e [m^{-3}]', 'FontSize', 14);
    
    % 右軸の色調整
    ax.YAxis(2).Color = color_ne;
    if ne_data_ready
        ylim([0, max(ne_mean) * 1.2]);
    end

    % --- 共通設定 ---
    grid on;
    title(sprintf('Radial Profiles at t = %.0f \\mu s', t_plot), 'FontSize', 16);
    
    % 凡例
    legend({'SXR', 'n_e'}, 'Location', 'best', 'FontSize', 12);

% end