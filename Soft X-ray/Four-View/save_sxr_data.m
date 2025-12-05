% clear
% close all
clearvars -except date doFilter doNLR
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
pathname.github = getenv('GITHUB_DIR');


%%%%実験オペレーションの取得
prompt = {'Date:','doFilter:','doNLR:'};
definput = {'','',''};
if exist('date','var')
    definput{1} = num2str(date);
end
if exist('doFilter','var')
    definput{2} = num2str(doFilter);
end
if exist('doNLR','var')
    definput{3} = num2str(doNLR);
end
dlgtitle = 'Input';
dims = [1 35];
answer = inputdlg(prompt,dlgtitle,dims,definput);
if isempty(answer)
    return
end

date = str2double(cell2mat(answer(1)));
doFilter = logical(str2num(cell2mat(answer(2))));
doNLR = logical(str2num(cell2mat(answer(3))));

SXR.doFilter = doFilter;
SXR.doNLR = doNLR;
SXR.show_xpoint = false;
SXR.show_localmax = false;
SXR.date = date;

if doFilter & doNLR
    options = 'NLF_NLR';
elseif ~doFilter & doNLR
    options = 'LF_NLR';
elseif doFilter & ~doNLR
    options = 'NLF_LR';
else
    options = 'LF_LR';
end

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
doX = false;
doDown = false;
doSep = false;
if exist(sxrDataFile,'file')
    % load(sxrDataFile,'idxList','xpointList');
    load(sxrDataFile)
    if ~exist('xpointList','var')
        doX = true;
        xpointData = struct('max',zeros(4,8),'mean',zeros(4,8),'std',zeros(4,8),'x',zeros(4,8), ...
            'MR',zeros(1,8),'t',zeros(1,8));
        xpointList = repmat(xpointData,numel(IDXlist),1);
    end
    if ~exist('downstreamList','var')
        doDown = true;
        downstreamData = struct('max_l',zeros(4,8),'mean_l',zeros(4,8),'std_l',zeros(4,8), ...
            'max_r',zeros(4,8),'mean_r',zeros(4,8),'std_r',zeros(4,8), ...
            'MR',zeros(1,8),'t',zeros(1,8));
        downstreamList = repmat(downstreamData,numel(IDXlist),1);
    end
    if ~exist('separatrixList','var')
        doSep = true;
        separatrixData = struct('max_l',zeros(4,8),'mean_l',zeros(4,8),'std_l',zeros(4,8), ...
            'max_r',zeros(4,8),'mean_r',zeros(4,8),'std_r',zeros(4,8), ...
            'MR',zeros(1,8),'t',zeros(1,8));
        separatrixList = repmat(separatrixData,numel(IDXlist),1);
    end

else
    doX = true;
    doDown = true;
    doSep = true;
    idxList = zeros(numel(IDXlist),1);
    xpointData = struct('max',zeros(4,8),'mean',zeros(4,8),'std',zeros(4,8),'x',zeros(4,8), ...
        'MR',zeros(1,8),'t',zeros(1,8));
    xpointList = repmat(xpointData,numel(IDXlist),1);
    downstreamData = struct('max_l',zeros(4,8),'mean_l',zeros(4,8),'std_l',zeros(4,8), ...
        'max_r',zeros(4,8),'mean_r',zeros(4,8),'std_r',zeros(4,8), ...
        'MR',zeros(1,8),'t',zeros(1,8));
    downstreamList = repmat(downstreamData,numel(IDXlist),1);
    separatrixData = struct('max_l',zeros(4,8),'mean_l',zeros(4,8),'std_l',zeros(4,8), ...
        'max_r',zeros(4,8),'mean_r',zeros(4,8),'std_r',zeros(4,8), ...
        'MR',zeros(1,8),'t',zeros(1,8));
    separatrixList = repmat(separatrixData,numel(IDXlist),1);
end

% doSep = 1;

for i=1:n_data
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
    SXR.start = startlist(i);
    SXR.interval = intervallist(i);
    SXR.shot = IDXlist(i);
    SXR.SXRfilename = strcat(getenv('SXR_IMAGE_DIR'),filesep,num2str(date),'/shot',num2str(SXR.shot,'%03i'),'.tif');
    if isfile(SXR.SXRfilename)
        idxList(i) = PCB.idx;
        if doX
            xpointList(i) = get_emission_xpoint(PCB,SXR,pathname);
        end
        if doDown
            downstreamList(i) = get_emission_downstream(PCB,SXR,pathname);
        end
        if doSep
            separatrixList(i) = get_emission_separatrix(PCB,SXR,pathname);
        end
    end
end

save(sxrDataFile,'idxList','xpointList','downstreamList','separatrixList');