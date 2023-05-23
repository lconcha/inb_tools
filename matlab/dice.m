function DSC = dice(A,B)
% Dice similarity coefficient
% DSC = dice(A,B)

% Luis Concha
% INB, UNAM, 2011


A = logical(A);
B = logical(B);


I = A & B;
I = sum(I(:));
n = sum(A(:)>0) + sum(B(:)>0);




DSC = (2 .* I) ./ n;
