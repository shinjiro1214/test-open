% 1. 画像読み込み
img = imread('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/SXR_Images/250220/shot005.tif');
% img = imread('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/SXR_Images/250220/shot002.tif');
% gray = rgb2gray(img);  % 既にモノクロなら不要
gray = img;

im_center = imread('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/SXR_Images/250220/shot002.tif');
% [centers,radii] = imfindcircles(gray,[60 80],'Sensitivity',0.995,"Method","twostage");
[centers,radii] = get_circle(im_center,[70 80]);

number = 4;
figure;hold on;
imagesc(gray);viscircles(centers(1:number,:),radii(1:number,:));
plot(centers(1:number,1),centers(1:number,2),'*','Color','red');
hold off;

% 閾値以上の値を1にする
% 円の外も1にする
% エッジ検出？

% 2. 白い円のマスクを抽出
bw = imbinarize(gray);           % 白い部分が1になるバイナリ画像
bw = imfill(bw, 'holes');        % 円の中も埋める
bw = bwareafilt(bw, 4);          % 面積の大きい4つの領域（円）だけ残す

% 3. 円内のみに限定してエッジ検出（黒い線分だけ）
masked_gray = gray;             
masked_gray(~bw) = 255;          % 円の外側を白で塗りつぶしてエッジ無視
edges = edge(masked_gray, 'canny');

% 4. Hough変換
[H, theta, rho] = hough(edges);
peaks = houghpeaks(H, 20);       % 最大20本の線分を取得（調整可能）
lines = houghlines(edges, theta, rho, peaks, 'FillGap', 5, 'MinLength', 10);

% 5. 線分の角度計算 & 表示
% figure, imshow(img), hold on
figure, imagesc(img), hold on
angles = zeros(length(lines), 1);
for k = 1:length(lines)
    pt1 = lines(k).point1;
    pt2 = lines(k).point2;
    line([pt1(1), pt2(1)], [pt1(2), pt2(2)], 'Color', 'green', 'LineWidth', 2);
    
    dx = pt2(1) - pt1(1);
    dy = pt2(2) - pt1(2);
    angle = atan2d(-dy, dx);
    angles(k) = mod(angle, 180);
end
hold off

% 結果出力
disp('検出された線分の角度（度）：');
disp(angles);


function [circleInformation,radii] = get_circle(imageFile,radiusRange)
    imageFile = wiener2(imageFile,[10,10]);
    imageFile = imadjust(imageFile);
    % 円を検出します．range,sensitivity,method がパラメータです．
    % この画像なら，range=[70,~], sensitivity=0.995がよさそう．[85,~]でも検知するけど，ちょっと大きめの円を取ってしまう
    [centers,radii] = imfindcircles(imageFile,radiusRange,'Sensitivity',0.995,"Method","twostage"); % 半径は必ず整数
    % 検出した円をnumber個だけ描画します．このとき，numberは32個の円が全て含まれる程度に大きく設定します．
    % numberに許される最大値はnumel(radii)で，TIF画像によりますがおよそ200程度ぽいです．優先度の低い円を考慮から外すためにnumberをある程度小さくする必要があります．
    % こちらを整理前のcentersとします．numberを調整したので検出に漏れはありませんがダブりがあります．

    number = 30;
    figure;hold on;
    imagesc(imageFile);viscircles(centers(1:number,:),radii(1:number,:));
    plot(centers(1:number,1),centers(1:number,2),'*','Color','red');
    hold off;

    % ダブりで検出した円を整理します．
    % 中心が近く同じ円を指すと判断されるものをgroupnumberでまとめます
    % ここで，その判断基準であるcenter同士の距離の閾値(if r<80)は上手くいくようにTIF画像ごとに変える必要があります．
    % 1,2行目が中心座標、3行目が半径、4行目がgroupnumbaerであるような配列circleInformationを作成
    circleInformation = [centers(1:number,:) radii(1:number) zeros([number,1])];
    groupnumber = 1;
    for i=1:number
        x1=circleInformation(i,1);y1=circleInformation(i,2);
        if circleInformation(i,4) == 0
            for j=i:number
                x2=circleInformation(j,1);y2=circleInformation(j,2);
                r = sqrt((x1-x2)^2+(y1-y2)^2);
                if r < 80
                    circleInformation(j,4) = groupnumber;
                end
            end
            groupnumber = groupnumber + 1;
        end
    end
    % 同じgroupnumberをもつ円情報を統合し，ひとつにします．
    % 同じ円を2回以上数えている場合は確度の最も高いものを採用します．
    for i = 1:groupnumber-1
        [row0,~,~] = find(circleInformation == i);
        rows = find(circleInformation(:,4)==i);
        if numel(rows) >1
            row = rows(1);
        else 
            row = rows;
        end

        center_mean_x = sum(circleInformation(row,1))/numel(row);
        center_mean_y = sum(circleInformation(row,2))/numel(row);
        radius_mean = sum(circleInformation(row,3))/numel(row);
        circleInformation(row0,:) = [];circleInformation(end+1,:) = [center_mean_x,center_mean_y,radius_mean,i];
    end
    radii = circleInformation(:,3);circleInformation = circleInformation(:,1:2);
end