function plot_four_images_v1(date, projectionNumber, rawImage1, rawImage2, rawImage3, rawImage4, doCalibration)
% PLOT_FOUR_IMAGES_V1
% 4つの異なるrawImageに対し、v=1(View 1)の座標で画像を切り抜き、表示する関数
%
% Inputs:
%   date            : 実験日付 (例: 240111)
%   projectionNumber: 再構成計算用の解像度 (例: 80)
%   rawImage1~4     : 比較したい4つの生画像データ
%   doCalibration   : 校正係数を適用するかどうか (true/false)

    % 引数が省略された場合のデフォルト設定
    if nargin < 7
        doCalibration = false;
    end

    % --- 1. 設定と準備 ---
    rawImages = {rawImage1, rawImage2, rawImage3, rawImage4};
    
    % 位置情報ファイルのパス
    baseDir = '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View';
    positionPath = fullfile(baseDir, 'fiberPositions.xlsx');
    
    % 座標と半径(IW)の取得
    positionData = readmatrix(positionPath, 'Sheet', num2str(date), 'Range', 'C2:E33');
    IW = positionData(1, 3);
    
    % v=1 (View 1) の座標 (最初の8行)
    Center_V1 = round(positionData(1:8, 1:2));

    % 解像度計算
    resolution = projectionNumber / (IW * 2);

    % 円形マスク用インデックス k の取得 (校正係数の適用に必要)
    k = find_circle(projectionNumber / 2);

    % --- 2. 校正係数のロード (必要な場合のみ) ---
    calibrationFactor = [];
    if doCalibration
        calibDir = fullfile(getenv('SXR_IMAGE_DIR'), num2str(date));
        calibFile = fullfile(calibDir, 'calibrationFactor.mat');
        
        % ファイル確認とロード
        if exist(calibFile, 'file')
            load(calibFile, 'calibrationFactor');
            % サイズ不整合チェック（再計算が必要な場合）
            if numel(calibrationFactor(1, 1, :)) ~= numel(k)
                disp('Calibration factor size mismatch. Recalculating...');
                calibrationFactor = get_calibration_factor(date, projectionNumber);
            end
        else
            disp('Calibration file not found. Calculating...');
            calibrationFactor = get_calibration_factor(date, projectionNumber);
        end
    end

    % --- 3. プロット作成 ---
    figTitle = sprintf('View 1 Extraction: Date %d', date);
    if doCalibration, figTitle = [figTitle, ' (Calibrated)']; end

    figure('Name', figTitle, 'Color', 'w', 'Position', [100, 100, 1200, 600]);

    % 画像ループ (行)
    for imgIdx = 1:4
        currentRawImage = rawImages{imgIdx};
        
        % バックグラウンド取得
        bgRegion = double(currentRawImage(1:2*IW, 1:2*IW, 1));
        bgLevel = mean(bgRegion, 'all');

        % ファイバーループ (列)
        for fibIdx = 1:8
            % 座標取得
            cx = Center_V1(fibIdx, 1);
            cy = Center_V1(fibIdx, 2);
            
            % 切り出し
            xRange = cx - IW + 1 : cx + IW;
            yRange = cy - IW + 1 : cy + IW;
            
            imgCrop = double(currentRawImage(yRange, xRange, 1));
            imgSub = imgCrop - bgLevel;
            
            % 上下反転 & クリップ
            imgProc = flipud(imgSub);
            imgProc(imgProc < 0) = 0;
            
            % リサイズ
            imgResized = imresize(imgProc, resolution, 'nearest');

            % --- 校正係数の適用 ---
            if doCalibration
                % calibrationFactorは (View, Fiber, Pixel)
                % ここでは View=1 なので 1番目のインデックスを1に固定
                factorVec = squeeze(calibrationFactor(1, fibIdx, :));
                % factorVec = squeeze(calibrationFactor(3, fibIdx, :));
                
                % 円形領域 k の部分にのみ係数を掛ける
                imgResized(k) = imgResized(k) .* factorVec;

                % % 2回かけてみる
                % imgResized(k) = imgResized(k) .* factorVec;
            end

            % --- プロット ---
            subplot(4, 8, (imgIdx - 1) * 8 + fibIdx);
            imagesc(imgResized);
            clim([50 350]);
            % clim([50 200]);
            axis image off;
            
            % 装飾
            if imgIdx == 1
                title(sprintf('Fib %d', fibIdx), 'FontSize', 10);
            end
            if fibIdx == 1
                ylabel(sprintf('Img %d', imgIdx), 'FontSize', 12, 'FontWeight', 'bold');
                set(gca, 'YTick', [], 'XTick', []);
            end
        end
    end
    sgtitle(figTitle, 'FontSize', 16);
end

% --- Helper Function: 円形領域のインデックス取得 ---
function k = find_circle(L)
    % L: 半径 (projectionNumber/2)
    R_map = zeros(2*L);
    for i = 1:2*L
        for j = 1:2*L
            % 中心 (L+0.5, L+0.5) からの距離計算
            R_map(i,j) = sqrt((L-i+0.5)^2 + (j-L-0.5)^2);
        end
    end
    k = find(R_map < L);
end