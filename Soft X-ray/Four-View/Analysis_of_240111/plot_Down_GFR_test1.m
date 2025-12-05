% clear
% close all
% clearvars -except date doFilter doNLR plotMax plotType
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View_Simulation';


%%%%%ここが各PCのパスx
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
pathname.ts3u=getenv('ts3u_path');%old-koalaのts-3uまでのパス（mrdなど）
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.NIFS=getenv('NIFS_path');%resultsまでのpath（ドップラー、SXR）
pathname.save=getenv('savedata_path');%outputデータ保存先
pathname.rawdata38=getenv('rawdata038_path');%dtacq a038のrawdataの保管場所
pathname.woTFdata=getenv('woTFdata_path');%rawdata（TFoffset引いた）の保管場所
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
pathname.SXRDATA = getenv('SXRDATA_DIR');
pathname.MAGDATA = getenv('MAGDATA_DIR');


date = 240111;
SXR.doFilter = false;
SXR.doNLR = true;
SXR.show_xpoint = false;
SXR.show_localmax = false;
SXR.date = date;

options = 'LF_NLR';

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,date);
IDXlist = T.shot;
IDXlist = IDXlist.';
n_data=numel(IDXlist);%計測データ数
shotlist_a039 =T.a039(IDXlist);
shotlist_a040 = T.a040(IDXlist);
shotlist = [shotlist_a039, shotlist_a040];
tfshotlist_a039 =T.a039_TF(IDXlist);
tfshotlist_a040 =T.a040_TF(IDXlist);
tfshotlist = [tfshotlist_a039, tfshotlist_a040];
EFlist=T.EF_A_(IDXlist);
TFlist=T.TF_kV_(IDXlist);
dtacqlist=39.*ones(n_data,1);
startlist = T.SXRStart(IDXlist);
intervallist = T.SXRInterval(IDXlist);

PCB.trange=400:800;%【input】計算時間範囲
PCB.n=40; %【input】rz方向のメッシュ数
PCB.start = 20; %plot開始時間-400

sxrDataDir = pathname.SXRDATA;
sxrDataFile = strcat(sxrDataDir,filesep,num2str(date),'_',options,'.mat');
if exist(sxrDataFile,'file')    
    load(sxrDataFile,'idxList','xpointList','downstreamList','separatrixList');
    idxList_sxr = idxList;
else
    disp('No sxr data');
    return
end

magDataDir = pathname.MAGDATA;
magDataFile = strcat(magDataDir,'/',num2str(date),'.mat');
% magDataFile = '/Users/shinjirotakeda/Library/CloudStorage/OneDrive-TheUniversityofTokyo/Documents/data/240111_old7（GFRほぼ一定）.mat';
if exist(magDataFile,'file')
    load(magDataFile,'idxList','BrList','BtList','bList','BtList_th','bList_th');
    idxList_mag = idxList;
else
    disp('No mag data');
    return
end

idxList = idxList(7:18);
BrList = BrList(7:18);
BtList = BtList(7:18);
bList = bList(7:18);
BtList_th = BtList_th(7:18);
bList_th = bList_th(7:18);

downIntensityPath = '/Users/shinjirotakeda/Library/CloudStorage/GoogleDrive-takeda-shinjiro234@g.ecc.u-tokyo.ac.jp/マイドライブ/SXR_DATA/ReconstructionResults/LF_NLR/240111_DownMax_470.xlsx';
intensityTable = readmatrix(downIntensityPath);
I_shot = intensityTable(:,1);
I_low = intensityTable(:,2);
I_middle = intensityTable(:,3);
I_high = intensityTable(:,4);

I_middle(2) = NaN;

% figure;
% subplot(1,3,1);plot(bList,I_low,'*');xlim([2.5 4]);
% subplot(1,3,2);plot(bList,I_middle,'*');xlim([2.5 4]);
% subplot(1,3,3);plot(bList,I_high,'*');xlim([2.5 4]);

Irel_low = I_low./I_middle;
Irel_high = I_high./I_middle;
xData = BtList_th;
figure;hold on;
plot(xData,Irel_low,'*');
% plot(xData,Irel_high,'*');


% num_data = 4;
% GFR = zeros(1,num_data);

% % Imax = zeros(4,num_data);
% Imean = zeros(4,num_data);
% % Istd = zeros(4,num_data);

% m = 2;