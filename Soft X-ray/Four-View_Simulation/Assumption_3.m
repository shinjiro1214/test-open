function [EE,Iwgn] = Assumption_3(N_projection,gm2d,zmin,zmax,rmin,rmax,plot_flag)

[~, N_g] = size(gm2d);
% N_projection = sqrt(N_p);
N_grid = sqrt(N_g);
m=N_grid;
n=N_grid;
% z_0=0.3;
z_0=-0.1;
r_0=0.2;
z=linspace(-1,1,m);
r=linspace(-1,1,n);

% z_grid = linspace(200,-200,m);
z_grid = linspace(zmin,zmax,m);
r_grid = linspace(rmax,rmin,n);

[r_space,z_space] = meshgrid(r,z); %rが横、zが縦の座標系（左上最小）
r0_space = sqrt((z_space-z_0).^2+4*(r_space-r_0).^2);
r1_space = sqrt((z_space+z_0).^2+(r_space+r_0).^2);
% r1_space = abs(0.5*(z_space-z_0)+(r_space-r_0))/sqrt(1.25);
% EE = exp(-0.5*r0_space.^2).*exp(-5*r1_space)+1.5*exp(-r0_space.^2);


% 数値的にファントムを生成
EE = exp(-25*r0_space.^2) + exp(-25*r1_space.^2);
% EE = zeros(size(r0_space));
% EE(r0_space<0.1 | r1_space<0.2) = 1;

% % 広めに定義したグリッドデータを元にファントムを生成し、そのうちから再構成領域のみを抉り取りたい
% [r_space1,z_space1] = meshgrid(r_grid,z_grid); %rが横、zが縦の座標系（右上最小?）

% EE = zeros(m,n);
% for i=1:m
%     for j=1:n
%         r0 = sqrt((z(i)-z_0)^2+(r(j)-r_0)^2);
%         r1 = abs(0.5*(z(i)-z_0)+(r(j)-r_0))/sqrt(1.25);
%         EE(i,j) = 1*exp(-0.5*r0^2)*exp(-5*r1)+1.5*exp(-r0^2);
%     end
% end
% size(E)
EE = EE./max(max(EE))*0.2;
EE = fliplr(rot90(EE)); %rが縦、zが横、右下最小

% % 2視点システム時のデータからファントム生成
% loadpath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_LR/210924/shot45/4_high.txt';
% EE = readmatrix(loadpath);
% % 4視点システム時のデータからファントム生成
% load('/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_LR/240111/shot29/4.mat','EE1');
% EE = EE1;
% EE = flipud(EE);
% EE = imresize(EE,sqrt(size(gm2d,2))/size(EE,1),'nearest');

%2D matrix is transformed to 1D transversal vector
E = reshape(EE,1,[]);
% whos gm2d
% whos E
I=gm2d*(E)';
Iwgn=awgn(I,10*log10(10),'measured'); % 5 related to 20%; 10 related to 10%;
% Iwgn=awgn(I,10*log10(5),'measured'); % 5 related to 20%; 10 related to 10%;
Iwgn(Iwgn<0)=0;


% 1D column vector is transformed to 2D matrix
n_p = N_projection;
II = zeros(n_p);
IIwgn = zeros(n_p);
k=FindCircle(n_p/2);
II(k) = I;
IIwgn(k) = Iwgn;
Iwgn = Iwgn.';

% I_check = II(75,:);
% j = 1:numel(I_check);
% figure;plot(j,I_check);

if plot_flag
    figure('Position',[1 358 1470 420]);
    subplot(1,3,1);
    [mesh_z,mesh_r] = meshgrid(z_grid,r_grid);
    [~,h] = contourf(mesh_z,mesh_r,EE,20);
    h.LineStyle = 'none';
    c=colorbar;c.Label.String='Intensity [a.u.]';
    % c.FontSize=18;
    title('Original')
    axis image
    % figure;imagesc(z_grid,r_grid,EE);c=colorbar('Ticks',[0.1,0.5,1]);
    % c.Label.String='Assumed Intensity [a.u.]';xlabel('Z [mm]');ylabel('R [mm]');
    % axis xy
    % ax = gca;
    % ax.XDir = 'reverse';
    subplot(1,3,2);
    imagesc(II);c=colorbar('Ticks',[0,20,40]);
    c.Label.String='Assumed Intensity [a.u.]';xlabel('Z Pixels');ylabel('R Pixels');title('Projected emission w/o noise');
    axis image
    subplot(1,3,3);
    imagesc(IIwgn);c=colorbar('Ticks',[0,20,40]);
    c.Label.String='Assumed Intensity [a.u.]';xlabel('Z Pixels');ylabel('R Pixels');title('Projected emission w/ noise');
    axis image
end

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