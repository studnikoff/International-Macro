clear
tic

%%%%%%%%%%%%%%%%%%
%%% PARAMETERS %%%
%%%%%%%%%%%%%%%%%%
beta = 0.96; %discount factor
sigma = 2; %inverse of intertemporal elasticity
h = [0.01;1]; %labor
A = [0.9;1.1]; %TFP shocks
P_h = [0.8 0.2;0.2 0.8]; %transition matrix for labor
P_A = [0.9 0.1;0.1 0.9]; %transition matrix for TFP
bc = 0; %borrowing constraint
delta = 1; %capital depreciation
alpha = 1/3; %capital share
N = 300; %number of iterations
T = 1000; %number of simulation periods
M = 1000; %number of agents


%%%%%%%%%%
%%% SS %%%
%%%%%%%%%%
P_A_SS = P_A^1000; %stationary distribution of TFP
A_SS = P_A_SS(1,:)*A; %SS TFP
P_h_SS = P_h^1000; %stationary distribution of labor
h_SS = P_h_SS(1,:)*h; %SS labor
K_SS = h_SS*((1/beta-1+delta)/alpha/A_SS)^(1/(alpha-1)); %capital in Ramsey SS 


%%%%%%%%%%%%
%%% GRID %%%
%%%%%%%%%%%%
n_a = 50; %number of elements on grid for assets
n_K = 50; %number of elements on grid for capital
a_min = bc;
a_max = 10*K_SS;
K_min = 1.5*K_SS;
K_max = 3*K_SS;
g = (0:1/(n_a-1):1)';
a = a_min+(a_max-a_min)*g.^3; %grid of wealth
gg = (0:1/(n_K-1):1)';
K = K_min+(K_max-K_min)*gg; %grid of capital 
S = [kron(a,ones(4*n_K,1)) repmat(kron(h,ones(2*n_K,1)),n_a,1) repmat(kron(K,ones(2,1)),2*n_a,1) repmat(A  ,n_a*2*n_K,1)]; %state space
n_s = size(S,1); %number of elements on grid
S_n = [repmat(kron([1;2],ones(2*n_K,1)),n_a,1) repmat([1;2],n_a*2*n_K,1)]; %numbers of shocks


%%%%%%%%%%%%%
%%% GUESS %%%
%%%%%%%%%%%%%
b_ols = [0;1;0;1];
R_2 = 0; 
while R_2 < 0.99
H = [exp(b_ols(1)) b_ols(2); exp(b_ols(3)) b_ols(4)]; 
K_f = H(S_n(:,2),1).*S(:,3).^H(S_n(:,2),2); %future capital
[~, ind_K] = min(abs(repmat(K_f,1,n_K)-repmat(K',n_s,1)),[],2); %number of future K
J = [2*ind_K-1 2*ind_K 2*n_K+2*ind_K-1 2*n_K+2*ind_K]; %potential future states
P = zeros(n_s,4*n_K);
for i = 1:n_s
    P(i,J(i,1:2)) = P_h(S_n(i,1),1)*P_A(S_n(i,2),:);
    P(i,J(i,3:4)) = P_h(S_n(i,1),2)*P_A(S_n(i,2),:);
end
R = 1-delta+alpha*S(:,4).*(h_SS./S(:,3)).^(alpha-1); %capital rent
W = (1-alpha)*S(:,4).*(S(:,3)./h_SS).^alpha; %wage


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SOLVING FOR VALUE FUNCTION %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c = repmat(R.*S(:,1)+W.*S(:,2),1,n_a)-repmat(a',n_s,1); %���������� ��������� ����������� � ������� S, � ������� � ��� 
%�������� ��� ���������� ��������� ��� ������� ���������. �� ��������, ��� �� �������� � ��� ������ ���������� �������
%�������� ����������, ������� �������� �����������. ������ ��������� � ��� �� ������� �� ������� ����������, ������� �� ���
%������ ����������� �� ����� ���������� ��������. ������ ��������� (����������) ��� ��� � �������� ������� �����������. ������� 
%�� ������� ������� �� ������������� �������, � ������� ����� ��� �������� ���������� (���� ������� ��� ����������).
c = max(c,0); %consumption as function of a,a'
U = (c.^(1-sigma)-1)/(1-sigma); %utility on grid
V = zeros(n_s,1); %initial guess
for t = 1:N
    V_old = V;
    [V, I] = max(U+beta*P*reshape(V,4*n_K,n_a),[],2); %Bellman equation. ����� ��� ��� ��, ��� �� ��������. ��� ����� ��������� ���.
    %�������� value function. ��� ����� ���������� ��������� ������� P � reshaped ������� V. 
    error = max(abs((V-V_old)./V_old)); %������� ���������� ������ value function �� �����. ���� ���������� ���������, �� �� ������� 
    %� ����������� value function. � �������� N=300 �������� ������ ���� ����������, ����� �������. �� ����� �������������� ���� ����, 
    %��� �� �������� ������, ����� �������� ��� ����� �� ���� �������, ��� ����������� ����� ����� � ������ value function �� ����������
    %�� ��������� ��������.
end
Savings = a(I); %I - ��� ������-������� ����������� n_s c �������� ����������� ������� ����������. a(I) ��� ���� ������-������� ����������� n_s
%�� ���������� ����������� ������� ����������.


%%%%%%%%%%%%%%%%%%%
%%% SIMULATIONS %%%
%%%%%%%%%%%%%%%%%%%
%��� �������� ��������� �� ������ ����� �������� �� � ����������� ���������� ����� ���������� ���������, � � �� �������� �� �������.
tfp_n(1,1) = 1; %��� tfp � ��� ��� ������: 1 - ��� ������ ������������������, 2 - �������. ������� ��������� ������� ������������������ ��� ������.
emp_n(:,1) = randi(2,M,1); %��� ����� � ��� ���� ������ 2 ��������, �� ���� - �������������� ����������, �.�. ��� ������� �/� �������� ����.
%������� ���������� �� ��������� ������� �������� ������� �/� ���� ����� 1, ���� ����� 2. ������� ������ ������� ����������� M(���������� �/�).
cap_n(1,1) = n_K/2; %�������� ������� ��������� ������� ����� ��� ��������.
assets_n(:,1) = randi(n_a,M,1); %����� �������� ������� ������ ��� ���������� ��� ������� �/�. ����� ������� n_a. ������� ������ ������� ����������� M.
state = zeros(M,T); %������ ����� ��������� - ������ �������� �������� � �������������� market clearing ��� ��������, �.�. ������� �������� �������
%����� ��������� ���������� �� ������� ������ �� ���������� ������� (� ����� ������ ������� ����� 1000 �������). ��� ����� ��� ���������� �����, � �����
%��������� ��������� ������ ����� (�/�). � ��� ������� �� ����� ���������� ����� ��������� ���� ������� � ������ ������ ���������, ������� ������������ 
%������ ��������� � ������� S.
for t = 1:T
    state(:,t) = tfp_n(1,t)+2*(cap_n(1,t)-1)+2*n_K*(emp_n(:,t)-1)+4*n_K*(assets_n(:,t)-1); %current state of agents; ��� ������� �� ����� ��������;
    %����� �� ������, ����� ���������� �� ������� ���������� ��������� S (��� ���� �� �����). ������ � ���������� ����������: ���� � �������� ������
    %����� ���������� m, �� ��� ����� ���������� � ������� S ������ m-1 ������, ������� ������������ ������� ���������� �� 1 �� (m-1). � ������ ����� ����� 
    %4*n_K �������, ������������� ����� ��������� ����� ������������� �� ��� �����. ����� 3� ���������: �� ��� ��������� � ������ ��� ����� �� �����������,
    %���������� ������� � ���� �� ���� ������ �� �����. ������ ��������� - ��������� � ������ ���� �� ��������. ������ ��������� - ���������� ������������� 
    %�����, � ����������� �� ����, ����� ������� ������������������ ������ � ���������.
    assets_n(:,t+1) = I(state(:,t)); %evolution of agents' wealth; ������, ���� ����� ���������, � ������� ��������� ������ �� �������, �� ����� ���������
    %����������� ������� ���������� �������� �������. I(state(:,t)) ��� ���� ������ ������� ����������� M � �������� ����������� ���������� �������� �������.
    capital = mean(a(assets_n(:,t+1))); %������� ������� �������� �������. ��� ����� ��� ���� ������� ��� � �������� ��������� ���������� �������� �������.
    %a(assets_n(:,t+1)) ��������� ��� �������� ������ �������� ���������� �������� �������. ������� �������.
    [~, cap_n(1,t+1)] = min(abs(capital-K')); %number of future K; �������, ������� �� �������� �� ���������� ����, �� ������� ��������� � ����� ���� ���������
    %�� ����� ������� ��� ��������. ������� ���� ����� ��������� �������� ��������, ������� ���� �� ����� �������.
    
    %����� ��� ����� ������ ����� ��������� ������������������ � ���������.
    %� ������������������ ������� - ��� ����� ��� ���� �������.
    %��� ����� ����� ������� �� ��������� ������� �� �������:
    %���������� �� ����, ��� ����������� x, ������� ������������� f(x) ����� ����������� ������������� �� ������� [0;1] (���� ��������� ��� �� ����� �� ������, �������).
    x = rand(1,1); %evolution of TFP number; ����� ��������� ����� �� 0 �� 1.
    if x < P_A(tfp_n(1,t),tfp_n(1,t)) %���� x<����������� �������� � ��� �� ���������, �� �������� � ��� �� ���������
        tfp_n(1,t+1) = tfp_n(1,t);
    else 
        tfp_n(1,t+1) = 3-tfp_n(1,t);
    end
    
    %��� ����� ��������� - �� ������������ ��� ������� ������.
    x = rand(M,1); %evolution of h number; ����� ��������� ������ �� ���������� �� 0 �� 1.
    ind = find(P_h(emp_n(:,t),1) > x); %� ������ ������� ������� P_h ����������� ����������� ����, ��� �� � ����� �������� � h_������. �������������,
    %������ � ������� emp_n(:,t), ��� ������� ��� ����������� ������ x �������� � ����� � ��������� h_������. ���������� ��� ������ � ���������� ind.
    %����� ���� ������ �������� 2, � ����� ������ ��� �������� ind �������� �� 1.
    emp_n(:,t+1) = 2;
    emp_n(ind,t+1) = 1;  
end


%%%%%%%%%%%
%%% OLS %%%
%%%%%%%%%%%
t = T/10; %�.�. �� �������� ��������� �� ��������� �����, ����� ���������� ������ ��������� ���������. ��� ����� �������� �������.
b_old = b_ols; %���������� ������� �������� ������������� ���������, ����� ����� ����������� �������� �� � ������.
cap = K(cap_n)'; %capital history; �������� ������ �� ��������� �������� �� ���� �������� ���������
Y = log(cap(1,t+1:T+1))'; %log(K')
%��������� ��������� � �������� ��� �������� ��������������� �������� (� ����� ������ ����).
X(:,1) = 2-tfp_n(1,t:T); %������ ����������, ����� 1, ���� A=A_������
X(:,2) = X(:,1).*log(cap(1,t:T))'; %�� �� �����, ��� ������, ���������� �� ���(�������).
X(:,3) = tfp_n(1,t:T)-1; %����� 1, ���� A=A_�������
X(:,4) = X(:,3).*log(cap(1,t:T))';
Y_hat = X*b_ols; %��������� ��������� �� ������ ��������������
R_2 = corr(Y,Y_hat) %������������ R^2
b_ols = (X'*X)\(X'*Y) %�������� ����� ������������
b_ols = 1/2*b_ols+1/2*b_old; %����� � �������� ����� ������������� ����� ������� ����� ������ � �������, ��� ���������� ����� �����.
end %���� �� ���� ��������. ����� ���� �������� �������� R^2. ���� ��� ��� ��� ����, �� ������ ����� �������� � ������ �������������� b_ols. 


%%%%%%%%%%%%%%%
%%% FIGURES %%%
%%%%%%%%%%%%%%%
plot((t:T),Y,(t:T),Y_hat)
legend('Actual capital','Expected capital')

plot((900:1000),cap(900:1000),(900:1000),tfp_n(900:1000))
legend('Capital','TFP')
toc