function vq = bz_rbfinterp(rpos, zpos, grid2D, bz, ok, t)
%%入力
% bz[samplingnumber×ch],rpos(ch),zpos(ch),grid2D{rq(n×n),zq(n×n)},ok(128(true or false)),t[us]
%%出力
% vq(n×n) ：bzがn×nのグリッドにrbf補間されたもの

%%スムージングと関数の選択
smoothval=0.05;
% func='multiquadric';%Gaussian, Linear, Cubic,multiquadric, Thinplate から選べる
func='Linear';
const=0.015;
%%無視するチャンネルを除いたbzの散布データ（okのチャンネルのみ残す）
x=zpos(ok);
y=rpos(ok);
z=double(bz(t,ok))';

%%補間
vq= rbfinterp([grid2D.zq(:)'; grid2D.rq(:)'], rbfcreate([x' ; y'], z','RBFFunction',func,'RBFConstant',const,'RBFSmooth', smoothval ));%,'RBFSmooth', smoothval,'RBFConstant',const));
vq = reshape(vq, size(grid2D.zq));
end