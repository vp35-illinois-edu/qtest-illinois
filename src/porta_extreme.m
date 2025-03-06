function V=porta_extreme(A,B,valid)
%PORTA_EXTREME converts inequalities into vertices
%   V = porta_extreme(A,B)
%
%   A is a matrix and B is a column vector, specifying the inequality
%   constraints in the form of AX <= B.
%
% Optionally:
%   V = porta_extreme(A,B,VALID)
%
%   where VALID is a feasible point that satisfies the system.
%
% Outputs:
%
%   V is a matrix where each row contains an extreme point of the convex
%   polytope. 
%
% Caution:
%   
%   The output is undefined if the system is unbounded (e.g. a cone)

if size(A,1)<1 || size(A,2)<1 || size(A,1)~=size(B,1) || size(B,2)~=1
    error('Matrix size mismatch!');
end

if nargin<3
    if isfield(optimset,'LargeScale') && isfield(optimset,'Simplex')
        options_lin=optimset('LargeScale','off','Simplex','off','Display','off');
    else
        options_lin=optimoptions('linprog','Algorithm','dual-simplex','Display','off');
    end
    [valid,lambda,exitflag,output]=linprog(ones(1,size(A,2)),A,B,[],[], ...
        [],[],options_lin);
    if exitflag<=0
        %error('Cannot find a feasible point!');
        V=[];
        return;
    end
%     %use another corner
%     [valid2,~,~,~]=linprog(-ones(1,size(A,2)),A,B,[],[], ...
%         [],[],options_lin);
%     valid=0.5*(valid+valid2)';
    valid=valid';
else
    if size(valid,1)~=1 || size(valid,2)~=size(A,2)
        valid=valid';
        if size(valid,1)~=1 || size(valid,2)~=size(A,2)
            error('The given VALID point has wrong dimension!');
        end
    end
    if sum(A*valid'<=B)<size(A,1)
        error('The given VALID point is not feasible!');
    end
end

tol=1e-6;
[Anum,Aden]=rat(A,tol);
[Bnum,Bden]=rat(B,tol);
[Vnum,Vden]=rat(valid,tol);
valid_sum=valid;
valid_count=1;
while sum((Anum./Aden)*(Vnum./Vden)'>(Bnum./Bden))>0
    if valid_count>=100
        error('porta_extreme: cannot find a valid interior point, need better precision');
    end
    [newvalid,~,~,~]=linprog(2*rand(1,size(A,2))-1,Anum./Aden,Bnum./Bden,[],[], ...
        [],[],options_lin);
    valid_sum=valid_sum+newvalid';
    valid_count=valid_count+1;
    valid=valid_sum/valid_count;
    [Vnum,Vden]=rat(valid,tol);
end

if ismac && strcmp(computer('arch'), 'maca64')
    method = 'cddgmpmex_combined';
else
    method = 'porta';
end

disp("H to V conversion - start using method " + method)

switch method
    case 'cddmex'
        H = struct('A', A, 'B', B);
        Hreduced = cddmex('reduce_h', H);
        Vout = cddmex('extreme', Hreduced);
        Vreduced = cddmex('reduce_v', Vout);
        V = Vreduced.V;

    case 'cddgmpmex'
        H = struct('ANum', Anum, 'ADen', Aden, 'A', A, 'B', B, 'BNum', Bnum, 'BDen', Bden);
        % Hreduced = cddgmpmex('reduce_h', H);
        Hreduced  = H;
        Vout = cddgmpmex('extreme', Hreduced);
        % Vreduced = cddgmpmex('reduce_v', Vout);
        Vreduced = Vout;
        V = Vreduced.V;

    case 'cddgmpmex_combined'
        H = struct('ANum', Anum, 'ADen', Aden, 'A', A, 'B', B, 'BNum', Bnum, 'BDen', Bden);
        Vout = cddgmpmex('reduce_all_extreme', H);
        V = Vout.V;

    case 'porta'
        clear portavmex
        V=portavmex(Anum,Aden,Bnum,Bden,Vnum,Vden);

    otherwise
        error('Unknown method specified');
end

if strcmp(method, 'porta') == 0
    % Convert -0 to 0 to avoid potential issues with negative zero representation
    V(V == 0) = 0;
end

disp("H to V conversion - done using method " + method)
