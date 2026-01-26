addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View'

pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';

% --- SXR Low (EE1) ---
% nshot_1 = 17;
nshot_1 = 7;
path_1 = strcat(pathFirstHalf, num2str(nshot_1), pathLastHalf);

% 座標設定
rmin = 70/1000; rmax = 375/1000;
r_space_SXR = linspace(rmin, rmax, 50);
z_space_SXR2 = linspace(-0.2, 0.2, 50); % zmin2, zmax2
z_space_SXR1 = linspace(-0.2, 0.2, 50); % zmin1, zmax1

if exist(path_1, 'file')
    load(path_1, 'EE1');
    z_indices_SXR2 = abs(z_space_SXR2) <= 0.01;
    SXR_r_tmp1 = EE1(:, z_indices_SXR2);
    SXR_mean_1 = mean(SXR_r_tmp1, 2);
    SXR_std_1 = std(SXR_r_tmp1, 0, 2);
else
    warning('SXR EE1 not found.');
    SXR_mean_1 = zeros(50,1); SXR_std_1 = zeros(50,1);
end

% --- SXR High (EE4) ---
nshot_4 = 9;
path_4 = strcat(pathFirstHalf, num2str(nshot_4), pathLastHalf);

if exist(path_4, 'file')
    load(path_4, 'EE4');
    EE4 = EE4 .* 2; % ユーザーコードのスケール補正
    z_indices_SXR1 = abs(z_space_SXR1) <= 0.01;
    SXR_r_tmp4 = EE4(:, z_indices_SXR1);
    SXR_mean_4 = mean(SXR_r_tmp4, 2);
    SXR_std_4 = std(SXR_r_tmp4, 0, 2);
else
    warning('SXR EE4 not found.');
    SXR_mean_4 = zeros(50,1); SXR_std_4 = zeros(50,1);
end

x_range = [0.1, 0.25];

figure;hold on;
% errorbar(r_space_SXR, SXR_mean_1, SXR_std_1, 'o-', 'LineWidth', 2, ...
%         'CapSize', 8, 'MarkerSize', 5);
% errorbar(r_space_SXR, SXR_mean_4, SXR_std_4, 'o-', 'LineWidth', 2, ...
%         'CapSize', 8, 'MarkerSize', 5);
errorbar(r_space_SXR, SXR_mean_1+0.04, SXR_std_1, 'o-', 'LineWidth', 2, ...
        'CapSize', 8, 'MarkerSize', 5);
errorbar(r_space_SXR, SXR_mean_4+0.04, SXR_std_4, 'o-', 'LineWidth', 2, ...
        'CapSize', 8, 'MarkerSize', 5);

legend({'I_{20-80 eV}','I_{100 eV <}'},'Location','best');
xlim(x_range);
ylim([0, Inf]);
ylabel('SXR intensity [a.u.]');
xlabel('r [m]');
grid on; ax = gca; ax.FontSize = 18;