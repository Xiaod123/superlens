! fieldmap.f90
! Written: 22/01/2012
! By: Alex mcMurray and Alun Daley
! Takes equations derived from EM boundary conditions
! for double interface and uses them to plot field map of Ey
! over x and z.
program fieldmap
implicit none !doesn't assume types from names, must be declared explicitly

! Declare stuff here
double precision :: x = 0.0, z = 0.0, thetai, eta, xstepfrac, zstepfrac, kxstepfrac
double precision :: xi, zi, c=300000000, xf, zf, Eyout, PI, Eyout2, eps1, mu1, mu2, g, co1,co2
complex*16 :: Ey, Ie, Re, Ce, De, Te, kx, kz1, kz2, A, B, C2, D2, F, G2, H, I2, J, K, i, n1, n2, test, kc, eps2
integer*4 :: m, n, p, xsize, zsize !, SIZE
character :: filename*80
double precision, dimension(:), allocatable :: xarray
double precision, dimension(:), allocatable :: zarray
complex*16, dimension(0:200) :: kxarray
complex*16, dimension(:,:,:), allocatable :: Eyarray
complex*16, dimension(:,:), allocatable :: fieldtransformed

zi=-5
xi=-5
zf=5
xf=5
zstepfrac=0.05
xstepfrac=0.05

xsize = int(((xf-xi)/xstepfrac)) + 1
zsize = int(((zf-zi)/zstepfrac)) + 1

allocate(xarray(0:xsize))
allocate(zarray(0:zsize))
allocate(Eyarray(0:xsize,0:zsize,0:201))
allocate(fieldtransformed(0:xsize,0:zsize))

PI=4.D0*DATAN(1.D0) ! ensures maximum precision on any architechture apparently
i = (0.0,1.0)
!CSIN is complex?? etc.
!Can just use normal functions as modern fortran can determine the type required, 
!specialist csqrt etc. are obsolete

eta = 3 !go from 0.1 to 5, dimensionless parameter equal to d/lambda
! where d is the thickness of the slab and lambda is the free space wavelength of the incident light
! w and d and lambda are all replaced by eta

eps1=1
mu1=1
eps2=(2.0,0)
mu2=1


g = 0.5

n1=SQRT(eps1*mu1)
n2=SQRT(eps2*mu2)

if (RealPart(n2) < 0) then
	n2 = -1 * n2
end if
!print *, n2

!Ey=(0,0); I=(0,0); R=(0,0); C=(0,0); D=(0,0); T=(0,0); kx=(0,0); kz=(0,0)

!open(unit=2,file='fieldmap.dat') !makes output file, in unit 1

!m and n are dimensionless integers defined as integer steps of a fraction of d

!might want to use arrays as that will make it easier to keep track of values
!real, dimension(0:9) :: examplearray to make array from 0 index not 1.

!initial values of x and z
!x and z are now parametised forms equivalent to normal x and z divided by lambda

kc = (n1*(2*PI*eta)*SIN(PI/4)) !normally SIN(pi/4)
print *, 'kc=', kc 
kxstepfrac = (n1*(2*PI*eta)*SIN(PI/2))/100.0


do p=0, xsize
	xarray(p)= xi + p*xstepfrac
end do

do p=0, zsize
	zarray(p)= zi + p*zstepfrac
end do
do p=0, 200
	kxarray(p)= -(n1*(2*PI*eta)*SIN(PI/2)) + p*kxstepfrac !used to be 0+ 
	!print *, kxarray(p)
end do







print *, "shape=", shape(Eyarray)


!SIZE= (((zf-zi)/zstepfrac)*((xf-xi)/xstepfrac))
!double precision, dimension(0:SIZE) :: xarray, yarray, Eyarray

do p=1, 200
	!thetai = p*(PI/12.0)
	!kx=n1*(2*PI*eta)*SIN(thetai)
	if (mod(p,10)==0) then
	 print *, p
	end if
	!kx is now a parametised kx where w/c is replaced by 2*PI*eta, 
	!therefore is multiplied by factor of d over normal kx

	kz2 = SQRT((n2*(2*PI*eta))**2 - kxarray(p)**2)
	kz1 = SQRT((n1*(2*PI*eta))**2 - kxarray(p)**2)
	!print *, "kvals:", kz2, kz1
	kx=kxarray(p)
	


	! Remove d term from exponential arguments because this is factored into new parametised k
	! replace c/w with 1/(2*PI*eta)
	A = EXP(i*kz2); B=EXP(-i*kz2); C2=EXP(i*kz1); D2=(-1*kz1)/(2*PI*eta*mu1); F=(1*kz1)/(2*PI*eta*mu1)
	G2 = (-1*kz2)/(2*PI*eta*mu2); H = (1*kz2)/(2*PI*eta*mu2); I2=(-1*kz2*EXP(i*kz2))/(2*PI*eta*mu2)
	J = (1*kz2*EXP(-i*kz2))/(2*PI*eta*mu2)
	K=(-1*kz1*EXP(i*kz1))/(2*PI*eta*mu1)
	
	print *, "vals1:", A, B, C2, D2, F, G2, H, I2, J, K
	test = (2*PI*eta*mu1)
	
	Ie = (1.0,0.0)
	De = ((D2-F)*(C2*I2 - A*K))/((H-F)*(A*K - C2*I2) + (G2-F)*(K*B - C2*J) )
	Te = ((D2-F)*(I2*B - J*A))/((H-F)*(A*K - C2*I2) + (G2-F)*(K*B - C2*J) )
	Ce = ((D2-F)*(K*B - J*C2))/((H-F)*(A*K - C2*I2) + (G2-F)*(K*B - C2*J) )
	Re = Ce + De - 1.0

	!print *,"vals2:", De, Te, Ce, Re


	write(filename,20) eta,'eta', g,'g', RealPart(eps2), 'eps2gaussdielecfieldmap.dat'
	
	open(unit=2,file= filename)
	

	do m=0, zsize-1
		z= zarray(m) !define z in terms of m and d
		!primes are dimensionless parameters
		do n=0, xsize-1
			!define x and z in their loops so they update each time
			!define x in terms of m and d
			!divide exponential terms by eta in order to compensate for parametisation
			x = xarray(n)
			if (z<=0) then 
				Eyarray(n,m,p) = Ie*EXP((i*kx*x)/eta)*EXP((i*kz1*z)/eta) + Re*EXP((i*kx*x)/eta)*EXP((-i*kz1*z)/eta)
				!print *, "EY: ", Ey
			else if((z>float(0)) .and. (z<eta)) then
				Eyarray(n,m,p) = Ce*EXP((i*kx*x)/eta)*EXP((i*kz2*z)/eta) + De*EXP((i*kx*x)/eta)*EXP((-i*kz2*z)/eta)
			else
				Eyarray(n,m,p) = Te*EXP((i*kx*x)/eta)*EXP((i*kz1*z)/eta)
			end if

			!define x and z and Ey arrays here, and fill them.
			!xarray(n+ (m*((5-xi)/xstepfrac))) = x
			!zarray(n+ (m*((5-xi)/xstepfrac))) = z
			!Eyarray(n+ (m*((5-xi)/xstepfrac))) = Ey
			!Eyout = abs(Ey)
			!Eyout2=RealPart(Ey)
			!write(2,10) x, z, Eyout, Eyout2


		end do
			
	end do

end do


do n=0, xsize
	do m=0, zsize
		fieldtransformed(n,m) = 0
	end do
end do


co1=(g/(2*sqrt(PI)))
co2=-0.25*(g**2)
do m=0, zsize
	if (mod(m,100)==0) then 
		print *, m
	end if
	do n=0, xsize
		do p=1, 200-1

			fieldtransformed(n,m)=fieldtransformed(n,m)+ &
			Eyarray(n,m,p)*co1*EXP(co2*((kxarray(p) - kc)**2) + i*kxarray(p)*xarray(n)/eta)*kxstepfrac
			!print *, Eyarray(n,m,p), n , m, p
			!print *, "Eyarray, n=",n,"m=",m,"p=",p,"val=",Eyarray(n,m,p)
			!print *, "fieldtransformed, n=",n,"m=",m,"val=",fieldtransformed(n,m)
		end do		
	end do
end do

!work out how to export to matlab and plot

do m=0, zsize
	if (mod(m,100)==0) then 
		print *, m
	end if
	do n=0, xsize
		!print *, "realfieldtransformed, n=",n,"m=",m,"val=",RealPart(fieldtransformed(n,m))
		write(2,10) xarray(n), zarray(m), abs(fieldtransformed(n,m)), RealPart(fieldtransformed(n,m))
	end do
end do
10	format(4e15.5,4e15.5,4e15.5,4e15.5)
20 	format(f3.1,A,f3.1,A,f4.1,A)

end program fieldmap