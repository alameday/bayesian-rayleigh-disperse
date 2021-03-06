function main()
% Execute UKF From example data generated by mat_disperse_v2

%% INITIALIZE PATH
initialize_path();

%% PARAMETERS TO BE IDENTIFIED AND PROCESS NOISE COVARIANCE (Q)
% thk = [5.0 10.0 10.0]';
% dns = [1.7 1.8 1.8 1.8]';
% vs = [200 300 400 500]';
% vp = [400 600 800 1000]';
params = {'thk1', 'thk2', 'thk3', 'dns1', 'dns2', 'dns3', 'dns4', 'vs1', 'vs2', 'vs3', 'vs4', 'vp1', 'vp2', 'vp3', 'vp4'}; % Material parameters to be estimated (nx1)
exact_p = [5.0, 10.0, 10.0, 1.7, 1.8, 1.8, 1.8, 200, 300, 400, 500, 400, 600, 800, 1000]; % Exact parameters (nx1)
cov_q = [1e-6 * ones(1, length(params))]; % Normalized coefficient of variation of process noise (N_q x n)

%% INITIALIZATION OF THE FILTER
x_ini=1.4*ones(length(params),1)'.*exact_p; % Initial state (N_x x n) (e.g. [0.9*60,0.9*29000,0.9*0.01,0.9*18; 0.8*60,0.8*29000,0.9*0.01,0.8*18]
cov=0.1*ones(1,length(params)); % Coefficient of variation (N_x x n) (e.g. [0.3,0.3,0.3,0.3; 0.15,0.15,0.15,0.15]; 
x_ini=bsxfun(@rdivide,x_ini,exact_p); % Normalize the initial state

%% UKF ALGORITHM
alpha=0.01;
kappa=0;
beta=2;

%% LENGTHS OF VARIABLES
n=length(params);
N_x_ini=size(x_ini,1); % Number of different initial parameter estimates
N_cov_ini=size(cov,1); % Number of different initial parameter covariance

%% FREQUENCY SET
freq = linspace(5, 150, 20)';
nfreq = length(freq);

%% FIXED VARIABLES
% Process equation
f=@(x)[eye(n)*x];

%% SIMULATED DATA (without noise)
y=mat_disperse(exact_p(1:3)', exact_p(4:7)', exact_p(12:15)', exact_p(8:11)', freq);

for c_x_ini=1:N_x_ini
    for c_cov_ini=1:N_cov_ini
        %% UKF ALGORITHM
        x_initial=x_ini(c_x_ini,:)';    % To be saved (normalized)
        x=x_initial;
        P_initial=diag(cov(c_cov_ini,:).^2);           % Normalized initial state covariance (P0)
        P=P_initial;
        % Initial estimate of response
        y_initial=mat_disperse(x_initial'.*exact_p(1:3)', x_initial'.*exact_p(4:7)', x_initial'.*exact_p(12:15)', x_initial'.*exact_p(8:11)', freq);
   
        % TO RUN MANUAL: xhat_k_1=x; Pk_1=P; yk=YY; rhat_k_1=r; Pk_1_rr=Pr;
        [x,P,yhat_k,r,Pr]=dukf_fem_normalized(iGMfile,iGMdirection,iGMfact,f,x,P,YY,Q,r,Pr,U,T,alpha,kappa,beta,min_lim,max_lim,new_sp,kk,workdir,col_output,exact_p,Fs,NstepG,adaptive,cumulative,step_update(c_steps));
        % x=xhat_k; P=Pk ; r=rhat_k; Pr=Pk_rr;
        display(['Progress: ',num2str(kk/N_max_update*100),'%']);
          % Save variables
          x_est(:,kk) = x;                     % Posterior state estimate
          P_est(:,:,kk) = P;                   % Posterior state covariance
          if strcmp(cumulative,'yes')
            y_est(:,kk)=yhat_k;
          else
            y_est(1:m,kk)=yhat_k;
            Pr_est(:,:,kk)=Pr;
            r_est(:,kk)=r;
          end
          x
        end
        toc;
        % Final estimate of response
        x_final=x; % modify if another criteria (not last estimate) is assumed
        [y_final]=motion(iGMfile,iGMdirection,iGMfact,N,x_final'.*exact_p,outputs,col_output,Fs,'Final',NstepG);


% Added some noise to data
sigma = 0.02 + zeros(nfreq, 1);
err = sigma .* randn(nfreq, 1);
vr_exp = vr + err;

% Invertion parameters
maxiter = 10;
mu = 10;
tol_vs = 0.01;

% New guess (initial solution) is defined to inverse
lng = length(dns);
thk1 = thk;
dns1 = ones(lng, 1) .* mean(dns);
vs1 = ones(lng, 1) .* mean(vs);
vp1 = ones(lng, 1) .* mean(vp);

% Inversion mat_disperse(thk, dns, vp, vs, freq);
[niter, vr_iter, vp_iter, vs_iter, dns_iter] = mat_inverse(freq, vr_exp, sigma, thk1, vp1, vs1, dns1, maxiter, mu, tol_vs);


end