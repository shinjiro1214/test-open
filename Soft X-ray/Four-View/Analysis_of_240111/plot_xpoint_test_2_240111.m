
% pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/result_matrix/LF_NLR/240111/shot';
pathFirstHalf = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot';
pathLastHalf = '/3.mat';

% 1:'1um Al', 2:'2.5um Al', 3:'2um Mylar', 4:'1um Mylar'

nShot_25_1 = 21;
nShot_25_2 = 19;
nShot_25_3 = 19;
nShot_25_4 = 19;
nShot_30_1 = 14;
nShot_30_2 = 24;
nShot_30_3 = 24;
nShot_30_4 = 23;
nShot_35_1 = 11;
nShot_35_3 = 25;
nShot_35_4 = 12;
% nShot_35_4 = 7;
nShot_40_1 = 30;
nShot_40_2 = 29;
nShot_40_3 = 25; %or29
% nShot_40_4 = 7;
nShot_40_4 = 12;

mPath_25_1 = strcat(pathFirstHalf,num2str(nShot_25_1),pathLastHalf);
mPath_25_2 = strcat(pathFirstHalf,num2str(nShot_25_2),'/3.mat');
mPath_25_3 = strcat(pathFirstHalf,num2str(nShot_25_3),'/3.mat');
mPath_25_4 = strcat(pathFirstHalf,num2str(nShot_25_4),pathLastHalf);
mPath_30_1 = strcat(pathFirstHalf,num2str(nShot_30_1),pathLastHalf);
mPath_30_2 = strcat(pathFirstHalf,num2str(nShot_30_2),pathLastHalf);
mPath_30_3 = strcat(pathFirstHalf,num2str(nShot_30_3),pathLastHalf);
mPath_30_4 = strcat(pathFirstHalf,num2str(nShot_30_4),pathLastHalf);
mpath_30_4_2 = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/result_matrix/LF_NLR/240111/shot13/3.mat';
mPath_35_1 = strcat(pathFirstHalf,num2str(nShot_35_1),pathLastHalf);
mPath_35_2 = mPath_35_1;
mPath_35_3 = strcat(pathFirstHalf,num2str(nShot_35_3),pathLastHalf);
mPath_35_4 = strcat(pathFirstHalf,num2str(nShot_35_4),pathLastHalf);
mPath_40_1 = strcat(pathFirstHalf,num2str(nShot_40_1),pathLastHalf);
mPath_40_2 = strcat(pathFirstHalf,num2str(nShot_40_2),pathLastHalf);
mPath_40_3 = strcat(pathFirstHalf,num2str(nShot_40_3),pathLastHalf);
mPath_40_4 = strcat(pathFirstHalf,num2str(nShot_40_4),pathLastHalf);

% load(mPath_25_1,'EE1','EE2','EE3','EE4');
% EE_25_1=EE1;EE_25_2=EE2;EE_25_3=EE3;EE_25_4=EE4;
load(mPath_25_1,'EE1');EE_25_1=EE1;
load(mPath_25_2,'EE2');EE_25_2=EE2;
load(mPath_25_3,'EE3');EE_25_3=EE3;
load(mPath_25_4,'EE4');EE_25_4=EE4;
EE_25 = cat(3,EE_25_1,EE_25_2,EE_25_3,EE_25_4);

% load(mPath_30_1,'EE1','EE2');
% EE_30_1=EE1;EE_30_2=EE2;
load(mPath_30_1,'EE1');EE_30_1=EE1;
load(mPath_30_2,'EE2');EE_30_2=EE2;
load(mPath_30_3,'EE3');EE_30_3=EE3;
load(mPath_30_4,'EE4');EE_30_4=EE4;
% load(mpath_30_4_2,'EE4');EE_30_4_2 = EE4;
% EE_30_4 = EE_30_4_2;
% EE_30_4 = (EE_30_4+EE_30_4_2)/2;
% N = EE_30_4.*EE_30_4_2;
% N(N<0) = 0;
% EE_30_4 = sqrt(N);
EE_30 = cat(3,EE_30_1,EE_30_2,EE_30_3,EE_30_4);

load(mPath_35_1,'EE1','EE2');
EE_35_1=EE1;EE_35_2=EE2;
load(mPath_35_3,'EE3');EE_35_3=EE3;
load(mPath_35_4,'EE4');EE_35_4=EE4;
EE_35 = cat(3,EE_35_1,EE_35_2,EE_35_3,EE_35_4);

load(mPath_40_1,'EE1');EE_40_1=EE1;
load(mPath_40_2,'EE2');EE_40_2=EE2;
load(mPath_40_3,'EE3');EE_40_3=EE3;
load(mPath_40_4,'EE4');EE_40_4=EE4;
EE_40 = cat(3,EE_40_1,EE_40_2,EE_40_3,EE_40_4);


idx25 = 21;
idx30 = 14;
idx35 = 11;
idx40 = 25;
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
PCBfile25 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx25),'_200ch.mat');
load(PCBfile25,'data2D','grid2D');PCBdata25.data2D=data2D;PCBdata25.grid2D=grid2D;
PCBfile30 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx30),'_200ch.mat');
load(PCBfile30,'data2D','grid2D');PCBdata30.data2D=data2D;PCBdata30.grid2D=grid2D;
PCBfile35 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx35),'_200ch.mat');
load(PCBfile35,'data2D','grid2D');PCBdata35.data2D=data2D;PCBdata35.grid2D=grid2D;
PCBfile40 = strcat(pathname.pre_processed_directory,'/',num2str(240111),sprintf('%03d',idx40),'_200ch.mat');
load(PCBfile40,'data2D','grid2D');PCBdata40.data2D=data2D;PCBdata40.grid2D=grid2D;

SXR.date = 240111;
SXR.shot = 0;
SXR.show_localmax = false;
SXR.doSave = false;
SXR.doFilter = false;
SXR.doNLR = true;

zhole1=40;zhole2=-40;                                  
% zmin1=-240;zmax1=320;zmin2=-320;zmax2=240;             
% rmin=55;rmax=375;
zmin1=-100;zmax1=180;zmin2=-180;zmax2=100;
rmin=70;rmax=330;
range = [zmin1,zmax1,zmin2,zmax2,rmin,rmax];
t = 469;

SXRdata25.EE = EE_25;
SXRdata30.EE = EE_30;
SXRdata35.EE = EE_35;
SXRdata40.EE = EE_40;

SXRdata25.range = range;
SXRdata30.range = range;
SXRdata35.range = range;
SXRdata40.range = range;
SXRdata25.t = 465;
SXRdata30.t = t;
SXRdata35.t = t;
SXRdata40.t = t;

f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
plot_save_sxr(PCBdata25,SXR,SXRdata25);
f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
plot_save_sxr(PCBdata30,SXR,SXRdata30);
f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
plot_save_sxr(PCBdata35,SXR,SXRdata35);
% f = figure;f.Units = 'normalized';f.Position = [0.1,0.2,0.8,0.8];
% plot_save_sxr(PCBdata40,SXR,SXRdata40);