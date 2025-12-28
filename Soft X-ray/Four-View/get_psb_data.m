clearvars -except saved_answer

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m

% --- ファイル選択 (CSV読み込み) ---
default_csv_path = fullfile('/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/', 'analysis', 'FRC_Classification_Summary.csv');
[file, path] = uigetfile('*.csv', 'Select FRC_Classification_Summary.csv', default_csv_path);
if isequal(file, 0), disp('Canceled'); return; end
csv_filepath = fullfile(path, file);

opts = detectImportOptions(csv_filepath);
opts = setvartype(opts, {'Classification'}, 'string');
T_summary = readtable(csv_filepath, opts);

% --- ログ取得 (最初に1回だけ) ---
fprintf('Loading Experiment Log (getTS6log)...\n');
DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
FullLog = getTS6log(DOCID); 

% --- 解析設定 ---
merge_start = 450;   % 合体中のJtピーク探索開始 [us]
merge_end = 485;     % 合体中のJtピーク探索終了 [us]
relax_time_def = 510; % 緩和後のヘリシティ評価時刻 [us]

n_data = height(T_summary);
peak_Jt_list = nan(n_data, 1);
final_helicity_list = nan(n_data, 1);
class_labels = strings(n_data, 1);
shot_numbers = T_summary.Shot;

fprintf('Analyzing %d shots...\n', n_data);

% === 解析ループ ===
for i = 1:n_data
    target_date = T_summary.Date(i);
    target_shot = T_summary.Shot(i); % これが "Shot番号" (例: 5, 6...)
    
    % 1. 日付でログを検索 (searchlogを使用)
    % 日付フォーマットの揺らぎ (251220 vs 20251220) を吸収
    date_short = mod(target_date, 1000000); 
    
    % まず日付で絞り込み
    T_date = searchlog(FullLog, 'date', date_short);
    
    % 2. Shot番号から a039/a040 を特定
    % T_date.shot の中から target_shot と一致する行を探す
    idx_in_log = find(T_date.shot == target_shot);
    
    if isempty(idx_in_log)
        fprintf('[Warning] Shot %d (Date %d) not found in Log. Skipping.\n', target_shot, target_date);
        continue;
    end
    
    % 先頭のヒットを使用 (通常は1つだけのはず)
    row_idx = idx_in_log(1);
    
    % --- PCB構造体の作成 ---
    PCB.date = target_date;
    
    % 【重要】Shot番号からファイル番号(a039, a040)への変換
    file_a039 = T_date.a039(row_idx);
    file_a040 = T_date.a040(row_idx);
    PCB.shot = [file_a039, file_a040]; 
    
    % TFショット情報の取得
    tf_a039 = T_date.a039_TF(row_idx);
    tf_a040 = T_date.a040_TF(row_idx);
    PCB.tfshot = [tf_a039, tf_a040];
    
    % TFショットが同じなら [0,0] (Spheromak合体など)
    if all(PCB.shot == PCB.tfshot)
        PCB.tfshot = [0,0];
    end
    
    % コイル電流情報の取得
    PCB.i_EF = T_date.EF_A_(row_idx);
    PCB.TF = T_date.TF_kV_(row_idx);
    
    % その他設定
    PCB.dataType = 1;
    PCB.chtype = 1;
    PCB.restart = 0;
    
    % --- データ読み込みと計算 ---
    try
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
        
        % 1. Jt Peak (合体中) の計算
        % 時間マスク
        t_mask = (data2D.trange >= merge_start) & (data2D.trange <= merge_end);
        
        if any(t_mask)
            Jt_slice = data2D.Jt(:, :, t_mask);
            
            % 探索領域: X点周辺 (R~0.15-0.35, Z~-0.1~0.1)
            zvals = grid2D.zq(1,:);
            rvals = grid2D.rq(:,1);
            z_mask = abs(zvals) < 0.10;
            r_mask = (rvals > 0.15) & (rvals < 0.35);
            
            Jt_roi = Jt_slice(r_mask, z_mask, :);
            
            % 絶対値の最大を取得
            peak_Jt_list(i) = max(abs(Jt_roi(:)), [], 'omitnan');
        else
            peak_Jt_list(i) = NaN;
        end
        
        % 2. Helicity (緩和後) の計算
        [~, t_idx] = min(abs(data2D.trange - relax_time_def));
        
        dr = grid2D.rq(2,1) - grid2D.rq(1,1);
        dz = grid2D.zq(1,2) - grid2D.zq(1,1);
        
        Psi = data2D.psi(:,:,t_idx);
        
        % TFショット判定
        if PCB.tfshot(1) == 0
            Bt = data2D.Bt(:,:,t_idx);
        else
            if isfield(data2D, 'Bt_th')
                Bt = data2D.Bt_th(:,:,t_idx);
            else
                Bt = data2D.Bt(:,:,t_idx);
            end
        end
        
        % ヘリシティ計算 (Separatrix内側)
        K = calc_helicity_snapshot(Psi, Bt, dr, dz, 'separatrix');
        final_helicity_list(i) = abs(K) * 1e6; % [micro Wb^2]
        
        % 分類ラベルの継承
        class_labels(i) = T_summary.Classification(i);
        
        fprintf('Shot %d: Jt=%.2f, K=%.2f -> %s\n', target_shot, peak_Jt_list(i), final_helicity_list(i), class_labels(i));
        
    catch ME
        fprintf('[Error] Shot %d process failed: %s\n', target_shot, ME.message);
        continue;
    end
end

% === 相関プロット ===
figure('Name', 'Jt vs Helicity Correlation', 'Color', 'w', 'Position', [100, 100, 900, 700]);
hold on; grid on; box on;

% グループ分け
idx_frc = class_labels == "FRC";
idx_sph = class_labels == "Spheromak";

% プロット
scatter(peak_Jt_list(idx_sph), final_helicity_list(idx_sph), 100, 'r', 'filled', ...
    'MarkerEdgeColor', 'k', 'DisplayName', 'Spheromak');
scatter(peak_Jt_list(idx_frc), final_helicity_list(idx_frc), 120, 'b', 'filled', ...
    'MarkerEdgeColor', 'k', 'DisplayName', 'FRC');

% ラベルと装飾
xlabel('Peak Toroidal Current Density J_t [MA/m^2] (Merging Phase)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Residual Magnetic Helicity [\mu Wb^2] (Relaxation Phase)', 'FontSize', 12, 'FontWeight', 'bold');
title({'Correlation: Reconnection Strength vs Helicity Dissipation', ...
       'Does stronger J_t lead to FRC formation?'}, 'FontSize', 14);

% 領域の目安ラベル
text(min(xlim), max(ylim)*0.9, '  Spheromak (Low Jt, High K)', 'Color', 'r', 'FontSize', 11, 'FontWeight', 'bold');
text(max(xlim)*0.6, min(ylim)*1.1, 'FRC (High Jt, Low K)  ', 'Color', 'b', 'FontSize', 11, 'FontWeight', 'bold');

legend('Location', 'best', 'FontSize', 12);

% データ点にShot番号を表示
for i = 1:n_data
    if ~isnan(peak_Jt_list(i)) && ~isnan(final_helicity_list(i))
        text(peak_Jt_list(i), final_helicity_list(i), sprintf('  %d', shot_numbers(i)), ...
            'FontSize', 8, 'Color', [0.4 0.4 0.4]);
    end
end


% === 関数定義 ===

function K = calc_helicity_snapshot(Psi, Bt, dr, dz, domain)
    % ヘリシティ K = 2 * int( Phi(Psi) ) dPsi
    Psi_max = max(Psi(:));
    
    if strcmp(domain, 'separatrix')
        Psi_edge = 0; % セパラトリックス内側
        if Psi_max <= 0, K = 0; return; end
    else
        Psi_edge = min(Psi(:)); % 壁まで
    end
    
    if Psi_max <= Psi_edge, K = 0; return; end
    
    n_bins = 50;
    psi_levels = linspace(Psi_edge, Psi_max, n_bins);
    Phi_vals = zeros(1, n_bins);
    flux_density = Bt * dr * dz; 
    
    for j = 1:n_bins
        mask = Psi > psi_levels(j);
        Phi_vals(j) = sum(flux_density(mask)); 
    end
    K = 2 * trapz(psi_levels, Phi_vals);
end

% ユーザー提供のログ取得関数
function [ts6log]=getTS6log(DOCID)
    loginURL = 'https://www.google.com';
    csvURL = ['https://docs.google.com/spreadsheet/ccc?key=' DOCID '&output=csv&pref=2'];
    cookieManager = java.net.CookieManager([], java.net.CookiePolicy.ACCEPT_ALL);
    java.net.CookieHandler.setDefault(cookieManager);
    handler = sun.net.www.protocol.https.Handler;
    connection = java.net.URL([],loginURL,handler).openConnection();
    connection.getInputStream();
    ts6log = webread(csvURL);
end