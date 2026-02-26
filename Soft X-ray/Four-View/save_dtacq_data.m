function save_dtacq_data(dtacq_num, shot, tfshot, filename, run_background)
    if nargin < 5, run_background = false; end

    [folder, ~, ~] = fileparts(filename);
    if ~exist(folder, 'dir'), mkdir(folder); end

    if exist(filename, 'file') == 0
        % パス設定 (ユーザー環境に合わせてください)
        pyScriptPath = '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/get_mds_data.py';
        pythonCmd = '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/venv_x86/bin/python3';
        
        % 基本コマンド
        baseCmd = sprintf('export DYLD_LIBRARY_PATH=/usr/local/mdsplus/lib:$DYLD_LIBRARY_PATH; arch -x86_64 "%s" "%s" %d %d %d "%s"', ...
                      pythonCmd, pyScriptPath, dtacq_num, shot, tfshot, filename);
        
        if run_background
            % 【バックグラウンド時】
            % MATLABは待機しないためエラーを直接拾えません。
            % 代わりにエラーログを同ディレクトリの .log ファイルに書き出します。
            logFile = [filename '.log'];
            cmd = sprintf('%s > "%s" 2>&1 &', baseCmd, logFile);
            system(cmd);
            fprintf('Background task started. Check log if failed: %s\n', logFile);
        else
            % 【フォアグラウンド時（通常）】
            % 実行してステータスと出力を取得
            [status, cmdout] = system(baseCmd);
            
            % status が 0 以外ならエラーとみなす
            if status ~= 0
                 % PythonのTracebackをMATLABのエラーとして表示
                 error('Python Error Occurred:\n%s', cmdout);
            end
            
            % ファイル生成の念押し確認
            if exist(filename, 'file') == 0
                error('Python script finished with success code, but .mat file was not found.\nOutput: %s', cmdout);
            end
        end
    end
end