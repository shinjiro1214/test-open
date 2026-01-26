function [imageVector1, imageVector2, imageVector3, imageVector4] = get_sxr_image2(date, number, projectionNumber, rawImage)

    % --- 設定パラメータ ---
    % doCheck = false; % 確認用プロットのオンオフ
    doCheck = true; % 確認用プロットのオンオフ
    
    % 位置情報ファイルのパス設定
    baseDir = '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View';
    positionPath = fullfile(baseDir, 'fiberPositions.xlsx');
    
    % ファイバー位置と切出し半径(IW)の取得
    % Center: [View(1-4), Fiber(1-8), Coord(x,y)]
    positionData = readmatrix(positionPath, 'Sheet', num2str(date), 'Range', 'C2:E33');
    IW = positionData(1, 3);
    
    Center = zeros(4, 8, 2);
    for v = 1:4
        % Excelデータの並びを行列に格納 (1-8行目:View1, 9-16行目:View2...)
        Center(v, :, :) = positionData(1+8*(v-1):8+8*(v-1), 1:2);
    end
    Center = round(Center);

    % --- 前処理 ---
    % バックグラウンドノイズ算出 (画像の左上隅を使用)
    % rawImageがuint型の場合があるためdoubleにキャストして計算
    bgRegion = double(rawImage(1:2*IW, 1:2*IW, 1));
    bgLevel = mean(bgRegion, 'all');

    % 再構成用インデックスと解像度
    k = find_circle(projectionNumber / 2);
    resolution = projectionNumber / (IW * 2);

    % 校正データの取得
    calibDir = fullfile(getenv('SXR_IMAGE_DIR'), num2str(date));
    calibFile = fullfile(calibDir, 'calibrationFactor.mat');
    
    if exist(calibFile, 'file')
        load(calibFile, 'calibrationFactor');
        % サイズ不整合時の再計算
        if numel(calibrationFactor(1, 1, :)) ~= numel(k)
            calibrationFactor = get_calibration_factor(date, projectionNumber);
        end
    else
        calibrationFactor = get_calibration_factor(date, projectionNumber);
    end

    % --- 画像切り出しと加工 (メインループ) ---
    % 結果格納用 [View, Fiber, Pixel]
    imageVectors = zeros(4, 8, numel(k));
    
    if doCheck
        f1 = figure('Position', [200, 250, 1060, 500]);
    end

    for i = 1:8 % Fiber Loop
        for v = 1:4 % View Loop (1:4)
            
            % 1. 切り出し範囲の決定 (Centerは [x, y])
            cx = Center(v, i, 1);
            cy = Center(v, i, 2);
            xRange = cx - IW + 1 : cx + IW;
            yRange = cy - IW + 1 : cy + IW;
            
            % 2. 切り出し & BG引き & 負値クリップ
            imgCrop = double(rawImage(yRange, xRange, 1));
            imgSub = imgCrop - bgLevel;
            
            % 3. 上下反転 (flipud) & 負値除去
            % 元コードの処理順序: BG引き -> flipud -> 0未満カット
            imgProc = flipud(imgSub); 
            imgProc(imgProc < 0) = 0;
            
            % 4. リサイズ
            imgResized = imresize(imgProc, resolution, 'nearest');
            
            % 5. 校正係数の適用 (ベクトル部分のみ)
            % imgResized(k) は列ベクトルになるため、要素ごとに掛け算
            calibVal = squeeze(calibrationFactor(v, i, :));
            vecVal = imgResized(k) .* calibVal;
            
            % 6. 格納
            imageVectors(v, i, :) = vecVal;
            
            % --- 確認用プロット ---
            if doCheck
                figure(f1);
                % 4行8列のプロット配置
                subplot(4, 8, 8*(v-1) + i); 
                
                % 表示用に全画素に校正をかけた画像を作る（k以外は0のまま簡易表示）
                % ※厳密に表示したい場合はimgResized全体に校正マップをかける必要がありますが
                % ここではベクトル値の確認と割り切って元のresize画像を表示
                imagesc(imgResized);clim([50,400]);
                title(sprintf('%d, %d', v, i));
                axis image off;
            end
        end
    end

    % --- 出力データの整形 ---
    % 指定された shot number に対応するデータを抽出
    % squeezeで [View, Pixel] -> 1次元ベクトル化
    % 出力変数が4つに分かれているため個別に代入
    
    % imageVectors: [4, 8, pixels]
    % ここでの `number` は fiber index (1-8) を指すと想定
    
    imageVector1 = squeeze(imageVectors(1, number, :))';
    imageVector2 = squeeze(imageVectors(2, number, :))';
    imageVector3 = squeeze(imageVectors(3, number, :))';
    imageVector4 = squeeze(imageVectors(4, number, :))';

    % 特定日付の入れ替え処理
    if date == 240828 
        % 右下(4)と左上(2)の交換
        tmp = imageVector2;
        imageVector2 = imageVector4;
        imageVector4 = tmp;
    end
end