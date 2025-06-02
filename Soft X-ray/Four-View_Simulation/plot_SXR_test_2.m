% function plot_SXR_test()
close all
% NL = false;
NL = true;

% Definition of reconstruction condition
N_projection_new = 30; %square root of the projection number
N_grid_new = 70; %square root of the grid number

% load parameters for the reconstruction
filepath = 'parameters.mat';

% if the parameter file does not exist, calculate the parameters
if isfile(filepath)
    load(filepath, 'gm2d1', 'gm2d2', 'gm2d3', 'gm2d4', 'U1', 'U2', 'U3', 'U4', ...
        's1', 's2', 's3', 's4', 'v1', 'v2', 'v3', 'v4', 'M', 'K', 'range','N_projection', 'N_grid');
    if N_projection_new ~= N_projection || N_grid_new ~= N_grid
        disp('Different parameters - Start calculation!');
        clc_parameters_new(N_projection_new,N_grid_new,filepath);
        % clc_parameters(N_projection_new,N_grid_new,filepath);
        load(filepath, 'gm2d1', 'gm2d2', 'gm2d3', 'gm2d4', 'U1', 'U2', 'U3', 'U4', ...
            's1', 's2', 's3', 's4', 'v1', 'v2', 'v3', 'v4', 'M', 'K', 'range','N_projection', 'N_grid');
    end
else
    disp('No parameter - Start calculation!');
    clc_parameters_new(N_projection_new,N_grid_new,filepath);
    % clc_parameters(N_projection_new,N_grid_new,filepath);
    load(filepath, 'gm2d1', 'gm2d2', 'gm2d3', 'gm2d4', 'U1', 'U2', 'U3', 'U4', ...
        's1', 's2', 's3', 's4', 'v1', 'v2', 'v3', 'v4', 'M', 'K', 'range','N_projection', 'N_grid');   
end

    
plot_flag = false;
% % ファントムテスト用の画像を準備（4視点分）
zmin = range(3);
zmax = range(4);
rmin = range(5);
rmax = range(6);
[EE_original,Iwgn_phantom1] = Assumption_3(N_projection,gm2d1,zmin,zmax,rmin,rmax,true);

% reconstruct original images from noisy signal
EE1 = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn_phantom1,plot_flag,NL);
EE1(EE1<0) = 1e-5;

E1 = reshape(flipud(EE1),[],1);

Iwgn1 = (gm2d1*E1).';

Iwgn1 = awgn(Iwgn1,10*log10(10),'measured');
% Iwgn=awgn(I,10*log10(10),'measured'); % 5 related to 20%; 10 related to 10%;
Iwgn1(Iwgn1<0) = 1e-5;

figure;
plot(Iwgn_phantom1);hold on;plot(Iwgn1);

EE_new1 = clc_distribution(M,K,gm2d1,U1,s1,v1,Iwgn1,plot_flag,NL);
EE_new1(EE_new1<0) = 1e-5;

% plot the reconstructed images
range = range./1000;
zmin = range(1);
zmax = range(2);
rmin = range(5);
rmax = range(6);
r_space_SXR = linspace(rmin,rmax,size(EE1,1));
z_space_SXR = linspace(zmin,zmax,size(EE1,2));

r_range = find(0.060<=r_space_SXR & r_space_SXR<=0.330);
r_space_SXR = r_space_SXR(r_range);
z_range = find(-0.17<=z_space_SXR & z_space_SXR<=0.17);

z_space_SXR = z_space_SXR(z_range);

EE_original = flipud(EE_original);
EE0 = EE_original(r_range,z_range);
EE1 = EE1(r_range,z_range);

figure('Position',[1 358 1470 420]);
subplot(1,3,1)
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE0,20);
h1.LineStyle = 'none';
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
title('オリジナル');
axis image

subplot(1,3,2)
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE1,20);
h1.LineStyle = 'none';
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
title('再構成1回目');
axis image

EE_new1 = EE_new1(r_range,z_range);

subplot(1,3,3);
[SXR_mesh_z,SXR_mesh_r] = meshgrid(z_space_SXR,r_space_SXR);
[~,h1] = contourf(SXR_mesh_z,SXR_mesh_r,EE_new1,20);
h1.LineStyle = 'none';
c=colorbar;c.Label.String='Intensity [a.u.]';%c.FontSize=18;
title('再構成2回目');
axis image

error1 = sum((EE_new1-EE1).^2/max(EE1,[],'all'),'all')/numel(EE1);
% error1 = sum((EE_new1-EE1).^2./EE1,'all')/numel(EE1);
EE_original = EE_original(r_range,z_range);
error_original = sum((EE_original-EE1).^2/max(EE_original,[],'all'),'all')/numel(EE_original);

disp(error1);
disp(error_original);