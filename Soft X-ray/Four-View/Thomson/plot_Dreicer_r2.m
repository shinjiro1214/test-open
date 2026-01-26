% plot_Dreicer_r_multi_avg
% 径方向に電子密度、温度をプロットし、Dreicer電場を計算
% 同じ時刻のデータを平均してエラーバー付きでプロットする

addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

% --- データ設定 ---
thomsonShotList = [30,31,32,33,36,37,38,40,42];
thomsonTimeList = [462,462,464,464,466,466,468,468,468];

% 物理定数
e0 = 8.85e-12;
e = 1.6e-19;
me = 9.11e-31;

% ユニークな時間を抽出（ソートしておく）
uniqueTimes = unique(thomsonTimeList);
numTimes = length(uniqueTimes);

figure; hold on;
% 色のリストを作成（時間ごとに色を変えるため）
colors = lines(numTimes);

for t = 1:numTimes
    targetTime = uniqueTimes(t);
    
    % この時間に該当するショットのインデックスを探す
    shotIndices = find(thomsonTimeList == targetTime);
    
    % この時間の計算結果を一時保存する配列
    Ed_collection = [];
    
    % --- 該当するショットをすべてループしてデータを集める ---
    for k = 1:length(shotIndices)
        idx = shotIndices(k);
        thomsonIdx = thomsonShotList(idx);
        
        % パスの生成
        thomsonPath = ['/Users/shinjirotakeda/Downloads/ThomsonData/250325',num2str(thomsonIdx,'%03i'),'_TeNePe.csv'];
        
        % データ読み込み（ファイルがない場合のエラー処理は適宜追加してください）
        if exist(thomsonPath, 'file')
            T = readmatrix(thomsonPath);
            
            % データの整形
            r = reshape(T(:,2),7,[]);
            z = reshape(T(:,3),7,[]);
            
            Te_mat = reshape(T(:,4),7,[]);
            SD_Te_mat = reshape(T(:,5),7,[]);
            % SN比カット
            Te_mat(Te_mat./SD_Te_mat < 0.15) = NaN;
            
            ne_mat = reshape(T(:,6),7,[]);
            SD_ne_mat = reshape(T(:,7),7,[]);
            % SN比カット
            ne_mat(ne_mat./SD_ne_mat < 0.15) = NaN;
            
            z_axis = z(:,1);
            r_axis = r(1,:); % r軸は共通と仮定
            
            % Z方向の範囲指定と平均
            z_indices = abs(z_axis) <= 0.01;
            
            ne_tmp = squeeze(ne_mat(z_indices,:));
            ne_mean_shot = mean(ne_tmp, 1, 'omitnan'); % Z方向平均
            
            Te_tmp = squeeze(Te_mat(z_indices,:));
            Te_mean_shot = mean(Te_tmp, 1, 'omitnan'); % Z方向平均
            
            % --- Dreicer電場の計算 (各ショットごと) ---
            % NaNが含まれると結果もNaNになるが、後のmean/stdで除外されるのでOK
            lambdaD = sqrt(e0 .* e .* Te_mean_shot ./ (e^2 .* ne_mean_shot));
            Lambda = 4 * pi * ne_mean_shot .* lambdaD.^3;
            
            % 計算式 (元のコードの係数を維持)
            E_D_shot = 0.43 * e^3 * ne_mean_shot .* log(Lambda) ./ (8 * pi * e0^2 * e .* Te_mean_shot);
            
            % コレクションに追加 (行:ショット, 列:半径)
            Ed_collection = [Ed_collection; E_D_shot];
        else
            warning(['File not found: ', thomsonPath]);
        end
    end
    
    % --- 統計処理 (時間ごとの平均と標準偏差) ---
    if ~isempty(Ed_collection)
        % ショット方向(dim=1)に対して平均と標準偏差をとる
        % 'omitnan' を使うことで、NaNを除外して計算する
        Ed_mean_time = mean(Ed_collection, 1, 'omitnan');
        Ed_std_time = std(Ed_collection, 0, 1, 'omitnan');
        
        % --- プロット ---
        % errorbar(x, y, y_error)
        eb = errorbar(r_axis, Ed_mean_time, Ed_std_time, ...
            'LineWidth', 1.5, ...
            'Marker', 'o', ...
            'MarkerSize', 6, ...
            'CapSize', 10, ...
            'Color', colors(t,:), ...
            'MarkerFaceColor', colors(t,:));
    end
end

% --- グラフの体裁 ---
ylabel('Dreicer electric field [V/m]');
xlabel('r [m]');

% 凡例の作成
mu_str = char(181); 
legendLabels = string(uniqueTimes) + " " + mu_str + "s";
legend(legendLabels, 'Location', 'best');

ax = gca;
ax.FontSize = 18;
grid on;
% xlim([0.1 0.25]); % 必要に応じてコメントアウトを外す