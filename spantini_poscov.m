function [Gpos, del2,info] = spantini_poscov(LH,L_pr,r_vals,method)

if nargin == 3
    method = 'svd';
end

switch method
    case 'svd'
        Gamma_pr = L_pr*L_pr';
        H = LH*LH';
    case 'eig'
        Gamma_pr = L_pr;
        H = LH;
end

d = size(H,1);
Gpos = zeros(d,d,length(r_vals)+1);

% true posterior cov
prec = inv(Gamma_pr);
Gpos(:,:,end) = inv(H + prec);

switch method
    case 'eig'
        % low rank GEV problem
        [V,D] = eig(H,prec);
        [~,a] = sort(diag(D),'descend');
        What = V(:,a);
        for i = 1:d     % normalize
            What(:,i) = What(:,i) / sqrt(What(:,i)'*prec*What(:,i));
        end
        del2 = diag(D(a,a));
    case 'svd'
        % low rank SVD calc
        [myV,myS,myW] = svd(LH'*L_pr);
        What = L_pr*myW;
        del2 = diag(myS).^2;
        info.V = myV;
        info.S = myS;
        info.W = myW;
end

% compute low-rank updates for all specified ranks in r_vals
for rr = 1:length(r_vals)
    r = r_vals(rr);
    KKT = What(:,1:r)*diag(del2(1:r)./(1+del2(1:r)))*What(:,1:r)';
    Gpos(:,:,rr) = Gamma_pr - KKT;
end
