function [] = plot_acceleration(ESP,ESPdata2D,pathname)

addpath(fullfile(pathname.github,'test-open','Soft X-ray','Four-View'));
PCB = get_PCB_data(240111,30,455,1);
% PCB = get_PCB_data(240827,13,460,2);
% PCB = get_PCB_data(240828,16,460,2);
% PCB = get_PCB_data(240828,32,468,1);
% PCB = get_PCB_data(230830,32,455,1);

% [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);

t_plot_idx = PCB.start:PCB.dt:PCB.start+PCB.dt*31;
t_plot = PCB.trange(t_plot_idx);
% legendList = arrayfun(@(x) sprintf('%dus', x), t_plot, 'UniformOutput', false);
% legendList = {'465us','468us','470us'};

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
[E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot);

%% トカマク合体 加速メカニズム比較解析（エネルギー利得率換算）

% --- 0. 比較のための物理パラメータ設定（ここを調整してください） ---
% どの粒子を、どのくらいのエネルギーで評価するかを決めます
target_species = 'electron'; % 'electron' or 'ion'
Temp_eV = 10;               % 想定する粒子の温度 (eV)
B_scale = 1.0;               % 磁場データの単位がTeslaでない場合のスケーリング係数
E_scale = 1.0;               % 電場データの単位がV/mでない場合のスケーリング係数

% 物理定数 (SI単位)
e_charge = 1.602e-19;
if strcmp(target_species, 'electron')
    mass = 9.109e-31;
    q = -e_charge; % 電子の場合はドリフト方向が逆になるが、エネルギー利得(E.v)の符号は正負ありうる
else
    mass = 1.672e-27; % プロトンと仮定
    q = e_charge;
end

% 代表速度 (熱速度 v_th) の計算
% W = 1/2 m v^2 = T_eV * e_charge  =>  v = sqrt(2 * T_eV * e / m)
v_th = sqrt(2 * Temp_eV * e_charge / mass);

fprintf('評価条件: %s (%.1f eV), v_th = %.2e m/s\n', target_species, Temp_eV, v_th);


% --- 1. データの準備（前回と同様） ---
target_t = 467;
target_t_idx = find(t_plot==target_t); % 任意の時刻
R = ESPdata2D.phi_mesh_r; 
Z = ESPdata2D.phi_mesh_z;
dr = R(2,1) - R(1,1);
dz = Z(1,2) - Z(1,1);

% データ抽出と単位合わせ
Br = B_data.Br(:, :, target_t_idx) * B_scale;
Bz = B_data.Bz(:, :, target_t_idx) * B_scale;
Bt = B_data.Bt(:, :, target_t_idx) * B_scale;
Er = E_data.Er(:, :, target_t_idx) * E_scale;
Ez = E_data.Ez(:, :, target_t_idx) * E_scale;
Et = E_data.Et(:, :, target_t_idx) * E_scale;
E_para = E_data.Epara(:,:,target_t_idx) * E_scale;

% 磁場強度と単位ベクトル
B_mag = sqrt(Br.^2 + Bz.^2 + Bt.^2);
B_mag(B_mag < 1e-6) = 1e-6; % ゼロ除算防止
br = Br ./ B_mag; bz = Bz ./ B_mag; bt = Bt ./ B_mag;

% --- 2. 微分量の計算 (修正版) ---
% データ構造が (r, z) = (行, 列) であるため、
% gradient関数の仕様 [d/dx(列), d/dy(行)] に合わせて引数と戻り値を逆に設定します。

% |B| の微分
[dAbsB_dz, dAbsB_dr] = gradient(B_mag, dz, dr);

% 単位ベクトル b の各成分の微分
[dbr_dz, dbr_dr] = gradient(br, dz, dr);
[dbz_dz, dbz_dr] = gradient(bz, dz, dr);
[dbt_dz, dbt_dr] = gradient(bt, dz, dr);


% --- 3. エネルギー利得率 (Power [eV/s]) の計算 ---
% ここで全ての項を [eV/s] の次元に統一します。
% Power = q * v . E  (これを eV単位にするため e_charge で割る)

% (A) 平行加速: P_para = q * v_para * E_para
% 仮定: v_para ~ v_th (熱速度で平行方向に走っている粒子を想定)
% E_para = Er.*br + Ez.*bz + Et.*bt;
Power_Para = (q * v_th * E_para) / e_charge; % [eV/s]
% ※ qの符号により加速/減速が変わります。絶対値で比較したい場合は abs() を取ります。

% (B) Fermi加速 (Curvature Drift): P_fermi = q * v_curv . E
% v_curv = (m v_para^2 / q B) * (b x kappa)
% 仮定: v_para^2 ~ v_th^2
kappa_r = (br.*dbr_dr + bz.*dbr_dz) - (bt.^2) ./ R;
kappa_t = (br.*dbt_dr + bz.*dbt_dz) + (br.*bt) ./ R;
kappa_z = (br.*dbz_dr + bz.*dbz_dz);

% ベクトル積 (b x kappa) ※前回の B x kappa と異なり b を使うので係数注意
bxk_r = bz .* kappa_t - bt .* kappa_z;
bxk_t = bt .* kappa_r - br .* kappa_t;
bxk_z = br .* kappa_z - bz .* kappa_r;

v_curv_coeff = (mass * v_th^2) ./ (q * B_mag);
Power_Fermi = (q * (v_curv_coeff .* bxk_r .* Er + ...
                    v_curv_coeff .* bxk_t .* Et + ...
                    v_curv_coeff .* bxk_z .* Ez)) / e_charge; % [eV/s]

% (C) Betatron加速 (Grad-B Drift): P_beta = q * v_gradB . E
% v_gradB = (m v_perp^2 / 2 q B) * (b x \nabla B / B)
% 仮定: v_perp^2 ~ v_th^2
% ベクトル積 (b x \nabla B)
bxG_r = bz .* 0        - bt .* dAbsB_dz;
bxG_t = bt .* dAbsB_dr - br .* 0;
bxG_z = br .* dAbsB_dz - bz .* dAbsB_dr;

v_gradB_coeff = (mass * v_th^2) ./ (2 * q * B_mag.^2);
Power_Betatron = (q * (v_gradB_coeff .* bxG_r .* Er + ...
                       v_gradB_coeff .* bxG_t .* Et + ...
                       v_gradB_coeff .* bxG_z .* Ez)) / e_charge; % [eV/s]


%% --- 追加パート: Z範囲平均 (z=-0.02 ~ 0.02) の径方向分布 (エラーバー付き) ---

% 1. 平均するZ範囲の設定
z_range_min = -0.02;
z_range_max = 0.02;

% 2. 範囲内のインデックスを特定
% Z座標は2次元目(列方向)に変化すると仮定 (Z(1, :) を参照)
z_vec = Z(1, :);
z_indices = find(z_vec >= z_range_min & z_vec <= z_range_max);

% エラーハンドリング
if isempty(z_indices)
    warning('指定された範囲内にグリッドが存在しません。最も近い点を使用します。');
    [~, z_indices] = min(abs(z_vec)); % 0に近い1点
end

fprintf('平均化範囲: Z = [%.4f, %.4f] m (index: %d - %d, point数: %d)\n', ...
    z_vec(z_indices(1)), z_vec(z_indices(end)), z_indices(1), z_indices(end), length(z_indices));

% 3. 統計量の計算関数 (平均と標準偏差)
% data は (r, z) 配列。
% 指定された z_indices (列) を抽出して、dim=2 (横方向) に平均を取ります。
calc_mean = @(data) mean(data(:, z_indices), 2, 'omitnan');
calc_std  = @(data) std(data(:, z_indices), 0, 2, 'omitnan');

% (A) 加速項の統計計算
m_Para = calc_mean(Power_Para); s_Para = calc_std(Power_Para);
m_Fermi = calc_mean(Power_Fermi); s_Fermi = calc_std(Power_Fermi);
m_Beta = calc_mean(Power_Betatron); s_Beta = calc_std(Power_Betatron);

% (B) 平行電場の統計計算
m_Epara = calc_mean(E_para); s_Epara = calc_std(E_para);

% r軸 (行方向なので R(:,1) を使用)
r_axis = R(:, 1); 

%% --- 4. プロット (2軸表示: yyaxis) ---
figure('Name', 'Dual-Axis Acceleration Profile', 'Position', [150, 150, 1000, 600]);

% X軸データ
x = r_axis;

% === 左軸 (yyaxis left): 平行電場加速 ===
yyaxis left
% プロット (赤色系)
eb1 = errorbar(x, m_Para, s_Para, '-o', 'Color', 'r', ...
    'LineWidth', 1.5, 'MarkerSize', 4, 'CapSize', 0, 'MarkerFaceColor', 'r');
hold on;
% 左軸のゼロライン (赤の破線)
yline(0, 'r--', 'LineWidth', 1, 'Alpha', 0.6, 'HandleVisibility', 'off');

ylabel('Parallel Power Density [eV/s]', 'FontSize', 12);
set(gca, 'YColor', 'r'); % 軸の色を赤に設定
ylim auto; % 自動スケール


% === 右軸 (yyaxis right): Fermi & Betatron ===
yyaxis right
% プロット (Fermi: 青, Betatron: 緑)
eb2 = errorbar(x, m_Fermi, s_Fermi, '-s', 'Color', 'b', ...
    'LineWidth', 1.5, 'MarkerSize', 4, 'CapSize', 0, 'MarkerFaceColor', 'b');
hold on;
eb3 = errorbar(x, m_Beta, s_Beta, '-^', 'Color', [0 0.5 0], ... % 濃い緑
    'LineWidth', 1.5, 'MarkerSize', 4, 'CapSize', 0, 'MarkerFaceColor', [0 0.5 0]);

% 右軸のゼロライン (黒の破線)
yline(0, 'k--', 'LineWidth', 1, 'Alpha', 0.6, 'HandleVisibility', 'off');

ylabel('Fermi / Betatron Power Density [eV/s]', 'FontSize', 12);
set(gca, 'YColor', 'k'); % 軸の色を黒（中立）に設定
% ylim auto; % 自動スケール
ylim([-6e5 6e5]);


% === 共通設定 ===
title(sprintf('Z-Averaged Power Density (Z \\in [%.2f, %.2f] m)', z_range_min, z_range_max));
xlabel('Radius R [m]', 'FontSize', 12);
grid on;
% xlim([min(x), max(x)]);
xlim([min(x), 0.25]);

% 凡例 (左右どちらの軸か明記すると親切です)
legend([eb1, eb2, eb3], ...
    {'Parallel (Left Axis)', 'Fermi (Right Axis)', 'Betatron (Right Axis)'}, ...
    'Location', 'best', 'FontSize', 18);

hold off;
ax=gca;ax.FontSize=18;

end

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

function PCB = get_PCB_data(date,shotIDX,start,dt)
    PCB.type = 1;
    PCB.doOverwrite = false;
    PCB.trange = 400:800;
    PCB.n = 40;
    PCB.start = start-399;
    PCB.dt = dt;

    % date = 230828;shotIDX=41;
    % date = 230830;shotIDX=37;
    % date = 240111;shotIDX=29;
    % date = 240828;shotIDX=5;
    % date = 250314;shotIDX=55;
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