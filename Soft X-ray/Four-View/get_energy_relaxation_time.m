function tau_eq = get_energy_relaxation_time(Te_eV, ne_m3, gas_type)
% CALC_ENERGY_RELAXATION_TIME エネルギー緩和時間 tau_eq を計算する関数
%
%   tau_eq = get_energy_relaxation_time(Te_eV, ne_m3, gas_type)
%
%   入力:
%       Te_eV    : 電子温度 [eV] (スカラー または 配列)
%       ne_m3    : 電子密度 [m^-3] (スカラー または 配列)
%       gas_type : ガス種 ('Ar', 'H', 'D', 'He')
%
%   出力:
%       tau_eq   : エネルギー緩和時間 [s]
%
%   式 (画像の式は tau_eq^-1 なので、最後に逆数をとります):
%       tau_eq^-1 = (ne * Z^2 * e^4 * m_e^(1/2) * lnLambda) / ...
%                   (3 * pi * (2*pi)^(1/2) * eps0^2 * M_ion * Te^(3/2))

    %% 1. 物理定数 (SI単位)
    e     = 1.60217663e-19; % 電気素量 [C]
    eps0  = 8.85418781e-12; % 真空の誘電率 [F/m]
    m_e   = 9.10938356e-31; % 電子質量 [kg]
    m_p   = 1.6726219e-27;  % 陽子質量 [kg]
    
    %% 2. ガス種のパラメータ設定 (質量M, 電荷数Z)
    % ※ ここでは単純化のため、1価イオン(Z=1)を仮定しています。
    %    必要に応じて Z を変更してください。
    switch upper(gas_type)
        case 'AR'
            A = 39.95; % アルゴン原子量
            Z = 1;     % 価数
        case 'H'
            A = 1.008;
            Z = 1;
        case 'D'
            A = 2.014;
            Z = 1;
        case 'HE'
            A = 4.003;
            Z = 1; % プラズマ条件によっては Z=2
        otherwise
            error('未対応のガス種です。Ar, H, D, He から選んでください。');
    end
    
    M_ion = A * m_p; % イオン質量 [kg]

    %% 3. 単位変換と前処理
    Te_J = Te_eV .* e; % eV -> Joule
    
    % クーロン対数 (ln Lambda) の計算
    % 一般的な近似式: ln(Lambda) = 23 - ln(ne^0.5 * Te^(-1.5))  (Te in eV, ne in cm^-3)
    % ここでは簡単のため、低温プラズマで一般的な固定値、もしくはSIでの簡易計算を使用
    % 厳密に計算する場合は以下:
    % lambda_D = sqrt(eps0 * Te_J ./ (ne_m3 * e^2)); % デバイ長
    % b_min = Z * e^2 ./ (4 * pi * eps0 * 3 * Te_J); % 衝突パラメータ最小値 (古典的)
    % Lambda = lambda_D ./ b_min;
    % lnLambda = log(Lambda);
    
    % 簡易的に 13 (実験室プラズマの代表値) とする場合:
    % lnLambda = 13; 
    
    % 今回は計算します（配列計算対応）
    % デバイ長 [m]
    lambda_D = sqrt(eps0 .* Te_J ./ (ne_m3 .* e^2)); 
    % 90度散乱のインパクトパラメータ (古典論)
    b0 = Z * e^2 ./ (12 * pi * eps0 .* Te_J); 
    Lambda = lambda_D ./ b0;
    lnLambda = log(Lambda);
    
    % lnLambdaが極端な値にならないようガード (通常10-20の範囲)
    lnLambda(lnLambda < 2) = 2; 

    %% 4. 数式の計算 (画像の式)
    % 分子: ne * Z^2 * e^4 * m^(1/2) * lnLambda
    numerator = ne_m3 .* (Z^2) * (e^4) * sqrt(m_e) .* lnLambda;
    
    % 分母: 3 * pi * (2*pi)^(1/2) * eps0^2 * M * Te^(3/2)
    denominator = 3 * pi * sqrt(2*pi) * (eps0^2) * M_ion .* (Te_J.^(3/2));
    
    % 逆緩和時間 (頻度) [s^-1]
    inv_tau = numerator ./ denominator;
    
    % 緩和時間 [s]
    tau_eq = 1 ./ inv_tau;

    % 緩和時間 [us]
    tau_eq = tau_eq * 1e6;

end