%電子温度見積もり
A=40;
delta_phi = 50;%浮遊電位とプラズマ電位の差

m_p=1.67E-27;
m_e=9.11E-31;
m_i=A*m_p;
k=1.38E-23;
e=1.6E-19;

T_e = delta_phi/log(sqrt(m_i/(4*pi*m_e)));