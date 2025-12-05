function [centerPositions,radii] = find_fibers_32ch(calibrationImage,radiusRange)

% 中心位置のインデックス
centerIdx1 = [1,3,11,9,17,19,27,25];
centerIdx2 = [2,4,12,10,18,20,28,26];
centerIdx3 = [5,7,15,13,21,23,31,29];
centerIdx4 = [6,8,16,14,22,24,32,30];
centerIdx = [centerIdx1;centerIdx2;centerIdx3;centerIdx4];

% このブロックでは，ファイバーの較正画像から32個の円を漏れなく検出することを目指します
% 個別のTIF画像で調整すべき変数は，画像path, imfindcircles(RadiusRenge, Sensitivity), numberです．
% 画像を読み込み，前処理を施します．
% CalibrationImage = imread(FiberCalibrationImagePath);% imagesc(CalibrationImage);title(CalibrationImage,'RawImage');
calibrationImage = wiener2(calibrationImage,[10,10]);% imagesc(CalibrationImage);title(CalibrationImage,'WienerFiltered<RawImage');
calibrationImage = imadjust(calibrationImage);% imagesc(CalibrationImage);title(CalibrationImage,'ContrastAdjusted<WienerFiltered<RawImage');
% 円を検出します．range,sensitivity,method がパラメータです．
% この画像なら，range=[70,~], sensitivity=0.995がよさそう．[85,~]でも検知するけど，ちょっと大きめの円を取ってしまう
% if date == 230316
%     radiusRange = [85,105];
% else    
%     radiusRange = [65,75];
% end
% [centers,radii] = imfindcircles(calibrationImage,radiusRange,'Sensitivity',0.995,"Method","twostage");
[centers,radii] = imfindcircles(calibrationImage,radiusRange,'Sensitivity',0.999,"Method","twostage");
% 検出した円をnumber個だけ描画します．このとき，numberは32個の円が全て含まれる程度に大きく設定します．
% numberに許される最大値はnumel(radii)です．優先度の低い円を考慮から外すためにnumberをある程度小さくする必要があります．
% こちらを整理前のcentersとします．
number = 60;

% 検出した円を整理できないか試します．
% 中心が近く同じ円を指すと判断されるものをgroupnumberでまとめます
centers = [centers(1:number,:) radii(1:number) zeros([number,1])];
groupnumber = 1;
r_min = min(radii(1:number));
for i=1:number
    x1=centers(i,1);y1=centers(i,2);%r1=centers(i,3);
    if centers(i,4) == 0
        for j=i:number
            x2=centers(j,1);y2=centers(j,2);
            r = sqrt((x1-x2)^2+(y1-y2)^2);
            if r < 2*r_min%100
                centers(j,4) = groupnumber;
            end
        end
        groupnumber = groupnumber + 1;
    end
end
% ここでは，同じgroupnumberをもつ円情報を統合し，ひとつにします．
% ただし同じ円を4回以上数えている場合は優先度の高い上位3つ以外は考慮から外します．
for i = 1:groupnumber-1
    [row0,~,~] = find(centers == i);
    if numel(row0) >1
        row = row0(1);
    else 
        row = row0;
    end
    center_mean_x = sum(centers(row,1))/numel(row);
    center_mean_y = sum(centers(row,2))/numel(row);
    radius_mean = sum(centers(row,3))/numel(row);
    centers(row0,:) = [];centers(end+1,:) = [center_mean_x,center_mean_y,radius_mean,i];
end
radii = centers(:,3);centers = centers(:,1:2);
% % 整理後のcentersです．ただし時系列には整列されていません．
% figure;hold on;imagesc(calibrationImage);viscircles(centers,radii,'LineWidth',1,'EnhanceVisibility',0);plot(centers(:,1),centers(:,2),'*','Color','red');set(gcf,'Name','ファイバーチェック画像に対する円検出','NumberTitle','off');hold off;
% centersを時系列に整理します．
% まず横軸x座標を基準に並び替えます
centers = [centers radii];
[~,I] = sort(centers(:,1),'descend'); %1列目の要素を降順（大きい方（右）から順）に並び替える
centers = centers(I,:);%1列目基準で全体を並び替える
% 次に横軸が近しい4つのデータの中で，縦軸を基準に並び替えます．
% これで，右上から左下に五十音表と同じ順に整理されます
for i = 1:8
    range = 1+4*(i-1):1:4+4*(i-1);
    % [~,I] = sort(centers(range,2),'descend');%2列目の要素を降順（大きい方（下）から順）に並び替える
    [~,I] = sort(centers(range,2));%2列目の要素を昇順（小さい方（上）から順）に並び替える
    I = I + 4*(i-1);
    centers(range,:) = centers(I,:);
end
% 次にX線フィルタ種類と時系列順に整理します．
% X線フィルタは，右上を1，右下を2, 左下を4とします
% CentersTimeRaps(3,:,:)はX線フィルタ3の時系列[8 2]行列です．
% CentersTimeRaps(3,4,:)はX線フィルタ3の時系列4番目のxy座標です．
centersTimeRaps = zeros(4,8,3);
for i = 1:4
    centersTimeRaps(i,:,:) = centers(centerIdx(i,:),:);
end
centerPositions = centersTimeRaps(:,:,1:2);
radii = repmat(max(centersTimeRaps(:,:,3),[],'all'),[32,1]);