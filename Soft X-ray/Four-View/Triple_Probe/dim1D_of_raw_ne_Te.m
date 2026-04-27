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
% filepath = "/Users/shohgookazaki/Documents/UTokyo/OnoTanabeLab/koala/home/pub/mnt/data/TripleProbe";
filepath = "/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/triple_probe/raw_data";

filename = strcat(filepath, '/', num2str(date), '/ES_', num2str(date), shotnum, '.csv');

% ファイルの読み込み
filename = char(strtrim(filename));
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

% 1次元プロットの直前で補間を適用 (一時変数に格納して元データは保持)
Te_line = fillmissing(Te_values, 'linear');
ne_line = fillmissing(ne_values, 'linear');

% subplot(3,1,2) と subplot(3,1,3) の scatter を plot に変更



% plot
figure;
sgtitle('Triple probe data of Ar ST')

subplot(3,1,1)
hold on;
plot(time, I2_values);
plot(time, I3_values);
legend({['I2 (V_p=', num2str(V2), 'V)'], ['I3 (V_p=', num2str(V3), 'V)']})
ylabel('Probe current [A]')
xlim([475, 490])
ylim([-1 5]);
hold off
grid on

% subplot(3,1,2)
% scatter(time, Te_values / K2ev, 5, "black");
% % plot(time, Te_values/K2ev)
% xlim([475, 490]);
% ylim([0 20]);
% ylabel('Te [eV]')
% grid on
subplot(3,1,2)
plot(time, Te_line / K2ev, '-k', 'LineWidth', 1); % 補間済みデータを線でプロット
xlim([475, 490]); ylim([0 20]); ylabel('Te [eV]'); grid on;

% subplot(3,1,3)
% scatter(time, ne_values, 3, "black");
% xlim([475, 490]);
% ylim([0 2e20]);
% xlabel('time [us]')
% ylabel('ne [m^{-3}]')
% grid on
subplot(3,1,3)
plot(time, ne_line, '-k', 'LineWidth', 1); % 補間済みデータを線でプロット
xlim([475, 490]); ylim([0 2e20]); xlabel('time [us]'); ylabel('ne [m^{-3}]'); grid on;

mkdir(strcat(save_filepath, '/', num2str(date), '/figure/triple_probe'));
saveas(gcf, strcat(save_filepath, '/', num2str(date), '/figure/triple_probe/', shotnum, '_', num2str(index_start), '-', num2str(index_end), 'us'), 'png');
fprintf("saved your file %s", shotnum)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ランキスト数 (Lundquist Number) の計算
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 注意: "Rankist" は一般的ではないため、プラズマ物理で一般的なルンドキスト数(S)として計算します。
% S = tau_R / tau_A = (mu_0 * L * V_A) / eta

% --- ユーザー設定パラメータ (環境に合わせて変更してください) ---
B_field = 0.004;   % 磁場強度 [T] (例: 0.1 T)
L_char  = 0.1;  % 代表長さ [m] (例: プラズマ半径やシート幅 5cm)
lnLambda = 10;   % クーロン対数 (通常 10-15 程度)
Z_eff = 1;       % 実効電荷数

% --- 定数定義 ---
mu0 = 4 * pi * 1e-7; % 真空の透磁率

% 1. 温度を eV 単位に変換 (Spitzer抵抗率の計算用)
% 既存コードの Te_values は Kelvin です
Te_eV = Te_values / K2ev; 

% 2. アルベン速度 (V_A) の計算
% V_A = B / sqrt(mu0 * ni * mi)
rho_mass = ne_values * mi; % 質量密度 (ni ~ ne と仮定)
Va_values = B_field ./ sqrt(mu0 * rho_mass);

% 3. Spitzer 抵抗率 (eta) の計算
% eta_parallel approx 5.2e-5 * Z * lnLambda / Te[eV]^(3/2) [Ohm m]
% Teが極端に低い、またはNaNの場合は計算エラーになるため注意
eta_values = (5.2e-5 * Z_eff * lnLambda) ./ (Te_eV .^ 1.5);

% 4. ルンドキスト数 (S) の計算
% S = mu0 * L * Va / eta
S_values = (mu0 * L_char .* Va_values) ./ eta_values;

% 異常値の処理 (NaN や Inf, 負の値を排除)
S_values(isinf(S_values) | S_values < 0) = NaN;

% --- プロット (新規Figure) ---
figure;
scatter(time, S_values, 5, 'filled');
title(['Lundquist Number (S) : B=' num2str(B_field) 'T, L=' num2str(L_char) 'm']);
xlabel('Time [\mus]');
ylabel('Lundquist Number S');
xlim([450, 500]); % 時間軸は既存コードに合わせる
grid on;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 電子熱圧力 (Electron Thermal Pressure) の計算
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 目的: ショック形成の証拠となる圧力ジャンプ(Delta P)を確認する
% 式: P_e = n_e * k_B * T_e [Pa]

% Te_values は既存コードで [K] になっています
% ne_values は [m^-3] です
% kb は [J/K] です

% 1. 圧力計算 [Pa]
Pe_values = ne_values .* kb .* Te_values;

% 2. 異常値の除去 (負の値やNaN)
Pe_values(Pe_values < 0) = NaN;

% --- プロット (新規Figure) ---
figure('Name', 'Electron Thermal Pressure');
plot(time, Pe_values, 'LineWidth', 1.5, 'Color', [0.85 0.33 0.1]); % 赤茶色っぽい色
title(['Electron Thermal Pressure P_e : Shot ' num2str(shotnum)]);
xlabel('Time [\mus]');
ylabel('Electron Pressure [Pa]');
xlim([450, 500]); % 既存のプロット範囲に合わせる
grid on;

% --- 簡易解析: 圧力上昇量の表示 ---
% ベースライン（立ち上がり前）とピークの差分を表示
% ※ 時間範囲は波形を見て適宜調整してください
try
    % 仮に460us付近をベース、470-490usをピーク領域と仮定
    base_idx = (time >= 455 & time <= 465);
    peak_idx = (time >= 465 & time <= 490);
    
    if any(base_idx) && any(peak_idx)
        P_base = mean(Pe_values(base_idx), 'omitnan');
        P_peak = max(Pe_values(peak_idx), [], 'omitnan');
        Delta_P = P_peak - P_base;
        
        fprintf('--- Electron Pressure Analysis ---\n');
        fprintf('Base Pressure (approx): %.2f Pa\n', P_base);
        fprintf('Peak Pressure:          %.2f Pa\n', P_peak);
        fprintf('Pressure Increase (dP): %.2f Pa\n', Delta_P);
        fprintf('Compression Ratio:      %.2f\n', P_peak / P_base);
        fprintf('----------------------------------\n');
    end
catch
    disp('圧力の自動解析に失敗しました（時間範囲等がデータと合わない可能性があります）');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ドライサー電場 (Dreicer Field) の計算
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 目的: Runaway加速が起こりうるか判定する (E_rec > E_D ?)
% 式: E_D = (n_e * e^3 * lnLambda) / (4 * pi * eps0^2 * k_B * T_e)
% 簡略式 (Te in eV): E_D approx 3.1e-13 * n_e * lnLambda / Te[eV] [V/m]

% % --- 定数 ---
% lnLambda_Dreicer = 10; % クーロン対数（通常10程度）

% % 1. Te を eV に変換 (既存のTe_valuesはKelvin)
% Te_eV_for_Ed = Te_values / K2ev;

% % 2. ドライサー電場計算 [V/m]
% % Teが0に近いと発散するので、極小値でクリップするかNaN処理
% valid_Te_mask = (Te_eV_for_Ed > 0.1); % 0.1eV以下は計算しない

% Ed_values = nan(size(Te_values));
% Ed_values(valid_Te_mask) = 2.6e-17 * ne_values(valid_Te_mask) * lnLambda_Dreicer ./ Te_eV_for_Ed(valid_Te_mask);

eps0 = 8.85418781e-12; % 真空の誘電率 [F/m]

% 1. 動的なクーロン対数 ln(Lambda) の計算
% Te_valuesはKelvin。1160K(0.1eV)以下や密度0以下はエラー回避のため除外
valid_mask = (Te_values > 1160) & (ne_values > 0); 

lambda_D = nan(size(Te_values));
% 資源節約: eps0 * kb 等の定数乗算をまとめても良いが、可読性のためそのままベクトル計算
lambda_D(valid_mask) = sqrt((eps0 * kb .* Te_values(valid_mask)) ./ (ne_values(valid_mask) * q^2));

Lambda = nan(size(Te_values));
Lambda(valid_mask) = (4*pi/3) .* (lambda_D(valid_mask).^3) .* ne_values(valid_mask);
lnLambda_dyn = log(Lambda);

% 2. ドライサー電場計算 [V/m]
% 画像の式 m_e * v_Te^2 は標準理論の k_B * T_e に等しいため、直接 kb*Te を使用して計算コスト削減
const_Ed = q^3 / (4 * pi * eps0^2 * kb); 
Ed_values = nan(size(Te_values));
Ed_values(valid_mask) = const_Ed .* ne_values(valid_mask) .* lnLambda_dyn(valid_mask) ./ Te_values(valid_mask);

%%%%%%%%%%%%%%%%%%Etを計算する
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m

% --- 基本設定 ---
doCheck = 0;
dataType = 1;
PCB.chtype = 1;


shotnum = inputdlg(prompt, dlgtitle, dims, definput);
shotnum = str2double(shotnum{1});
IDXlist = shotnum;
PCB.restart = 0;
xaxis = 2;
xpointdata = 1;

PCB.xpointdata = xpointdata;

% === プロット範囲設定 ===
PCB.trange = 400:600;
PCB.n = 40;
PCB.start = 450; 
PCB.end = 490;
FIG.start = 460;
FIG.end = 500;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
T=getTS6log(DOCID);
T=searchlog(T,'date',date);

if isnan(T.shot(1))
    T(1, :) = [];
end

n_data = numel(IDXlist);
shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
EFlist = T.EF_A_(IDXlist);
TFlist = T.TF_kV_(IDXlist);

% データ格納用
all_data = zeros(n_data,numel(PCB.trange));
all_merging_ratios = zeros(n_data, numel(PCB.trange));

% Et/Jt計算用の一時保存配列
all_data_Et_raw = zeros(n_data, numel(PCB.trange));
all_data_Jt_raw = zeros(n_data, numel(PCB.trange));

% 3種同時プロット用
all_data_Et = zeros(n_data, numel(PCB.trange));
all_data_Jt = zeros(n_data, numel(PCB.trange));
all_data_Curv = zeros(n_data, numel(PCB.trange));

disp('Getting coeff')
file_id = '1izM2mY1kjGAxIqMIXwhyzw1iuuMF3k5VXFJqi9Sy2U4';
    url = sprintf('https://docs.google.com/spreadsheets/d/%s/export?format=xlsx', file_id);
    
% 一時ファイルとしてダウンロード (計算資源節約のため websave を使用)
temp_file = 'temp_coeff.xlsx';
options = weboptions('Timeout', 30);
websave(temp_file, url, options);
% --- 既存のロジック (ファイル名を temp_file に変更) ---
sheets = sheetnames(temp_file);
sheets = str2double(sheets);
    
% 外部情報の参照と乖離の指摘（日付形式の確認）
% 一般的な形式(YYMMDD)を想定していますが、桁数が異なるとロジックが破綻するため確認推奨

sheet_date = max(sheets(sheets <= date));
    
% 指定シートを読み込み
PCB.C = readmatrix(temp_file, 'Sheet', num2str(sheet_date));
delete(temp_file); % ダウンロードした一時ファイルを削除

% === データ処理ループ ===
for i=1:n_data
    PCB.date = date;
    PCB.idx = IDXlist(i);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    PCB.dataType = dataType;
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.TF=TFlist(i);
    
    if doCheck
        check_signal(PCB, pathname);
    else
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
        merging_ratio = get_merging_ratio(data2D, grid2D, PCB.trange);
        
        % --- データ取得 ---
        if PCB.xpointdata == 2 % Et/Jt (Ratio of Averages)
            % EtとJtを個別に取得
            pcb_temp = PCB;
            
            % Et取得 (Option 1)
            pcb_temp.xpointdata = 1;
            all_data_Et_raw(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            
            % Jt取得 (Option 5 -> 生の値)
            pcb_temp.xpointdata = 5;
            all_data_Jt_raw(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            
            % ダミー
            all_data(i,:) = all_data_Et_raw(i,:); 

        elseif PCB.xpointdata == 7 % All (Et, Jt, Curv, Et/Jt)
            pcb_temp = PCB; 
            % 1. Et
            pcb_temp.xpointdata = 1;
            all_data_Et(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            % 2. Jt
            pcb_temp.xpointdata = 5;
            all_data_Jt(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            % 3. Curvature
            pcb_temp.xpointdata = 6;
            all_data_Curv(i,:) = xpointplot(grid2D, data2D, pcb_temp);
            
            all_data(i,:) = all_data_Et(i,:);
        else
            all_data(i,:) = xpointplot(grid2D, data2D, PCB);
        end

        mask = (PCB.trange >= FIG.start) & (PCB.trange <= FIG.end);
        merging_ratio(~mask) = NaN; 
        all_merging_ratios(i, :) = merging_ratio; 
    end
end

if true
    % === 統計処理 ===
    qmerge = prctile(all_merging_ratios, [10 90],1);
    iqrmerge = qmerge(2,:)-qmerge(1,:);
    filtered_merge = all_merging_ratios;
    filtered_merge(filtered_merge < qmerge(1,:)-1.5*iqrmerge | filtered_merge > qmerge(2,:)+1.5*iqrmerge) = NaN;
    mean_merging_ratio = mean(filtered_merge, 1, 'omitnan');
    stderr_merging_ratio = std(filtered_merge, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(filtered_merge), 1));
    
    if xpointdata == 2
        % === Et/Jt (Ratio of Averages) ===
        mean_Et_raw = mean(all_data_Et_raw, 1, 'omitnan');
        mean_Jt_raw = mean(all_data_Jt_raw, 1, 'omitnan');
        
        all_mean_data = (mean_Et_raw ./ mean_Jt_raw) * 1e3;
        
        % 誤差伝播
        ste_Et = std(all_data_Et_raw, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Et_raw), 1));
        ste_Jt = std(all_data_Jt_raw, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Jt_raw), 1));
        
        rel_err_Et = ste_Et ./ abs(mean_Et_raw);
        rel_err_Jt = ste_Jt ./ abs(mean_Jt_raw);
        stderr_mean = abs(all_mean_data) .* sqrt(rel_err_Et.^2 + rel_err_Jt.^2);
        
    elseif xpointdata == 7
        % === All Plot (Et, Jt, Curv, Et/Jt) ===
        mean_Et = mean(all_data_Et, 1, 'omitnan');
        mean_Jt = mean(all_data_Jt, 1, 'omitnan');
        mean_Curv = mean(all_data_Curv, 1, 'omitnan');
        
        % Et/Jt の計算 (Option 2と同じロジック)
        mean_Res = (mean_Et ./ mean_Jt) * 1e3;
        
        err_Et = std(all_data_Et, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Et),1));
        err_Jt = std(all_data_Jt, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Jt),1));
        err_Curv = std(all_data_Curv, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data_Curv),1));
        
        % Et/Jt の誤差伝播
        rel_err_Et = err_Et ./ abs(mean_Et);
        rel_err_Jt = err_Jt ./ abs(mean_Jt);
        err_Res = abs(mean_Res) .* sqrt(rel_err_Et.^2 + rel_err_Jt.^2);
        
        all_mean_data = mean_Et; 
        stderr_mean = err_Et;
    else
        all_mean_data = mean(all_data,1,'omitnan');
        stderr_mean = std(all_data, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_data),1));
    end
    
    t = PCB.trange; 
    % === プロット描画 ===
    
    if xpointdata == 7
        range_idx = (PCB.trange >= PCB.start) & (PCB.trange <= PCB.end);
        if xaxis == 1, x_plot = mean_merging_ratio(range_idx); x_lim = [0 100]; x_label_str='Merging ratio [%]';
        elseif xaxis == 2, x_plot = PCB.trange(range_idx); x_lim = [PCB.start PCB.end]; x_label_str='time [s]'; end
        
        % データ準備
        y1 = mean_Et(range_idx); e1 = err_Et(range_idx);       % Et (Black)
        y2 = mean_Jt(range_idx); e2 = err_Jt(range_idx);       % Jt (Red)
        y3 = mean_Curv(range_idx); e3 = err_Curv(range_idx);   % Curv (Blue)
        y4 = mean_Res(range_idx); e4 = err_Res(range_idx);     % Et/Jt (Green)
        
        fig = figure('Units', 'pixels', 'Position', [100 100 1100 600], 'Color', 'w');
        
        % --- 軸位置の定義 ---
        % メインのプロットエリアを少し狭くして、右側に軸を入れるスペースを作る
        % [left bottom width height]
        ax_pos = [0.10 0.15 0.60 0.75]; 
        
        % --- Axis 1: Et (Left, Black) ---
        ax1 = axes('Position', ax_pos, 'YColor', 'k', 'Box', 'off', 'Color', 'none'); hold(ax1, 'on');
        if xaxis == 2
            fill_y = [-1e9 1e9]; 
            % patch([475 483 483 475], [fill_y(1) fill_y(1) fill_y(2) fill_y(2)], ...
            %       [0.85 0.92 1], 'EdgeColor', 'none', 'Parent', ax1, 'HandleVisibility', 'off');
        end
        plot_shaded_error(x_plot, y1, e1, [0.6 0.6 0.6], 0.3, ax1);
        plot(ax1, x_plot, y1, '.-k', 'LineWidth', 1.2, 'MarkerSize', 10);
        set(ax1, 'Layer', 'top'); 
        ylabel(ax1, 'Et [V/m]', 'FontSize', 12, 'FontWeight', 'bold');
        xlabel(ax1, x_label_str, 'FontSize', 12); grid(ax1, 'on'); ylim(ax1, [-350 350]); 
        
        % --- Axis 2: Jt (Right, Red) ---
        ax2 = axes('Position', ax_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', 'r', 'Box', 'off'); hold(ax2, 'on');
        plot_shaded_error(x_plot, y2, e2, [1 0.7 0.7], 0.3, ax2);
        plot(ax2, x_plot, y2, '.-r', 'LineWidth', 1.2, 'MarkerSize', 10);
        ylabel(ax2, 'Jt [MA/m^2]', 'FontSize', 12, 'FontWeight', 'bold'); ylim(ax2, [-1e6 1e6]); 
        
        % --- Axis 3: Curvature (Right+, Blue) ---
        % ax2の右隣に配置
        ax3_pos = ax_pos; 
        ax3_pos(1) = ax_pos(1) + ax_pos(3) + 0.06; % メイン軸の右端から少し離す
        ax3_pos(3) = 1e-5; % 幅はほぼゼロ
        
        % ダミー軸（プロット用）
        ax3_plot = axes('Position', ax_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', 'b', 'Box', 'off', 'Visible', 'off'); hold(ax3_plot, 'on');
        plot_shaded_error(x_plot, y3, e3, [0.7 0.7 1], 0.3, ax3_plot);
        plot(ax3_plot, x_plot, y3, '.-b', 'LineWidth', 1.2, 'MarkerSize', 10);
        ylim(ax3_plot, [0 150]); 
        
        % 目盛り表示用軸
        ax3_scale = axes('Position', ax3_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', 'b', 'Box', 'off');
        ylabel(ax3_scale, 'Curvature [m^{-1}]', 'FontSize', 12, 'FontWeight', 'bold');
        ylim(ax3_scale, [0 150]);

        % --- Axis 4: Et/Jt (Right++, Green) ---
        % ax3のさらに右隣に配置
        ax4_pos = ax3_pos;
        ax4_pos(1) = ax3_pos(1) + 0.08; % ax3からさらに右へずらす
        
        % ダミー軸（プロット用）
        ax4_plot = axes('Position', ax_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', [0 0.5 0], 'Box', 'off', 'Visible', 'off'); hold(ax4_plot, 'on');
        plot_shaded_error(x_plot, y4, e4, [0.7 1 0.7], 0.3, ax4_plot);
        plot(ax4_plot, x_plot, y4, '.-', 'Color', [0 0.5 0], 'LineWidth', 1.2, 'MarkerSize', 10);
        ylim(ax4_plot, [-4 4]); 

        % 目盛り表示用軸
        ax4_scale = axes('Position', ax4_pos, 'YAxisLocation', 'right', 'Color', 'none', 'XColor', 'none', 'YColor', [0 0.5 0], 'Box', 'off');
        ylabel(ax4_scale, 'Et/Jt [m\Omega m]', 'FontSize', 12, 'FontWeight', 'bold');
        ylim(ax4_scale, [-4 4]);

        % リンクの設定
        linkaxes([ax1, ax2, ax3_plot, ax4_plot], 'x'); 
        xlim(ax1, x_lim);
        
        title(ax1, ['Shot: ', num2str(date)]); hold off;
        
    else
        % --- 単一プロットモード (Et/Jt を含む) ---
        x_plot = mean_merging_ratio; 
        E_rec_estimate = all_mean_data;
        
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ---------------- 修正ここから ----------------
% 3. プロット作成
figure('Name', 'Dreicer Field Check');
hold on;

% 左軸: ドライサー電場 (時間軸は time)
plot(time, Ed_values, 'LineWidth', 1.5, 'Color', 'b', 'DisplayName', 'Dreicer Field E_D');

% 計測された再結合電場 Et をプロット (時間軸は PCB.trange)
% yline ではなく通常の plot を使用する
plot(PCB.trange, abs(E_rec_estimate), 'r-', 'LineWidth', 2, 'DisplayName', 'Reconnection Field E_t');

ylabel('Electric Field [V/m]');
title(['Electric Field E_D vs E_t (Shot ' num2str(shotnum) ')']);
xlabel('Time [\mus]');
xlim([475, 490]);
legend('show', 'Location', 'best');
grid on;
hold off;

% --- Runaway 判定 ---
% E_D < E_rec となる領域があるかチェック
runaway_indices = (Ed_values < E_rec_estimate);
if any(runaway_indices)
    fprintf('!!! Runaway Condition Met (E_rec > E_D) !!!\n');
    fprintf('Possible Runaway Times: %.1f - %.1f us\n', min(time(runaway_indices)), max(time(runaway_indices)));
else
    fprintf('Runaway condition NOT met with E_rec = %.1f V/m\n', E_rec_estimate);
end



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





function plot_shaded_error(x, y, err, color, alpha, ax)
    x = x(:)'; y = y(:)'; err = err(:)';
    y_upper = y + err;
    y_lower = y - err;
    x_poly = [x, fliplr(x)];
    y_poly = [y_upper, fliplr(y_lower)];
    mask = ~isnan(x_poly) & ~isnan(y_poly);
    if any(mask)
        fill(ax, x_poly(mask), y_poly(mask), color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
    end
end

function set_ylabel(xpointdata)
    if xpointdata == 1
        ylim([-350 350]);
        ylabel('Et [V/m]');
    elseif xpointdata == 2
        ylim([-4 4])
        ylabel('Et/Jt [m\Omega m]')
    elseif xpointdata == 4
        ylabel('dEt/dt [V/m/s]');
    elseif xpointdata == 5
        ylabel('Jt [MA/m^2]'); 
        ylim([-4 4])
    elseif xpointdata == 6
        ylabel('Curvature [m^{-1}]');
    end
end