%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1次元のプロット
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% データの読み込み
shotlist = [26:29];
date = 251219;
figure;hold on;
for shot = shotlist
    if shot < 10
        shotnum = ['00', num2str(shot)];
    else 
        shotnum = ['0', num2str(shot)];
    end

    % save_filepath = "G:\My Drive\lab\lab_data\mach_probe_rawdata";

    % 研究室内にいる場合のファイルパス
    % filepath = "\\NIFS\experiment\results\MachProbe\";
    % 研究室外のファイルパス
    % filepath = "G:\My Drive\lab\lab_data\mach_probe_rawdata";

    filepath = getenv('NIFS_TRIPLE');
    % filename = strcat(filepath, '\', num2str(date), '\ES_', num2str(date), shotnum, '.csv');
    filename = fullfile(filepath,num2str(date), ['ES_', num2str(date), shotnum, '.csv']);

    % ファイルの読み込み
    test = readmatrix(filename);
    index_start = 4500;
    index_end = 7500;


    I2_values = test(index_start:index_end, 36);
    % I3_values = test(index_start:index_end, 37);

    % 強化したスムージング
    I2_values = smoothdata(I2_values, 'movmean', 50);
    I3_values = smoothdata(I3_values, 'movmean', 50);

    % % 強化したスムージング
    % I2_values = smoothdata(I2_values, 'movmean', 10);
    % I3_values = smoothdata(I3_values, 'movmean', 10);
    time = test(index_start:index_end, 1);

    plot(time,I2_values);
end

xlim([460 480]);
ylabel('Probe current [A]');xlabel('time [us]')