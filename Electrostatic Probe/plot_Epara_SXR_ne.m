function [] = plot_Epara_SXR_ne(ESP, ESPdata2D, pathname)

    % =========================================================================
    % --- 1. 基本設定 (ユーザーコードより) ---
    % =========================================================================
    % addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View')); % 必要に応じてコメントイン
    PCB.type = 1;
    PCB.doOverwrite = false;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = 68; % Start time index
    PCB.date = 240111;
    PCB.idx = 30;
    PCB.shot = [3597 2071];
    PCB.tfshot = [3569 2043];
    PCB.i_EF = 200;
    PCB.TF = 4;
    
    % 時間設定
    t_plot_idx = PCB.start;
    t_plot = PCB.trange(t_plot_idx);
    fprintf('Plotting for t = %.0f us\n', t_plot);

    % グリッドデータの処理 (必要に応じてコメントアウトを外してください)
    % [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
    [grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);

    % =========================================================================
    % --- 2. Epara (平行電場) の計算 ---
    % =========================================================================
    % 境界条件処理 (ユーザーコードより)
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

    % Epara計算
    [E_data, ~] = get_Epara(grid2D, data2D, ESP, ESPdata2D, t_plot);
    Epara = E_data.Epara;

    % z=0近傍の平均化
    z_axis_E = ESPdata2D.phi_mesh_z(1,:);
    r_axis_E = ESPdata2D.phi_mesh_r(:,1);
    z_indices_E = abs(z_axis_E) <= 0.01;

    E_r_tmp = squeeze(Epara(:, z_indices_E, 1));
    E_r_mean = mean(E_r_tmp, 2);
    E_r_std = std(E_r_tmp, 0, 2);

    % =========================================================================
    % --- 3. SXR (軟X線) データの取得 ---
    % =========================================================================
    pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
    pathLastHalf = '/3.mat';
    
    % --- SXR Low (EE1) ---
    nshot_1 = 17;
    path_1 = strcat(pathFirstHalf, num2str(nshot_1), pathLastHalf);
    
    % 座標設定
    rmin = 70/1000; rmax = 375/1000;
    r_space_SXR = linspace(rmin, rmax, 50);
    z_space_SXR2 = linspace(-0.2, 0.2, 50); % zmin2, zmax2
    z_space_SXR1 = linspace(-0.2, 0.2, 50); % zmin1, zmax1

    if exist(path_1, 'file')
        load(path_1, 'EE1');
        z_indices_SXR2 = abs(z_space_SXR2) <= 0.01;
        SXR_r_tmp1 = EE1(:, z_indices_SXR2);
        SXR_mean_1 = mean(SXR_r_tmp1, 2);
        SXR_std_1 = std(SXR_r_tmp1, 0, 2);
    else
        warning('SXR EE1 not found.');
        SXR_mean_1 = zeros(50,1); SXR_std_1 = zeros(50,1);
    end

    % --- SXR High (EE4) ---
    nshot_4 = 9;
    path_4 = strcat(pathFirstHalf, num2str(nshot_4), pathLastHalf);
    
    if exist(path_4, 'file')
        load(path_4, 'EE4');
        z_indices_SXR1 = abs(z_space_SXR1) <= 0.01;
        SXR_r_tmp4 = EE4(:, z_indices_SXR1);
        SXR_mean_4 = mean(SXR_r_tmp4, 2);
        SXR_std_4 = std(SXR_r_tmp4, 0, 2);
    else
        warning('SXR EE4 not found.');
        SXR_mean_4 = zeros(50,1); SXR_std_4 = zeros(50,1);
    end

    % =========================================================================
    % --- 4. ne (電子密度) データの取得 ---
    % =========================================================================
    probe_date = 251218; 
    probe_path = fullfile(getenv('PROBE_DATA_DIR'),'tripleProbe',[num2str(probe_date),'.mat']);


    ne_data_ready = false;
    if exist(probe_path, 'file')
        load(probe_path, 'triple_data2D', 'R_values', 'time_values');
        [~, t_idx_ne] = min(abs(time_values - t_plot));
        
        ne_mean = squeeze(triple_data2D.ne(:, 1, t_idx_ne)); 
        if isfield(triple_data2D, 'ne_std')
            ne_std = squeeze(triple_data2D.ne_std(:, 1, t_idx_ne));
        else
            ne_std = zeros(size(ne_mean));
        end
        ne_data_ready = true;
    else
        warning('Triple probe data not found.');
    end

    % =========================================================================
    % --- 5. プロット (1x4 Subplots) ---
    % =========================================================================
    figure('Color', 'w', 'Position', [277    73   412   765]);
    t = tiledlayout(4,1, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % 共通X軸範囲
    x_range = [0.1, 0.25];
    
    % --- Panel 1: ne (電子密度) ---
    nexttile;
    if ne_data_ready
        errorbar(R_values, ne_mean, ne_std, 'o-', 'LineWidth', 1.5, ...
            'Color', [0, 0.4470, 0.7410], 'MarkerFaceColor', [0, 0.4470, 0.7410], ...
            'CapSize', 8, 'MarkerSize', 5);
    end
    xlim(x_range);
    title('$n_e$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$n_e$ [m$^{-3}$]', 'Interpreter', 'latex');
    xlabel('r [m]');
    grid on; ax = gca; ax.FontSize = 12;

    % --- Panel 2: Epara (平行電場) ---
    nexttile;
    errorbar(r_axis_E, E_r_mean, E_r_std, 'o-', 'LineWidth', 1.5, ...
        'Color', [0.8500, 0.3250, 0.0980], 'MarkerFaceColor', [0.8500, 0.3250, 0.0980], ...
        'CapSize', 8, 'MarkerSize', 5);
    xlim(x_range);
    ylim([-300, 300]); % ユーザー指定範囲
    title('$E_{\parallel}$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$E_{\parallel}$ [V/m]', 'Interpreter', 'latex');
    xlabel('r [m]');
    grid on; ax = gca; ax.FontSize = 12;

    % --- Panel 3: SXR Low (EE1) ---
    nexttile;
    errorbar(r_space_SXR, SXR_mean_1, SXR_std_1, 'o-', 'LineWidth', 1.5, ...
        'Color', [0.9290, 0.6940, 0.1250], 'MarkerFaceColor', [0.9290, 0.6940, 0.1250], ...
        'CapSize', 8, 'MarkerSize', 5);
    xlim(x_range);
    ylim([0, Inf]);
    title('SXR (20-80 eV)', 'FontSize', 14);
    ylabel('Intensity [a.u.]');
    xlabel('r [m]');
    grid on; ax = gca; ax.FontSize = 12;

    % --- Panel 4: SXR High (EE4) ---
    nexttile;
    errorbar(r_space_SXR, SXR_mean_4, SXR_std_4, 'o-', 'LineWidth', 1.5, ...
        'Color', [0.4940, 0.1840, 0.5560], 'MarkerFaceColor', [0.4940, 0.1840, 0.5560], ...
        'CapSize', 8, 'MarkerSize', 5);
    xlim(x_range);
    ylim([0, Inf]);
    title('SXR (100 eV <)', 'FontSize', 14);
    ylabel('Intensity [a.u.]');
    xlabel('r [m]');
    grid on; ax = gca; ax.FontSize = 12;

    % % 全体タイトル
    % sgtitle(sprintf('Radial Profiles at t = %.0f \\mu s', t_plot), 'FontSize', 16);

end

% =========================================================================
% --- 内部関数: get_Epara ---
% =========================================================================
function [E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot)
    [Epara,Epara_t,E_r,E_z,E_t,B_r,B_z,B_t,J_t,phi_perp,Epara_perp] = deal(zeros([size(ESPdata2D.phi_mesh_r),numel(t_plot)]));
    rq_mag = grid2D.rq;zq_mag = grid2D.zq;
    rq_esp = ESPdata2D.phi_mesh_r;zq_esp = ESPdata2D.phi_mesh_z;
    drq = abs( rq_esp(1,1) - rq_esp(2,1) );
    dzq = abs( zq_esp(1,1) - zq_esp(1,2) );
    for i = 1:numel(t_plot)
        t = t_plot(i);
        idx_mag = find(data2D.trange==t);
        idx_esp = find(ESP.trange==t);
        Bt = data2D.Bt_th(:,:,idx_mag);
        % Bt = 0.6*data2D.Bt_th(:,:,idx_mag);
        Br = data2D.Br(:,:,idx_mag);
        Bz = data2D.Bz(:,:,idx_mag);
        Et = data2D.Et(:,:,idx_mag);
        Jt = data2D.Jt(:,:,idx_mag);
        Bt_q = interp2(zq_mag,rq_mag,Bt,zq_esp,rq_esp);
        Br_q = interp2(zq_mag,rq_mag,Br,zq_esp,rq_esp);
        Bz_q = interp2(zq_mag,rq_mag,Bz,zq_esp,rq_esp);
        Et_q = interp2(zq_mag,rq_mag,Et,zq_esp,rq_esp);
        Jt_q = interp2(zq_mag,rq_mag,Jt,zq_esp,rq_esp);
        Er = squeeze(ESPdata2D.Er_grid(idx_esp,:,:));
        Ez = squeeze(ESPdata2D.Ez_grid(idx_esp,:,:));
        B = cat(3,Br_q,Bz_q,Bt_q);
        E = cat(3,Er,Ez,Et_q);
        norm_B = B./sqrt(dot(B,B,3));
        norm_Bp = Br_q.^2 + Bz_q.^2;
        alpha = -Et_q.*Bt_q ./ ( norm_Bp + eps );
        Er_perp = alpha .* Br_q;
        Ez_perp = alpha .* Bz_q;
        for j = 2:size(rq_esp,1)
            phi_perp(j,1,i) = phi_perp(j-1,1,i) + Er_perp(j-1,1) * drq;
        end
        for j = 2:size(rq_esp,1)
            phi_perp(:,j,i) = phi_perp(:, j-1,i) + Ez_perp(:,j-1) * dzq;
        end
        phi_perp(:,:,i) = phi_perp(:,:,i) - mean(phi_perp(:,:,i),"all");
        phi_perp(:,:,i) = -1 * phi_perp(:,:,i);
        Eperp = cat(3,Er_perp, Ez_perp, Et_q);
        Epara_perp(:,:,i) = dot(norm_B,Eperp,3);
        Epara(:,:,i) = dot(norm_B,E,3);
        Epara_t(:,:,i) = Epara(:,:,i).*Bt_q./sqrt(dot(B,B,3));
        E_r(:,:,i)=Er;E_z(:,:,i)=Ez;E_t(:,:,i)=Et_q;
        B_r(:,:,i)=Br_q;B_z(:,:,i)=Bz_q;B_t(:,:,i)=Bt_q;
        J_t(:,:,i)=Jt_q;
        phi_perp(rq_esp(:,1)>0.23,:,i) = 0;
    end
    E_data.Epara = Epara;E_data.Epara_perp = Epara_perp;E_data.Epara_t = Epara_t;
    E_data.Er = E_r;E_data.Ez = E_z;E_data.Et = E_t;E_data.E = E;
    B_data.Br = B_r;B_data.Bz = B_z;B_data.Bt = B_t;B_data.B = B;B_data.Jt = J_t;
    E_data.phi_perp = phi_perp;
end