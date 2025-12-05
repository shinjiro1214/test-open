function IxData = get_emission_xpoint(PCB,SXR,pathname)

trange = PCB.trange;
[grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D);
mergingRatio = xPointList.psi./mean(magAxisList.psi);
trange_sxr = SXR.start:SXR.interval:SXR.start+SXR.interval*7;

mergingRatioSXR = mergingRatio(ismember(trange,trange_sxr));

Imax = zeros(4,8);
Imean = zeros(4,8);
Istd = zeros(4,8);
Ix = zeros(4,8);
IxData = struct('max',Imax,'mean',Imean,'std',Istd,'x',Ix,'MR',mergingRatioSXR,'t',trange_sxr);

date = SXR.date;
shot = SXR.shot;
% start = SXR.start;
% interval = SXR.interval;
doFilter = SXR.doFilter;
doNLR = SXR.doNLR;
% SXRfilename = SXR.SXRfilename;

if doFilter & doNLR
    options = 'NLF_NLR';
elseif ~doFilter & doNLR
    options = 'LF_NLR';
elseif doFilter & ~doNLR
    options = 'NLF_LR';
else
    options = 'LF_LR';
end

dirPath = getenv('SXR_MATRIX_DIR');
matrixFolder = strcat(dirPath,filesep,options,filesep,num2str(date),'/shot',num2str(shot));
if exist(matrixFolder,'dir') == 0
    disp('No emission distribution calculation results');
    
    return
end

parameterFile = 'parameters.mat';
disp(strcat('Loading matrix from :',matrixFolder))
load(parameterFile,'range');

% xPointListに含まれるr,z座標からインデックスを抽出（rq,zqから）
% それぞれの時間の画像でX点座標（インデックス）を中心に5*5で発光強度を抽出
% 最大値、平均値、標準偏差を保存？

range = range./1000;
zmin1 = range(1);
zmax1 = range(2);
zmin2 = range(3);
zmax2 = range(4);
rmin = range(5);
rmax = range(6);
% r_space_SXR = linspace(rmin,rmax,size(EE,1));
% z_space_SXR1 = linspace(zmin1,zmax1,size(EE,2));
% z_space_SXR2 = linspace(zmin2,zmax2,size(EE,2));

% Imax = zeros(4,8);
% Imean = zeros(4,8);
% Istd = zeros(4,8);
% IxData = struct('max',Imax,'mean',Imean,'std',Istd,'MR',mergingRatioSXR,'t',trange_sxr);

for i = 1:8
    matrixPath = strcat(matrixFolder,filesep,num2str(i),'.mat');
    load(matrixPath,'EE1','EE2','EE3','EE4');
    r_space_SXR = linspace(rmin,rmax,size(EE1,1));
    z_space_SXR1 = linspace(zmin1,zmax1,size(EE1,2));
    z_space_SXR2 = linspace(zmin2,zmax2,size(EE1,2));
    EE = cat(3,EE1,EE2,EE3,EE4);
    EE(EE<0) = 0;
    t = SXR.start+SXR.interval*(i-1);
    t_idx = find(trange==t);
    x_r = xPointList.r(t_idx);
    x_z = xPointList.z(t_idx); 
    [Z1,R] = meshgrid(z_space_SXR1,r_space_SXR);
    [Z2,~] = meshgrid(z_space_SXR2,r_space_SXR);
    if ~isnan(x_r)
        for j = 1:4
            r_idx = knnsearch(r_space_SXR.',x_r);
            r_range = r_space_SXR<=x_r + 0.02 & r_space_SXR>=x_r - 0.02;
            if j <= 2
                z_idx = knnsearch(z_space_SXR2.',x_z);
                z_range = z_space_SXR2<=x_z + 0.01 & z_space_SXR2>=x_z - 0.01;
                circleFlag = sqrt((Z2-x_z).^2+(R-x_r).^2)<=0.01;
            else
                z_idx = knnsearch(z_space_SXR1.',x_z);
                z_range = z_space_SXR1<=x_z + 0.01 & z_space_SXR1>=x_z - 0.01;
                circleFlag = sqrt((Z1-x_z).^2+(R-x_r).^2)<=0.01;
            end
            % EE_x = EE(r_idx-2:r_idx+2,z_idx-2:z_idx+2,j);
            % EE_x = EE(r_range,z_range,j);
            EE_tmp = EE(:,:,j);
            EE_x = EE_tmp(circleFlag);
            IxData.max(j,i) = max(EE_x,[],'all');
            IxData.mean(j,i) = mean(EE_x,'all');
            IxData.std(j,i) = std(EE_x,0,'all');
            IxData.x(j,i) = EE(r_idx,z_idx,j);
        end
    end

end

end