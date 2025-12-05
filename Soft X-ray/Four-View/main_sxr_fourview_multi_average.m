% 用件定義

% 条件が同じ複数のショットの平均値を使って発光分布を表示するコード
% 生データの平均値を使うか、再構成結果の平均を取るか
% どちらにしても既存コードをうまく使いたい

% 生データの平均を取る場合
% スプレッドシートから同じ条件のshotを抽出
% その段階でそれぞれのshotの結果を取得し、平均値のファイルを作成
% そのファイル名をSXR.SXRfilenameとしてplot_sxr_multiに渡す
% 同時にSXR.shotも変更？恐らく再構成結果の保存にしか使用していない
% 磁気面は一旦そのshotのものを使ってみる
% まずはこっち

% 再構成結果の平均を取る場合
% そもそもコード全体の編集が必要
% plot_sxr_multi内で複数回再構成結果を取得（この場合は計算結果が存在することを前提としてよさそう）
% 各時点における再構成結果の平均をとってプロット
% この場合も磁気面については平均は取らなくてよさそう

clearvars -except date IDXlist doSave doFilter doNLR doPlotPsi
addpath([getenv('GITHUB_DIR'),'test-open',filesep,'pcb_experiment']); %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス

%%%%%ここが各PCのパス
%【※コードを使用する前に】環境変数を設定しておくか、matlab内のコマンドからsetenv('パス名','アドレス')で指定してから動かす
pathname.NIFS=getenv('NIFS_path');%192.168.1.111
pathname.fourier=getenv('fourier_path');%fourierのmd0（データックのショットが入ってる）までのpath
pathname.rawdata=getenv('rawdata_path');%dtacqのrawdataの保管場所;
pathname.pre_processed_directory = getenv('pre_processed_directory_path');%計算結果の保存先（どこでもいい）
pathname.github=getenv('GITHUB_DIR');%githubのパス

%%%%実験オペレーションの取得
prompt = {'Date:','Shot number:','doSave:','doFilter:','doNLR:','doPlotPsi:'};
definput = {'','','','','',''};
if exist('date','var')
    definput{1} = num2str(date);
end
if exist('IDXlist','var')
    definput{2} = num2str(IDXlist);
end
if exist('doSave','var')
    definput{3} = num2str(doSave);
end
if exist('doFilter','var')
    definput{4} = num2str(doFilter);
end
if exist('doNLR','var')
    definput{5} = num2str(doNLR);
end
if exist('doPlotPsi','var')
    definput{6} = num2str(doPlotPsi);
end
dlgtitle = 'Input';
dims = [1 35];
% if exist('date','var') && exist('IDXlist','var')
%     definput = {num2str(date),num2str(IDXlist)};
% else
%     definput = {'',''};
% end
answer = inputdlg(prompt,dlgtitle,dims,definput);
if isempty(answer)
    return
end
date = str2double(cell2mat(answer(1)));
IDXlist = str2num(cell2mat(answer(2))); %実際のショット番号
doSave = logical(str2num(cell2mat(answer(3))));
doFilter = logical(str2num(cell2mat(answer(4))));
doNLR = logical(str2num(cell2mat(answer(5))));
doPlotPsi = logical(str2num(cell2mat(answer(6))));

SXR.doSave = doSave;
SXR.doFilter = doFilter;
SXR.doNLR = doNLR;
SXR.projection=30;
SXR.grid=50;

DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
T=searchlog(T,node,date);

T = T(strcmp(T.SXRComment,'success'),:); %軟X線画像が撮れたshotに限定してデータを取得
T_condition = T(:,13:end);
T_condition = rmmissing(T_condition,2);

% T_condition.gas = [];
T_condition.SXRComment = [];
rows_to_compare = T_condition;
% row_to_test = T_condition(10,:); %基準となるshotのインデックス（切り出し後の並び）
% compareResults = table2array(rows_to_compare(:,:) == row_to_test);

n_data=numel(IDXlist);%計測データ数
IDXlist2 =  find(any(T.shot == IDXlist,2)); %切り出し後の配列における対象ショットのidx

% n_data=numel(IDXlist2);%計測データ数
shotlist_a039 = T.a039(IDXlist2);
shotlist_a040 = T.a040(IDXlist2);
shotlist = [shotlist_a039, shotlist_a040];
tfshotlist_a039 = T.a039_TF(IDXlist2);
tfshotlist_a040 = T.a040_TF(IDXlist2);
tfshotlist = [tfshotlist_a039, tfshotlist_a040];
EFlist=T.EF_A_(IDXlist2);
TFlist=T.TF_kV_(IDXlist2);
dtacqlist=39.*ones(n_data,1);
startlist = T.SXRStart(IDXlist2);
intervallist = T.SXRInterval(IDXlist2);

PCB.trange=400:800;%【input】計算時間範囲
PCB.n=50; %【input】rz方向のメッシュ数

t = 470;
SXR.show_xpoint = false;
SXR.show_localmax = false;

for i=1:n_data
    disp(strcat('(',num2str(i),'/',num2str(n_data),')'));
    % IDXlist2 = find(T.shot == IDXlist(i));
    % shotlist_a039 = T.a039(IDXlist2);
    % shotlist_a040 = T.a040(IDXlist2);
    % shotlist = [shotlist_a039, shotlist_a040];
    % tfshotlist_a039 = T.a039_TF(IDXlist2);
    % tfshotlist_a040 = T.a040_TF(IDXlist2);
    % tfshotlist = [tfshotlist_a039, tfshotlist_a040];
    % EFlist=T.EF_A_(IDXlist2);
    % TFlist=T.TF_kV_(IDXlist2);
    % dtacqlist=39.*ones(n_data,1);
    % startlist = T.SXRStart(IDXlist2);
    % intervallist = T.SXRInterval(IDXlist2);

    PCB.idx = IDXlist(i);
    % j = find(IDXlist2 == PCB.idx);
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    if date == 250325 && PCB.idx >= 37
        PCB.shot=shotlist(1,:);
        PCB.tfshot=tfshotlist(1,:);
    end
    PCB.i_EF=EFlist(i);
    PCB.date = date;
    TF=TFlist(i);
    SXR.start = startlist(i);
    SXR.interval = intervallist(i);
    [PCBdata.grid2D,PCBdata.data2D] = process_PCBdata_200ch(PCB,pathname);
    PCBdata.doPlotPsi = doPlotPsi;
    
    avgIdx = IDXlist(i)+100;
    SXRfilename_avg = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date),'/shot',num2str(avgIdx,'%03i'),'.tif');
    row_to_test = T_condition(IDXlist2(i),:); %基準となるshotのインデックス（切り出し後の並び）
    compareResults = table2array(rows_to_compare(:,:) == row_to_test);
    if ~exist(SXRfilename_avg,'file')
        SXRfilename_tmp = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date),'/shot',num2str(IDXlist(i),'%03i'),'.tif');
        averageImg = zeros(size(imread(SXRfilename_tmp)),'uint16');
        sameShotList = T.shot(all(compareResults,2),:);
        n_sameData = numel(sameShotList);
        for j = 1:n_sameData
            SXRfilename_tmp = strcat(getenv('SXR_IMAGE_DIR'),'/',num2str(date),'/shot',num2str(sameShotList(j),'%03i'),'.tif');
            averageImg = averageImg + imread(SXRfilename_tmp);
        end
        averageImg = averageImg/n_sameData;
        imwrite(averageImg,SXRfilename_avg);
    end
    SXR.date = date;
    SXR.shot = avgIdx;
    SXR.SXRfilename = SXRfilename_avg;
    plot_sxr_multi(PCBdata,SXR);
end