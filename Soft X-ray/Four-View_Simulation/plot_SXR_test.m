function plot_SXR_test()
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Four-view';
%ReconMethod = 0; %0:Tikhonov, 1:Fisher, 2:MEM
plot_flag1 = true;
plot_flag2 = true;

% 再構成条件の定義
newProjectionNumber = 30;%80; %投影数＝視線数の平方根
newGridNumber = 50;%100; %グリッド数（再構成結果の画素数の平方根）

if evalin('base', 'exist(''N_projection'', ''var'')')
    NP = evalin('base', 'N_projection');
    if NP ~= newProjectionNumber
        [gm2d1, gm2d2, gm2d3, gm2d4, U1, U2, U3, U4, ...
                  s1, s2, s3, s4, v1, v2, v3, v4, M, K, range, N_projection, N_grid] = parametercheck(newProjectionNumber, newGridNumber);
    end
else
    [gm2d1, gm2d2, gm2d3, gm2d4, U1, U2, U3, U4, ...
              s1, s2, s3, s4, v1, v2, v3, v4, M, K, range, N_projection, N_grid] = parametercheck(newProjectionNumber, newGridNumber);
end

% number = (t-start)/interval+1;
% ファントムテスト用の画像を準備（4視点分）
[EEideal1,Iwgn1,I1,II1,IIwgn1] = Assumption(N_projection,gm2d1,plot_flag1);
%[~,Iwgn2] = Assumption(N_projection,gm2d2,false);
%[~,Iwgn3] = Assumption(N_projection,gm2d3,false);
%[~,Iwgn4] = Assumption(N_projection,gm2d4,false);
% % こっちを使う時は N_projection_new = 80, N_grid_new = 100
% [~,Iwgn1] = Assumption_2(N_projection,gm2d1,true);
% [~,Iwgn2] = Assumption_2(N_projection,gm2d2,false);
% [~,Iwgn3] = Assumption_2(N_projection,gm2d3,false);
% [~,Iwgn4] = Assumption_2(N_projection,gm2d4,false);

[~, N_g] = size(gm2d1);
% N_projection = sqrt(N_p);
N_grid = sqrt(N_g);
m=N_grid;
n=N_grid;
z_0=0;
r_0=-0.3;
z=linspace(-1,1,m);
r=linspace(-1,1,n);
z_grid = linspace(-200,200,m);
r_grid = linspace(330,70,n);
if plot_flag1
    for i = 1:size(Iwgn1,1)
        EEideal = EEideal1{i};
        II = II1{i};
        IIwgn = IIwgn1{i};
        [mesh_z,mesh_r] = meshgrid(z_grid,r_grid);
        figure('Visible', 'off');  % Create figure without displaying
        [~,h] = contourf(mesh_z,mesh_r,EEideal,20);
        h.LineStyle = 'none';
        c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
        % Save the contourf figure
        exportgraphics(gcf, sprintf('assumption_data/a%d_EEideal.png', i));  % Save as PNG
    
        % figure;imagesc(z_grid,r_grid,EE);c=colorbar('Ticks',[0.1,0.5,1]);
        % c.Label.String='Assumed Intensity [a.u.]';xlabel('Z [mm]');ylabel('R [mm]');
        % axis xy
        % ax = gca;
        % ax.XDir = 'reverse';
        figure('Visible', 'off');
        imagesc(II);c=colorbar('Ticks',[0,20,40]);
        c.Label.String='Assumed Intensity [a.u.]';xlabel('Z Pixels');ylabel('R Pixels');
        exportgraphics(gcf, sprintf('assumption_data/a%d_II.png', i));  % Save as PNG
        
        figure('Visible', 'off');
        imagesc(IIwgn);c=colorbar('Ticks',[0,20,40]);
        c.Label.String='Assumed Intensity [a.u.]';xlabel('Z Pixels');ylabel('R Pixels');
        % Save the IIwgn figure
        exportgraphics(gcf, sprintf('assumption_data/a%d_IIwgn.png', i));  % Save as PNG
        % Close the figure to free up memory
        close all;  % Close all figures after saving
    end
end

sim_cell = cell(3, size(Iwgn1, 1)); % 構造的類似
immse_cell = cell(3, size(Iwgn1, 1)); % 平均二乗誤差
multissim_cell = cell(3, size(Iwgn1, 1)); % マルチスケール構造的類似

for r = 3%1:3
    ReconMethod = r-1;
    for i = 1:size(Iwgn1,1)
        Iwgn = Iwgn1{i};
        I = I1{i};
        EE1 = get_distribution(M,K,gm2d1,U1,s1,v1,Iwgn,false,ReconMethod);
        
        %評価の計算---------
        EE = EE1(:);
        sxr = gm2d1*EE;
        sxr_cal = getCircleData(sxr,N_projection);
        I_cal = getCircleData(I,N_projection);
        
        [ssimval, ~] = ssim(I_cal, sxr_cal);
                
        sim_cell{r,i} = ssimval;
        immse_cell{r,i} = immse(I_cal,sxr_cal);
        multissim_cell{r,i} = multissim(sxr_cal,I_cal);
        %ここまで-----------
        if plot_flag2
            saveplot(EE1,r,i,range);
        end
    end
end
% Convert the cell arrays to matrices
sim_matrix = cell2mat(sim_cell);
immse_matrix = cell2mat(immse_cell);
multissim_matrix = cell2mat(multissim_cell);

% Save matrices to an Excel file
filename = 'assumption_data/evaluation_results_10%.xlsx';
writematrix(sim_matrix, filename, 'Sheet', 1, 'Range', 'A1');
writematrix(immse_matrix, filename, 'Sheet', 2, 'Range', 'A1');
writematrix(multissim_matrix, filename, 'Sheet', 3, 'Range', 'A1');

%EE2 = get_distribution(M,K,gm2d2,U2,s2,v2,Iwgn2,plot_flag,NL);
%EE3 = get_distribution(M,K,gm2d3,U3,s3,v3,Iwgn3,plot_flag,NL);
%EE4 = get_distribution(M,K,gm2d4,U4,s4,v4,Iwgn4,plot_flag,NL);
%{
EE1 = get_MFI_reconstruction(Iwgn1, gm2d1);
EE2 = get_MFI_reconstruction(Iwgn2, gm2d2);
EE3 = get_MFI_reconstruction(Iwgn3, gm2d3);
EE4 = get_MFI_reconstruction(Iwgn4, gm2d4);
%}
% f = figure;
% f.Units = 'normalized';
% f.Position = [0.1,0.2,0.8,0.4];


end

function saveplot(EE1,r,i,range)
    % 表示範囲の設定に使うパラメータを取得
    range_1000 = range./1000;
    zmin = range_1000(1);
    zmax = range_1000(2);
    rmin = range_1000(5);
    rmax = range_1000(6);
    r_space_SXR = linspace(rmin,rmax,size(EE1,1));
    z_space_SXR = linspace(zmin,zmax,size(EE1,2));
    
    r_range = find(0.060<=r_space_SXR & r_space_SXR<=0.330);
    r_space_SXR = r_space_SXR(r_range);
    z_range = find(-0.17<=z_space_SXR & z_space_SXR<=0.17);
    z_space_SXR = z_space_SXR(z_range);

    EE1 = EE1(r_range,z_range);
    %EE2 = EE2(r_range,z_range);
    %EE3 = EE3(r_range,z_range);
    %EE4 = EE4(r_range,z_range);

    
    
    figure('Visible','off');
    subplot(2,2,1);
    [SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);

    [~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE1,20);
    h1.LineStyle = 'none';
    c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
    %title('1');
    %{
    subplot(2,2,2);
    [~,h2] = contourf(SXR_mesh_z,SXR_mesh_r,EE2,20);
    h2.LineStyle = 'none';
    c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
    title('2');
    
    subplot(2,2,3);
    [~,h3] = contourf(SXR_mesh_z,SXR_mesh_r,EE3,20);
    h3.LineStyle = 'none';
    c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
    title('3');
    
    subplot(2,2,4);
    [~,h4] = contourf(SXR_mesh_z,SXR_mesh_r,EE4,20);
    h4.LineStyle = 'none';
    c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
    title('4');
    %}

    filename = sprintf('assumption_data/a%d_sxr_%d.png', i, r-1);
    
    % グラフを画像として保存
    exportgraphics(gcf, filename);
    close all; % 図を閉じる
end

function k = FindCircle(L)
    R = zeros(2*L);
    for i = 1:2*L
        for j = 1:2*L
            R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2);
        end
    end
    % figure;imagesc(R)
    k = find(R<L);
end
function E_cal = getCircleData(E,n_p)
    E_cal = zeros(n_p);
    k = FindCircle(n_p/2);
    E_cal(k) = E;
    E_cal = double(E_cal);
end