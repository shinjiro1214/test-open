function calibrationFactor = get_calibration_factor(date,N_projection)

calibrationPath = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date));
calibrationImage = imread(strcat(calibrationPath,'/PositionCheck.tif'));
% [centers,radii]=find_fibers(CalibrationImage);
% IW = round(mean(radii));
% centers = round(centers);
% 
% Center = zeros(2,8,2);
% TimeRapsImage = zeros(2,8,2*IW,2*IW);
% 
% Center(1,:,:) = centers([1,3,6,8,9,11,14,16],:);
% Center(2,:,:) = centers([2,4,5,7,10,12,13,15],:);

% 校正用画像からファイバーの位置（＋半径）を取得
if date == 230316
    radiusRange = [85,105];
else    
    radiusRange = [65,75];
end
% [Center,IW] = find_fibers2(calibrationImage,[65,75]);
[center,radii] = find_fibers_32ch(calibrationImage,radiusRange);
IW = mean(radii);
timeSeries = zeros(2,8,2*IW,2*IW);
center = round(center);

rawImage = calibrationImage;

% for i = 1:8
%     UpRangeV = Center(1,i,1)-IW+1:Center(1,i,1)+IW;
%     UpRangeH = Center(1,i,2)-IW+1:Center(1,i,2)+IW;
%     DownRangeV = Center(2,i,1)-IW+1:Center(2,i,1)+IW;
%     DownRangeH = Center(2,i,2)-IW+1:Center(2,i,2)+IW;
%     TimeRapsImage(1,i,:,:) = RawImage(UpRangeV,UpRangeH,1);
%     TimeRapsImage(2,i,:,:) = RawImage(DownRangeV,DownRangeH,1);
%     TimeRapsImage(1,i,:,:) = rot90(TimeRapsImage(1,i,:,:),2);
%     TimeRapsImage(2,i,:,:) = rot90(TimeRapsImage(2,i,:,:),2);
% end

% バックグラウンドノイズのデータを取得
backgroundImage = cast(rawImage(1:2*IW,1:2*IW,1),'double');
backgroundNoise = ones(size(backgroundImage))*mean(backgroundImage,'all');

% N_projection = 80;
k = FindCircle(N_projection/2);
imageVectors = zeros(4,8,numel(k));

resolution = N_projection/(IW*2);

% 画像データの行列化
for i=1:8
    % 画像切り取りの縦方向・横方向範囲を指定
    horizontalRange1 = center(1,i,1)-IW+1:center(1,i,1)+IW;
    verticalRange1 = center(1,i,2)-IW+1:center(1,i,2)+IW;
    horizontalRange2 = center(2,i,1)-IW+1:center(2,i,1)+IW;
    verticalRange2 = center(2,i,2)-IW+1:center(2,i,2)+IW;
    horizontalRange3 = center(3,i,1)-IW+1:center(3,i,1)+IW;
    verticalRange3 = center(3,i,2)-IW+1:center(3,i,2)+IW;
    horizontalRange4 = center(4,i,1)-IW+1:center(4,i,1)+IW;
    verticalRange4 = center(4,i,2)-IW+1:center(4,i,2)+IW;
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
    
%     whos RoughImage1
%     whos SD
%     
%     RoughImage1 = RoughImage1./fliplr(SD./100);
%     RoughImage2 = RoughImage2./fliplr(SD./100);

    % ベクトル化
    imageVectors(1,i,:) = roughImage1(k);
    imageVectors(2,i,:) = roughImage2(k);
    imageVectors(3,i,:) = roughImage3(k);
    imageVectors(4,i,:) = roughImage4(k);
end

% レンズに入射した一様な光が一様になるように補正
meanIntensity = mean(imageVectors,'all');
calibrationFactor = meanIntensity./imageVectors;

% calibrationFactor = ones(size(imageVectors));

% CalibrationSavePath = strcat(CalibrationPath,'/CalibrationFactor.mat');
% save(CalibrationSavePath,'CalibrationFactor');

% 角度補正（今のままだと上下逆＠231003）（MCPの分）
% imagescとpplotで上下が反転してるせい→どっちが正しい？
theta1 = -pi*3/4;
theta2 = -pi*1/4;
theta3 = pi*3/4;
theta4 = pi*1/4;
correctionTerm1 = get_angle_correction(N_projection,theta1);
correctionTerm2 = get_angle_correction(N_projection,theta2);
correctionTerm3 = get_angle_correction(N_projection,theta3);
correctionTerm4 = get_angle_correction(N_projection,theta4);

angleCorrection = ones(size(calibrationFactor));
for i = 1:8
    angleCorrection(1,i,:) = correctionTerm1;
    angleCorrection(2,i,:) = correctionTerm2;
    angleCorrection(3,i,:) = correctionTerm3;
    angleCorrection(4,i,:) = correctionTerm4;
end

calibrationFactor = calibrationFactor.*angleCorrection;
outlier = calibrationFactor>=3;
% calibrationFactor(outlier) = 3;
calibrationSavePath = strcat(calibrationPath,'/calibrationFactor.mat');
save(calibrationSavePath,'calibrationFactor');

end

function k = FindCircle(L)
R = zeros(2*L);
for i = 1:2*L
    for j = 1:2*L
        R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2);
    end
end
% figure;imagesc(R)
k = find(R<L);
end