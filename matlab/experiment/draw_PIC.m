addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

% data50 = readmatrix("data50.csv");
% data50_3D = zeros(512,256,52);
% for i = 1:256
%     row_s = 1 + 512*(i-1);
%     row_e = 512*i;
%     data50_3D(:,i,:) = data50(row_s:row_e,:);
% end
% charge = data50_3D(:,:,15);
E0 = data50_3D(:,:,2);
E1 = data50_3D(:,:,3);
E2 = data50_3D(:,:,4);
% B0 = data50_3D(:,:,5);
% B1 = data50_3D(:,:,6);
% B2 = data50_3D(:,:,7);
x = linspace(-128,127,256);
y = linspace(-256,255,512);
[xx,yy] = meshgrid(x,y);

psi = zeros(512,256);
for i_y = 1:size(y,2)
    psi_y = 0;
    for i_x = 1:size(x,2)
        psi_y = psi_y + B0(i_y,i_x);
        psi(i_y,i_x) = psi_y;
    end
end
for i_x = 1:size(x,2)
    psi_x = 0;
    for i_y = 1:size(y,2)
        psi_x = psi_x + B2(i_y,i_x);
        psi(i_y,i_x) = psi(i_y,i_x) - psi_x;
    end
end

V = zeros(512,256);  % 静電ポテンシャルの初期化
for i_x = 2:size(x,2)
    for i_y = 2:size(y,2)
        V(i_y,i_x) = V(i_y-1,i_x) - E0(i_y-1,i_x);  % x方向の積分
        V(i_y,i_x) = V(i_y,i_x-1) - E2(i_y,i_x-1);  % y方向の積分
    end
end

% charge = data50_3D(:,:,19) - data50_3D(:,:,36); 

figure

contourf(xx,yy,charge,80,'LineStyle','none')
c = colorbar;
clim([-0.05 0.05])
colormap(redblue(3000));
c.Label.String = 'Charge Density [C/m^3]';

% contourf(xx,yy,V,80,'LineStyle','none')
% c = colorbar;
% clim([-0.3 1.2])
% colormap(redblue(3000));
% c.Label.String = 'Electrostatic Potential [kV]';

hold on
contour(xx,yy,psi,80,'k')
daspect([1 1 1])
xlim([-75 75])
ylim([-150 150])
xlabel('X [px]')
ylabel('Y [px]')