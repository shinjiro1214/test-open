clearvars -except saved_answer Results_Table

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

run define_path.m

% --- 解析パラメータ設定 ---
time_initial = 430;   % [us] 合体前 (初期状態)
merge_start = 450;    % [us] 合体中 (Jtピーク探索開始)
merge_end = 485;      % [us] 合体中 (Jtピーク探索終了)
relax_time_def = 510; % [us] 緩和後 (最終状態)

% PCB共通設定
PCB.n = 40;              
PCB.trange = 300:600;    
PCB.dt = 1;              
PCB.start = 60;          
PCB.dataType = 1;        
PCB.chtype = 1;          
PCB.restart = 0;         
PCB.doCheck = 0; 

% =========================================================================
%  データ計算パート
% =========================================================================

reuse_data = false;
if exist('Results_Table', 'var') && ~isempty(Results_Table)
    % 既存テーブルにフィールドが足りているかチェック
    if ismember('Peak_Jt', Results_Table.Properties.VariableNames)
        choice = questdlg('計算済みのデータ(Results_Table)があります。再利用しますか？', ...
            'データ再利用', 'はい (プロットのみ)', 'いいえ (再計算)', 'はい (プロットのみ)');
        if strcmp(choice, 'はい (プロットのみ)'), reuse_data = true; end
    end
end

if ~reuse_data
    % ファイル選択
    default_csv_path = fullfile(pwd, 'analysis', 'FRC_Classification_Summary.csv');
    [file, path] = uigetfile('*.csv', 'Select FRC_Classification_Summary.csv', default_csv_path);
    if isequal(file, 0), disp('Canceled'); return; end
    csv_filepath = fullfile(path, file);

    opts = detectImportOptions(csv_filepath);
    opts = setvartype(opts, {'Classification'}, 'string');
    T_summary = readtable(csv_filepath, opts);
    
    % ログ取得
    fprintf('Loading Experiment Log (getTS6log)...\n');
    DOCID = '1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
    FullLog = getTS6log(DOCID); 
    
    n_data = height(T_summary);
    
    % テーブル初期化 (全パラメータ格納用)
    Results_Table = T_summary;
    Results_Table.TF_kV = nan(n_data, 1);
    Results_Table.Init_Helicity = nan(n_data, 1);
    Results_Table.Init_Bt_Max = nan(n_data, 1);
    Results_Table.Peak_Jt = nan(n_data, 1);
    Results_Table.Peak_Et = nan(n_data, 1);
    Results_Table.Peak_Cond = nan(n_data, 1); % Jt/Et
    Results_Table.Res_Helicity = nan(n_data, 1);
    
    fprintf('Analyzing %d shots...\n', n_data);

    for i = 1:n_data
        target_date = T_summary.Date(i);
        target_shot = T_summary.Shot(i);
        
        % ログ検索
        date_short = mod(target_date, 1000000); 
        T_date = searchlog(FullLog, 'date', date_short);
        if isempty(T_date) || isempty(T_date.shot)
             fprintf('[Skip] Log not found for Date %d.\n', target_date); continue;
        end
        idx_in_log = find(T_date.shot == target_shot);
        if isempty(idx_in_log)
            fprintf('[Skip] Shot %d not found in Log.\n', target_shot); continue;
        end
        row_idx = idx_in_log(1);
        
        % PCB設定
        PCB.date = target_date;
        PCB.idx = target_shot; 
        PCB.shot = [T_date.a039(row_idx), T_date.a040(row_idx)];
        PCB.tfshot = [T_date.a039_TF(row_idx), T_date.a040_TF(row_idx)];
        if all(PCB.shot == PCB.tfshot), PCB.tfshot = [0,0]; end
        PCB.i_EF = T_date.EF_A_(row_idx);
        PCB.TF = T_date.TF_kV_(row_idx);
        
        Results_Table.TF_kV(i) = PCB.TF;

        try
            [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
            dr = grid2D.rq(2,1) - grid2D.rq(1,1);
            dz = grid2D.zq(1,2) - grid2D.zq(1,1);
            
            % --- 1. 合体前 (Initial) ---
            [~, t_init_idx] = min(abs(data2D.trange - time_initial));
            Psi_init = data2D.psi(:,:,t_init_idx);
            if PCB.tfshot(1) == 0, Bt_init = data2D.Bt(:,:,t_init_idx);
            else, if isfield(data2D, 'Bt_th'), Bt_init = data2D.Bt_th(:,:,t_init_idx); else, Bt_init = data2D.Bt(:,:,t_init_idx); end; end
            
            K_init = calc_helicity_snapshot(Psi_init, Bt_init, dr, dz, 'full'); 
            Results_Table.Init_Helicity(i) = abs(K_init) * 1e6;
            Results_Table.Init_Bt_Max(i) = max(abs(Bt_init(:)));
            
            % --- 2. 合体中 (Merging Process) ---
            t_mask = (data2D.trange >= merge_start) & (data2D.trange <= merge_end);
            if any(t_mask)
                Jt_slice = data2D.Jt(:, :, t_mask);
                Et_slice = data2D.Et(:, :, t_mask);
                
                % X点周辺マスク
                zvals = grid2D.zq(1,:); rvals = grid2D.rq(:,1);
                z_mask = abs(zvals) < 0.10;
                r_mask = (rvals > 0.15) & (rvals < 0.35);
                Jt_roi = Jt_slice(r_mask, z_mask, :);
                Et_roi = Et_slice(r_mask, z_mask, :);
                
                [max_Jt, idx_max] = max(abs(Jt_roi(:)));
                Et_at_peak = abs(Et_roi(idx_max));
                
                Results_Table.Peak_Jt(i) = max_Jt;
                Results_Table.Peak_Et(i) = Et_at_peak;
                if Et_at_peak > 1e-3
                    Results_Table.Peak_Cond(i) = max_Jt / Et_at_peak;
                end
            end
            
            % --- 3. 緩和後 (Residual) ---
            [~, t_res_idx] = min(abs(data2D.trange - relax_time_def));
            Psi_res = data2D.psi(:,:,t_res_idx);
            if PCB.tfshot(1) == 0, Bt_res = data2D.Bt(:,:,t_res_idx);
            else, if isfield(data2D, 'Bt_th'), Bt_res = data2D.Bt_th(:,:,t_res_idx); else, Bt_res = data2D.Bt(:,:,t_res_idx); end; end
            
            K_res = calc_helicity_snapshot(Psi_res, Bt_res, dr, dz, 'separatrix');
            Results_Table.Res_Helicity(i) = abs(K_res) * 1e6;
            
            fprintf('Shot %d: Jt=%.1f, Jt/Et=%.1f, K_res=%.1f\n', target_shot, Results_Table.Peak_Jt(i), Results_Table.Peak_Cond(i), Results_Table.Res_Helicity(i));
            
        catch ME
            fprintf('[Error] Shot %d: %s\n', target_shot, ME.message);
            continue;
        end
    end
end

% =========================================================================
%  インタラクティブ・プロット (全パラメータ選択可能)
% =========================================================================
create_interactive_plot(Results_Table);


% === ローカル関数 ===

function create_interactive_plot(Results)
    fig = figure('Name', 'Multi-Parameter Correlation Analysis', 'Color', 'w', ...
                 'Position', [100, 100, 1000, 700], 'NumberTitle', 'off');
    
    ax = axes('Parent', fig, 'Position', [0.1, 0.25, 0.85, 0.7]);
    grid(ax, 'on'); box(ax, 'on'); hold(ax, 'on');
    
    % 選択可能なパラメータ一覧
    param_map = {
        'TF_kV',         'TF Voltage [kV] (Input)';
        'Init_Helicity', 'Initial Helicity [\mu Wb^2] (Input)';
        'Init_Bt_Max',   'Max Bt [T] (Input)';
        'Peak_Jt',       'Peak Jt [MA/m^2] (Process)';
        'Peak_Et',       'Peak Et [V/m] (Process)';
        'Peak_Cond',     'Conductivity Jt/Et [S/m] (Process)';
        'Res_Helicity',  'Residual Helicity [\mu Wb^2] (Output)';
        'Mean_Ratio',    'Mean Ratio |Bt|/Bp (Output)';
    };
    
    bg = uibuttongroup('Parent', fig, 'Position', [0.1, 0.02, 0.85, 0.15], ...
                       'Title', 'Plot Axes', 'BackgroundColor', 'w');
                   
    uicontrol(bg, 'Style', 'text', 'String', 'X-Axis:', ...
              'Position', [20, 50, 60, 20], 'BackgroundColor', 'w', 'HorizontalAlignment', 'right');
    x_popup = uicontrol(bg, 'Style', 'popupmenu', 'String', param_map(:,2), ...
              'Position', [90, 50, 250, 25], 'Value', 6); % Default: Jt/Et

    uicontrol(bg, 'Style', 'text', 'String', 'Y-Axis:', ...
              'Position', [360, 50, 60, 20], 'BackgroundColor', 'w', 'HorizontalAlignment', 'right');
    y_popup = uicontrol(bg, 'Style', 'popupmenu', 'String', param_map(:,2), ...
              'Position', [430, 50, 250, 25], 'Value', 8); % Default: Mean Ratio
          
    set(x_popup, 'Callback', @update_cb);
    set(y_popup, 'Callback', @update_cb);
    
    function update_cb(~, ~)
        x_idx = x_popup.Value; y_idx = y_popup.Value;
        x_col = param_map{x_idx, 1}; y_col = param_map{y_idx, 1};
        x_data = Results.(x_col); y_data = Results.(y_col);
        
        cla(ax); hold(ax, 'on');
        idx_frc = Results.Classification == "FRC";
        idx_sph = Results.Classification == "Spheromak";
        
        scatter(ax, x_data(idx_frc), y_data(idx_frc), 120, 'b', 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'FRC');
        scatter(ax, x_data(idx_sph), y_data(idx_sph), 100, 'r', 'filled', 'MarkerEdgeColor', 'k', 'DisplayName', 'Spheromak');
        
        xlabel(ax, param_map{x_idx, 2}, 'FontSize', 12, 'FontWeight', 'bold');
        ylabel(ax, param_map{y_idx, 2}, 'FontSize', 12, 'FontWeight', 'bold');
        title(ax, [param_map{y_idx, 2} ' vs ' param_map{x_idx, 2}], 'FontSize', 14);
        legend(ax, 'Location', 'best', 'FontSize', 12); grid(ax, 'on');
        
        for k = 1:height(Results)
            if ~isnan(x_data(k)) && ~isnan(y_data(k))
                text(ax, x_data(k), y_data(k), sprintf('  %d', Results.Shot(k)), 'FontSize', 8, 'Color', [0.5 0.5 0.5], 'Interpreter', 'none');
            end
        end
    end
    update_cb();
end

function K = calc_helicity_snapshot(Psi, Bt, dr, dz, domain)
    Psi_max = max(Psi(:));
    if strcmp(domain, 'separatrix')
        Psi_edge = 0;
    else
        Psi_edge = min(Psi(:)); 
    end
    
    if Psi_max <= Psi_edge
        K = 0; return; 
    end
    
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