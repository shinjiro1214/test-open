function [] = plot_Jt_SXR_ne(ESP, ESPdata2D, pathname)

    % --- 1. 基本設定 (元のコードと同様) ---
    addpath(fullfile(pathname.github, 'test-open', 'Soft X-ray', 'Four-View'));
    PCB.type = 1;
    PCB.doOverwrite = false;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = 70;
    PCB.idx = 30;
    PCB.date = 240111;
    PCB.shot = [3597 2071];
    PCB.tfshot = [3569 2043];
    PCB.i_EF = 200;
    PCB.TF = 4;

    % PCBデータ処理
    [grid2D, data2D] = process_PCBdata_200ch(PCB, pathname);

    % 時間設定
    t_plot_idx = PCB.start;
    t_plot = PCB.trange(t_plot_idx); % [us]

    % --- 2. ESPデータのグリッド調整 (元のコードと同様) ---
    n=4;
    if PCB.date == 240111
        ER1 = ESPdata2D.Er_grid;
        ER2 = ER1;
        ER2(:,:,1:50-n) = ER1(:,:,1+n:50);
        ER2(:,:,50-n+1:50) = repmat(ER1(:,:,50),1,1,n);
        ESPdata2D.Er_grid = ER2;
        EZ1 = ESPdata2D.Ez_grid;
        EZ2 = EZ1;
        EZ2(:,:,1:50-n) = EZ1(:,:,1+n:50);
        EZ2(:,:,50-n+1:50) = repmat(EZ1(:,:,50),1,1,n);
        ESPdata2D.Ez_grid = EZ2;
    end

    % --- 3. Jt (電流密度) の計算 ---
    [~, B_data] = get_Epara(grid2D, data2D, ESP, ESPdata2D, t_plot);
    Jt = B_data.Jt;
    
    % Jtの統計処理 (z=0付近)
    z_axis = ESPdata2D.phi_mesh_z(1, :);
    r_axis = ESPdata2D.phi_mesh_r(:, 1);
    z_indices = abs(z_axis) <= 0.01;
    
    J_r_tmp = squeeze(Jt(:, z_indices, 1));
    J_r_mean = mean(J_r_tmp, 2);
    J_r_std = std(J_r_tmp, 0, 2);

    % --- 4. SXR (軟X線) データの取得 ---
    pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
    pathLastHalf = '/3.mat';
    nshot_1 = 17;
    path_1 = strcat(pathFirstHalf, num2str(nshot_1), pathLastHalf);
    
    if exist(path_1, 'file')
        load(path_1, 'EE1');
        % SXRの座標設定
        rmin = 70/1000; rmax = 375/1000;
        zmin2 = -200/1000; zmax2 = 200/1000;
        r_space_SXR = linspace(rmin, rmax, 50);
        z_space_SXR2 = linspace(zmin2, zmax2, 50);
        
        % SXRの統計処理 (z=0付近)
        z_indices_SXR = abs(z_space_SXR2) <= 0.01;
        SXR_r_tmp = EE1(:, z_indices_SXR);
        SXR_r_mean = mean(SXR_r_tmp, 2);
        SXR_r_std = std(SXR_r_tmp, 0, 2);
    else
        warning('SXR data file not found: %s', path_1);
        SXR_r_mean = zeros(50, 1);
        SXR_r_std = zeros(50, 1);
        r_space_SXR = linspace(0.07, 0.375, 50);
    end

    % --- 5. ne (電子密度) データの取得 ---
    % ※パスは環境に合わせて調整してください
    probe_date = 251218; % 例として前回の日付を使用
    probe_dir = getenv('PROBE_DATA_DIR');
    if isempty(probe_dir)
        % パスが見つからない場合の仮パス (適宜変更してください)
        probe_path = fullfile(pwd, [num2str(probe_date), '.mat']);
    else
        probe_path = fullfile(probe_dir, [num2str(probe_date), '.mat']);
    end

    ne_data_ready = false;
    if exist(probe_path, 'file')
        load(probe_path, 'triple_data2D', 'R_values', 'time_values');
        % 指定時間(t_plot)に最も近いneデータを抽出
        [~, t_idx_ne] = min(abs(time_values - t_plot));
        ne_mean = squeeze(triple_data2D.ne(:, 1, t_idx_ne)); % R x 1 (Timeはsqueezeで消える)
        ne_data_ready = true;
        fprintf('ne data loaded for t = %.1f us\n', time_values(t_idx_ne));
    else
        warning('Triple probe data not found: %s', probe_path);
        ne_mean = zeros(10, 1);
        R_values = linspace(0.1, 0.3, 10);
    end


    % =========================================================================
    % --- 6. 3軸プロットの作成 ---
    % =========================================================================
    fig = figure('Position', [100, 100, 900, 600], 'Color', 'w');
    
    % 色の設定
    color_Jt = [0, 0.4470, 0.7410];  % 青
    color_ne = [0.8500, 0.3250, 0.0980]; % 赤/オレンジ
    color_SXR = [0.9290, 0.6940, 0.1250]; % 黄色/ゴールド

    % --- [Axis 1: Left] Jt (Toroidal Current) ---
    yyaxis left
    h1 = errorbar(r_axis, J_r_mean, J_r_std, 'LineWidth', 2, ...
        'Marker', 'o', 'MarkerSize', 6, 'CapSize', 0, 'Color', color_Jt);
    ylabel('$J_t$ [A/m$^2$]', 'Interpreter', 'latex', 'FontSize', 14);
    xlabel('r [m]', 'FontSize', 14);
    ax1 = gca;
    ax1.YColor = color_Jt;
    ax1.XColor = 'k';
    ax1.FontSize = 14;
    xlim([0.1 0.28]); % X軸範囲の統一
    grid on;
    
    % Y軸範囲の調整 (Jt)
    maxVal = max(abs(J_r_mean)) * 1.2;
    if maxVal == 0, maxVal = 1; end
    ylim([-maxVal, maxVal]);

    % --- [Axis 2: Right] ne (Electron Density) ---
    yyaxis right
    if ne_data_ready
        h2 = plot(R_values, ne_mean, '-s', 'LineWidth', 2, ...
            'MarkerSize', 8, 'MarkerFaceColor', color_ne, 'Color', color_ne);
    else
        h2 = plot(nan, nan, '-s'); % ダミー
    end
    ylabel('$n_e$ [m$^{-3}$]', 'Interpreter', 'latex', 'FontSize', 14);
    ax1.YAxis(2).Color = color_ne;
    
    % Y軸範囲の調整 (ne)
    if ne_data_ready
        ylim([0, max(ne_mean, [], 'all') * 1.2]);
    end

    % --- [Axis 3: Far Right] SXR (Soft X-ray) ---
    % 透明なAxesを重ねて3つ目の軸を作成します
    axpos = ax1.Position;
    % 元のグラフを少し左に縮めて、3つ目の軸が入るスペースを作る
    ax1.Position = [axpos(1), axpos(2), axpos(3) * 0.85, axpos(4)];
    
    % 新しいAxesの作成
    ax2 = axes('Position', ax1.Position, ...
        'XAxisLocation', 'top', ...
        'YAxisLocation', 'right', ...
        'Color', 'none', ...
        'XColor', 'none', ... % X軸は表示しない
        'YColor', color_SXR, ...
        'FontSize', 14);
    
    hold(ax2, 'on');
    h3 = errorbar(ax2, r_space_SXR, SXR_r_mean, SXR_r_std, 'LineWidth', 2, ...
        'Marker', '^', 'MarkerSize', 6, 'CapSize', 0, 'Color', color_SXR);
    
    % 3つ目の軸を外側にずらす
    ax2.YAxis.Visible = 'on';
    % 軸の位置を少し右にオフセット
    ax2.Position(3) = ax1.Position(3); % 幅を同期
    
    % 軸ラベルのために少し工夫（MATLABの標準機能では外側にオフセットできないため）
    % linkaxesでX軸を同期
    linkaxes([ax1, ax2], 'x');
    xlim(ax2, [0.1 0.28]); % X軸範囲を明示的に指定
    
    % ラベル作成（外側に配置）
    % 第2軸(ne)のラベル位置
    ylabel(ax2, 'SXR intensity [a.u.]', 'FontSize', 14);
    
    % 軸の位置を調整して重ならないようにするテクニック
    % 右軸(ne)のさらに右に軸線を描画するために、ax2のY軸位置をずらす
    % MATLAB標準では難しいので、SXRの軸ラベルを目立たせることで対応
    
    % タイトル
    title(ax1, sprintf('Radial Profiles at t = %.0f \\mu s', t_plot), 'FontSize', 16);

    % --- 凡例 ---
    legend([h1, h2, h3], {'$J_t$', '$n_e$', 'SXR'}, ...
        'Interpreter', 'latex', 'Location', 'northwest', 'FontSize', 12);
    
    hold off;

end

% --- 以下、Helper Functions (元のコードと同様) ---
function [E_data, B_data] = get_Epara(grid2D, data2D, ESP, ESPdata2D, t_plot)
    % (元のコードのまま変更なし)
    [Epara, Epara_t, E_r, E_z, E_t, B_r, B_z, B_t, J_t, phi_perp, Epara_perp] = deal(zeros([size(ESPdata2D.phi_mesh_r), numel(t_plot)]));
    rq_mag = grid2D.rq; zq_mag = grid2D.zq;
    rq_esp = ESPdata2D.phi_mesh_r; zq_esp = ESPdata2D.phi_mesh_z;
    drq = abs(rq_esp(1, 1) - rq_esp(2, 1));
    dzq = abs(zq_esp(1, 1) - zq_esp(1, 2));
    for i = 1:numel(t_plot)
        t = t_plot(i);
        idx_mag = find(data2D.trange == t);
        idx_esp = find(ESP.trange == t);
        Bt = data2D.Bt_th(:, :, idx_mag);
        Br = data2D.Br(:, :, idx_mag);
        Bz = data2D.Bz(:, :, idx_mag);
        Et = data2D.Et(:, :, idx_mag);
        Jt = data2D.Jt(:, :, idx_mag);
        Bt_q = interp2(zq_mag, rq_mag, Bt, zq_esp, rq_esp);
        Br_q = interp2(zq_mag, rq_mag, Br, zq_esp, rq_esp);
        Bz_q = interp2(zq_mag, rq_mag, Bz, zq_esp, rq_esp);
        Et_q = interp2(zq_mag, rq_mag, Et, zq_esp, rq_esp);
        Jt_q = interp2(zq_mag, rq_mag, Jt, zq_esp, rq_esp);
        Er = squeeze(ESPdata2D.Er_grid(idx_esp, :, :));
        Ez = squeeze(ESPdata2D.Ez_grid(idx_esp, :, :));
        B = cat(3, Br_q, Bz_q, Bt_q);
        E = cat(3, Er, Ez, Et_q);
        norm_B = B ./ sqrt(dot(B, B, 3));
        norm_Bp = Br_q.^2 + Bz_q.^2;
        alpha = -Et_q .* Bt_q ./ (norm_Bp + eps);
        Er_perp = alpha .* Br_q;
        Ez_perp = alpha .* Bz_q;
        for j = 2:size(rq_esp, 1)
            phi_perp(j, 1, i) = phi_perp(j-1, 1, i) + Er_perp(j-1, 1) * drq;
        end
        for j = 2:size(rq_esp, 1)
            phi_perp(:, j, i) = phi_perp(:, j-1, i) + Ez_perp(:, j-1) * dzq;
        end
        phi_perp(:, :, i) = phi_perp(:, :, i) - mean(phi_perp(:, :, i), "all");
        phi_perp(:, :, i) = -1 * phi_perp(:, :, i);
        Eperp = cat(3, Er_perp, Ez_perp, Et_q);
        Epara_perp(:, :, i) = dot(norm_B, Eperp, 3);
        Epara(:, :, i) = dot(norm_B, E, 3);
        Epara_t(:, :, i) = Epara(:, :, i) .* Bt_q ./ sqrt(dot(B, B, 3));
        E_r(:, :, i) = Er; E_z(:, :, i) = Ez; E_t(:, :, i) = Et_q;
        B_r(:, :, i) = Br_q; B_z(:, :, i) = Bz_q; B_t(:, :, i) = Bt_q;
        J_t(:, :, i) = Jt_q;
        phi_perp(rq_esp(:, 1) > 0.23, :, i) = 0;
    end
    E_data.Epara = Epara; E_data.Epara_perp = Epara_perp; E_data.Epara_t = Epara_t;
    E_data.Er = E_r; E_data.Ez = E_z; E_data.Et = E_t; E_data.E = E;
    B_data.Br = B_r; B_data.Bz = B_z; B_data.Bt = B_t; B_data.B = B; B_data.Jt = J_t;
    E_data.phi_perp = phi_perp;
end