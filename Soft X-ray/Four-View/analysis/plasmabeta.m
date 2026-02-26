clearvars -except saved_answer

% =========================================================
%  Path & Setup
% =========================================================
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/';
addpath '/Users/shohgookazaki/Documents/MATLAB/inputsdlg_v2.3.2'
addpath '/Users/shohgookazaki/Documents/matlab/common';

% トリプルプローブデータのパス
tp_filepath_base = "/Users/shohgookazaki/Library/CloudStorage/GoogleDrive-shohgo-okazaki@g.ecc.u-tokyo.ac.jp/My Drive/OnoLab/data/ElectroStatic/triple_probe/raw_data";

run define_path.m

% =========================================================
%  User Inputs
% =========================================================
name = 'Plasma Beta Calculation Input';
prompt = {'Date:', 'Shot number:', 'Probe R [m]:', 'Probe Z [m]:', 'Restart:', 'Check Raw Sig:'};
formats = struct('type', {}, 'style', {}, 'items', {}, 'format', {}, 'limits', {}, 'size', {});

if exist('saved_answer', 'var')
    defaultanswer = saved_answer;
else
    defaultanswer = {[], '', 0.375, 0.0, 1, 1}; 
end

formats(1,1).type = 'edit'; formats(1,1).format = 'integer'; formats(1,1).size = [100 20];
formats(2,1).type = 'edit'; formats(2,1).format = 'text';    formats(2,1).size = [100 20];
formats(3,1).type = 'edit'; formats(3,1).format = 'float';   formats(3,1).size = [100 20];
formats(4,1).type = 'edit'; formats(4,1).format = 'float';   formats(4,1).size = [100 20];
formats(5,1).type = 'list'; formats(5,1).style = 'popupmenu'; formats(5,1).items = {'false', 'true'};
formats(6,1).type = 'list'; formats(6,1).style = 'popupmenu'; formats(6,1).items = {'false', 'true'};

[answer, canceled] = inputsdlg(prompt, name, formats);
if isempty(answer) || canceled, return; end

date = answer{1};
IDXlist = str2num(answer{2});
ProbeR = answer{3};
ProbeZ = answer{4};
PCB.restart = answer{5}-1;
doCheck = answer{6}-1;
saved_answer = answer;

% PCBパラメータ
dataType = 1;
PCB.chtype = 1;
PCB.trange = 400:600; 
PCB.n = 40;
PCB.start = 450; 
PCB.end = 490;
PCB.xpointdata = 1; % ダミー

% TS6ログ取得
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

% 結果格納用
all_beta = zeros(n_data, numel(PCB.trange));
all_Pe = zeros(n_data, numel(PCB.trange));
all_Pmag = zeros(n_data, numel(PCB.trange));

% =========================================================
%  Main Loop
% =========================================================
for i=1:n_data
    % --- 1. PCB Data Processing ---
    PCB.date = date;
    PCB.idx = IDXlist(i);
    PCB.shot = shotlist(i,:);
    PCB.tfshot = tfshotlist(i,:);
    PCB.dataType = dataType;
    if PCB.shot == PCB.tfshot, PCB.tfshot = [0,0]; end
    PCB.i_EF = EFlist(i);
    PCB.TF = TFlist(i);
    
    if doCheck
        check_signal(PCB, pathname);
        continue;
    end
    
    fprintf('Processing Shot: %d (PCB) / ', PCB.shot(1));
    
    % ここは既存のまま
    [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);
    
    % --- 2. Triple Probe Data Processing ---
    if IDXlist(i) < 10
        shotnum_str = ['00', num2str(IDXlist(i))];
    else
        shotnum_str = ['0', num2str(IDXlist(i))];
    end
    fprintf('%s (Probe)\n', shotnum_str);
    
    % プローブファイルの読み込み
    tp_filename = strcat(tp_filepath_base, '/', num2str(date), '/ES_', num2str(date), shotnum_str, '.csv');
    
    try
        test = readmatrix(tp_filename);
        
        index_start = 4500;
        index_end = 7500;
        V2 = 30; V3 = 15;
        A = 39.95; 
        S_probe = 1.4e-5;
        q = 1.60217663e-19;
        kb = 1.380649e-23;
        K2ev = 11604.5250061657;
        mi = A * 1.66054e-27;
        
        I2_values = test(index_start:index_end, 36);
        I3_values = test(index_start:index_end, 37);
        time_probe = test(index_start:index_end, 1);
        
        % LUT法 Te, ne
        window_size = 50; 
        I2_values = smoothdata(I2_values, 'movmean', window_size);
        I3_values = smoothdata(I3_values, 'movmean', window_size);
        I1_values = I2_values + I3_values;
        
        current_threshold = 0.05; 
        valid_indices = (I2_values > current_threshold) & (I3_values > current_threshold);
        
        Te_range = 0.1:0.05:150; 
        RHS_table = (1 - exp(-q*V2./(kb*Te_range*K2ev)))./(1 - exp(-q*V3./(kb*Te_range*K2ev)));
        [RHS_table, unique_idx] = unique(RHS_table);
        Te_lookup = Te_range(unique_idx) * K2ev; 
        
        LHS_data = (I1_values + I2_values) ./ (I1_values + I3_values);
        min_RHS = min(RHS_table) + 0.0001;
        max_RHS = max(RHS_table) - 0.0001;
        LHS_data(LHS_data < min_RHS) = min_RHS; 
        LHS_data(LHS_data > max_RHS) = max_RHS;
        
        Te_values = nan(size(I1_values));
        Te_values(valid_indices) = interp1(RHS_table, Te_lookup, LHS_data(valid_indices), 'linear', 'extrap');
        
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
            ne_values(valid_Te) = (numerator_ne ./ denominator_ne) ./ (const_ne * sqrt(Te_valid));
        end
        
        % Pe計算
        Pe_raw = ne_values .* kb .* Te_values;
        Pe_raw(Pe_raw < 0) = NaN;
        
        % PCBの時間軸に合わせて補間
        Pe_interp = interp1(time_probe, Pe_raw, PCB.trange, 'linear', NaN);
        
        % --- 3. Magnetic Pressure Extraction (Index Search Method) ---
        
        % グリッド座標を取得 (grid2D.rq, grid2D.zq は Meshgrid の想定)
        % xpointplotコードのやり方を参照：
        % zvals = grid2D.zq(1,:) -> Z軸ベクトル
        % rvals = grid2D.rq(:,1) -> R軸ベクトル
        zvals = grid2D.zq(1,:);
        rvals = grid2D.rq(:,1);
        
        % 最も近いインデックスを探す (Nearest Neighbor)
        [~, z_idx] = min(abs(zvals - ProbeZ));
        [~, r_idx] = min(abs(rvals - ProbeR));
        
        % データ抜き出し
        % data2D.magnetic_pressure は (R, Z, Time) の3次元配列と想定
        % 時間軸方向はPCB.trangeと同期させる必要があるため、ループで回す
        
        Pmag_at_probe = zeros(size(PCB.trange));
        
        for t_k = 1:length(PCB.trange)
            t_val = PCB.trange(t_k);
            
            % data2D内の時間インデックスを探す
            % 通常 data2D.trange と PCB.trange は一致しているはずだが、
            % xpointplot同様、論理インデックスで検索する
            pcb_tidx = find(data2D.trange == t_val);
            
            if ~isempty(pcb_tidx)
                % data2D.magnetic_pressure(行, 列, 時間)
                Pmag_at_probe(t_k) = data2D.magnetic_pressure(r_idx, z_idx, pcb_tidx);
            else
                Pmag_at_probe(t_k) = NaN;
            end
        end
        
        % ベータ計算
        beta_val = Pe_interp ./ Pmag_at_probe;
        
        % 格納
        all_beta(i, :) = beta_val;
        all_Pe(i, :) = Pe_interp;
        all_Pmag(i, :) = Pmag_at_probe;
        
        % デバッグ表示
        fprintf('  > Mean Pe: %.2f Pa, Mean Pmag: %.2f Pa\n', mean(Pe_interp,'omitnan'), mean(Pmag_at_probe,'omitnan'));
        
    catch ME
        warning('Error processing shot %d: %s', IDXlist(i), ME.message);
        all_beta(i, :) = NaN;
    end
end

% =========================================================
%  Plotting
% =========================================================
if ~doCheck
    mean_beta = mean(all_beta, 1, 'omitnan');
    std_beta = std(all_beta, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(all_beta), 1));
    
    mean_Pe = mean(all_Pe, 1, 'omitnan');
    mean_Pmag = mean(all_Pmag, 1, 'omitnan');

    figure('Units', 'pixels', 'Position', [100 100 800 600], 'Color', 'w');
    t = PCB.trange;
    
    % Plot 1: Pressure
    subplot(2,1,1); hold on;
    plot(t, mean_Pe, 'r', 'LineWidth', 1.5, 'DisplayName', 'P_{thermal} (e^-)');
    plot(t, mean_Pmag, 'b', 'LineWidth', 1.5, 'DisplayName', 'P_{magnetic}');
    ylabel('Pressure [Pa]');
    title(['Pressure Comparison at R=', num2str(ProbeR), 'm, Z=', num2str(ProbeZ), 'm']);
    legend; grid on;
    xlim([PCB.start PCB.end]);
    
    % Plot 2: Beta
    subplot(2,1,2); hold on;
    fill([t, fliplr(t)], [mean_beta+std_beta, fliplr(mean_beta-std_beta)], ...
         [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(t, mean_beta, 'k.-', 'LineWidth', 1.5);
    yline(1.0, '--r', '\beta = 1');
    
    ylabel('Plasma Beta \beta_e');
    xlabel('Time [\mus]');
    title(['Plasma Beta (Pe/Pmag) [Date: ' num2str(date) ']']);
    grid on;
    xlim([PCB.start PCB.end]);
    
    hold off;
end