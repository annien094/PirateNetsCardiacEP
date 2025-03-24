% function [Vsav,Wsav]=AlievPanfilov1D_RK_Istim(BCL,ncyc,extra,ncells,iscyclic,flagmovie)
% (Ventricular) Aliev-Panfilov model in single-cell with the parameters
% from Goektepe et al, 2010
% Marta, 18/03/2021

% BCL in AU: basic cycle length: time between repeated stimuli (e.g. 30)
% ncyc: number of cycles, number of times the cell is stimulated (e.g. 10)
% extra in AU: time after BCL*ncyc during which the simulation runs (e.g.
% 0)
% ncells is number of cells in 1D cable (e.g. 200)
% iscyclic, = 0 for a cable, = 1 for a ring (connecting the ends of the
% cable - the boundary conditions are not set for the ring yet!)
% flagmovie, = 0 to show a movie of the potential propagating, = 0
% otherwise

% Aliev-Panfilov model parameters 
% V is the electrical potential difference across the cell membrane in 
% arbitrary units (AU)
% t is the time in AU - to scale do tms = t *12.9

% close all
% clear all
BCL=100;
ncyc=1;
extra=0;
ncells=100;
iscyclic=0;
flagmovie=0;
h=0.1;

% one of the biggest determinants of the propagation speed
% (D should lead to realistic conduction velocities, i.e.
% between 0.6 and 0.9 m/s)
X = ncells + 2; % to allow boundary conditions implementation
stimgeo=false(ncells+2,1);
stimgeo(1:5)=true; % indices of cells where external stimulus is felt

% Model parameters
dt=0.005; % AU, time step for finite differences solver
gathert=round(1/dt); % number of iterations at which V is outputted
% for plotting, set to correspond to 1 ms, regardless of dt
tend=BCL*ncyc+extra; % ms, duration of simulation
stimdur=1; % UA, duration of stimulus
Ia=0.1*stimgeo; % AU, value for Istim when cell is stimulated

V(1,1:X)=0.01; % initial V
W(1,1:X)=0.01; % initial W

Vsav=zeros(ceil(tend/gathert),ncells); % array where V will be saved during simulation
Wsav=zeros(ceil(tend/gathert),ncells); % array where W will be saved during simulation

ind=0; %iterations counter
kk=0; %counter for number of stimuli applied

y=[V;W]';
% for loop for explicit RK4 finite differences simulation
for t=dt:dt:tend % for every timestep
    ind=ind+1; % count interations
        % stimulate at every BCL time interval for ncyc times
        if t>=BCL*kk&&kk<ncyc
            Istim=Ia; % stimulating current
        end
        % stop stimulating after stimdur
        if t>=BCL*kk+stimdur*2
            kk=kk+1;
            Istim=zeros(ncells+2,1); % stimulating current
        end
        
        y=[V;W]';
        k1=AlPan(y,Istim);
        k2=AlPan(y+dt/2.*k1,Istim);
        k3=AlPan(y+dt/2.*k2,Istim);
        k4=AlPan(y+dt.*k3,Istim);
        y=y+dt/6.*(k1+2*k2+2*k3+k4);
        V=y(:,1)';
        W=y(:,2)';
                      
        % rectangular boundary conditions: no flux of V
        if  ~iscyclic % 1D cable
            V(1)=V(2);
            V(end)=V(end-1);
        else % ring
            % set up later - need to amend derivatives calculation too
        end
        
        % At every gathert iterations, save V value for plotting
        if mod(ind,gathert)==0
            % save values
            Vsav(round(ind/gathert),:)=V(2:end-1)';
            Wsav(round(ind/gathert),:)=W(2:end-1)';
            % show (thicker) cable
            if flagmovie
                subplot(2,1,1)
                imagesc(repmat(V(2:end-1),[round(ncells/20) 1]),[0 1])
                axis image
                title([])
                set(gca,'FontSize',14)
                yticks(0)
                xlabel('x (voxels)')
                set(gca,'FontSize',14)
                title(['V (AU) - Time: ' num2str(t,'%.0f') ' ms'])
                colorbar
                
                subplot(2,1,2)
                imagesc(repmat(W(2:end-1),[round(ncells/20) 1]),[0 1])
                axis image
                title(['Time: ' num2str(t,'%.0f') ' AU'])
                set(gca,'FontSize',14)
                yticks(0)
                xlabel('x (voxels)')
                set(gca,'FontSize',14)
                title('W (AU)')
                colorbar
                pause(0.01)
            end
        end
end
close all

figure
subplot(2,1,1)
title('V (AU)')
imagesc(Vsav',[0 1])
ylabel('Time (AU)')
xlabel('V (AU)')
colorbar
set(gca,'FontSize',14)

subplot(2,1,2)
title('W (AU)')
imagesc(Wsav',[0 1])
ylabel('Time (AU)')
xlabel('W (AU)')
colorbar
set(gca,'FontSize',14)

V = Vsav(1:end,:,:);
W = Wsav(1:end,:,:);
t = 1:1:length(V);
x = h:h:h*ncells;
y = h:h:h*ncells;
save('1DAPplanar_2003.mat','t','x',"V",'W')

function dydt = AlPan(y,Istim)
    a = 0.01;
    k = 8.0;
    mu1 = 0.2;
    mu2 = 0.3;
    epsi = 0.002;
    b  = 0.15;
    h = 0.1; % mm cell length
    D = 0.1; % mm^2/UA, diffusion coefficient (for monodomain equation)
    
    V=y(:,1)';
    W=y(:,2)';
    dV=4*D.*del2(V,h);
    dWdt=(epsi + mu1.*W./(mu2+V)).*(-W-k.*V.*(V-b-1));
    dVdt=(-k.*V.*(V-a).*(V-1)-W.*V)+dV+Istim';
    dydt=[dVdt; dWdt]';
end
% end