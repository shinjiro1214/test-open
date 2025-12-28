function vq = bz_rbfinterp(rpos, zpos, grid2D, bz, ok, t)
%%入力
% bz[samplingnumber×ch],rpos(ch),zpos(ch),grid2D{rq(n×n),zq(n×n)},ok(128(true or false)),t[us]
%%出力
% vq(n×n) ：bzがn×nのグリッドにrbf補間されたもの

%%スムージングと関数の選択
% --- 推奨設定 ---
smoothval = 0.05; % ノイズの量に応じて調整 (0.01 ~ 0.1 程度)
func = 'Thinplate'; % 薄板スプライン (パラメータ調整不要で自然な滑らかさになる)
% const = 0.015; % Thinplateの場合はconstは無視されることが多いですが、念のため残してもOK

%%無視するチャンネルを除いたbzの散布データ（okのチャンネルのみ残す）
x = zpos(ok);
y = rpos(ok);
z = double(bz(t,ok))';

%%補間
% Thinplate等はRBFConstantの影響を受けにくい、または自動調整されることが多いですが
% rbfcreateの仕様に合わせて引数はそのまま渡します。
vq = rbfinterp([grid2D.zq(:)'; grid2D.rq(:)'], ...
               rbfcreate([x' ; y'], z', ...
                         'RBFFunction', func, ...
                         'RBFSmooth', smoothval)); 
                         % 'RBFConstant', const はThinplateでは基本不要ですが、
                         % エラーが出るなら入れてください

vq = reshape(vq, size(grid2D.zq));
end