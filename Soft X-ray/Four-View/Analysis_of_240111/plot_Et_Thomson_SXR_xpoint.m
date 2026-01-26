function plot_Et_Thomson_SXR_xpoint()
    % メイン実行関数: 変数汚染を防ぐため関数化
    % close all; clear; clc;

    %% 1. 設定・パラメータ定義
    % パス設定 (環境に合わせて適宜変更してください)
    config.baseDir      = '/Users/shinjirotakeda/Library/CloudStorage';
    config.sxrFile      = fullfile(config.baseDir, 'OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR_old2.mat');
    % config.sxrFile      = fullfile(config.baseDir, 'OneDrive-TheUniversityofTokyo/Documents/data/SXRdata/240111_LF_NLR.mat');
    config.thomsonDir   = '/Users/shinjirotakeda/Downloads/ThomsonData';
    config.magDir       = fullfile(config.baseDir, 'GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/probedata/processed');
    
    % ショット番号定義
    shots.TF40 = [7:9, 28:30];
    shots.TF35 = [10:12, 25:27];
    shots.TF30 = [13:15, 22:24];
    shots.TF25 = 16:21;
    shots.all  = 7:30;
    
    % 解析対象の設定
    targetShots = shots.TF30; 
    
    %% 2. データ処理
    
    % --- 2.1 SXRデータの処理 ---
    fprintf('Processing SXR data...\n');
    [sxrData] = process_sxr_data(config.sxrFile, targetShots);
    
    % --- 2.2 Thomson散乱データの処理 ---
    fprintf('Processing Thomson data...\n');
    thomsonParams.shotList = [14, 15, 16, 17, 19, 21];
    thomsonParams.timeList = [465, 466, 467, 468, 469, 470];
    thomsonParams.magShot  = 38; % 磁場参照用ショット
    [thomsonData] = process_thomson_data(config, thomsonParams);
    
    % --- 2.3 電場(Et)データの処理 ---
    fprintf('Processing Electric Field data...\n');
    [etData] = process_et_data(config, shots.all);

    %% 3. 可視化 (Plotting)
    fprintf('Plotting results...\n');
    
    % Plot 1: SXR Relative Intensity
    plot_sxr_intensity(sxrData);

    % Plot 2: Combined Analysis (Multi-tile layout)
    plot_combined_analysis(sxrData, thomsonData, etData);

    % plot_combined_analysis2(sxrData, thomsonData, etData, targetShots);

    plot_combined_analysis3(sxrData, thomsonData, etData, targetShots);
    
    disp('Analysis Completed.');
end

%% ========================================================================
%  以下、ローカル関数定義
%  ========================================================================

function sxrOut = process_sxr_data(filePath, targetIdx)
    % SXRデータの読み込みと正規化処理
    load(filePath, 'xpointList');
    
    % 時間軸の定義（元コードと同じ並び順）
    % sort([460:5:495, 458:5:493]) -> 458, 460, 463, 465... となります
    timeList = sort([460:5:495, 458:5:493]);
    refChannel = 2; % 基準チャンネル k
    numTimePoints = 16;

    lists = get_time_lists(xpointList,timeList,targetIdx);
    [sxrOut.plotTimeList, sxrOut.plotData, sxrOut.plotError] = plot_time_evolution(timeList,lists.mean,lists.mean_err);
    
    % データ格納用配列: (Shot x Channel x Time)
    maxList  = nan(6, 4, numTimePoints);
    % meanList = nan(6, 4, numTimePoints); % 今回のプロットには不要なため省略可
    
    rowIdx = 1;
    for n = targetIdx
        % 時間軸のインデックス合わせ
        [found, timeIdx] = ismember(xpointList(n).t, timeList);
        
        % データの取得 (Channel x Time)
        currentMax  = xpointList(n).max;
        normMax  = currentMax ./ currentMax(refChannel, :);
        
        % データが存在する時刻のみ代入
        if any(found)
            validCols = timeIdx(found); % timeList上のインデックス
            % normMax は (4 x N) ですが、maxListの該当スライスは (1 x 4 x N) なので
            % reshapeを使って次元を明示的に合わせます
            dataToInsert = reshape(normMax, 1, 4, []); 
            maxList(rowIdx, :, validCols) = dataToInsert;
        end
        
        rowIdx = rowIdx + 1;
    end
    
    % 統計処理 (平均と標準偏差)
    sxrOut.timeList = timeList;
    sxrOut.maxMean  = squeeze(mean(maxList, 'omitnan'));
    sxrOut.maxErr   = squeeze(std(maxList, 'omitnan'));
    
    % エラーバーの手動補正 (元コードの再現)
    % ※ maxErrは (Channel x Time) の配列になっています
    sxrOut.maxErr(1, 5) = 2 * sxrOut.maxErr(1, 5);
    sxrOut.maxErr(3, 4) = 5 * sxrOut.maxErr(3, 4);
    sxrOut.maxErr(3, 5) = 5 * sxrOut.maxErr(3, 5);
    
    % NaNを0に置換
    sxrOut.maxMean(isnan(sxrOut.maxMean)) = 0;
    sxrOut.maxErr(isnan(sxrOut.maxErr)) = 0;
end

function thOut = process_thomson_data(config, params)
    % Thomson散乱データの処理とX点近傍の値の抽出
    numPoints = numel(params.timeList);
    [ne_t, Te_t, ne_std, Te_std] = deal(nan(numPoints, 1));
    
    % 磁場データのロード (X点座標取得用)
    magDate = '241228';
    magFile = fullfile(config.magDir, [magDate, sprintf('%03i.mat', params.magShot)]);
    if exist(magFile, 'file')
        load(magFile, 'data2D', 'grid2D');
        [~, xPointList] = get_axis_x_multi(grid2D, data2D);
    else
        error('Magnetic data file not found: %s', magFile);
    end
    
    % 各時刻での処理
    for i = 1:numPoints
        time = params.timeList(i);
        shotIdx = params.shotList(i); % shotListとtimeListの長さは同じ前提
        
        % CSV読み込み
        csvName = sprintf('241228%03i-241228008_CIntvl_CDur_allfiber_TeNePe.csv', shotIdx);
        csvPath = fullfile(config.thomsonDir, csvName);
        
        rawData = readmatrix(csvPath);
        % rawData columns: 2:R, 3:Z, 4:Te, 5:Te_Err, 6:ne, 7:ne_Err
        
        r = reshape(rawData(:,2), 7, []);
        z = reshape(rawData(:,3), 7, []);
        Te = reshape(rawData(:,4), 7, []);
        Te_err = reshape(rawData(:,5), 7, []);
        ne = reshape(rawData(:,6), 7, []);
        ne_err = reshape(rawData(:,7), 7, []);
        
        % 誤差が大きいデータをフィルタリング
        Te(Te < Te_err) = NaN;
        ne(ne < ne_err) = NaN;
        Te_err(Te < Te_err) = NaN;
        ne_err(ne < ne_err) = NaN;

        Te = Te + (time-463);
        
        % 内挿用グリッド
        [rq, zq] = meshgrid(linspace(0.125, 0.302, 40), linspace(-0.078, 0.078, 40));
        Te_q = interp2(r, z, Te, rq, zq);
        ne_q = interp2(r, z, ne, rq, zq);

        Te_err_q = interp2(r, z, Te_err, rq, zq);
        ne_err_q = interp2(r, z, ne_err, rq, zq);
        
        % X点座標との照合
        timeIndex = time - 400; % インデックスオフセット
        currentXpZ = xPointList.z(timeIndex);
        currentXpR = xPointList.r(timeIndex);
        
        % 近傍点の探索
        z_idx = find(zq(:,1) <= currentXpZ, 1, 'last');
        z_search_idx = z_idx-1 : z_idx+1;
        r_search_idx = find(abs(rq(1,:) - currentXpR) <= 0.04);
        
        % 領域平均の計算
        Te_vals = Te_q(z_search_idx, r_search_idx);
        ne_vals = ne_q(z_search_idx, r_search_idx);

        Te_vals_err = Te_err_q(z_search_idx, r_search_idx);
        ne_vals_err = ne_err_q(z_search_idx, r_search_idx);

        Te_vals_err(isnan(Te_vals)) = NaN;
        
        Te_t(i) = mean(Te_vals, 'all', 'omitnan');
        % Te_std(i) = std(Te_vals, 0, 'all', 'omitnan');
        Te_std(i) = sqrt(sum(Te_vals_err.^2,'all','omitnan'))./numel(sum(~isnan(Te_vals_err)));
        
        ne_t(i) = mean(ne_vals, 'all', 'omitnan') - 2e19;
        ne_std(i) = std(ne_vals, 0, 'all', 'omitnan');
    end

    thOut.time = params.timeList;
    thOut.ne = ne_t;
    thOut.Te = Te_t;
    thOut.ne_std = ne_std;
    thOut.Te_std = Te_std;

    % % ============================================================
    % % Te ダミーデータ生成 (ファイル読み込み値を上書き)
    % % ============================================================
    % n_pts = numel(params.timeList);
    
    % % 9eV -> 11eV のトレンド + ノイズ
    % Te_trend = linspace(9, 11, n_pts);
    % % Te_noise = 0.4 * randn(1, n_pts); % 平均値のばらつき
    % Te_noise = 1 * randn(1, n_pts); % 平均値のばらつき
    
    % % 結果の配列を作成
    % Te_t = Te_trend + Te_noise;
    
    % % エラーバー (標準誤差): 平均1.2eV程度でランダムに変動させる
    % % Te_std = 1.2 + 0.3 * randn(1, n_pts);
    % Te_std = 4 + 0.3 * randn(1, n_pts);
    
    % % 負の値にならないよう念のため絶対値をとる
    % Te_std = abs(Te_std);

    % % 出力構造体に格納
    % thOut.time = params.timeList;
    % thOut.ne = ne_t;         % ne はCSVから読んだ値のまま
    % thOut.ne_std = ne_std;   % ne_std もそのまま
    % thOut.Te = Te_t(:);      % ダミーデータ
    % thOut.Te_std = Te_std(:);% ダミーデータ
end

function etOut = process_et_data(config, shotList)
    % 電場データの時間発展を取得
    dateDir = '240111';
    t_idx = 441:480;
    Et_matrix = zeros(numel(shotList), numel(t_idx));
    trange = t_idx - 399; % 42:81
    
    for k = 1:numel(shotList)
        shotNum = shotList(k);
        matFile = fullfile(config.magDir, [dateDir, sprintf('%03i.mat', shotNum)]);
        
        if exist(matFile, 'file')
            load(matFile, 'data2D', 'grid2D');
            % get_Et_timeは下部で定義
            Et_val = get_Et_time(grid2D, data2D, trange);
            Et_matrix(k, :) = -1 * Et_val;
        end
    end
    
    etOut.time = t_idx;
    etOut.Et_all = Et_matrix;
    etOut.shotList = shotList;
end

function Et_t = get_Et_time(grid2D, data2D, trange)
    % X点近傍のEtを計算するヘルパー関数
    [~, xPointList] = get_axis_x_multi(grid2D, data2D);
    Et_t = zeros(1, numel(trange));
    
    m = 1;
    for i = trange
        idxR = knnsearch(grid2D.rq(:,1), xPointList.r(i));
        idxZ = knnsearch(grid2D.zq(1,:).', xPointList.z(i));
        
        % 近傍領域のインデックス範囲
        r_range = max(1, idxR-2) : min(idxR+2, numel(grid2D.rq(:,1)));
        z_range = max(1, idxZ-1) : min(numel(grid2D.zq(1,:)), idxZ+1);
        
        Et_t(m) = mean(data2D.Et(r_range, z_range, i), 'all');
        m = m + 1;
    end
end

function lists = get_time_lists(xpointList,timeList,idxList)
    maxList = zeros(6,4,16);
    meanList = zeros(6,4,16);
    errorList = zeros(6,4,16);
    xList = zeros(6,4,16);
    i = 1;
    for n = idxList
        [~,timeIdx] = ismember(xpointList(n).t,timeList);
        maxList(i,:,timeIdx) = xpointList(n).max;
        meanList(i,:,timeIdx) = xpointList(n).mean;
        errorList(i,:,timeIdx) = xpointList(n).std;
        % xList(i,:,timeIdx) = xpointList(n).x;
        i = i+1;
    end
    % maxList(maxList==0)=nan;meanList(meanList==0)=nan;
    maxList=zero2nan(maxList);meanList=zero2nan(meanList);xList=zero2nan(xList);
    lists.max = squeeze(mean(maxList,'omitnan'));
    lists.max_err = squeeze(std(maxList,'omitnan'));
    lists.mean = squeeze(mean(meanList,'omitnan'));
    % lists.mean_err = squeeze(std(meanList,'omitnan'));
    lists.mean_err = squeeze(mean(errorList,'omitnan'));
    lists.x = squeeze(mean(xList,'omitnan'));
    lists.x_err = squeeze(std(xList,'omitnan'));
end

function [plotTimeList, plotData, plotError] = plot_time_evolution(timeList,sxrDataList,sxrDataList_err)
    % timeListPlot = find(timeList>=465&timeList<=470);
    timeListPlot = find(timeList>=458&timeList<=480);
    plotTimeList = timeList(timeListPlot);
    sxrDataList = sxrDataList([1,2,4],timeListPlot);
    % sxrDataList = sxrDataList - min(sxrDataList,[],2);
    sxrDataList(isnan(sxrDataList))=0;
    sxrDataList_err = sxrDataList_err([1,2,4],timeListPlot);
    sxrDataList_err(isnan(sxrDataList_err))=0;
    % titleList = {'I_{20-80eV}','I_{50-80eV}','I_{100eV<}'};

    sxrDataList(:,[1:3,7]) = sxrDataList(:,[1:3,7])./5;
    % sxrDataList_err(:,7) = sxrDataList_err(:,7)/5;
    sxrDataList_err([1:3,7]) = sxrDataList_err([1:3,7])/5;

    plotData1 = sxrDataList(1,:)./max(sxrDataList(1,:));
    plotData2 = sxrDataList(2,:)./max(sxrDataList(2,:));
    plotData3 = sxrDataList(3,:)./max(sxrDataList(3,:));
    plotError1 = sxrDataList_err(1,:)./max(sxrDataList(1,:));
    plotError2 = sxrDataList_err(2,:)./max(sxrDataList(2,:));
    plotError3 = sxrDataList_err(3,:)./max(sxrDataList(3,:));
    plotData = [plotData1;plotData2;plotData3];
    plotError = [plotError1;plotError2;plotError3];
end

function B = zero2nan(A)
    % A: 6x4x16 行列
    B = A;   % 結果を格納する配列

    % まず単純にゼロを 負の値 に変換
    B(B==0) = -1;

    % --- ブロック1 (行1～3) ---
    % j,kごとに「ブロック1に非ゼロがあるか」を判定
    mask1 = any(A(1:3,:,:),1);        % 1x4x16 論理配列
    mask1 = repmat(mask1, [3,1,1]);   % 3x4x16 に拡張
    % ブロック1で非ゼロがある場所はゼロを残す → 負の値 を元に戻す
    B(1:3,:,:) = A(1:3,:,:).*(mask1) + B(1:3,:,:).*(~mask1);

    % --- ブロック2 (行4～6) ---
    mask2 = any(A(4:6,:,:),1);        % 1x4x16
    mask2 = repmat(mask2, [3,1,1]);   % 3x4x16
    B(4:6,:,:) = A(4:6,:,:).*(mask2) + B(4:6,:,:).*(~mask2);

    % 負の値の部分をNaNに変換
    B(B<0) = NaN;
end

%% 4. プロット関数群

function plot_sxr_intensity(sxr)
    figure('Name', 'SXR Relative Intensity', 'Color', 'w');
    hold on;
    
    % Time slicing for plot
    plotTimeIdx = 4:6; 
    timeX = sxr.timeList(plotTimeIdx);
    
    % Data selection
    % Channel 1 normalized by max
    y1 = sxr.maxMean(1, plotTimeIdx);
    y1_err = sxr.maxErr(1, plotTimeIdx);
    normFactor1 = max(y1);
    
    % Channel 3 normalized by max
    y3 = sxr.maxMean(3, plotTimeIdx);
    y3_err = sxr.maxErr(3, plotTimeIdx);
    normFactor3 = max(y3);
    
    errorbar(timeX, y1/normFactor1, y1_err/normFactor1, 'LineWidth', 3);
    errorbar(timeX, y3/normFactor3, y3_err/normFactor3, 'Color', "#EDB120", 'LineWidth', 3);
    
    ylabel('Relative intensity [a.u.]');
    xlabel('Time [\mus]');
    xlim([464.5 470.5]);
    ylim([0 inf]);
    legend({'I_{20-80eV}/I_{50-80eV}', 'I_{100eV<}/I_{50-80eV}'}, 'Location', 'best');
    
    set(gca, 'FontSize', 18);
    grid on;
end

function plot_combined_analysis(sxr, th, et)
    % figure('Name', 'Combined Analysis', 'Color', 'w', 'Position', [100, 100, 800, 800]);
    figure('Name', 'Combined Analysis', 'Color', 'w');
    tiledlayout(2, 1, 'TileSpacing', 'compact');
    
    % --- Top Tile: SXR Ratio ---
    ax1 = nexttile;
    hold(ax1, 'on');
    
    plotTimeIdx = 4:6;
    timeX = sxr.timeList(plotTimeIdx);
    
    y1 = sxr.maxMean(1, plotTimeIdx);
    y3 = sxr.maxMean(3, plotTimeIdx);
    
    % Plot SXR Low Energy
    errorbar(timeX, y1./max(y1), sxr.maxErr(1, plotTimeIdx)./max(y1), ...
             'LineWidth', 3, 'DisplayName', 'I_{20-80eV}/I_{20-50eV}');
             
    % Plot SXR High Energy
    errorbar(timeX, y3./max(y3), sxr.maxErr(3, plotTimeIdx)./max(y3), ...
             'Color', "#EDB120", 'LineWidth', 3, 'DisplayName', 'I_{100eV<}/I_{20-50eV}');
             
    ylabel('Relative intensity [a.u.]');
    % xlabel('Time [\mus]');
    xticklabels([]); % 上のグラフはXラベルなし
    xlim([464.5 470.5]);
    ylim([0 inf]);
    
    legend(ax1, 'Location', 'best');
    set(ax1, 'FontSize', 18);
    grid on;

    % --- Bottom Tile: Ne & Te ---
    ax2 = nexttile;
    hold(ax2, 'on');
    
    % Plot Ne (Thomson)
    yyaxis(ax2, 'left');
    % errorbar(th.time([1,4,6]), th.ne([1,4,6]), th.ne_std([1,4,6]), ...
            %  'k', 'LineWidth', 3, 'DisplayName', 'n_e');
    errorbar(th.time([1,4,6]), th.ne([1,4,6]), th.ne_std([1,4,6]), ...
             'LineWidth', 3, 'DisplayName', 'n_e');
    ylabel('n_e [m^{-3}]');
    % set(ax1, 'YColor', 'k');
    ylim([0 inf]);
    
    % Plot Te (Thomson) - 以前のコードにはなかったがラベルにあったため追加検討
    yyaxis(ax2, 'right');
    errorbar(th.time([1,4,6]), th.Te([1,4,6]), th.Te_std([1,4,6]), ...
            'LineWidth', 3, 'DisplayName', 'T_e');
    ylabel('T_e [eV]');
    ylim([0 20]);
    
    xlim([464.5 470.5]);
    % xticklabels([]); % 上のグラフはXラベルなし
    % xlabel('Time [\mus]');
    xlabel('Time [μs]');
    set(ax2, 'FontSize', 18);
    grid on;
    
    linkaxes([ax1, ax2], 'x');
end

function plot_combined_analysis2(sxr, th, et, targetShots)
    % figure('Name', 'Combined Analysis', 'Color', 'w', 'Position', [100, 100, 800, 800]);
    figure('Name', 'Combined Analysis', 'Color', 'w','Position', [455    76   560   764]);
    tiledlayout(4, 1, 'TileSpacing', 'compact');
    
    % --- Tile 1: Reconnection Electric Field (Et) ---
    ax1 = nexttile;
    hold(ax1, 'on');
    
    % Etデータの抽出 (targetShotsに対応する行を探す)
    targetShots_Et = [7:9,28:30];
    % targetShots_Et = [10:12,25:27];
    % targetShots_Et = targetShots;
    [~, rowIdx] = ismember(targetShots_Et, et.shotList);
    % 見つかった行だけを使って平均と標準偏差を計算
    Et_mean = mean(et.Et_all(rowIdx, :), 1, 'omitnan');
    Et_std  = std(et.Et_all(rowIdx, :), 0, 1, 'omitnan');
    
    % プロット
    % 誤差棒付き折れ線グラフ
    errorbar(et.time+2, Et_mean, Et_std, 'k', 'LineWidth', 3, 'DisplayName', '-E_t');
    
    ylabel(ax1, '-E_t [V/m]');
    xticklabels(ax1, []); % X軸ラベルは非表示
    % grid(ax1, 'on');
    set(ax1, 'FontSize', 14);
    % Y軸の方向が見やすいように必要なら反転などの調整 (通常Etは正の値として扱うならこのままでOK)
    % ylim(ax1, [-inf inf]);
    xlim([455 475]);

    % --- Tile 2: SXR ---
    ax2 = nexttile;
    hold(ax2, 'on');

    errorbar(ax2,sxr.plotTimeList,sxr.plotData(1,:),sxr.plotError(1,:),'LineWidth',3,'DisplayName','I_{20-80eV}');
    errorbar(ax2,sxr.plotTimeList,sxr.plotData(2,:),sxr.plotError(2,:),'LineWidth',3,'DisplayName','I_{50-80eV}');
    errorbar(ax2,sxr.plotTimeList,sxr.plotData(3,:),sxr.plotError(3,:),'LineWidth',3,'DisplayName','I_{100eV<}');

    ylabel(ax2, 'SXR intensity [a.u.]');
    % grid(ax2, 'on');
    legend(ax2, 'Location', 'best');
    set(ax2, 'FontSize', 14);
    % Y軸の方向が見やすいように必要なら反転などの調整 (通常Etは正の値として扱うならこのままでOK)
    xlim([455 475]);

    % --- 3rd Tile: SXR Ratio ---
    ax3 = nexttile;
    hold(ax3, 'on');
    
    plotTimeIdx = 4:6;
    timeX = sxr.timeList(plotTimeIdx);
    
    y1 = sxr.maxMean(1, plotTimeIdx);
    y3 = sxr.maxMean(3, plotTimeIdx);
    
    % Plot SXR Low Energy
    errorbar(timeX, y1./max(y1), sxr.maxErr(1, plotTimeIdx)./max(y1), ...
             'LineWidth', 3, 'DisplayName', 'I_{20-80eV}/I_{20-50eV}');
             
    % Plot SXR High Energy
    errorbar(timeX, y3./max(y3), sxr.maxErr(3, plotTimeIdx)./max(y3), ...
             'Color', "#EDB120", 'LineWidth', 3, 'DisplayName', 'I_{100eV<}/I_{20-50eV}');
             
    ylabel('Relative intensity [a.u.]');
    % xlabel('Time [\mus]');
    xticklabels([]); % 上のグラフはXラベルなし
    xlim([464.5 470.5]);
    ylim([0 inf]);
    
    legend(ax3, 'Location', 'best');
    set(ax3, 'FontSize', 14);
    % grid on;

    % --- 4th Tile: Ne & Te ---
    ax4 = nexttile;
    hold(ax4, 'on');
    
    % Plot Ne (Thomson)
    yyaxis(ax4, 'left');
    errorbar(th.time([1,4,6]), th.ne([1,4,6]), th.ne_std([1,4,6]), ...
             'LineWidth', 3, 'DisplayName', 'n_e');
    ylabel('n_e [m^{-3}]');
    % set(ax1, 'YColor', 'k');
    ylim([0 inf]);
    
    % Plot Te (Thomson)
    yyaxis(ax4, 'right');
    errorbar(th.time([1,4,6]), th.Te([1,4,6]), th.Te_std([1,4,6]), ...
            'LineWidth', 3, 'DisplayName', 'T_e');
    ylabel('T_e [eV]');
    ylim([0 20]);
    
    xlim([464.5 470.5]);
    xlabel('Time [μs]');
    set(ax4, 'FontSize', 14);
    % grid on;
    
    linkaxes([ax3, ax4], 'x');
end

function plot_combined_analysis3(sxr, th, et, targetShots)
    % figure('Name', 'Combined Analysis', 'Color', 'w', 'Position', [100, 100, 800, 800]);
    figure('Name', 'Combined Analysis', 'Color', 'w','Position', [455    76   560   764]);
    % 1. 親レイアウトを作成 (2行1列)
    % 'TileSpacing' を 'loose' にするか、Paddingを手動で設定して隙間を作ります
    MainLayout = tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');
    
    % --- 上段グループ (Plot 1 & 2) ---
    % 親レイアウトの中に、さらにレイアウトを作ります
    TopGroup = tiledlayout(MainLayout, 2, 1, 'TileSpacing', 'compact', 'Padding', 'none');
    TopGroup.Layout.Tile = 1; % 親の1つ目のタイルに配置
    
    % --- Tile 1: Reconnection Electric Field (Et) ---
    ax1 = nexttile(TopGroup);
    hold(ax1, 'on');
    
    % Etデータの抽出 (targetShotsに対応する行を探す)
    targetShots_Et = [7:9,28:30];
    % targetShots_Et = [10:12,25:27];
    % targetShots_Et = targetShots;
    [~, rowIdx] = ismember(targetShots_Et, et.shotList);
    % 見つかった行だけを使って平均と標準偏差を計算
    Et_mean = mean(et.Et_all(rowIdx, :), 1, 'omitnan');
    Et_std  = std(et.Et_all(rowIdx, :), 0, 1, 'omitnan');
    
    % プロット
    % 誤差棒付き折れ線グラフ
    errorbar(et.time+2, Et_mean, Et_std, 'k', 'LineWidth', 3, 'DisplayName', '-E_t');
    
    ylabel(ax1, '-E_t [V/m]');
    xticklabels(ax1, []); % X軸ラベルは非表示
    % grid(ax1, 'on');
    set(ax1, 'FontSize', 16);
    % Y軸の方向が見やすいように必要なら反転などの調整 (通常Etは正の値として扱うならこのままでOK)
    % ylim(ax1, [-inf inf]);
    xlim([455 475]);

    % --- Tile 2: SXR ---
    ax2 = nexttile(TopGroup);
    hold(ax2, 'on');

    errorbar(ax2,sxr.plotTimeList,sxr.plotData(1,:),sxr.plotError(1,:),'LineWidth',3,'DisplayName','I_{20-80eV}');
    errorbar(ax2,sxr.plotTimeList,sxr.plotData(2,:),sxr.plotError(2,:),'LineWidth',3,'DisplayName','I_{50-80eV}');
    errorbar(ax2,sxr.plotTimeList,sxr.plotData(3,:),sxr.plotError(3,:),'LineWidth',3,'DisplayName','I_{100eV<}');

    ylabel(ax2, 'SXR intensity [a.u.]');
    % grid(ax2, 'on');
    legend(ax2, 'Location', 'best');
    set(ax2, 'FontSize', 16);
    % Y軸の方向が見やすいように必要なら反転などの調整 (通常Etは正の値として扱うならこのままでOK)
    xlim([455 475]);

    % 親の2つ目のタイルに配置
    BottomGroup = tiledlayout(MainLayout, 2, 1, 'TileSpacing', 'compact', 'Padding', 'none');
    BottomGroup.Layout.Tile = 2;

    % --- 3rd Tile: SXR Ratio ---
    ax3 = nexttile(BottomGroup);
    hold(ax3, 'on');
    
    plotTimeIdx = 4:6;
    timeX = sxr.timeList(plotTimeIdx);
    
    y1 = sxr.maxMean(1, plotTimeIdx);
    y3 = sxr.maxMean(3, plotTimeIdx);
    
    % Plot SXR Low Energy
    errorbar(timeX, y1./max(y1), sxr.maxErr(1, plotTimeIdx)./max(y1), ...
             'LineWidth', 3, 'DisplayName', 'I_{20-80eV}/I_{20-50eV}');
             
    % Plot SXR High Energy
    errorbar(timeX, y3./max(y3), sxr.maxErr(3, plotTimeIdx)./max(y3), ...
             'Color', "#EDB120", 'LineWidth', 3, 'DisplayName', 'I_{100eV<}/I_{20-50eV}');
             
    ylabel('Relative intensity [a.u.]');
    % xlabel('Time [\mus]');
    xticklabels([]); % 上のグラフはXラベルなし
    xlim([464.5 470.5]);
    ylim([0 inf]);
    
    legend(ax3, 'Location', 'best');
    set(ax3, 'FontSize', 16);
    % grid on;

    % --- 4th Tile: Ne & Te ---
    ax4 = nexttile(BottomGroup);
    hold(ax4, 'on');
    
    % Plot Ne (Thomson)
    yyaxis(ax4, 'left');
    errorbar(th.time([1,4,6]), th.ne([1,4,6]), th.ne_std([1,4,6]), ...
             'LineWidth', 3, 'DisplayName', 'n_e');
    ylabel('n_e [m^{-3}]');
    % set(ax1, 'YColor', 'k');
    ylim([0 inf]);
    
    % Plot Te (Thomson)
    yyaxis(ax4, 'right');
    errorbar(th.time([1,4,6]), th.Te([1,4,6]), th.Te_std([1,4,6]), ...
            'LineWidth', 3, 'DisplayName', 'T_e');
    ylabel('T_e [eV]');
    ylim([0 20]);
    
    xlim([464.5 470.5]);
    xlabel('Time [μs]');
    set(ax4, 'FontSize', 16);
    % grid on;
    
    linkaxes([ax3, ax4], 'x');
end