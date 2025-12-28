function save_dtacq_data(dtacq_num, shot, tfshot, filename, run_background)
    if nargin < 5, run_background = false; end % デフォルトは待機

    [folder, ~, ~] = fileparts(filename);
    if ~exist(folder, 'dir'), mkdir(folder); end

    if exist(filename, 'file') == 0
        % パス設定
        pyScriptPath = '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/get_mds_data.py';
        pythonCmd = '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-View/venv_x86/bin/python3';
        
        % コマンド生成
        cmd = sprintf('export DYLD_LIBRARY_PATH=/usr/local/mdsplus/lib:$DYLD_LIBRARY_PATH; arch -x86_64 "%s" "%s" %d %d %d "%s"', ...
                      pythonCmd, pyScriptPath, dtacq_num, shot, tfshot, filename);
        
        if run_background
            % バックグラウンド実行（& をつける）
            system([cmd ' > /dev/null 2>&1 &']);
        else
            % 通常実行（待機する）
            [status, cmdout] = system(cmd);
            if status ~= 0 || contains(cmdout, 'Error') || contains(cmdout, 'Failed')
                 error('Python script failed: %s', cmdout);
            end
            if exist(filename, 'file') == 0
                error('Python finished but .mat file was not created.');
            end
        end
    end
end