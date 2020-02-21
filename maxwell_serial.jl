const c = 1.0 # speed of light 
const csq = c * c

include("mesh.jl")
include("fdtd.jl")

function main( nstep )

    cfl    = 0.2    # Courant-Friedrich-Levy
    tfinal = 1.	    # final time
    nstepmax = 500  # max steps
    md = 2	    # md : wave number x (initial condition)
    nd = 2	    # nd : wave number y (initial condition)
    nx = 1000	    # x number of points
    ny = 1000	    # y number of points
    dimx = 1.0	    # width
    dimy = 1.0	    # height

    dx = dimx / nx
    dy = dimy / ny

    mesh = Mesh( dimx, nx, dimy, ny)

    dx, dy = mesh.dx, mesh.dy
    
    dt = cfl / sqrt(1/dx^2+1/dy^2) / c
    
    nstep  = min( nstepmax, nstep)
    
    fields = MeshFields(mesh)
    
    omega = c * sqrt((md*pi/dimx)^2+(nd*pi/dimy)^2)

    # Ex and Ey are set at t = 0.0
    # Bz is set at  t = -dt/2

    for j=1:ny, i=1:nx
        fields.bz[i,j] = (- cos(md*pi*((i-0.5)*dx/dimx)) 
                          * cos(nd*pi*((j-0.5)*dy/dimy))
                          * cos(omega*(-0.5*dt)) )
    end  
    
    tag = 1111
    
    for istep = 1:nstep # Loop over time
    
       # Ex(n) [1:nx]*[1:ny+1] --> B(n+1/2) [1:nx]*[1:ny]
       # Ey(n) [1:nx+1]*[1:ny] --> B(n+1/2) [1:nx]*[1:ny]

       faraday!(fields, 1, nx, 1, ny, dt)   
    
       periodic_bc!(fields, 1, nx, 1, ny, dt)

       ampere_maxwell!(fields, 1, nx, 1, ny, dt) 
    
       err_l2 = 0.0
       time = (istep-0.5)*dt
       for j = 1:ny, i = 1:nx
           th_bz = (- cos(md*pi*((i-0.5)*dx/dimx))
                    * cos(nd*pi*((j-0.5)*dy/dimy))
                    * cos(omega*time))
           err_l2 += (fields.bz[i,j] - th_bz)^2
       end
    
       println(sqrt(err_l2))
    
    end # next time step
    
end

main( 1 ) # trigger building

@time main( 500 )