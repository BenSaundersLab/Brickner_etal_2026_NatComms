% Sonal Sinha 08/26/2020
%%
function d = Distance(A,B)
    change_x = A(1,1) - B(1,1);
    change_y = A(1,2) - B(1,2);
    distance_1 = power(change_x,2) + power(change_y,2);
    d = power(distance_1,0.5);
end