function plot_phi_parallel(ESP,ESPdata2D,pathname)

t_plot = 468;

PCB = get_PCB_data(240111,27,465,2); %磁場計算に必要なデータの取得
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname); %磁場データ＋座標データの計算
[E_data,B_data] = get_Epara(PCB,grid2D,data2D,ESP,ESPdata2D,t_plot); %磁場と電場のグリッドを揃える

% Z_grid = grid2D.zq;
% R_grid = grid2D.rq;
Z_grid = ESPdata2D.phi_mesh_z;
R_grid = ESPdata2D.phi_mesh_r;
Bz_data = B_data.Bz;
Br_data = B_data.Br;
Bt_data = B_data.Bt;
Ez_data = E_data.Ez;
Er_data = E_data.Er;
Et_data = E_data.Et;

% 前提: Z_grid, R_grid, Bz_data, Br_data, Ez_data, Er_data は既に用意されている

% -----------------------------------------------------------
% 1. 新しいソース項 (E_parallel_p) の計算
% -----------------------------------------------------------
% ポロイダル磁場強度 Bp
Bp_data = sqrt(Br_data.^2 + Bz_data.^2);

% ゼロ除算回避のための微小値
epsilon = 1e-10; 

% ベクトルの内積 (Er*Br + Ez*Bz) を Bp で割って射影成分を出す
% これが磁力線平行方向の電場 E_para です
E_para_data = (Er_data .* Br_data + Ez_data .* Bz_data) ./ (Bp_data + epsilon);

% -----------------------------------------------------------
% 2. 磁力線追跡 (stream2)
% -----------------------------------------------------------
Z_start = min(Z_grid(:));
R_start = 0.15;

% 磁力線追跡
lines = stream2(Z_grid, R_grid, Bz_data, Br_data, Z_start, R_start);
line_path = lines{1}; % 1本だけ取り出す

% 磁力線上の座標
Z_line = line_path(:, 1);
R_line = line_path(:, 2);

% -----------------------------------------------------------
% 3. 磁力線に沿って各物理量を補間
% -----------------------------------------------------------
% 磁場
br = interp2(Z_grid, R_grid, Br_data, Z_line, R_line, 'linear');
bz = interp2(Z_grid, R_grid, Bz_data, Z_line, R_line, 'linear');
bt = interp2(Z_grid, R_grid, Bt_data, Z_line, R_line, 'linear');
bp = sqrt(br.^2 + bz.^2);

% 電場
et = interp2(Z_grid, R_grid, Et_data, Z_line, R_line, 'linear');
er = interp2(Z_grid, R_grid, Er_data, Z_line, R_line, 'linear');
ez = interp2(Z_grid, R_grid, Ez_data, Z_line, R_line, 'linear');

% -----------------------------------------------------------
% 4. 勾配の計算と積分
% -----------------------------------------------------------
% 距離 ds
dZ = diff(Z_line);
dR = diff(R_line);
ds = sqrt(dZ.^2 + dR.^2);

% --- 方法1: Et と Bt から推定 (Ideal MHD assumption) ---
% 以前の式: dPhi/ds = (Et * Bt) / Bp
grad_phi_1 = (et .* bt) ./ (bp + eps);
grad_phi_1_mid = (grad_phi_1(1:end-1) + grad_phi_1(2:end)) / 2;
Phi_1 = [0; cumsum(grad_phi_1_mid .* ds)];

% --- 方法2: Ez と Er から直接計算 (Direct Integration) ---
% 式: dPhi/ds = - E_para_pol = - (Er*Br + Ez*Bz) / Bp
% 内積計算
E_dot_B_pol = er .* br + ez .* bz;
grad_phi_2 = - E_dot_B_pol ./ (bp + eps);

grad_phi_2_mid = (grad_phi_2(1:end-1) + grad_phi_2(2:end)) / 2;
Phi_2 = [0; cumsum(grad_phi_2_mid .* ds)];

% -----------------------------------------------------------
% 5. 結果の比較プロット
% -----------------------------------------------------------
figure('Color', 'w', 'Position', [100, 100, 800, 600]);

% 上段: ポテンシャル分布の比較
subplot(2, 1, 1);
plot(Z_line, Phi_1, 'r', 'LineWidth', 2, 'DisplayName', 'Method 1: from Et, Bt (Inductive)');
hold on;
plot(Z_line, Phi_2, 'b--', 'LineWidth', 2, 'DisplayName', 'Method 2: from Er, Ez (Poloidal E)');
hold off;
title(['Potential Integration Comparison (Start R=', num2str(R_start), 'm)']);
ylabel('Potential \phi (V)');
legend('Location', 'best');
grid on;
xlim([min(Z_line), max(Z_line)]);

% 下段: 局所的な電場(勾配)の比較
subplot(2, 1, 2);
plot(Z_line, grad_phi_1, 'r', 'LineWidth', 1.5, 'DisplayName', '(Et Bt)/Bp');
hold on;
plot(Z_line, grad_phi_2, 'b--', 'LineWidth', 1.5, 'DisplayName', '-(Er Br + Ez Bz)/Bp');

% 差分(= 平行電場 E_para) を塗りつぶしで表示
% E_para * B / Bp のような成分に相当
difference = grad_phi_1 - grad_phi_2; 
area(Z_line, difference, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none', ...
    'DisplayName', 'Difference (\propto E_{||})');

hold off;
title('Local Gradient Comparison (d\phi/ds)');
xlabel('Toroidal Coordinate Z (m)');
ylabel('Electric Field (V/m)');
legend('Location', 'best');
grid on;
xlim([min(Z_line), max(Z_line)]);

end

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
        Bt = data2D.Bt_th(:,:,idx_mag);
        % Bt = 0.6*data2D.Bt_th(:,:,idx_mag);
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

    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
    T=getTS6log(DOCID);
    node='date';
    % date=230714;
    T=searchlog(T,node,date);
    IDXlist = find(T.shot==shotIDX);
    % IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
    % n_data=numel(IDXlist);%計測データ数
    shotlist_a039 =T.a039(IDXlist);
    shotlist_a040 = T.a040(IDXlist);
    shotlist = [shotlist_a039, shotlist_a040];
    tfshotlist_a039 =T.a039_TF(IDXlist);
    tfshotlist_a040 =T.a040_TF(IDXlist);
    tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    % dtacqlist=39.*ones(n_data,1);
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