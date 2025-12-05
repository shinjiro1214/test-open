% clear
% close all
% clearvars -except date shotIDXList doCheck
clearvars -except default
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/pcb_experiment'; %getMDSdata.mとcoeff200ch.xlsxのあるフォルダへのパス
addpath '/Users/shinjirotakeda/Documents/GitHub/test-open/Soft X-ray/Four-View_Simulation';

%%%%%%%%%%%%%%%%%%%%%%%%
%280ch用新規pcbプローブのみでの磁気面（Bz）
%%%%%%%%%%%%%%%%%%%%%%%%


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

% %%%%実験オペレーションの取得
% prompt = {'Date:','Shot number:','doCheck:'};
% definput = {'','',''};
% if exist('date','var')
%     definput{1} = num2str(date);
% end
% if exist('shotIDXList','var')
%     definput{2} = num2str(shotIDXList);
% end
% if exist('doCheck','var')
%     definput{3} = num2str(doCheck);
% end
% dlgtitle = 'Input';
% dims = [1 35];
% % if exist('date','var') && exist('IDXlist','var') && exist('doCheck','var')
% %     definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
% % else
% %     definput = {'','',''};
% % end
% % definput = {'','',''};
% % definput = {num2str(date),num2str(IDXlist),num2str(doCheck)};
% answer = inputdlg(prompt,dlgtitle,dims,definput);
% date = str2double(cell2mat(answer(1)));
% shotIDXList = str2num(cell2mat(answer(2)));
% doCheck = logical(str2num(cell2mat(answer(3))));

if ~exist('default','var'), default=NaN; end
answer = customDialog(default);
default = answer;
date = str2double(answer.dateValue);
shotIDXList = str2double(answer.shotValue);
PCB.type = answer.dataTypeValue;
doCheck = logical(answer.checkValue);
PCB.doOverwrite = logical(answer.overwriteValue);



DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw';%スプレッドシートのID
T=getTS6log(DOCID);
node='date';
% date=230714;
T=searchlog(T,node,date);
IDXlist = find(T.shot==shotIDXList);
% IDXlist= 1; %[5:50 52:55 58:59];%[4:6 8:11 13 15:19 21:23 24:30 33:37 39:40 42:51 53:59 61:63 65:69 71:74];
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
% PCB.start = 50; %plot開始時間-400
PCB.start = 63; %plot開始時間-400
% PCB.start = 69; %plot開始時間-400
PCB.dt = 2;

% doCheck = false;
% doCheck = true;
% if ~doCheck
%     figure('Position', [0 0 1500 1500],'visible','on');
% end
% psiList = zeros(n_data,numel(PCB.trange));
% idxLegend = strsplit(num2str(IDXlist),' ');
for i=1:n_data
    % dtacq_num=dtacqlist;
    % PCB.idx = IDXlist(i);
    PCB.idx = shotIDXList;
    PCB.shot=shotlist(i,:);
    PCB.tfshot=tfshotlist(i,:);
    if PCB.shot == PCB.tfshot
        PCB.tfshot = [0,0];
    end
    PCB.i_EF=EFlist(i);
    PCB.TF=TFlist(i);
    PCB.date = date;
    if doCheck
        check_signal(PCB,pathname);
    else
        plot_psi280ch(PCB,pathname);
        % plot_psi280ch_short(PCB,pathname);
        % rgwData = get_rgw_data(PCB,pathname);
        % figure;hold on;
        % for j = 1:size(rgwData.V_all,1)
        %     plot(rgwData.t,rgwData.V_all(j,:));
        % end
        % xlim([3900 5000]);ylim([-0.5 0.5]);
        % [B_r,B_t,b] = get_guide_field_ratio(PCB,pathname);
        % [B_r,B_t,b] = get_guide_field_ratio2(PCB,pathname);
        % disp(['B_r=',num2str(B_r),', B_t=',num2str(B_t),', b=',num2str(b)]);
        % data = get_guide_field_ratio3(PCB,pathname);
        % disp(['B_r=',num2str(data.Br),', B_t=',num2str(data.Bt),', b=',num2str(data.GFR)]);
        % disp(['B_t_th=',num2str(data.Bt_th),', b_th=',num2str(data.GFR_th)]);
        % get_B_reconnection(PCB,pathname);
        % [grid2D,data2D] = process_PCBdata_200ch(PCB,pathname);
        % [magAxisList,xPointList] = get_axis_x_multi(grid2D,data2D);
        % psiList(i,:) = xPointList.psi;
    end
end
% figure;hold on
% for i = 1:n_data
%     plot(PCB.trange,psiList(i,:),LineWidth=3);
% end
% xlim([455 485]);
% legend(idxLegend);

function answer = customDialog(default)
    if ~isfield(default,'dateValue')
        defaultDate = ''; 
    else
        defaultDate = default.dateValue;
    end
    if ~isfield(default,'shotValue')
        defaultShot = ''; 
    else
        defaultShot = default.shotValue;
    end
    if ~isfield(default,'dataTypeValue')
        defaultDataType = 1; 
    else
        defaultDataType = default.dataTypeValue;
    end
    if ~isfield(default,'checkValue')
        defaultCheck = false; 
    else
        defaultCheck = default.checkValue;
    end
    if ~isfield(default,'overwriteValue')
        defaultOverwrite = false; 
    else
        defaultOverwrite = default.overwriteValue;
    end

    % ダイアログボックスを作成
    d = dialog('Position', [300, 300, 400, 350], 'Name', 'Custom Dialog');

    % 'date'テキスト入力フィールドのラベル
    uicontrol('Parent', d, ...
              'Style', 'text', ...
              'Position', [20, 290, 100, 20], ...
              'String', 'Date:');
    
    % 'date'テキスト入力フィールド
    dateField = uicontrol('Parent', d, ...
                          'Style', 'edit', ...
                          'Position', [130, 290, 200, 25], ...
                          'String', defaultDate);

    % 'shot'テキスト入力フィールドのラベル
    uicontrol('Parent', d, ...
              'Style', 'text', ...
              'Position', [20, 250, 100, 20], ...
              'String', 'Shot:');
    
    % 'shot'テキスト入力フィールド
    shotField = uicontrol('Parent', d, ...
                          'Style', 'edit', ...
                          'Position', [130, 250, 200, 25], ...
                          'String', defaultShot);

    % 'data type'リスト選択フィールドのラベル
    uicontrol('Parent', d, ...
              'Style', 'text', ...
              'Position', [20, 210, 100, 20], ...
              'String', 'Data Type:');
    
    % 'data type'リスト選択フィールド
    dataTypeList = uicontrol('Parent', d, ...
                             'Style', 'popupmenu', ...
                             'Position', [130, 210, 200, 25], ...
                             'String', {'psi', 'Bz', 'Bt', 'Br', 'Et', 'Jt', 'GFR', 'Bp', 'B', 'Eeff', 'Energy increment', 'Energy gain', 'Resistivity'}, ...
                             'Value', defaultDataType);

    % 'check'ラジオボタン
    checkRadioButton = uicontrol('Parent', d, ...
                                 'Style', 'radiobutton', ...
                                 'Position', [130, 170, 200, 25], ...
                                 'String', 'Check', ...
                                 'Value', defaultCheck);

    % 'overwrite'ラジオボタン
    overwriteRadioButton = uicontrol('Parent', d, ...
                                     'Style', 'radiobutton', ...
                                     'Position', [130, 140, 200, 25], ...
                                     'String', 'Overwrite', ...
                                     'Value', defaultOverwrite);

    % OKボタン
    btn = uicontrol('Parent', d, ...
                    'Position', [150, 50, 70, 25], ...
                    'String', 'OK', ...
                    'Callback', @btnCallback);

    % ボタンのコールバック関数
    function btnCallback(~, ~)
        % 各フィールドの値を取得
        answer.dateValue = get(dateField, 'String');
        answer.shotValue = get(shotField, 'String');
        answer.dataTypeValue = get(dataTypeList, 'Value');
        answer.checkValue = get(checkRadioButton, 'Value');
        answer.overwriteValue = get(overwriteRadioButton, 'Value');

        % ダイアログボックスを閉じる
        delete(d);
    end

    % ダイアログボックスが閉じられるまで待機
    uiwait(d);

    % 関数の返り値として出力
    if isvalid(d)
        delete(d);
    end
end