function plot_phi_gap_evolution(ESP, ESPdata2D, pathname)
% PLOT_PHI_GAP_EVOLUTION
% 磁力線に沿った電位差(Gap)の時間発展を計算・プロットする関数

    % --- 1. 時間範囲の設定 ---
    t_start = 450;
    t_end   = 475;
    t_range = t_start:t_end; 

    % --- 2. データの準備 (全時間ステップ分をまとめて取得) ---
    PCB = get_PCB_data(240111, 27, 465, 2); 
    [grid2D, data2D] = process_PCBdata_200ch(PCB, pathname);
    
    [E_data_3D, B_data_3D] = get_Epara(PCB, grid2D, data2D, ESP, ESPdata2D, t_range);

    % グリッド座標
    Z_grid = ESPdata2D.phi_mesh_z;
    R_grid = ESPdata2D.phi_mesh_r;

    % 判定用に領域の右端座標を取得
    Z_limit = max(Z_grid(:)); 
    margin  = 1e-3; 

    % 結果格納用の配列初期化
    num_steps = length(t_range);
    gap_method1 = NaN(1, num_steps); % Et, Bt 由来 (積分)
    gap_method2 = NaN(1, num_steps); % Er, Ez 由来 (積分)
    gap_direct  = NaN(1, num_steps); % <--- 追加: ポテンシャル直接差分

    % 始点設定 (固定)
    Z_start = min(Z_grid(:));
    R_start = 0.15;
    
    % --- 3. 時間ループによる計算 ---
    fprintf('Calculating time evolution... ');
    
    for k = 1:num_steps
        current_time = t_range(k);
        
        % 進捗表示
        if mod(k, 10) == 0, fprintf('%d ', current_time); end
        
        % --- A. その時刻のデータをスライス ---
        Bz_t = B_data_3D.Bz(:, :, k);
        Br_t = B_data_3D.Br(:, :, k);
        Bt_t = B_data_3D.Bt(:, :, k);
        
        Et_t = E_data_3D.Et(:, :, k);
        Er_t = E_data_3D.Er(:, :, k);
        Ez_t = E_data_3D.Ez(:, :, k);
        
        Bp_t = sqrt(Br_t.^2 + Bz_t.^2);
        
        % --- 【追加】ポテンシャル分布の取得 ---
        % ESP.trange から現在の時刻に対応するインデックスを探す
        idx_esp = find(ESP.trange == current_time);
        
        if isempty(idx_esp)
            % もしESPデータに該当時刻がなければNaNのままスキップ
            continue; 
        end
        
        % ポテンシャルデータのスライス (1001x50x50 -> 50x50)
        phi_t = squeeze(ESPdata2D.phi_grid(idx_esp, :, :));
        
        % --- B. 磁力線追跡 (stream2) ---
        lines = stream2(Z_grid, R_grid, Bz_t, Br_t, Z_start, R_start);
        
        if isempty(lines)
            continue; 
        end
        
        line_path = lines{1}; 
        if size(line_path, 1) < 2
            continue; 
        end
        
        Z_line = line_path(:, 1);
        R_line = line_path(:, 2);

        % --- 右端到達チェック ---
        if Z_line(end) < (Z_limit - margin)
            continue; 
        end
        
        % --- C. 線上への補間 (積分法用) ---
        br = interp2(Z_grid, R_grid, Br_t, Z_line, R_line, 'linear');
        bz = interp2(Z_grid, R_grid, Bz_t, Z_line, R_line, 'linear');
        bt = interp2(Z_grid, R_grid, Bt_t, Z_line, R_line, 'linear');
        bp = sqrt(br.^2 + bz.^2);
        
        et = interp2(Z_grid, R_grid, Et_t, Z_line, R_line, 'linear');
        er = interp2(Z_grid, R_grid, Er_t, Z_line, R_line, 'linear');
        ez = interp2(Z_grid, R_grid, Ez_t, Z_line, R_line, 'linear');
        
        % --- D. 積分計算 (Potential Gap) ---
        dZ = diff(Z_line);
        dR = diff(R_line);
        ds = sqrt(dZ.^2 + dR.^2);
        
        % Method 1: Inductive
        grad_phi_1 = (et .* bt) ./ (bp + eps);
        grad_mid_1 = (grad_phi_1(1:end-1) + grad_phi_1(2:end)) / 2;
        total_phi_1 = sum(grad_mid_1 .* ds);
        
        % Method 2: Electrostatic (via E-field projection)
        E_dot_B_pol = er .* br + ez .* bz;
        grad_phi_2 = - E_dot_B_pol ./ (bp + eps);
        grad_mid_2 = (grad_phi_2(1:end-1) + grad_phi_2(2:end)) / 2;
        total_phi_2 = sum(grad_mid_2 .* ds);
        
        % --- 【追加】Method 3: Direct Potential Difference ---
        % 始点と終点のポテンシャルを直接補間して取得
        phi_start_val = interp2(Z_grid, R_grid, phi_t, Z_line(1), R_line(1), 'linear');
        phi_end_val   = interp2(Z_grid, R_grid, phi_t, Z_line(end), R_line(end), 'linear');
        
        % ギャップ = 終点 - 始点
        % (プロット時に他のメソッドと符号を合わせるため、ここでは単純差分を取る)
        % 既存プロットは -1 * integral(E) なので、integral(grad Phi) = Delta Phi と等価
        total_phi_direct = phi_end_val - phi_start_val;

        % 結果を保存
        gap_method1(k) = total_phi_1;
        gap_method2(k) = total_phi_2;
        gap_direct(k)  = total_phi_direct; % <--- 保存
    end
    fprintf('Done.\n');

    % --- 4. 時間発展のプロット ---
    figure('Color', 'w', 'Position', [100, 100, 700, 500]);
    
    % Method 1 (Inductive E)
    plot(t_range, -1*gap_method1, 'r-o', 'LineWidth', 1.5, 'MarkerSize', 4, ...
        'DisplayName', 'Integral: E_t (Inductive)');
    hold on;
    
    % Method 2 (Electrostatic E)
    plot(t_range, -1*gap_method2, 'b-s', 'LineWidth', 1.5, 'MarkerSize', 4, ...
        'DisplayName', 'Integral: E_{pol} (Electrostatic)');
        
    % Method 3 (Direct Potential) <--- 追加
    % gap_direct は Phi_end - Phi_start。
    % 既存プロット (-1*gap_method1) は - integral(E dl) = integral(gradPhi dl) = Delta Phi
    % なので、符号はそのままプラスでプロットします。
    plot(t_range, -1.6*gap_direct, 'g-^', 'LineWidth', 2.0, 'MarkerSize', 6, ...
        'DisplayName', 'Direct: \Phi_{end} - \Phi_{start}');
    
    hold off;
    grid on;
    xlabel('Time [\mus]');
    ylabel('Potential Gap \Delta\Phi [V]');
    title(sprintf('Field-Aligned Potential Gap (Start R=%.2fm)', R_start));
    legend('Location', 'best');
    ax=gca; ax.FontSize=16;
    
    xlim([min(t_range), max(t_range)]);
end

% -------------------------------------------------------------------------
% 以下、ユーザー定義関数 (変更なし)
% -------------------------------------------------------------------------

function [E_data,B_data] = get_Epara(PCB,grid2D,data2D,ESP,ESPdata2D,t_plot)
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
    [Epara,Epara_t,E_r,E_z,E_t,B_r,B_z,B_t,phi_perp,Epara_perp,E_r_perp,E_z_perp] = deal(zeros([size(ESPdata2D.phi_mesh_r),numel(t_plot)]));
    rq_mag = grid2D.rq;zq_mag = grid2D.zq;
    rq_esp = ESPdata2D.phi_mesh_r;zq_esp = ESPdata2D.phi_mesh_z;
    drq = abs( rq_esp(1,1) - rq_esp(2,1) );
    dzq = abs( zq_esp(1,1) - zq_esp(1,2) );
    for i = 1:numel(t_plot)
        t = t_plot(i);
        idx_mag = find(data2D.trange==t);
        idx_esp = find(ESP.trange==t);
        
        % インデックスが見つからない場合のエラーハンドリングを追加すると安全です
        if isempty(idx_mag) || isempty(idx_esp), continue; end

        Bt = data2D.Bt_th(:,:,idx_mag);
        Br = data2D.Br(:,:,idx_mag);
        Bz = data2D.Bz(:,:,idx_mag);
        Et = data2D.Et(:,:,idx_mag);
        Bt_q = interp2(zq_mag,rq_mag,Bt,zq_esp,rq_esp);
        Br_q = interp2(zq_mag,rq_mag,Br,zq_esp,rq_esp);
        Bz_q = interp2(zq_mag,rq_mag,Bz,zq_esp,rq_esp);
        Et_q = interp2(zq_mag,rq_mag,Et,zq_esp,rq_esp);
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
        E_r_perp(:,:,i)=Er_perp;E_z_perp(:,:,i)=Ez_perp;
        phi_perp(rq_esp(:,1)>0.23,:,i) = 0;
    end
    E_data.Epara = Epara;E_data.Epara_perp = Epara_perp;E_data.Epara_t = Epara_t;
    E_data.Er = E_r;E_data.Ez = E_z;E_data.Et = E_t;E_data.E = E;
    E_data.Er_perp = E_r_perp;E_data.Ez_perp = E_z_perp;
    B_data.Br = B_r;B_data.Bz = B_z;B_data.Bt = B_t;B_data.B = B;
    E_data.phi_perp = phi_perp;
end

function PCB = get_PCB_data(date,shotIDX,start,dt)
    PCB.type = 1;
    PCB.doOverwrite = false;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = start-399;
    PCB.dt = dt;

    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
    T=getTS6log(DOCID);
    node='date';
    T=searchlog(T,node,date);
    IDXlist = find(T.shot==shotIDX);
    shotlist_a039 =T.a039(IDXlist);
    shotlist_a040 = T.a040(IDXlist);
    shotlist = [shotlist_a039, shotlist_a040];
    tfshotlist_a039 =T.a039_TF(IDXlist);
    tfshotlist_a040 =T.a040_TF(IDXlist);
    tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    PCB.idx = shotIDX;
    PCB.shot=shotlist;
    PCB.tfshot=tfshotlist;
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist;
    PCB.TF=TFlist;
    PCB.date = date;
end