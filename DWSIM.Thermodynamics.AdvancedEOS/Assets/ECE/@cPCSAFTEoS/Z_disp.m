function [Zdisp EoS] = Z_disp(EoS,T,dens_num,mix)
%Dispersive contribution to the compressibility coefficient with PC-SAFT EoS
%Auxiliary function, not to be used directly
%
%Reference: Gross and Sadowski, Ind. Eng. Chem. Res. 40 (2001) 1244-1260

%Copyright (c) 2011 �ngel Mart�n, University of Valladolid (Spain)
%This program is free software: you can redistribute it and/or modify
%it under the terms of the GNU General Public License as published by
%the Free Software Foundation, either version 3 of the License, or
%(at your option) any later version.
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%You should have received a copy of the GNU General Public License
%along with this program.  If not, see <http://www.gnu.org/licenses/>.

%Equation constants
a0(1) = 0.9105631445;
a0(2) = 0.6361281449;
a0(3) = 2.6861347891;
a0(4) = -26.547362491;
a0(5) = 97.759208784;
a0(6) = -159.59154087;
a0(7) = 91.297774084;
a1(1) = -0.3084016918;
a1(2) = 0.1860531159;
a1(3) = -2.5030047259;
a1(4) = 21.419793629;
a1(5) = -65.255885330;
a1(6) = 83.318680481;
a1(7) = -33.746922930;
a2(1) = -0.0906148351;
a2(2) = 0.4527842806;
a2(3) = 0.5962700728;
a2(4) = -1.7241829131;
a2(5) = -4.1302112531;
a2(6) = 13.776631870;
a2(7) = -8.6728470368;
b0(1) = 0.7240946941;
b0(2) = 2.2382791861;
b0(3) = -4.0025849485;
b0(4) = -21.003576815;
b0(5) = 26.855641363;
b0(6) = 206.55133841;
b0(7) = -355.60235612;
b1(1) = -0.5755498075;
b1(2) = 0.6995095521;
b1(3) = 3.8925673390;
b1(4) = -17.215471648;
b1(5) = 192.67226447;
b1(6) = -161.82646165;
b1(7) = -165.20769346;
b2(1) = 0.0976883116;
b2(2) = -0.2557574982;
b2(3) = -9.1558561530;
b2(4) = 20.642075974;
b2(5) = -38.804430052;
b2(6) = 93.626774077;
b2(7) = -29.666905585;

%Reads pure-component properties
numC = mix.numC;
x = mix.x;
k1 = mix.k1;
m = zeros(1,numC);
sigma = zeros(1,numC);
epsilon = zeros(1,numC);
for i = 1:numC
    m(i)= mix.comp(i).EoSParam(1);
    sigma(i) = mix.comp(i).EoSParam(2);
    epsilon(i) = mix.comp(i).EoSParam(3);
end

%Calculates the temperature-dependant segment diameter
d = zeros(1,numC);
for i = 1:numC
    d(i) = HardSphereDiameter(EoS,T,m(i),sigma(i),epsilon(i));
end

%mean segment number
m_prom = 0;
for i = 1:numC
    m_prom = m_prom + m(i)*x(i); %Eq. 6 of reference
end

%Calculates the a and b parameters
a = zeros(1,7);
b = zeros(1,7);
for j = 1:7
    a(j) = a0(j)+(m_prom-1)/m_prom*a1(j)+(m_prom-1)/m_prom*(m_prom-2)/m_prom*a2(j); %Eq. 18 of reference
    b(j) = b0(j)+(m_prom-1)/m_prom*b1(j)+(m_prom-1)/m_prom*(m_prom-2)/m_prom*b2(j); %Eq. 19 of reference
end

%Reduced density
dens_red = 0;
for i = 1:numC
    dens_red = dens_red + x(i)*m(i)*d(i)^3;
end
dens_red = dens_red*pi/6*dens_num; %Eq. 9 of reference

%**************************************************************************
%Mixing rules
%**************************************************************************
sigmaij = zeros(numC,numC);
epsilonij = zeros(numC,numC);
for i =1:numC
    for j = 1:numC
        sigmaij(i,j) = 0.5*(sigma(i) + sigma(j)); %Eq. A14 of reference
        epsilonij(i,j) = sqrt(epsilon(i)*epsilon(j)) * (1 - k1(i,j)); %Eq A15 of reference     	
    end
end
%**************************************************************************
%Zdisp
%**************************************************************************

dnuI1_dnu = 0;
dnuI2_dnu = 0;

for j = 1:7
    dnuI1_dnu = dnuI1_dnu + a(j)*(j)*dens_red^(j-1); %Eq. A29 of reference
    dnuI2_dnu = dnuI2_dnu + b(j)*(j)*dens_red^(j-1); %Eq. A30 of reference
end

term1 = (m_prom)*(8*dens_red-2*dens_red^2)/(1-dens_red)^4;
term2 = (1-m_prom)*(20*dens_red-27*dens_red^2+12*dens_red^3-2*dens_red^4)/((1-dens_red)*(2-dens_red))^2;
C1 = (1+term1 + term2)^-1; %Eq. A11 of reference

term1 = m_prom*(-4*dens_red^2+20*dens_red+8)/(1-dens_red)^5;
term2 = (1-m_prom)*(2*dens_red^3+12*dens_red^2-48*dens_red+40)/((1-dens_red)*(2-dens_red))^3;
C2 = -C1^2*(term1 + term2); %Eq. A31 of reference

prom1 = 0;
prom2 = 0;
for i = 1:numC
    for j = 1:numC
        prom1 = prom1 + x(i)*x(j)*m(i)*m(j)*epsilonij(i,j)/T*sigmaij(i,j)^3; %Eq. A12 of reference
        prom2 = prom2 + x(i)*x(j)*m(i)*m(j)*(epsilonij(i,j)/T)^2*sigmaij(i,j)^3; %Eq. A13 of reference
    end
end

I2 = 0;
for j = 1:7
    I2 = I2 + b(j)*dens_red^(j-1); %Eq. A17 of reference
end

term1 = -2*pi*dens_num*dnuI1_dnu*prom1;
term2 = -pi*dens_num*m_prom*(C1*dnuI2_dnu + C2*dens_red*I2)*prom2;

Zdisp = term1 + term2; %Eq. A28 of reference