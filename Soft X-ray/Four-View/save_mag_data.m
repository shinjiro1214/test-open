% clear
% close all
clearvars -except date
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
pathname.MAGDATA = getenv('MAGDATA_DIR');

%%%%実験オペレーションの取得
prompt = {'Date:'};
definput = {''};
if exist('date','var')
    definput{1} = num2str(date);
end

dlgtitle = 'Input';
dims = [1 35];
% if exist('date','var') && exist('IDXlist','var') && exist('doCheck','var')
%     definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
% else
%     definput = {'','',''};
% end
% definput = {'','',''};
% definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
answer = inputdlg(prompt,dlgtitle,dims,definput);
date = str2double(cell2mat(answer(1)));

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
% date=230714;
T=searchlog(T,node,date);
% IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
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

PCB.trange=400:800;%【input】計算時間範囲
PCB.n=40; %【input】rz方向のメッシュ数
PCB.start = 20; %plot開始時間-400

PCB.doOverwrite = false;

% doCheck = false;
% doCheck = true;
% if ~doCheck
%     figure('Position', [0 0 1500 1500],'visible','on');
% end

magDataDir = pathname.MAGDATA;
magDataFile = strcat(magDataDir,'/',num2str(date),'.mat');
if exist(magDataFile,'file')
    load(magDataFile,'idxList','BrList','BtList','bList','BtList_th','bList_th','EtList','tList');
else
    idxList = zeros(numel(IDXlist),1);
    BrList = zeros(numel(IDXlist),1);
    BtList = zeros(numel(IDXlist),1);
    bList = zeros(numel(IDXlist),1);
    BtList_th = zeros(numel(IDXlist),1);
    bList_th = zeros(numel(IDXlist),1);
    EtList = zeros(numel(IDXlist),1);
    tList = zeros(numel(IDXlist),1);
end

directory_rogo = strcat(pathname.fourier,'rogowski/');

for i=1:n_data
    % dtacq_num=dtacqlist;
    PCB.idx = IDXlist(i);
    disp(PCB.idx);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.TF=TFlist(i);
    PCB.date = date;

    % current_folder = strcat(directory_rogo,num2str(date),'/');
    if date == 230920
        % date_rgw = 230929;
        current_folder = strcat(directory_rogo,num2str(230929),'/');
        filename = strcat(current_folder,num2str(230929),sprintf('%03d',8),'.rgw');
        % if any(PCB.idx == [1,2,6,10,26,42,43,46,63])
        if PCB.idx<=14 || any(PCB.idx==[18:26,31,32,40:43,45:48,58,59,63,66,67])
            filename = strcat(current_folder,num2str(date),sprintf('%03d',PCB.idx),'.rgw');
        end
    else
        current_folder = strcat(directory_rogo,num2str(date),'/');
        filename = strcat(current_folder,num2str(date),sprintf('%03d',PCB.idx),'.rgw');
    end
    % filename = strcat(current_folder,num2str(date_rgw),sprintf('%03d',PCB.idx),'.rgw');
    
    if isfile(filename) && ~any(PCB.tfshot==0)
        % [B_r,B_t,b] = get_guide_field_ratio(PCB,pathname);
        % idxList(i) = PCB.idx;
        % BrList(i) = B_r;
        % BtList(i) = B_t;
        % bList(i) = b;       
        magData = get_guide_field_ratio3(PCB,pathname);
        idxList(i) = PCB.idx;
        BrList(i) = magData.Br;
        BtList(i) = magData.Bt;
        bList(i) = magData.GFR;
        BtList_th(i) = magData.Bt_th;
        bList_th(i) = magData.GFR_th;
        EtList(i) = magData.Et;
        tList(i) = magData.t;
    end

end

save(magDataFile,'idxList','BrList','BtList','bList','BtList_th','bList_th','EtList','tList');