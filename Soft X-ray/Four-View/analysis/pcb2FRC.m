clearvars -except saved_answer

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m

% --- ファイル選択 ---
default_csv_path = fullfile(pwd, 'analysis', 'FRC_Classification_Summary.csv');
[file, path] = uigetfile('*.csv', 'Select FRC_Classification_Summary.csv', default_csv_path);
if isequal(file, 0), disp('Canceled'); return; end
csv_filepath = fullfile(path, file);

% CSV読み込み
opts = detectImportOptions(csv_filepath);
opts = setvartype(opts, {'Classification'}, 'string');
T_summary = readtable(csv_filepath, opts);

% --- ログ取得 ---
fprintf('Loading Experiment Log (getTS6log)...\n');
DOCID = '1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
FullLog = getTS6log(DOCID); 

% === PCB構造体 共通設定 ===
PCB.n = 40;              
PCB.trange = 300:600;    
PCB.dt = 1;              
PCB.start = 60;          
PCB.dataType = 1;        
PCB.chtype = 1;          
PCB.restart = 0;         
PCB.doCheck = 0;         

% --- 解析パラメータ ---
merge_start = 450;   
merge_end = 485;     
relax_time_def = 510; 

n_data = height(T_summary);
ratio_JtEt_list = nan(n_data, 1);
final_helicity_list = nan(n_data, 1);
% 色付け用のデータ (Mean Ratio)
mean_ratio_list = T_summary.Mean_Ratio; 
shot_numbers = T_summary.Shot;

fprintf('Analyzing %d shots...\n', n_data);

% === 解析ループ ===
for i = 1:n_data
    target_date = T_summary.Date(i);
    target_shot = T_summary.Shot(i);
    
    % 1. 日付でログを検索
    date_short = mod(target_date, 1000000); 
    T_date = searchlog(FullLog, 'date', date_short);
    
    if isempty(T_date) || isempty(T_date.shot)
         fprintf('[Warning] Log not found for Date %d. Skipping Shot %d.\n', target_date, target_shot);
         continue;
    end

    idx_in_log = find(T_date.shot == target_shot);
    
    if isempty(idx_in_log)
        fprintf('[Warning] Shot %d (Date %d) not found in Log. Skipping.\n', target_shot, target_date);
        continue;
    end
    
    row_idx = idx_in_log(1);
    
    % --- PCB設定 ---
    PCB.date = target_date;
    PCB.idx = target_shot;
    PCB.shot = [T_date.a039(row_idx), T_date.a040(row_idx)];
    PCB.tfshot = [T_date.a039_TF(row_idx), T_date.a040_TF(row_idx)];
    if all(PCB.shot == PCB.tfshot)
        PCB.tfshot = [0,0];
    end
    PCB.i_EF = T_date.EF_A_(row_idx);
    PCB.TF = T_date.TF_kV_(row_idx);
    
    % --- データ処理 ---
    try
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
        
        % 1. Jt/Et Calculation
        t_mask = (data2D.trange >= merge_start) & (data2D.trange <= merge_end);
        
        if any(t_mask)
            Jt_slice = data2D.Jt(:, :, t_mask);
            Et_slice = data2D.Et(:, :, t_mask);
            
            zvals = grid2D.zq(1,:); rvals = grid2D.rq(:,1);
            z_mask = abs(zvals) < 0.10;
            r_mask = (rvals > 0.15) & (rvals < 0.35);
            
            Jt_roi = Jt_slice(r_mask, z_mask, :);
            Et_roi = Et_slice(r_mask, z_mask, :);
            
            [max_Jt_val, max_linear_idx] = max(abs(Jt_roi(:)));
            Et_at_peak = abs(Et_roi(max_linear_idx));
            
            if Et_at_peak < 1e-3
                ratio_val = NaN; 
            else
                ratio_val = max_Jt_val / Et_at_peak; 
            end
            ratio_JtEt_list(i) = ratio_val;
        else
            ratio_JtEt_list(i) = NaN;
        end
        
        % 2. Helicity Calculation
        [~, t_idx] = min(abs(data2D.trange - relax_time_def));
        dr = grid2D.rq(2,1) - grid2D.rq(1,1);
        dz = grid2D.zq(1,2) - grid2D.zq(1,1);
        
        Psi = data2D.psi(:,:,t_idx);
        if PCB.tfshot(1) == 0
            Bt = data2D.Bt(:,:,t_idx);
        else
            if isfield(data2D, 'Bt_th')
                Bt = data2D.Bt_th(:,:,t_idx);
            else
                Bt = data2D.Bt(:,:,t_idx);
            end
        end
        
        K = calc_helicity_snapshot(Psi, Bt, dr, dz, 'separatrix');
        final_helicity_list(i) = abs(K) * 1e6; 
        
        fprintf('Shot %d: Jt/Et=%.2e, K=%.2f, Ratio=%.3f\n', target_shot, ratio_JtEt_list(i), final_helicity_list(i), mean_ratio_list(i));
        
    catch ME
        fprintf('[Error] Shot %d process failed: %s\n', target_shot, ME.message);
        continue;
    end
end

% === グラデーション散布図の作成 ===
figure('Name', 'Conductivity vs Helicity (Colored by Ratio)', 'Color', 'w', 'Position', [100, 100, 950, 750]);
hold on; grid on; box on;

% Scatter Plot with Color mapping
% X: Jt/Et, Y: Helicity, Size: 120, Color: Mean_Ratio
scatter(ratio_JtEt_list, final_helicity_list, 150, mean_ratio_list, 'filled', 'MarkerEdgeColor', 'k');

% カラーバーの設定
cb = colorbar;
cb.Label.String = 'Mean Ratio |B_{t,axis}| / B_{p,max}';
cb.Label.FontSize = 12;
colormap turbo; % 視認性の良いカラーマップ

% カラーレンジの調整
% 0に近いほどFRC、値が大きいほどSpheromak。
% 0.5以上はすべて「強いSpheromak」として同じ色で飽和させた方が、0.1~0.2の違いが見やすい。
clim([0 0.5]); 

% 軸ラベル
xlabel('Apparent Conductivity J_t / E_t [S/m] (at Peak Current)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Residual Magnetic Helicity [\mu Wb^2] (Relaxation Phase)', 'FontSize', 12, 'FontWeight', 'bold');
title({'Correlation Colored by FRC-ness', ...
       'Blue/Green = FRC-like (Low Ratio), Red = Spheromak-like (High Ratio)'}, 'FontSize', 14);

% 領域の目安ラベル
text(min(xlim), max(ylim)*0.9, '  High Resistivity & FRC-like?', 'Color', 'b', 'FontSize', 11);
text(max(xlim)*0.6, min(ylim)*1.1, 'Low Resistivity & Spheromak-like?  ', 'Color', 'r', 'FontSize', 11, 'HorizontalAlignment', 'right');

% データ点ラベル
for i = 1:n_data
    if ~isnan(ratio_JtEt_list(i)) && ~isnan(final_helicity_list(i))
        text(ratio_JtEt_list(i), final_helicity_list(i), sprintf('  %d', shot_numbers(i)), ...
            'FontSize', 8, 'Color', [0.4 0.4 0.4]);
    end
end

% === 関数定義 ===

function K = calc_helicity_snapshot(Psi, Bt, dr, dz, domain)
    Psi_max = max(Psi(:));
    if strcmp(domain, 'separatrix')
        Psi_edge = 0;
        if Psi_max <= 0, K = 0; return; end
    else
        Psi_edge = min(Psi(:));
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