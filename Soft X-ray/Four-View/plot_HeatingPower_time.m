function plot_HeatingPower_time(PCB,pathname)

% shot = PCB.shot;
% trange = PCB.trange;
% start = PCB.start;

if PCB.date < 240000
    [grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
else
    [grid2D,data2D] = process_PCBdata_280ch(PCB,pathname);
end

ESP.date = 230830;
ESP.trange = 400:0.1:500;
ESPdata2D = cal_ESP(pathname,ESP);

% --- 1. 設定 ---
% r_range = [0.10, 0.18];   % rの範囲 [m]
r_range = [0.15, 0.18];   % rの範囲 [m]
z_range = [-0.05, 0.05];  % zの範囲 [m]

% 時間ステップ数の取得
% num_time_steps = size(data2D.Et, 3);
% time_indices = 1:num_time_steps; % 本来は data2D に対応する時間ベクトルがあればそれを使ってください
% num_time_steps = numel(data2D.trange);
trange=460:480;
num_time_steps = numel(trange);

[E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,trange);

rq_mag = grid2D.rq;zq_mag = grid2D.zq;
rq_esp = ESPdata2D.phi_mesh_r;zq_esp = ESPdata2D.phi_mesh_z;

% --- 2. 空間マスクの作成 ---
% grid2D.rq と grid2D.zq は同じサイズ (40x40) である前提
% 条件を満たす場所が 1 (True)、それ以外が 0 (False) となる論理配列を作成
% mask_ROI = (grid2D.rq >= r_range(1)) & (grid2D.rq <= r_range(2)) & ...
%            (grid2D.zq >= z_range(1)) & (grid2D.zq <= z_range(2));
mask_ROI = (rq_esp >= r_range(1)) & (rq_esp <= r_range(2)) & ...
           (zq_esp >= z_range(1)) & (zq_esp <= z_range(2));


% 対象となるグリッド数を表示（確認用）
fprintf('対象領域内のグリッド点数: %d / %d\n', sum(mask_ROI, 'all'), numel(mask_ROI));

% --- 3. ループ計算 ---
% 結果格納用配列
mean_EJ = zeros(1, num_time_steps);
std_EJ  = zeros(1, num_time_steps);

fprintf('計算中...');
for k = 1:num_time_steps
    % その時刻の Et と Jt を取り出す
    % Et_t = data2D.Et(:, :, k);
    % Jt_t = data2D.Jt(:, :, k);
    % idx_t_mag = find(data2D.trange==trange(k));
    % Et_t = data2D.Et(:, :, idx_t_mag);
    % Jt_t = data2D.Jt(:, :, idx_t_mag);
    % Jz_t = data2D.Jz(:, :, idx_t_mag);
    % idx_t_esp = find(ESP.trange==trange(k));
    % Ez_t = squeeze(ESPdata2D.Ez_grid(idx_t_esp,:,:));

    % Et_t = interp2(zq_mag,rq_mag,Et_t,zq_esp,rq_esp);
    % Jt_t = interp2(zq_mag,rq_mag,Jt_t,zq_esp,rq_esp);
    % Jz_t = interp2(zq_mag,rq_mag,Jz_t,zq_esp,rq_esp);
    Epara_t = E_data.Epara(:,:,k);
    Et_t = E_data.Et(:,:,k);
    Ez_t = E_data.Ez(:,:,k);
    Jt_t = B_data.Jt(:,:,k);
    Jz_t = B_data.Jz(:,:,k);
    B_t = B_data.B(:,:,k);
    Bt_t = B_data.Bt(:,:,k);
    Jpara_t = Jt_t.*Bt_t./B_t;

    
    % 加熱密度 (Power Density) = Et * Jt を計算 [W/m^3]
    % Power_t = -1 * (Et_t .* Jt_t);
    % Power_t = (Ez_t .* Jz_t);
    % Power_t = -1 * (Et_t .* Jt_t - Ez_t .* Jz_t);
    % Power_t = Epara_t.*Jpara_t;
    % Power_t = -1 .* Epara_t.*Jpara_t;
    Power_t = 1000.*Jpara_t;
    % Power_t = 1e6.*Epara_t;
    
    % マスクを使って対象領域のデータのみを抽出 (ベクトル化されます)
    vals = Power_t(mask_ROI);
    
    % 平均と標準偏差を計算 (NaNが含まれる場合に備えて omitnan を使用)
    mean_EJ(k) = mean(vals, 'all', 'omitnan');
    std_EJ(k)  = std(vals, 0, 'all', 'omitnan');
end
fprintf(' 完了。\n');

% --- 4. プロット (エラーバー付き) ---
figure('Color', 'w');

% エラーバーでプロット
% データ点数が多い(400点)場合、エラーバーが重なって見づらくなるため、
% CapSizeを小さくしたり、マーカーを省略したりして調整します。
% errorbar(data2D.trange, mean_EJ, std_EJ, '-', ...
%     'LineWidth', 1.5, ...
%     'Color', '#D95319', ...        % 色 (赤系)
%     'CapSize', 0, ...              % エラーバーの横棒のサイズ (0ですっきりさせる)
%     'Marker', 'none');             % 点が多いのでマーカーなし
errorbar(trange, mean_EJ, std_EJ, '-', ...
    'LineWidth', 1.5, ...
    'Color', '#D95319', ...        % 色 (赤系)
    'CapSize', 0, ...              % エラーバーの横棒のサイズ (0ですっきりさせる)
    'Marker', 'none');             % 点が多いのでマーカーなし

grid on;
xlabel('Time [us]'); % 時間ベクトルがあれば 'Time [s]' などに変更
ylabel('$E_\parallel \cdot J_\parallel [W/m^3]$','Interpreter','latex'); % 単位はデータのスケールに合わせてください
% title(sprintf('Mean E_\parallel \\cdot J_\parallel (r:%.2f-%.2f, z:%.2f-%.2f)', ...
    % r_range(1), r_range(2), z_range(1), z_range(2)));
xlim([460 480]);
% 軸のフォントサイズ調整
ax = gca;
ax.FontSize = 14;


% =========================================================================
%  1. 設定
% =========================================================================
% データファイル設定
target_date = 251218;
base_dir = getenv('PROBE_DATA_DIR'); % 環境変数が設定されていない場合は適宜書き換えてください
if isempty(base_dir)
    % 環境変数がない場合の仮パス (必要に応じて変更してください)
    base_dir = '/Path/To/Your/Data'; 
end
filepath_triple = fullfile(base_dir, 'tripleProbe', [num2str(target_date), '.mat']);

% 解析パラメータ
r_range = [0.15, 0.18];  % 解析対象の半径範囲 [m]
xlim_range = [460, 480]; % プロットする時間範囲 [us]
smooth_span = 5;         % 微分前の平滑化スパン (ノイズ対策)

% 定数
e_charge = 1.60217663e-19; % 素電荷 [C] (J/eV)

% =========================================================================
%  2. データのロードと抽出
% =========================================================================
if exist(filepath_triple, 'file')
    fprintf('Loading: %s\n', filepath_triple);
    load(filepath_triple, 'triple_data2D', 'R_values', 'time_values');
else
    error('File not found: %s', filepath_triple);
end

% データの取り出し
% triple_data2D.Te, .ne の構造が [Radial, 1, Time] であると仮定
Te_all = squeeze(triple_data2D.Te(:, 1, :)); % [eV]
ne_all = squeeze(triple_data2D.ne(:, 1, :)); % [m^-3]

% 指定した半径範囲 (ROI) のインデックスを特定
idx_roi = find(R_values >= r_range(1) & R_values <= r_range(2));

if isempty(idx_roi)
    error('指定された半径範囲にデータがありません。');
end

% ROI内のデータのみ抽出 [空間 x 時間]
Te_roi = Te_all(idx_roi, :);
ne_roi = ne_all(idx_roi, :);

% =========================================================================
%  3. 物理量の計算 (エネルギー密度と加熱パワー)
% =========================================================================
% 3.1 内部エネルギー密度 We [J/m^3] の計算
% We = (3/2) * ne * Te * e
We_roi = 1.5 .* (ne_roi .* Te_roi) .* e_charge;

% 3.2 加熱パワー密度 dWe/dt [W/m^3] の計算
% 時間刻み [s]
dt_seconds = mean(diff(time_values)) * 1e-6; 

% 結果格納用
HeatingPower_roi = zeros(size(We_roi));

% 各空間点ごとに時間微分を実行
for k = 1:size(We_roi, 1)
    raw_trace = We_roi(k, :);
    
    % ノイズ低減: 微分前に移動平均で平滑化
    smooth_trace = smoothdata(raw_trace, 'movmean', smooth_span);
    
    % 時間微分 (gradient)
    HeatingPower_roi(k, :) = gradient(smooth_trace, dt_seconds);
end

% =========================================================================
%  4. 統計処理 (空間平均と標準偏差)
% =========================================================================
% 空間方向(1次元目)に対して平均と標準偏差を計算
Power_mean = mean(HeatingPower_roi, 1, 'omitnan');
Power_std  = std(HeatingPower_roi, 0, 1, 'omitnan');

% プロット用のシェーディング領域計算
curve_upper = Power_mean + Power_std;
curve_lower = Power_mean - Power_std;
inBetween   = [curve_upper, fliplr(curve_lower)];
x_fill      = [time_values, fliplr(time_values)];

% =========================================================================
%  5. プロット
% =========================================================================
fig = figure('Name', 'Electron Heating Power', 'Color', 'w', 'Position', [150, 150, 700, 500]);

hold on;

% 1. エラーバー (標準偏差の帯)
h_fill = fill(x_fill, inBetween, [0.8500, 0.3250, 0.0980], ...
    'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'Spatial Std');

% 2. ゼロライン (加熱/冷却の境界)
yline(0, '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 1.5, 'HandleVisibility', 'off');

% 3. 平均値の線
h_line = plot(time_values, Power_mean, '-', ...
    'LineWidth', 2, 'Color', [0.8500, 0.3250, 0.0980], ...
    'DisplayName', 'Spatial Mean');

hold off;

% 装飾
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
ylabel('Heating Power Density dW_e/dt [W/m^3]', 'FontSize', 14);
title(sprintf('Electron Heating Power (r = %.2f - %.2f m)', r_range(1), r_range(2)), 'FontSize', 14);

xlim(xlim_range);

% Y軸の見栄え調整（絶対値の最大値を基準にする）
valid_idx = time_values >= xlim_range(1) & time_values <= xlim_range(2);
max_val = max(abs(curve_upper(valid_idx)), [], 'all', 'omitnan');
if ~isnan(max_val) && max_val > 0
    ylim([-max_val*1.2, max_val*1.2]);
end

legend([h_line, h_fill], 'Location', 'best');
ax = gca;
ax.FontSize = 16;
ax.LineWidth = 1.2;

fprintf('Processing Complete.\n');

figure;hold on;
% errorbar(data2D.trange, -1*mean_EJ, std_EJ, '-', ...
%     'LineWidth', 1.5, ...
%     'Color', '#D95319', ...        % 色 (赤系)
%     'CapSize', 0, ...              % エラーバーの横棒のサイズ (0ですっきりさせる)
%     'Marker', 'none');
h_jE = errorbar(trange, mean_EJ, std_EJ, '-', ...
    'LineWidth', 1.5, ...
    'Color', '#D95319', ...        % 色 (赤系)
    'CapSize', 0, ...              % エラーバーの横棒のサイズ (0ですっきりさせる)
    'Marker', 'none', ...
    'DisplayName', 'J・E');

% h_fill = fill(x_fill, inBetween, [0.8500, 0.3250, 0.0980], ...
%     'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
%     'DisplayName', 'Spatial Std');
% h_line = plot(time_values, Power_mean, '-', ...
%     'LineWidth', 2, 'Color', [0.8500, 0.3250, 0.0980], ...
%     'DisplayName', 'Spatial Mean');
h_fill = fill(x_fill, inBetween, [0, 0.4470, 0.7410], ...
    'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
    'DisplayName', 'Spatial Std');
h_line = plot(time_values, Power_mean, '-', ...
    'LineWidth', 2, 'Color', [0, 0.4470, 0.7410], ...
    'DisplayName', 'd(neTe)');
legend([h_jE,h_line],'Location','best');
ax = gca;
ax.FontSize = 16;
ax.LineWidth = 1.2;
% 装飾
grid on;
xlabel('Time [\mus]', 'FontSize', 14);
ylabel('Heating Power Density dW_e/dt [W/m^3]', 'FontSize', 14);
xlim([460 480]);
end

function [E_data,B_data] = get_Epara(grid2D,data2D,ESP,ESPdata2D,t_plot)
    a=1.6;n=4;
    ER1 = ESPdata2D.Er_grid.*a;
    ER2 = ER1;
    ER2(:,:,1:50-n) = ER1(:,:,1+n:50);
    ER2(:,:,50-n+1:50) = repmat(ER1(:,:,50),1,1,n);
    ESPdata2D.Er_grid = ER2;
    EZ1 = ESPdata2D.Ez_grid.*a;
    EZ2 = EZ1;
    EZ2(:,:,1:50-n) = EZ1(:,:,1+n:50);
    EZ2(:,:,50-n+1:50) = repmat(EZ1(:,:,50),1,1,n);
    ESPdata2D.Ez_grid = EZ2;

    [Epara,Epara_t,E_r,E_z,E_t,B_r,B_z,B_t,J_t,J_z,phi_perp,Epara_perp,B_size] = deal(zeros([size(ESPdata2D.phi_mesh_r),numel(t_plot)]));
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
        Jz = data2D.Jz(:,:,idx_mag);
        Bt_q = interp2(zq_mag,rq_mag,Bt,zq_esp,rq_esp);
        Br_q = interp2(zq_mag,rq_mag,Br,zq_esp,rq_esp);
        Bz_q = interp2(zq_mag,rq_mag,Bz,zq_esp,rq_esp);
        Et_q = interp2(zq_mag,rq_mag,Et,zq_esp,rq_esp);
        Jt_q = interp2(zq_mag,rq_mag,Jt,zq_esp,rq_esp);
        Jz_q = interp2(zq_mag,rq_mag,Jz,zq_esp,rq_esp);
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
        J_t(:,:,i)=Jt_q;J_z(:,:,i)=Jz_q;
        B_size(:,:,i) = sqrt(dot(B,B,3));
        phi_perp(rq_esp(:,1)>0.23,:,i) = 0;
    end
    E_data.Epara = Epara;E_data.Epara_perp = Epara_perp;E_data.Epara_t = Epara_t;
    E_data.Er = E_r;E_data.Ez = E_z;E_data.Et = E_t;E_data.E = E;
    B_data.Br = B_r;B_data.Bz = B_z;B_data.Bt = B_t;B_data.B = B_size;
    B_data.Jt = J_t;B_data.Jz = J_z;
    E_data.phi_perp = phi_perp;
end