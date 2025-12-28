%%%%%%%%%%%%%%%%%%%%%%%%
% Top-level file for calculating and plotting SXR emission for four-view
% experimental setup
%%%%%%%%%%%%%%%%%%%%%%%%
% clear
% close all
clearvars -except date IDXlist doSave doFilter doNLR ReconMethod
addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment'; 

addpath '/Users/shohgookazaki/Documents/matlab/common';
run define_path.m

PCB.restart = 0; 

%%%%実験オペレーションの取得
prompt = {'Date:','Shot number:','a039(not necessary):','doSave:','doFilter:','ReconMethod(0:TP,1:MFI,2:MEM,3:cGAN):', 'Reset'};
definput = {'','','','','','',''};
if exist('date','var')
    definput{1} = num2str(date);
end
if exist('IDXlist','var')
    definput{2} = num2str(IDXlist);
end
if exist('a039','var')
    definput{3} = num2str(a039);
end
if exist('doSave','var')
    definput{4} = num2str(doSave);
end
if exist('doFilter','var')
    definput{5} = num2str(doFilter);
end
if exist('ReconMethod','var')
    definput{6} = num2str(ReconMethod);
end
if exist('Reset','var')
    definput{7} = num2str(Reset);
end
dlgtitle = 'Input';
dims = [1 35];
answer = inputdlg(prompt,dlgtitle,dims,definput);
if isempty(answer)
    return
end
date = str2double(cell2mat(answer(1)));
IDXlist = str2num(cell2mat(answer(2)));
a039 = str2num(cell2mat(answer(3)));
doSave = logical(str2num(cell2mat(answer(4))));
doFilter = logical(str2num(cell2mat(answer(5))));
ReconMethod = str2num(cell2mat(answer(6)));
Reset = logical(str2num(cell2mat(answer(7))));

SXR.doSave = doSave;
SXR.doFilter = doFilter;
SXR.ReconMethod = ReconMethod;
SXR.Reset = Reset;

%-----------スプレッドシートからデータ抜き取り--------------------%
DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';
T=getTS6log(DOCID);

if ~isempty(date) && ~isempty(IDXlist)
    T=searchlog(T,'date',date);
    if isnan(T.shot(1))
        T(1, :) = [];
    end
    n_data=numel(IDXlist);
    shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
    tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
    EFlist=T.EF_A_(IDXlist);
    TFlist=T.TF_kV_(IDXlist);
    dtacqlist=39.*ones(n_data,1); 
    startlist = T.SXRStart(IDXlist);
    intervallist = T.SXRInterval(IDXlist);
elseif ~isempty(a039)
    T=searchlog(T,'a039',a039);
    if isnan(T.shot(1))
        T(1, :) = [];
    end
    n_data = numel(a039);
    shotlist = [T.a039, T.a040];
    tfshotlist = [T.a039_TF,T.a040_TF];
    EFlist = T.EF_A_;
    TFlist = T.TF_kV_;
    dtacqlist=39.*ones(n_data,1);
    startlist = T.SXRStart;
    intervallist = T.SXRInterval;
    date = T.date;
    IDXlist = T.shot;
end
%-------------------------------------------------%

PCB.trange=400:800;
PCB.n=50; 

t = 470;
SXR.show_xpoint = false;
SXR.show_localmax = false;

% NIFSの軟X線データをドライブにコピーする
copyFolderIfNotExist(strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date)), strcat(getenv('NIFS_path'),'/',num2str(date)));

for i=1:n_data
    disp(strcat('(',num2str(i),'/',num2str(n_data),')'));
    PCB.idx = IDXlist(i);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.date = date;
    TF=TFlist(i);
    SXR.start = startlist(i);
    SXR.interval = intervallist(i);
    [PCBdata.grid2D,PCBdata.data2D] = process_PCBdata_200ch(PCB,pathname); 
    SXR.date = date;
    SXR.shot = IDXlist(i);
    SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
    plot_sxr_multi(PCBdata,SXR,PCB);
end

function [] = plot_sxr_multi(PCBdata,SXR,PCB)
date = SXR.date;
shot = SXR.shot;
start = SXR.start;
interval = SXR.interval;
doSave = SXR.doSave;
doFilter = SXR.doFilter;
ReconMethod = SXR.ReconMethod;
SXRfilename = SXR.SXRfilename;

addpath '/Users/shohgookazaki/Documents/GitHub/test-open/Soft X-ray/Machine_Learning/code'; 

if doFilter == 1
    if ReconMethod == 0
        options = 'NLF_TP';
    elseif ReconMethod == 1
        options = 'NLF_MFI';
    elseif ReconMethod == 2
        options = 'NLF_MEM';
    elseif ReconMethod == 3
        options  = 'NLF_cGAN';
    elseif ReconMethod == 4
        options = 'NLF_GPT';
    end
else
    if ReconMethod == 0
        options = 'LF_TP';
    elseif ReconMethod == 1
        options = 'LF_MFI';
    elseif ReconMethod == 2
        options = 'LF_MEM';
    elseif ReconMethod == 3
        options  = 'LF_cGAN';
    elseif ReconMethod == 4
        options = 'LF_GPT';
    end
end

dirPath = getenv('SXR_MATRIX_DIR');
matrixFolder = strcat(dirPath,'/',options,'/',num2str(date),'/shot',num2str(shot));

% 計算済みデータがある前提なので、基本的にはロードを行うフロー
if exist(matrixFolder,'dir') == 0
    doCalculation = true;
    mkdir(matrixFolder);
elseif length(dir(matrixFolder))-2 ~= 8 
    doCalculation = true;
elseif SXR.Reset == 1
    doCalculation = true;
else
    doCalculation = false; 
end

newProjectionNumber = 30;
newGridNumber = 50;
parameterFile = sprintf('parameters%d%d.mat', newProjectionNumber, newGridNumber);

if doCalculation
    disp('No matrix data -- Start calculation');
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

    rawImage = imread(SXRfilename);
    if doFilter
        disp(size(rawImage));
        [rawImage,~] = imnlmfilt(rawImage,'SearchWindowSize',91,'ComparisonWindowSize',15);
    end
else
    disp(strcat('Loading matrix from :',matrixFolder))
    load(parameterFile,'range');
end

times = start:interval:(start+interval*7);
doPlot = false;

if doSave
    f = figure;
    f.Units = 'normalized';
    f.Position = [0.1,0.2,0.8,0.8];
end

for t = times
    number = (t-start)/interval+1;
    matrixPath = strcat(matrixFolder,'/',num2str(number),'.mat');
    if any(~exist(matrixPath,'file')) || any(SXR.Reset == 1)
        [VectorImage1,VectorImage2, VectorImage3, VectorImage4] = get_sxr_image(date,number,newProjectionNumber,rawImage);
        
        datadirPath = getenv('SXR_DATA_DIR');
        dataFolder = strcat(datadirPath,'/',num2str(date),'/shot',num2str(shot));
        if ~exist(dataFolder, 'dir')
            mkdir(dataFolder);
        end

        dataPath = strcat(dataFolder,'/',num2str(number),'.mat');
        n_p = N_projection;
        sxr1 = zeros(n_p);
        sxr2 = zeros(n_p);
        sxr3 = zeros(n_p);
        sxr4 = zeros(n_p);
        k=FindCircle(n_p/2);
        sxr1(k) = VectorImage1;
        sxr2(k) = VectorImage2;
        sxr3(k) = VectorImage3;
        sxr4(k) = VectorImage4;
        save(dataPath, 'sxr1', 'sxr2','sxr3','sxr4')
        
        EE1 = get_distribution(M,K,gm2d1,U1,s1,v1,VectorImage1,doPlot,ReconMethod, N_projection);
        EE2 = get_distribution(M,K,gm2d2,U2,s2,v2,VectorImage2,doPlot,ReconMethod, N_projection);
        EE3 = get_distribution(M,K,gm2d3,U3,s3,v3,VectorImage3,doPlot,ReconMethod, N_projection);
        EE4 = get_distribution(M,K,gm2d4,U4,s4,v4,VectorImage4,doPlot,ReconMethod, N_projection);
        
        save(matrixPath,'EE1','EE2','EE3','EE4');
    else
        load(matrixPath,'EE1','EE2','EE3','EE4');
    end
    
    EE = cat(3,EE1,EE2,EE3,EE4);

    if ~doSave
        f = figure;
        f.Units = 'normalized';
        f.Position = [0.1,0.2,0.8,0.8];
    end

    SXRdata.t = t;
    SXRdata.range = range;

    if ReconMethod ~= 3
        SXRdata.EE = EE;
        plot_save_sxr(PCBdata,SXR,SXRdata,PCB);
    else    
        cGANPath = strcat(dirPath,'/cGAN_large/',num2str(date),'/shot',num2str(shot),'/',num2str(number),'.mat');
        load(cGANPath,'EE1','EE2','EE3','EE4');
        EE = cat(3,EE1,EE2,EE3,EE4);
        SXRdata.EE = EE;
        plot_save_sxr(PCBdata,SXR,SXRdata,PCB);
    end
end

if doSave
    close(f);
end
end

function k = FindCircle(L)
    R = zeros(2*L);
    for i = 1:2*L
        for j = 1:2*L
            R(i,j) = sqrt((L-i+0.5)^2+(j-L-0.5)^2);
        end
    end
    k = find(R<L);
end

%==========================================================================
% 修正したplot_save_sxr関数（制限撤廃・全範囲表示版）
%==========================================================================
function plot_save_sxr(PCBdata,SXR,SXRdata,PCB)

grid2D = PCBdata.grid2D;
data2D = PCBdata.data2D;
date = SXR.date;
shot = SXR.shot;
show_localmax = SXR.show_localmax;
doSave = SXR.doSave;
doFilter = SXR.doFilter;
ReconMethod = SXR.ReconMethod;

EE = SXRdata.EE;
t = SXRdata.t;
range = SXRdata.range;

range = range./1000;
zmin1 = range(1);
zmax1 = range(2);
zmin2 = range(3);
zmax2 = range(4);
rmin = range(5);
rmax = range(6);
r_space_SXR = linspace(rmin,rmax,size(EE,1));
z_space_SXR1 = linspace(zmin1,zmax1,size(EE,2));
z_space_SXR2 = linspace(zmin2,zmax2,size(EE,2));

% --- 【変更点1】範囲制限のためのインデックス検索を無効化 ---
% 元のコード:
% r_range = find(rmin_psi<=r_space_SXR & r_space_SXR<=rmax_psi);
% ...
% 変更後: 全インデックスを使用
r_range = 1:size(EE,1);
z_range1 = 1:size(EE,2);
z_range2 = 1:size(EE,2);

% plot用配列も全範囲そのまま
r_space_SXR_plot = r_space_SXR;
z_space_SXR1_plot = z_space_SXR1;
z_space_SXR2_plot = z_space_SXR2;


psi_mesh_z = grid2D.zq;
psi_mesh_r = grid2D.rq;
t_idx = find(data2D.trange==t);
psi = data2D.psi(:,:,t_idx);
Bz = data2D.Bz(:,:,t_idx);
Br = data2D.Br(:,:,t_idx);
Bp = sqrt(Bz.^2+Br.^2);

psi_min = min(min(psi));
psi_max = max(max(psi));
contour_layer = linspace(psi_min,psi_max,20);

[SXR_mesh_z1,SXR_mesh_r] = meshgrid(z_space_SXR1_plot,r_space_SXR_plot);
[SXR_mesh_z2,~] = meshgrid(z_space_SXR2_plot,r_space_SXR_plot);

set(gcf, 'Visible', 'off');

% --- EE_qの計算は残すが、プロットには生データ(EE)を使う方針に変更 ---
EE_q = zeros(50,50,4);
for i = 1:4
    if i <=2
        EE_q(:,:,i) = griddata(z_space_SXR2,r_space_SXR,EE(:,:,i),psi_mesh_z,psi_mesh_r);
    else
        EE_q(:,:,i) = griddata(z_space_SXR1,r_space_SXR,EE(:,:,i),psi_mesh_z,psi_mesh_r);
    end
end

[magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D,PCB); 

positionList = [2,4,1,3];
nameList = {'1um Al', '2.5um Al', '2um Mylar', '1um Mylar'};

if PCB.date == 241110
    cLimList = {[0 3],[0 5],[0 10], [0 5]}; 
elseif PCB.date == 240111
    cLimList = {[0 2],[0 2],[0 2], [0 2]}; 
elseif PCB.date == 241230
    cLimList = {[0 0.5],[0 0.5],[0 0.5],[0 5]}; 
elseif PCB.date == 250125
    cLimList = {[0 3], [0 3], [0 3],[0 5]};
else
    cLimList = {[0 10],[0 5],[0 5],[0 5]};
end

% 負の要素を0で置換
negativeEE = find(EE<0);
EE(negativeEE) = zeros(size(negativeEE));
% negativeEEq = find(EE_q<0);
% EE_q(negativeEEq) = zeros(size(negativeEEq));

for i = 1:4
    p = positionList(i);
    subplot(2,2,p);
    cRange = cell2mat(cLimList(i));

    if i <= 2
        SXR_mesh_z = SXR_mesh_z2;
    else
        SXR_mesh_z = SXR_mesh_z1;
    end
    
    % --- 【変更点2】全データ(EE)をプロットに使用 ---
    % EEは上でインデックス制限を解除しているので、全範囲入っています
    EE_plot = EE(:,:,i); 

    % EE_q(補間データ)ではなく、SXR_mesh(元の計算グリッド)でプロット
    [~,h] = contourf(SXR_mesh_z,SXR_mesh_r,EE_plot,linspace(cRange(1),cRange(2),20));
    clim(cRange);

    colormap('turbo');
    h.LineStyle = 'none';
    c=colorbar;c.Label.String='Intensity [a.u.]';c.FontSize=18;
    hold on
    if show_localmax
        localmax_idx = imregionalmax(EE_plot);
        EE_localmax = EE_plot.*localmax_idx;
        [~, localmax_idx] = maxk(EE_localmax(:),2);
        localmax_pos_r = SXR_mesh_r(localmax_idx);
        localmax_pos_z = SXR_mesh_z(localmax_idx);
        plot(localmax_pos_z,localmax_pos_r,'r*');
    end
    
    % 磁気面を上から重ねて描画（範囲外はずれて見えるが、物理位置は正しい）
    [~,hp]=contourf(psi_mesh_z,psi_mesh_r,psi,contour_layer,'white','Fill','off');
    
    % --- 【変更点3】表示範囲制限(axis, ylim)を全て無効化 ---
    % axis([-0.17 0.17 0.06 0.33]); 
    hp.LineWidth = 1.5;
    
    plot(xPointList.z(t_idx),xPointList.r(t_idx),'wx','LineWidth',3);
    hold off;
    
    % 日付ごとのylim制限も無効化
    % if PCB.date == 241110 ||PCB.date == 250205 || PCB.date ==250206
    %     ylim([0.1 0.32]);
    % end
    
    title(string(nameList(i)));
end

sgtitle(strcat('shot',num2str(shot),',',num2str(t),'us'));
drawnow;

if doSave
    pathname_png = getenv('SXR_RECONSTRUCTED_DIR');
    pathname_fig = getenv('SXR_RECONSTRUCTED_FIG_DIR');
    if doFilter 
        if ReconMethod == 0
            directory = '/NLF_TP/';
        elseif ReconMethod == 1
            directory = '/NLF_MFI/';
        elseif ReconMethod == 2
            directory = '/NLF_MEM';
        elseif ReconMethod == 3
            directory = '/NLF_cGAN/';
        elseif ReconMethod == 4
            directory = '/NLF_GPT/';
        end
    elseif ~doFilter
        if ReconMethod == 0
            directory = '/LF_TP/';
        elseif ReconMethod == 1
            directory = '/LF_MFI/';
        elseif ReconMethod == 2
            directory = '/LF_MEM';
        elseif ReconMethod == 3
            directory = '/LF_cGAN/';
        elseif ReconMethod == 4
            directory = '/LF_GPT/';
        end
    end

    foldername_png = strcat(pathname_png,directory,'/',num2str(date),'/shot',num2str(shot));
    foldername_fig = strcat(pathname_fig,directory,'/',num2str(date),'/shot',num2str(shot));
    if exist(foldername_png,'dir') == 0
        mkdir(foldername_png);
    end
    if exist(foldername_fig,'dir') == 0
        mkdir(foldername_fig);
    end
    
    % --- 【変更点4】保存ファイル名に _all_ を追加 ---
    filename_png = strcat('/shot',num2str(shot),'_all_',num2str(t),'us.png');
    filename_fig = strcat('/shot',num2str(shot),'_all_',num2str(t),'us.fig');
    
    saveas(gcf,strcat(foldername_png,filename_png));
    saveas(gcf,strcat(foldername_fig,filename_fig));
end
end