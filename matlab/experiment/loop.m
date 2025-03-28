while true
    run main_pcb280ch.m
    opts.Interpreter = 'none';
    opts.Default = 'Yes';
    answer = questdlg('続行しますか?', ...
	'続行許可', ...
	'Yes','No',opts);
    % Handle response
    switch answer
        case 'Yes'
            disp(answer)
        case 'No'
            disp(answer)
            break
    end
end