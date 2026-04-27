clearvars -except date IDXlist doSave doFilter doNLR ReconMethod Reset

% --- ユーザー設定 ---
SXR.number = 3; % 1から8のうちどれか
SXR.energy = 4; % フィルター
SXR.doSave = 1;
SXR.doFilter = 1;
SXR.ReconMethod = 1;
SXR.Reset = 0;
SXR.directory = '/NLF_MFI';

[PCB, pathname] = get_psb_data();

% --- データ蓄積用変数の初期化 ---
history_PCB = [];
history_SXR = [];
common_r_PCB = [];
common_r_SXR = [];
last_save_dir = ''; 

for i=1:PCB.n_data
    PCB.date = PCB.alldate(i);
    PCB.idx = PCB.allidx(i);
    PCB.shot = PCB.allshot(i,:);
    PCB.tfshot = PCB.alltfshot(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=PCB.alli_EF(i);
    SXR.date = PCB.date; 
    SXR.shot = PCB.idx; 
    SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(SXR.date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
    SXR.start = PCB.startlist(i);
    SXR.interval = PCB.intervallist(i);

    PCB.i_EF=PCB.alli_EF(i);
    PCB.TF=PCB.allTF(i);
    currentDataTypes = PCB.alldataType{i};

    for k = 1:numel(currentDataTypes)
        PCB.dataType = currentDataTypes{k};
        if PCB.doCheck
            check_signal(PCB, pathname);
        elseif ~PCB.doCheck
            fprintf('Processing Shot: %d\n', PCB.shot(1));
            
            % データ取得
            [p_pcb, p_sxr, r_pcb, r_sxr, save_dir, SXR] = plot_pcb_sxr_r(PCB, SXR, pathname);
            
            % データを蓄積 (グリッドが変わらない前提で結合)
            if ~isempty(p_pcb) && ~isempty(p_sxr)
                history_PCB = [history_PCB, p_pcb];
                history_SXR = [history_SXR, p_sxr];
                
                % 最初のループで軸情報を保持
                if isempty(common_r_PCB)
                    common_r_PCB = r_pcb;
                    common_r_SXR = r_sxr;
                end
                last_save_dir = save_dir;
            end
        end
    end
end

% --- 【Plot 1】 全ショット重ね書き (Overlay Plot) ---
if ~isempty(history_SXR)
    fprintf('Plotting overlay of all shots...\n');
    figure('Name', 'Overlay SXR Profile', 'Color', 'w');
    hold on;
    
    % 全ショットを薄くプロット
    % 行列をそのままplotに渡すと列ごとに線を引いてくれます
    h_all = plot(common_r_SXR, history_SXR, 'Color', [1, 0.7, 0.7, 0.5], 'LineWidth', 1); 
    
    % 平均値を計算して強調プロット
    mean_SXR = mean(history_SXR, 2, 'omitnan');
    h_mean = plot(common_r_SXR, mean_SXR, 'r', 'LineWidth', 1);
    
    % 装飾
    xlabel('r - r_{xpoint} (m)', 'FontSize', 12);
    ylabel('SXR Intensity (a.u.)', 'FontSize', 12);
    title(['Overlay of SXR Profiles (N=', num2str(size(history_SXR, 2)), ')'], 'FontSize', 14);
    xlim([-0.1, 0.1]);
    ylim([0, 6]);
    xline(0, '--k', 'LineWidth', 1.2, 'DisplayName', 'X-point');
    grid on;
    
    % 凡例調整 (全ショット分出ると邪魔なので、代表1つと平均のみ表示)
    legend([h_all(1), h_mean], {'Individual Shots', 'Average'}, 'Location', 'best');
    
    % 保存
    if ~isempty(last_save_dir)
        parent_dir = fileparts(last_save_dir); 
        save_filename = fullfile(parent_dir, ['Overlay_SXR_', num2str(SXR.number),'_shots.png']);
        saveas(gcf, save_filename);
    end
end

% --- 【Plot 2】 平均プロファイル (Error Bar Plot) ---
if ~isempty(history_PCB)
    fprintf('Calculating and plotting average RELATIVE profiles with error bars...\n');
    
    mean_PCB = mean(history_PCB, 2, 'omitnan');
    std_PCB  = std(history_PCB, 0, 2, 'omitnan');
    mean_SXR = mean(history_SXR, 2, 'omitnan');
    std_SXR  = std(history_SXR, 0, 2, 'omitnan');
    
    % fill用の座標作成
    x_fill_PCB = [common_r_PCB; flipud(common_r_PCB)];
    y_fill_PCB = [mean_PCB + std_PCB; flipud(mean_PCB - std_PCB)];
    x_fill_SXR = [common_r_SXR; flipud(common_r_SXR)];
    y_fill_SXR = [mean_SXR + std_SXR; flipud(mean_SXR - std_SXR)];
    
    figure('Name', 'Average Relative Profile', 'Color', 'w');
    
    % --- SXR (赤) ---
    hold on;
    % エラーバー領域 (HandleVisibility offで凡例に出ないようにする)
    fill(x_fill_SXR, y_fill_SXR, 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    % 平均線
    plot(common_r_SXR, mean_SXR, '-r', 'LineWidth', 2, 'DisplayName', 'Avg SXR');
    
    ylabel('Avg SXR Intensity (a.u.)', 'FontSize', 12);
    ax = gca; 
    ylim([0, 10]);
    
    % 共通設定
    xlabel('r - r_{xpoint} (m)', 'FontSize', 12);
    title(['Average Profile \pm\sigma (N=', num2str(size(history_PCB, 2)), ')'], 'FontSize', 14);
    xlim([-0.1, 0.1]); 
    xline(0, '--k', 'LineWidth', 1.2, 'DisplayName', 'X-point');
    legend('Location', 'best');
    grid on;
    hold off;
    
    % 保存処理
    if ~isempty(last_save_dir)
        parent_dir = fileparts(last_save_dir); 
        disp(parent_dir)
        save_filename = fullfile(parent_dir, ['Average_ErrorBar_SXR_energy:', num2str(SXR.energy),'_number:', num2str(SXR.number), '_shots.png']);
        saveas(gcf, save_filename);
    end
end


% --- 関数定義 ---
function [p_pcb_rel, p_sxr_rel, r_rel_PCB, r_rel_SXR, foldername_png, SXR] = plot_pcb_sxr_r(PCB, SXR, pathname)
    % 初期化
    p_pcb_rel = []; p_sxr_rel = []; r_rel_PCB = []; r_rel_SXR = []; foldername_png = '';
    
    % プロット用定数定義
    xlabel_text = 'r - r_{xpoint} (m)';
    x_limits = [-0.1, 0.1];

    try
        % PCBデータの処理
        [grid2D, data2D] = process_PCBdata_280ch(PCB, pathname);

        % SXRデータの処理
        date = SXR.date;
        shot = SXR.shot;
        start = SXR.start;
        interval = SXR.interval;
        doFilter = SXR.doFilter;
        ReconMethod = SXR.ReconMethod;

        addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code'; 

        if doFilter == 1
            if ReconMethod == 0; options = 'NLF_TP';
            elseif ReconMethod == 1; options = 'NLF_MFI';
            elseif ReconMethod == 2; options = 'NLF_MEM';
            elseif ReconMethod == 3; options = 'NLF_cGAN';
            elseif ReconMethod == 4; options = 'NLF_GPT'; end
        else
            if ReconMethod == 0; options = 'LF_TP';
            elseif ReconMethod == 1; options = 'LF_MFI';
            elseif ReconMethod == 2; options = 'LF_MEM';
            elseif ReconMethod == 3; options = 'LF_cGAN';
            elseif ReconMethod == 4; options = 'LF_GPT'; end
        end

        dirPath = getenv('SXR_MATRIX_DIR');
        matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));

        newProjectionNumber = 30;
        newGridNumber = 50;
        parameterFile = sprintf('parameters%d%d.mat', newProjectionNumber, newGridNumber);

        load(parameterFile,'range');
        matrixPath = strcat(matrixFolder,'/',num2str(SXR.number),'.mat');
        disp(matrixPath)
        % ファイル存在確認を入れるとロバストになりますが、一旦そのまま
        load(matrixPath,'EE1','EE2','EE3','EE4');
        EE = cat(3,EE1,EE2,EE3,EE4);

        SXR.t_target = (SXR.number-1)*interval + start;
        disp(SXR.t_target)
        
        % range = range ./ 1000; % mm -> m 変換

        % zmin2 = range(3); 
        % zmax2 = range(4); 
        % rmin  = range(5); 
        % rmax  = range(6);
        
        % num_r_sxr = size(EE, 2);
        % num_z_sxr = size(EE, 1);
        % % r_space_SXR = linspace(rmin, rmax, num_r_sxr)'; % この変数は未使用、以下で定義
        % z_space_SXR2 = linspace(zmax2, zmin2, num_z_sxr);
        

        % EE_target = imgaussfilt(EE(:,:,SXR.energy), 1);
        % disp(max(max(EE_target)))

        % [~, t_idx] = min(abs(data2D.trange - SXR.t_target));
        
        % % X点位置の取得
        % [~, xPointList] = get_axis_x_multi(grid2D, data2D, PCB);
        % r_xp = xPointList.r(t_idx);
        % z_xp = xPointList.z(t_idx);

        % if isnan(z_xp), target_z = 0; else, target_z = z_xp; end
        
        % % --- プロファイル抽出 ---
        % [~, z_idx_pcb] = min(abs(grid2D.zq(:, 1) - target_z)); % ← 修正
        % p_pcb_rel = data2D.Bt(:, z_idx_pcb, t_idx);
        
        % [~, z_idx_sxr] = min(abs(z_space_SXR2 - target_z));
        % p_sxr_rel = EE_target(z_idx_sxr, :)';

        % % --- 2. 比較・確認用プロット（自分がどこを切ったか可視化） ---
        % % ※ループ内で毎回出すと重いので、doCheck=1の時などに組み込んでください
        % figure('Name', 'Check Slice Line', 'Color', 'w');
        % % SXRの2次元分布をプロット
        % imagesc(linspace(rmin, rmax, num_r_sxr), z_space_SXR2, EE_target);
        % set(gca, 'YDir', 'normal'); % 物理座標に合わせてZ軸を下から上へ
        % hold on;
        % % 抽出したラインとX点をプロットして比較
        % yline(target_z, 'r-', 'LineWidth', 2, 'DisplayName', 'Extraction Line (target\_z)');
        % plot(r_xp, z_xp, 'w+', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'X-point');
        % xlabel('R (m)'); ylabel('Z (m)'); title('SXR 2D Profile & Extraction Line');
        % legend('Location', 'best');
        % colorbar;
        
        % % --- 相対座標 ---
        % r_orig_PCB = grid2D.rq(:, 1);
        % r_orig_SXR = linspace(range(5), range(6), size(EE_target, 2))';
        
        range = range ./ 1000; % mm -> m 変換
        
        zmin1 = range(1); zmax1 = range(2);
        zmin2 = range(3); zmax2 = range(4); 
        rmin  = range(5); rmax  = range(6);
        
        num_r_sxr = size(EE, 1); % [修正] 第1次元が r
        num_z_sxr = size(EE, 2); % [修正] 第2次元が z
        
        % [修正] 昇順に統一し、条件分岐を追加
        z_space_SXR1 = linspace(zmin1, zmax1, num_z_sxr);
        z_space_SXR2 = linspace(zmin2, zmax2, num_z_sxr);
        
        if 241110 <= SXR.date && SXR.date <= 250206
            if SXR.energy == 1
                z_space_target = z_space_SXR2;
            else
                z_space_target = z_space_SXR1;
            end
        else
            if SXR.energy <= 2
                z_space_target = z_space_SXR2;
            else
                z_space_target = z_space_SXR1;
            end
        end

        EE_target = imgaussfilt(EE(:,:,SXR.energy), 1.5);

        [~, t_idx] = min(abs(data2D.trange - SXR.t_target));
        
        % X点位置の取得
        [~, xPointList] = get_axis_x_multi(grid2D, data2D, PCB);
        r_xp = xPointList.r(t_idx);
        z_xp = xPointList.z(t_idx);

        if isnan(z_xp), target_z = 0; else, target_z = z_xp; end
        
        % --- プロファイル抽出 ---
        [~, z_idx_pcb] = min(abs(grid2D.zq(1,:) - target_z));
        p_pcb_rel = data2D.Bt(:, z_idx_pcb, t_idx);
        
        [~, z_idx_sxr] = min(abs(z_space_target - target_z)); % [修正] 正しいz_spaceを使用
        p_sxr_rel = EE_target(:, z_idx_sxr); % [修正] 列(z)を固定し、行(r)をすべて取り出す

         % --- プロファイル抽出 ---
        [~, z_idx_pcb] = min(abs(grid2D.zq(:, 1) - target_z)); % ← 修正
        p_pcb_rel = data2D.Bt(:, z_idx_pcb, t_idx);
        
        [~, z_idx_sxr] = min(abs(z_space_SXR2 - target_z));
        p_sxr_rel = EE_target(z_idx_sxr, :)';

        % --- 2. 比較・確認用プロット（自分がどこを切ったか可視化） ---
        % ※ループ内で毎回出すと重いので、doCheck=1の時などに組み込んでください
        figure('Name', 'Check Slice Line', 'Color', 'w');
        % SXRの2次元分布をプロット
        imagesc(linspace(rmin, rmax, num_r_sxr), z_space_SXR2, EE_target);
        set(gca, 'YDir', 'normal'); % 物理座標に合わせてZ軸を下から上へ
        hold on;
        % 抽出したラインとX点をプロットして比較
        yline(target_z, 'r-', 'LineWidth', 2, 'DisplayName', 'Extraction Line (target\_z)');
        plot(r_xp, z_xp, 'w+', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'X-point');
        xlabel('R (m)'); ylabel('Z (m)'); title('SXR 2D Profile & Extraction Line');
        legend('Location', 'best');
        colorbar;
        
        % --- 相対座標 ---
        r_orig_PCB = grid2D.rq(:, 1);
        r_orig_SXR = linspace(rmin, rmax, num_r_sxr)'; % [修正] サイズを num_r_sxr に合わせる

        if ~isnan(r_xp)
            r_rel_PCB = r_orig_PCB - r_xp;
            r_rel_SXR = r_orig_SXR - r_xp;
            disp(r_xp)
        else
            return;
        end
        
        % パス情報（保存用）
        pathname_png = getenv('SXR_RECONSTRUCTED_DIR');
        foldername_png = strcat(pathname_png,SXR.directory,'/',num2str(date),'/shot',num2str(shot));

        % --- 個別プロット (確認用、不要ならコメントアウト) ---
        % figure('Name', ['Individual Shot Check'], 'Visible', 'off'); % 非表示で作成
        % plot(r_rel_SXR, profile_SXR);
        % title(['Shot ' num2str(shot)]);
        % close(gcf); 

    catch ME
        fprintf('Error in plot_pcb_sxr_r: %s\n', ME.message);
    end
end