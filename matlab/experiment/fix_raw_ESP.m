
% フォルダパスを設定
folderPath = "/Users/rsomeya/Desktop/240828";  % フォルダパスを適宜変更
files = dir(fullfile(folderPath, '*.csv'));

% CSVファイルごとに処理
for i = 1:length(files)
    fileName = files(i).name;
    filePath = fullfile(folderPath, fileName);

    % CSVファイルを読み込む（テーブル形式）
    data = readtable(filePath);

    % 1列目の2行目以降の値を取得し、7を加算
    try
        % 2行目以降の1列目が数値の場合にのみ処理を行う
        numericValues = data{1:end, 1};
        if isnumeric(numericValues)
            % 7を加算
            data{1:end, 1} = numericValues + 7;
        else
            warning('ファイル %s の1列目が数値でないためスキップしました。', fileName);
            continue;
        end

        % 修正したデータを同じファイルに上書き保存
        writetable(data, filePath);
        fprintf('修正完了: %s\n', fileName);
    catch ME
        % エラーハンドリング
        fprintf('エラーが発生しました: %s (%s)\n', fileName, ME.message);
    end
end

disp('全てのファイルの処理が完了しました。');

disp('全てのファイルの処理が完了しました。');