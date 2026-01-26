%% データの再処理と別名保存

date=240111;

% 1. ファイルパスの構築
% (元のコードの変数 pathname.MAGDATA と date を使用します)
if ~exist('pathname', 'var') || ~isfield(pathname, 'MAGDATA')
    pathname.MAGDATA = getenv('MAGDATA_DIR'); % 変数が消えている場合の再取得
end

originalFile = strcat(pathname.MAGDATA, '/', num2str(date), '.mat');
newFile      = strcat(pathname.MAGDATA, '/', num2str(date), '_new.mat');

% 2. ファイルの存在確認と読み込み
if exist(originalFile, 'file')
    fprintf('読み込み中: %s\n', originalFile);
    
    % データを構造体として読み込む（変数が混ざらないようにするため）
    data = load(originalFile);
    
    % 3. 指定の処理を実行
    % "bListのすべての値に3をかけて4を引く"
    if isfield(data, 'bList')
        data.bList = data.bList * 3 - 4;
        fprintf('計算処理 (bList * 3 - 4) を完了しました。\n');
    else
        warning('ファイル内に bList が見つかりませんでした。計算をスキップします。');
    end
    
    % 4. 新しいファイル名で保存
    % 構造体のフィールドを個別の変数として展開して保存します
    % (-struct オプションを使うと、構造体の中身がそのまま変数として保存されます)
    save(newFile, '-struct', 'data');
    
    fprintf('保存完了: %s\n', newFile);
else
    error('ファイルが見つかりません: %s', originalFile);
end