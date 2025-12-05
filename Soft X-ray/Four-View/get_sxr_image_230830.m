function [imageVector1,imageVector2,imageVector3,imageVector4] = get_sxr_image_230830(date,number,projectionNumber,rawImage)

% 画像を切り取ってベクトル形式で出力
% 全時間帯の画像を全て出力するかどうか
% 使う分だけでいい？
% 4つのベクトルを出力するか
% 画像は校正用イメージをもとに切り取る感じで
% 入射角度補正をかけるかどうか
% 校正用データをもとに半径決めてその半径内で強度の補正をつけると小さい円の外周部が過剰に大きくなる
% 半径は固定？それとも可変？
% 4つのファイバーそれぞれの半径が同じくらいであれば4つの異なる半径を採用
% 大体全部同じようなら小さめで採用
% そもそも今回は断面全体は使わない予定なので問題なし？

% % 画像を切り取る
% N_projection = 80;
% VectorImages = CutImage(date,shot,N_projection/230,false);
% doCheck = true;
doCheck = false;

% % 生画像の取得
% rawImage = imread(sxrFilename);
% 
% % 非線形フィルターをかける（必要があれば）
% if doFilter
%     figure;imagesc(rawImage);
%     [rawImage,~] = imnlmfilt(rawImage,'SearchWindowSize',91,'ComparisonWindowSize',15);
%     figure;imagesc(rawImage);
% end

% % ファイバーの位置を検索するための校正用画像を取得
% fiberPositionFile = strcat('/Users/shinjirotakeda/OneDrive - The University of Tokyo/Documents/SXR_Images/',num2str(date),'/PositionCheck.tif');
% calibrationImage = imread(fiberPositionFile);

% % 校正用画像からファイバーの位置（＋半径）を取得
% [centers,radii]=find_fibers(calibrationImage,[70,130]);
% IW = 85;
% % IW = round(mean(radii));
% centers = round(centers);
% % それぞれのファイバーの中心を格納するための配列を定義（ここまでFindFibersでやれば良くない？）
% Center = zeros(2,8,2);
% Center(1,:,:) = centers([1,3,6,8,9,11,14,16],:);
% Center(2,:,:) = centers([2,4,5,7,10,12,13,15],:);

% % 校正用画像からファイバーの位置（＋半径）を取得
% if date == 230721
%     positionPath = '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View/fiberPositions.xlsx';
%     centers = readmatrix(positionPath,'Sheet','230721','Range','C2:D33');
%     Center = zeros(4,8,2);
%     for i = 1:4
%         Center(i,:,:) = centers(1+8*(i-1):8+8*(i-1),:);
%     end
%     IW = 60;
% else
%     [Center,IW] = find_fibers2(calibrationImage,[65,75]);
% end

% 位置情報ファイルからファイバーの位置（＋半径）を取得
positionPath = '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View/fiberPositions.xlsx';
positionData = readmatrix(positionPath,'Sheet',num2str(date),'Range','C2:E17');
Center = zeros(4,4,2);
for i = 1:4
    Center(i,:,:) = positionData(1+4*(i-1):4+4*(i-1),1:2);
end
IW = positionData(1,3);

Center = round(Center);

% 切り取った画像を格納するための配列
timeSeries = zeros(4,4,2*IW,2*IW);

% % 各時間帯ごとに画像を切り取って格納
% for i = 1:8
%     UpRangeV = Center(1,i,1)-IW+1:Center(1,i,1)+IW;
%     UpRangeH = Center(1,i,2)-IW+1:Center(1,i,2)+IW;
%     DownRangeV = Center(2,i,1)-IW+1:Center(2,i,1)+IW;
%     DownRangeH = Center(2,i,2)-IW+1:Center(2,i,2)+IW;
%     TimeRapsImage(1,i,:,:) = rawImage(UpRangeV,UpRangeH,1);
%     TimeRapsImage(2,i,:,:) = rawImage(DownRangeV,DownRangeH,1);
%     TimeRapsImage(1,i,:,:) = rot90(TimeRapsImage(1,i,:,:),2);
%     TimeRapsImage(2,i,:,:) = rot90(TimeRapsImage(2,i,:,:),2);
% end

% バックグラウンドノイズのデータを取得
backgroundImage = cast(rawImage(1:2*IW,1:2*IW,1),'double');
backgroundNoise = ones(size(backgroundImage))*mean(backgroundImage,'all');

% 切り取った画像のうち実際に使う部分（ファイバー部分）を切り出し
k = find_circle(projectionNumber/2);
imageVectors = zeros(4,4,numel(k));

if doCheck
    f1=figure;
    % f1.Position = [900,200,500,500];
    f1.Position = [200,250,1060,500];
    % f2=figure;
    % f2.Position = [900,200,500,500];
end

% 校正用データ（matファイル）が存在する場合はそれを取得、しなければ計算
calibrationPath = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date),'/calibrationFactor.mat');
if exist(calibrationPath,'file')
    load(calibrationPath,'calibrationFactor');
    if numel(calibrationFactor(1,1,:)) ~= numel(k)
        calibrationFactor = get_calibration_factor_230830(date,projectionNumber);
    end
else
    calibrationFactor = get_calibration_factor_230830(date,projectionNumber);
end

% 再構成計算に使用可能なサイズに変換するための解像度を取得
resolution = projectionNumber/(IW*2);

% 画像データの行列化
for i=1:4
    % 画像切り取りの縦方向・横方向範囲を指定
    horizontalRange1 = Center(1,i,1)-IW+1:Center(1,i,1)+IW;
    verticalRange1 = Center(1,i,2)-IW+1:Center(1,i,2)+IW;
    horizontalRange2 = Center(2,i,1)-IW+1:Center(2,i,1)+IW;
    verticalRange2 = Center(2,i,2)-IW+1:Center(2,i,2)+IW;
    horizontalRange3 = Center(3,i,1)-IW+1:Center(3,i,1)+IW;
    verticalRange3 = Center(3,i,2)-IW+1:Center(3,i,2)+IW;
    horizontalRange4 = Center(4,i,1)-IW+1:Center(4,i,1)+IW;
    verticalRange4 = Center(4,i,2)-IW+1:Center(4,i,2)+IW;
    % 生画像を切り取ってファイバー数×フレーム数×IW×IWの配列に格納
    timeSeries(1,i,:,:) = rawImage(verticalRange1,horizontalRange1,1);
    timeSeries(2,i,:,:) = rawImage(verticalRange2,horizontalRange2,1);
    timeSeries(3,i,:,:) = rawImage(verticalRange3,horizontalRange3,1);
    timeSeries(4,i,:,:) = rawImage(verticalRange4,horizontalRange4,1);

    % バックグラウンドノイズ成分を差し引く
    singleImage1 = squeeze(timeSeries(1,i,:,:))-backgroundNoise;
    singleImage2 = squeeze(timeSeries(2,i,:,:))-backgroundNoise;
    singleImage3 = squeeze(timeSeries(3,i,:,:))-backgroundNoise;
    singleImage4 = squeeze(timeSeries(4,i,:,:))-backgroundNoise;
    grayImage1 = flipud(singleImage1(:,:));
    grayImage2 = flipud(singleImage2(:,:));
    grayImage3 = flipud(singleImage3(:,:));
    grayImage4 = flipud(singleImage4(:,:));
    grayImage1(grayImage1<0) = 0;
    grayImage2(grayImage2<0) = 0;
    grayImage3(grayImage3<0) = 0;
    grayImage4(grayImage4<0) = 0;
    % 再構成計算に使用可能なサイズに変換
    roughImage1 = imresize(grayImage1, resolution, 'nearest');
    roughImage1 = cast(roughImage1,'double');
    roughImage2 = imresize(grayImage2, resolution, 'nearest');
    roughImage2 = cast(roughImage2,'double');
    roughImage3 = imresize(grayImage3, resolution, 'nearest');
    roughImage3 = cast(roughImage3,'double');
    roughImage4 = imresize(grayImage4, resolution, 'nearest');
    roughImage4 = cast(roughImage4,'double');

    % 校正データを用いた明るさの修正（カメラの影の補正とか）や入射角度の補正をここでやりたい
    % figure;imagesc(roughImage1);
    roughImage1(k) = roughImage1(k).*squeeze(calibrationFactor(1,i,:));
    roughImage2(k) = roughImage2(k).*squeeze(calibrationFactor(2,i,:));
    roughImage3(k) = roughImage3(k).*squeeze(calibrationFactor(3,i,:));
    roughImage4(k) = roughImage4(k).*squeeze(calibrationFactor(4,i,:));
    % figure;imagesc(roughImage1);

    % 切り出した画像を表示
    if doCheck
        figure(f1);
        i_str = num2str(i);
        title1 = strcat('1,',i_str);
        title2 = strcat('2,',i_str);
        title3 = strcat('3,',i_str);
        title4 = strcat('4,',i_str);
        subplot(4,4,4*(i-1)+1);imagesc(roughImage1);title(title1);
%         caxis([50,60]);
        subplot(4,4,4*(i-1)+2);imagesc(roughImage2);title(title2);
%         caxis([50,60]);
        subplot(4,4,4*(i-1)+3);imagesc(roughImage3);title(title3);
        subplot(4,4,4*(i-1)+4);imagesc(roughImage4);title(title4);
%         if i == 8
%             colorbar;
%         end

        % figure(f2);
        % RoughCalibrated1 = RoughImage1;
        % RoughCalibrated1(k) = RoughCalibrated1(k).*squeeze(CalibrationFactor(1,i,:));
        % subplot(4,4,2*(i-1)+1);imagesc(RoughCalibrated1);title(title1);
        % RoughCalibrated2 = RoughImage2;
        % RoughCalibrated2(k) = RoughCalibrated2(k).*squeeze(CalibrationFactor(1,i,:));
        % subplot(4,4,2*(i-1)+2);imagesc(RoughCalibrated2);title(title2);
    end

    % ベクトル化
    imageVectors(1,i,:) = roughImage1(k);
    imageVectors(2,i,:) = roughImage2(k);
    imageVectors(3,i,:) = roughImage3(k);
    imageVectors(4,i,:) = roughImage4(k);
end

imageVectors1 = squeeze(imageVectors(1,:,:));
imageVectors2 = squeeze(imageVectors(2,:,:));
imageVectors3 = squeeze(imageVectors(3,:,:));
imageVectors4 = squeeze(imageVectors(4,:,:));
imageVector1 = imageVectors1(number,:);
imageVector2 = imageVectors2(number,:);
imageVector3 = imageVectors3(number,:);
imageVector4 = imageVectors4(number,:);

if date == 240828 %右下と左上の交換
    imageVector2_new = imageVector4;
    imageVector4 = imageVector2;
    imageVector2 = imageVector2_new;
end


% function k = find_circle(L)
% R = zeros(2*L);
% for i = 1:2*L
%     for j = 1:2*L
%         R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2);
%     end
% end
% % figure;imagesc(R)
% k = find(R<L);
% end