clear; clc;

%% 1. 基本設定（パス・座標定義）

% --- パス設定 ---
pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';

% 保存先フォルダの設定
saveDirName = '240111_new'; % 保存フォルダ名
[parentDir, ~] = fileparts(pathFirstHalf);
[grandParentDir, ~] = fileparts(parentDir);
% saveBasePath = fullfile(parentDir, saveDirName); 
saveBasePath = fullfile(grandParentDir, saveDirName); 

% フォルダがなければ作成
if ~exist(saveBasePath, 'dir')
    mkdir(saveBasePath);
    disp(['保存用フォルダを作成しました: ', saveBasePath]);
end

% --- 処理するショット番号のリスト ---
% switch文にあった番号を網羅しています。必要に応じて増減してください。
shotList = [19, 20, 21, 22, 24, 25, 28, 29]; 

% --- 座標系の定義 (全ショット共通と仮定) ---
% 元コードの定義に従い、50x50のグリッドを作成します
zmin1=-200; zmax1=200;
zmin2=-200; zmax2=200;
rmin=70; rmax=375;
range = [zmin1, zmax1, zmin2, zmax2, rmin, rmax] ./ 1000; % mm -> m 変換

z_space_SXR1 = linspace(range(1), range(2), 50);
z_space_SXR2 = linspace(range(3), range(4), 50);
r_space_SXR  = linspace(range(5), range(6), 50);

% メッシュグリッドの作成 (補間用)
[Z1, R] = meshgrid(z_space_SXR1, r_space_SXR);
[Z2, ~] = meshgrid(z_space_SXR2, r_space_SXR);

% griddedInterpolant用の1次元ベクトル (行, 列 の順序に注意)
vec_r = r_space_SXR; 
vec_z1 = z_space_SXR1;
vec_z2 = z_space_SXR2;

%% 2. ループ処理開始

disp('--- 一括補正処理を開始します ---');

for i = 1:length(shotList)
    n_shot = shotList(i);
    
    % --- ファイルパスの構築 ---
    % 例: .../shot21/3.mat
    loadPath = strcat(pathFirstHalf, num2str(n_shot), pathLastHalf);
    
    % ファイルの存在確認
    if ~isfile(loadPath)
        warning(['ファイルが見つかりません、スキップします: ', loadPath]);
        continue;
    end
    
    % データの読み込み
    fprintf('Processing Shot %d ... ', n_shot);
    loadedData = load(loadPath, 'EE1', 'EE2', 'EE3', 'EE4');
    EE1 = loadedData.EE1;
    EE2 = loadedData.EE2;
    EE3 = loadedData.EE3;
    EE4 = loadedData.EE4;
    
    % --- 補正値 (Shift) の決定 ---
    switch n_shot
        case 19
            CV_z = [-0.03, -0.01, 0.015];
            CV_r = [0.005, 0.01, -0.02];
        case 20
            CV_z = [-0.03, -0.01, -0.008];
            CV_r = [0.01, 0.005, -0.012];
        case 21
            CV_z = [-0.03, 0, 0];
            CV_r = [0, 0.002, -0.018];
        case 22
            CV_z = [-0.02, -0.01, -0.005];
            CV_r = [0.01, 0.014, -0.018];
        case 24
            CV_z = [-0.03, 0, 0.01];
            CV_r = [0.005, 0, -0.01];
        case 25
            CV_z = [-0.02, -0.01, -0.012];
            CV_r = [0.01, 0.014, -0.002];
        case 28
            CV_z = [-0.03, -0.01, -0.015];
            CV_r = [0.02, 0.015, -0.02];
        case 29
            CV_z = [-0.03, -0.01, -0.015];
            CV_r = [0.01, 0.0, -0.02];
        otherwise
            CV_z = [0,0,0];
            CV_r = [0,0,0];
            fprintf('(補正値未定義のためシフトなし) ');
    end
    
    % --- 補間・外挿処理 ---
    % ExtrapolationMethod = 'nearest' で境界値を維持して外挿します
    
    % 1. EE1 (1um Al) -> Index 1
    shift_z = CV_z(1); shift_r = CV_r(1);
    F = griddedInterpolant({vec_r, vec_z2}, EE1, 'linear', 'nearest');
    EE1_new = F(R - shift_r, Z2 - shift_z);
    
    % 2. EE2 (2.5um Al) -> Index 2
    shift_z = CV_z(2); shift_r = CV_r(2);
    F = griddedInterpolant({vec_r, vec_z2}, EE2, 'linear', 'nearest');
    EE2_new = F(R - shift_r, Z2 - shift_z);
    
    % 3. EE4 (1um Mylar) -> Index 3 (Z1軸を使用することに注意)
    shift_z = CV_z(3); shift_r = CV_r(3);
    F = griddedInterpolant({vec_r, vec_z1}, EE4, 'linear', 'nearest');
    EE4_new = F(R - shift_r, Z1 - shift_z);
    
    % 4. EE3 (2um Mylar) -> 補正なし（必要なら追加してください）
    EE3_new = EE3; 
    
    % --- データの保存 ---
    % 変数名を書き戻す
    EE1 = EE1_new;
    EE2 = EE2_new;
    EE3 = EE3_new;
    EE4 = EE4_new;
    
    % --- 保存処理 (フォルダ階層作成) ---
    
    % 1. 各ショット用のフォルダパスを作成 (例: .../shot_corrected_extrapolated/shot21)
    currentShotDir = fullfile(saveBasePath, ['shot', num2str(n_shot)]);
    
    % 2. フォルダが存在しなければ作成
    if ~exist(currentShotDir, 'dir')
        mkdir(currentShotDir);
    end
    
    % 3. ファイル名の抽出 (pathLastHalf から '3.mat' を取得)
    [~, fName, fExt] = fileparts(pathLastHalf); 
    saveFileName = [fName, fExt]; % '3.mat'
    
    % 4. 完全なパスを作成 (例: .../shot21/3.mat)
    saveFullFile = fullfile(currentShotDir, saveFileName);
    
    % 5. 保存
    save(saveFullFile, 'EE1', 'EE2', 'EE3', 'EE4');
    
    fprintf('-> Saved to: %s\n', saveFileName);
end

disp('--- 全処理完了 ---');