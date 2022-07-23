function [L,B,R]=ple_mars(Date)
% Low-accuracy planetray ephemeris for Mars
% Package: celestial.SolarSys
% Description: Low accuracy planetray ephemeris for Mars. Calculate
%              Mars heliocentric longitude latitude and radius vector
%              referred to mean ecliptic and equinox of date.
%              Accuarcy: Better than 1' in long/lat, ~0.001 au in dist.
% Input  : - matrix of dates, [D M Y frac_day] per line,
%            or JD per line. In TT time scale.
% Output : - Longitude in radians.
%          - Latitude in radians.
%          - Radius vector in au.
% Reference: VSOP87
% See also: ple_planet.m
% Tested : Matlab 5.3
%     By : Eran O. Ofek                    Oct 2001
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: [L,B,R]=celestial.SolarSys.ple_mars(2451545)
% Reliable: 2
%------------------------------------------------------------------------------


RAD = 180./pi;

FunTPI = @(X) (X./(2.*pi) - floor(X./(2.*pi))).*2.*pi;

SizeDate = size(Date);
N        = SizeDate(1);
ColN     = SizeDate(2);

if (ColN==4),
   JD = celestial.time.julday(Date);
elseif (ColN==1),
   JD = Date;
else
   error('Illigal number of columns in date matrix');
end

Tau = (JD(:) - 2451545.0)./365250.0;

SumL0 = 620347712 ...
   + 18656368.*cos(5.05037100 + 3340.61242670.*Tau) ...
   + 1108217.*cos(5.4009984 + 6681.2248534.*Tau) ...
   + 91798.*cos(5.75479 + 10021.83728.*Tau) ...
   + 27745.*cos(5.97050 + 3.52312.*Tau) ...
   + 12316.*cos(0.84956 + 2810.92146.*Tau) ...
   + 10610.*cos(2.93959 + 2281.23050.*Tau) ...
   + 8927.*cos(4.1570 + 0.0173.*Tau) ...
   + 8716.*cos(6.1101 + 13362.4497.*Tau) ...
   + 7775.*cos(3.3397 + 5621.8429.*Tau) ...
   + 6798.*cos(0.3646 + 398.1490.*Tau) ...
   + 4161.*cos(0.2281 + 2942.4634.*Tau) ...
   + 3575.*cos(1.6619 + 2544.3144.*Tau) ...
   + 3075.*cos(0.8570 + 191.4483.*Tau) ...
   + 2938.*cos(6.0789 + 0.0673.*Tau) ...
   + 2628.*cos(0.6481 + 3337.0893.*Tau) ...
   + 2580.*cos(0.0300 + 3344.1355.*Tau) ...
   + 2389.*cos(5.0390 + 796.2980.*Tau) ...
   + 1799.*cos(0.6563 + 529.6910.*Tau) ...
   + 1546.*cos(2.9158 + 1751.5395.*Tau) ...
   + 1528.*cos(1.1498 + 6151.5339.*Tau) ...
   + 1286.*cos(3.0680 + 2146.1654.*Tau) ...
   + 1264.*cos(3.6228 + 5092.1520.*Tau) ...
   + 1025.*cos(3.6933 + 8962.4553.*Tau);

SumL1 = 334085627474 ...
   + 1458227.*cos(3.6042605 + 3340.6124267.*Tau) ...
   + 164901.*cos(3.926313 + 6681.224853.*Tau) ...
   + 19963.*cos(4.26594 + 10021.83728.*Tau) ...
   + 3452.*cos(4.7321 + 3.5231.*Tau) ...
   + 2485.*cos(4.6128 + 13362.497.*Tau) ...
   + 842.*cos(4.459 + 2281.230.*Tau);

SumL2 = 58016.*cos(2.04979 + 3340.61243.*Tau) ...
   + 54188 ...
   + 13908.*cos(2.45742 + 6681.22485.*Tau) ...
   + 2465.*cos(2.8000 + 10021.8373.*Tau) ...
   + 398.*cos(3.141 + 13362.450.*Tau);

SumL3 = 1482.*cos(0.4443 + 3340.6124.*Tau) ...
   + 662.*cos(0.885 + 6681.225.*Tau);

SumL4 = -114;

SumL5 = -1;


L = SumL0 + SumL1.*Tau + SumL2.*Tau.^2 ...
          + SumL3.*Tau.^3 + SumL4.*Tau.^4 + SumL5.*Tau.^5;
L = L.*1e-8;

L = FunTPI(L);

SumB0 = 3197135.*cos(3.7683204 + 3340.6124267.*Tau) ...
   + 298033.*cos(4.106170 + 6681.224853.*Tau) ...
   + 289105 ...
   + 31366.*cos(4.44651 + 10021.83728.*Tau) ...
   + 3484.*cos(4.7881 + 13362.4497.*Tau);

SumB1 = 350069.*cos(5.368478 + 3340.612427.*Tau) ...
   - 14116 ...
   + 9671.*cos(5.4788 + 6681.2249.*Tau) ...
   + 1472.*cos(3.2021 + 10021.8373.*Tau);

SumB2 = 16727.*cos(0.60221 + 3340.61243.*Tau) ...
   - 4987 ...
   + 302.*cos(3.559 + 6681.225.*Tau);

SumB3 = 607.*cos(1.981 + 3340.612.*Tau) ...
   + 43;

SumB4 = 13 ...
   + 11.*cos(3.46 + 3340.61.*Tau);

B = SumB0 + SumB1.*Tau + SumB2.*Tau.^2 ...
          + SumB3.*Tau.^3 + SumB4.*Tau.^4;
B = B.*1e-8;

%B = FunTPI(B);

SumR0 = 153033488 ...
   + 14184953.*cos(3.47971284 + 3340.61242670.*Tau) ...
   + 660776.*cos(3.817834 + 6681.224853.*Tau) ...
   + 46179.*cos(4.15595 + 10021.83728.*Tau) ...
   + 8110.*cos(5.5596 + 2810.9215.*Tau) ...
   + 7485.*cos(1.7724 + 5621.8429.*Tau) ...
   + 5523.*cos(1.3644 + 2281.2305.*Tau) ...
   + 3825.*cos(4.4941 + 13362.4497.*Tau) ...
   + 2484.*cos(4.9255 + 2942.4634.*Tau) ...
   + 2307.*cos(0.0908 + 2544.3144.*Tau) ...
   + 1999.*cos(5.3606 + 3337.0893.*Tau) ...
   + 1960.*cos(4.7425 + 3344.1355.*Tau);

SumR1 = 1107433.*cos(2.0325052 + 3340.6124267.*Tau) ...
   + 103176.*cos(2.370718 + 6681.224853.*Tau) ...
   + 12877 ...
   + 10816.*cos(2.70888 + 10021.83728.*Tau) ...
   + 1195.*cos(3.0470 + 13362.4497.*Tau);

SumR2 = 44242.*cos(0.47931 + 3340.61243.*Tau) ...
   + 8138.*cos(0.8700 + 6681.2249.*Tau) ...
   + 1275.*cos(1.2259 + 10021.8373.*Tau);

SumR3 = 1113.*cos(5.1499 + 3340.6124.*Tau) ...
   + 424.*cos(5.613 + 6681.225.*Tau);

R = SumR0 + SumR1.*Tau + SumR2.*Tau.^2 ...
          + SumR3.*Tau.^3;
R = R.*1e-8;
