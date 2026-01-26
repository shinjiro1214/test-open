function save_sxr_images(date, projectionNumber, rawImage1, rawImage2, rawImage3, rawImage4, doCalibration)
% SAVE_SEPARATE_IMAGES_V1
% 4つのrawImageからv=1の位置を切り出し、個別のPNGファイルとして保存する関数
%
% ファイル名の形式: im{ImageIndex}_{FiberIndex}.png (例: im1_1.png)
% 保存先: カレントディレクトリ下の 'saved_images' フォルダ

    if nargin < 7
        doCalibration = false;
    end

    % --- 1. 設定と準備 ---
    rawImages = {rawImage1, rawImage2, rawImage3, rawImage4};
    
    % 保存用フォルダの作成
    saveDir = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/SXR_Images/251111/saved_images';
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    fprintf('Images will be saved in: %s\n', fullfile(pwd, saveDir));

    % 位置情報取得
    baseDir = '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View';
    positionPath = fullfile(baseDir, 'fiberPositions.xlsx');
    positionData = readmatrix(positionPath, 'Sheet', num2str(date), 'Range', 'C2:E33');
    IW = positionData(1, 3);
    
    % View 1 (Fiber 1-8) の座標
    Center_V1 = round(positionData(1:8, 1:2));
    resolution = projectionNumber / (IW * 2);
    k = find_circle(projectionNumber / 2);

    % 校正係数の準備
    calibrationFactor = [];
    if doCalibration
        calibDir = fullfile(getenv('SXR_IMAGE_DIR'), num2str(date));
        calibFile = fullfile(calibDir, 'calibrationFactor.mat');
        if exist(calibFile, 'file')
            load(calibFile, 'calibrationFactor');
            if numel(calibrationFactor(1, 1, :)) ~= numel(k)
                calibrationFactor = get_calibration_factor(date, projectionNumber);
            end
        else
            calibrationFactor = get_calibration_factor(date, projectionNumber);
        end
    end

    % --- 2. ループ処理と保存 ---
    % 図を表示するためのFigureを1つ作成
    hFig = figure('Name', 'Processing Images...', 'Color', 'w', 'Position', [500, 500, 400, 400]);

    for imgIdx = 1:4
        currentRawImage = rawImages{imgIdx};
        
        % バックグラウンド計算
        bgRegion = double(currentRawImage(1:2*IW, 1:2*IW, 1));
        bgLevel = mean(bgRegion, 'all');

        for fibIdx = 1:8
            % --- 画像切り出し処理 ---
            cx = Center_V1(fibIdx, 1);
            cy = Center_V1(fibIdx, 2);
            xRange = cx - IW + 1 : cx + IW;
            yRange = cy - IW + 1 : cy + IW;
            
            imgCrop = double(currentRawImage(yRange, xRange, 1));
            imgSub = imgCrop - bgLevel;
            imgProc = flipud(imgSub);
            imgProc(imgProc < 0) = 0;
            imgResized = imresize(imgProc, resolution, 'nearest');

            % 校正適用
            if doCalibration
                factorVec = squeeze(calibrationFactor(1, fibIdx, :));
                imgResized(k) = imgResized(k) .* factorVec;
            end

            % --- 表示と保存 ---
            % 現在のFigureに描画 (clfで前の描画を消去)
            clf(hFig); 
            
            % 画像表示
            imagesc(imgResized);clim([50 350]);
            axis image off; % アスペクト比固定＆軸・目盛りを消す
            
            % 必要に応じてカラーマップやClimを設定
            % colormap('jet');
            % clim([0, 100]); % 固定したい場合

            % タイトルを表示（保存画像にタイトルを含めたくない場合はコメントアウト）
            title(sprintf('Image %d - Fiber %d', imgIdx, fibIdx));
            
            % 描画更新（これがないとループが速すぎて表示が見えないことがあります）
            drawnow; 

            % ファイル名生成 (例: im1_1.png)
            fileName = sprintf('im%d_%d.png', imgIdx, fibIdx);
            fullPath = fullfile(saveDir, fileName);
            
            % 画像として保存
            % exportgraphics は余白を自動でカットして軸の中身だけ保存してくれます (R2020a以降)
            try
                exportgraphics(gca, fullPath, 'Resolution', 150);
            catch
                % R2020a未満の場合は saveas を使用
                saveas(gca, fullPath);
            end
            
            fprintf('Saved: %s\n', fileName);
        end
    end
    
    fprintf('All images processing completed.\n');
    close(hFig);
end

% --- Helper Function ---
function k = find_circle(L)
    R_map = zeros(2*L);
    for i = 1:2*L
        for j = 1:2*L
            R_map(i,j) = sqrt((L-i+0.5)^2 + (j-L-0.5)^2);
        end
    end
    k = find(R_map < L);
end