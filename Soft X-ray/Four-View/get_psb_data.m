function [PCB, pathname] = get_psb_data() 
    % 変数のクリア（前回の入力値 saved_data は保持する）
    clearvars -except saved_data
    
    % --- パス設定 ---
    addpath '/Users/shohgookazaki/Documents/GitHub/test-open/pcb_experiment';
    % inputdlg関連のパスは不要になったので削除しました
    addpath '/Users/shohgookazaki/Documents/matlab/common';
    run define_path.m
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % 200ch用新規pcbプローブのみでの磁気面（Bz）
    % dtacqのshot番号を直接指定する場合
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    % エラー回避用初期化
    PCB.doCheck = 0;
    dataType = 1;
    PCB.chtype = 1;
    
    %%%% 実験オペレーションの取得（高速版） %%%%
    
    % 前回の入力値があればデフォルトとして使用
    if exist('saved_data', 'var')
        defaults = saved_data;
    else
        % 初回起動時のデフォルト値
        defaults.date = [];
        defaults.shot = '';
        defaults.a039 = [];
        defaults.doCheck = 0; % 0=False
        defaults.restart = 0; % 0=False
        defaults.dataType = {}; 
    end
    
    % ★高速入力ウィンドウ呼び出し (get_input_fast.m を使用)
    [userInput, canceled] = get_input_fast(defaults);
    
    if canceled
        disp('Input canceled by user.');
        PCB = []; pathname = []; % キャンセル時は空を返して終了
        return;
    end
    
    % --- 入力値の展開 ---
    date = userInput.date;
    IDXlist_str = userInput.shot;
    IDXlist = str2num(IDXlist_str); % 文字列を数値配列に変換
    a039 = userInput.a039;
    
    PCB.doCheck = userInput.doCheck;
    PCB.restart = userInput.restart;
    
    % 選択されたデータタイプ（Cell配列）
    dataTypeList = userInput.dataType;
    
    % 次回のために保存（ワークスペースに残るようにする）
    saved_data = userInput;
    
    % --- データ取得・検索ロジック ---
    % PCB.xpointdata = xpointdata;
    FIG.start = 400;
    FIG.end = 500;
    DOCID='1wG5fBaiQ7-jOzOI-2pkPAeV6SDiHc_LrOdcbWlvhHBw'; % スプレッドシートのID
    
    T = getTS6log(DOCID);
    
    if ~isempty(date) && ~isempty(IDXlist)
        T = searchlog(T, 'date', date);
        if isnan(T.shot(1))
            T(1, :) = [];
        end
        n_data = numel(IDXlist); % 計測データ数
        % shotlist=T.a039(IDXlist);
        shotlist = [T.a039(IDXlist), T.a040(IDXlist)];
        % tfshotlist=T.a039_TF(IDXlist);
        tfshotlist = [T.a039_TF(IDXlist), T.a040_TF(IDXlist)];
        EFlist = T.EF_A_(IDXlist);
        TFlist = T.TF_kV_(IDXlist);
        dtacqlist = 39 .* ones(n_data, 1);
        
    elseif ~isempty(a039)
        T = searchlog(T, 'a039', a039);
        n_data = numel(a039);
        shotlist = [T.a039, T.a040];
        tfshotlist = [T.a039, T.a040];
        EFlist = T.EF_A_;
        TFlist = T.TF_kV_;
        dtacqlist = 39 .* ones(n_data, 1);
        date = T.date;
        IDXlist = T.shot;
    else
        % 入力が足りない場合などのエラーハンドリングが必要ならここに記述
        n_data = 0;
    end
    
    PCB.n_data = n_data; %【input】計測データ数
    % trange=400:600;%【input】計算時間範囲
    % n=50; %【input】rz方向のメッシュ数
    PCB.trange = 400:600; %【input】計算時間範囲
    PCB.n = 40; %【input】rz方向のメッシュ数
    %PCB.start = 80;
    PCB.start = 60; % plot開始時間-400
    PCB.dt = 2; % plot間隔時間
    
    all_data = zeros(n_data, numel(PCB.trange));
    all_merging_ratios = zeros(n_data, numel(PCB.trange));
    
    % データの格納ループ
    for i = 1:n_data
        % dtacq_num=dtacqlist;
        PCB.alldate(i) = date;
        PCB.allidx(i) = IDXlist(i);
        PCB.allshot(i,:) = shotlist(i,:);
        PCB.alltfshot(i,:) = tfshotlist(i,:);
        PCB.alldataType{i} = dataTypeList;
        
        if PCB.allshot(i) == PCB.alltfshot(i)
            PCB.alltfshot(i) = [0, 0];
        end
        
        PCB.alli_EF(i) = EFlist(i);
        PCB.allTF(i) = TFlist(i);
    end
    
    % pathnameが未定義だとエラーになる可能性があるため、とりあえず空を入れておきます
    % 必要に応じて修正してください
    if ~exist('pathname', 'var')
        pathname = ''; 
    end
    
end

function [data, canceled] = get_input_fast(defaults)
    % GET_INPUT_FAST: 軽量で高速な入力GUI
    % 起動速度を優先し、uicontrolを使用。
    
    % ウィンドウ設定
    W = 400; H = 450; % 幅と高さ
    hFig = figure('Name', 'Input', ...
        'NumberTitle', 'off', 'MenuBar', 'none', 'ToolBar', 'none', ...
        'Resize', 'off', 'Position', [300, 300, W, H], ...
        'WindowStyle', 'modal', 'Color', [0.94 0.94 0.94]);

    % デフォルト値の準備
    if isempty(defaults.date), defaults.date = ''; end
    if isempty(defaults.shot), defaults.shot = ''; end
    if isempty(defaults.a039), defaults.a039 = ''; end
    
    % --- UI部品の配置 (位置は [left bottom width height]) ---
    
    % 1. Date
    uicontrol(hFig, 'Style', 'text', 'String', 'Date:', ...
        'Position', [20 H-40 80 20], 'HorizontalAlignment', 'right');
    hDate = uicontrol(hFig, 'Style', 'edit', 'String', num2str(defaults.date), ...
        'Position', [110 H-37 150 25], 'BackgroundColor', 'white');

    % 2. Shot Number
    uicontrol(hFig, 'Style', 'text', 'String', 'Shot number:', ...
        'Position', [20 H-75 80 20], 'HorizontalAlignment', 'right');
    hShot = uicontrol(hFig, 'Style', 'edit', 'String', defaults.shot, ...
        'Position', [110 H-72 150 25], 'BackgroundColor', 'white');

    % 3. a039
    uicontrol(hFig, 'Style', 'text', 'String', 'a039:', ...
        'Position', [20 H-110 80 20], 'HorizontalAlignment', 'right');
    hA039 = uicontrol(hFig, 'Style', 'edit', 'String', num2str(defaults.a039), ...
        'Position', [110 H-107 150 25], 'BackgroundColor', 'white');

    % 4. Checkboxes (高速アクセスのためチェックボックス化)
    hCheck = uicontrol(hFig, 'Style', 'checkbox', 'String', 'doCheck', ...
        'Value', defaults.doCheck, 'Position', [110 H-145 100 20]);
    
    hRestart = uicontrol(hFig, 'Style', 'checkbox', 'String', 'Restart', ...
        'Value', defaults.restart, 'Position', [200 H-145 100 20]);

    % 5. Data Type List (一覧性を確保)
    uicontrol(hFig, 'Style', 'text', 'String', 'Data Type (Ctrl+Click for multiple):', ...
        'Position', [20 H-180 250 20], 'HorizontalAlignment', 'left');
    
    items = {'psi', 'Bz', 'Bt', 'Br','Jt','Et', 'lBl','dBzdt','dBtdt','dBrdt',...
             'dBdt_magnitude','B_parallel','dB_parallel_dt', 'curvature', ...
             'Bt_th','Lamor', 'Vcurvature','VdeltaB','Vmagneticfieldline','gradB_r','gradB_z'};
         
    hList = uicontrol(hFig, 'Style', 'listbox', 'String', items, ...
        'Min', 0, 'Max', 2, ... % 複数選択可能に設定
        'Position', [20 60 360 140], 'BackgroundColor', 'white');
    
    % デフォルト選択状態の復元
    if ~isempty(defaults.dataType)
        [~, idx] = intersect(items, defaults.dataType);
        set(hList, 'Value', idx);
    end

    % --- Buttons ---
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'OK', ...
        'Position', [230 15 100 30], 'FontWeight', 'bold', ...
        'Callback', @(s,e) uiresume(hFig));
    
    uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Cancel', ...
        'Position', [70 15 100 30], ...
        'Callback', @(s,e) closeWin(hFig));

    % キーボードショートカット (EnterでOK)
    set(hFig, 'WindowKeyPressFcn', @(s,e) keyPressHandler(s,e,hFig));

    % 待機
    uiwait(hFig);

    % --- データ取得 ---
    if ishandle(hFig)
        data.date = str2num(get(hDate, 'String')); %#ok<*ST2NM>
        data.shot = get(hShot, 'String'); % 文字列のまま
        data.a039 = str2num(get(hA039, 'String'));
        data.doCheck = get(hCheck, 'Value');
        data.restart = get(hRestart, 'Value');
        
        selIdx = get(hList, 'Value');
        data.dataType = items(selIdx);
        
        canceled = false;
        delete(hFig);
    else
        data = [];
        canceled = true;
    end
end

function closeWin(fig)
    delete(fig);
end

function keyPressHandler(~, event, fig)
    if strcmp(event.Key, 'return')
        uiresume(fig);
    elseif strcmp(event.Key, 'escape')
        delete(fig);
    end
end