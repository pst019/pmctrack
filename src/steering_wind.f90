subroutine steering_wind_f(u, v, p,                                           &
  &                        nx, ny, nz, nt, mi, mj,                            &
  &                        u_vor, v_vor)

  use types, only : wp
  use params, only : n_steering_x, n_steering_y
  use utils, only : integral_p

  implicit none

  integer    , intent (in)  :: nx, ny, nz, nt
  real   (wp), intent (in)  :: u     (0:nx, 0:ny, nz, nt)
  real   (wp), intent (in)  :: v     (0:nx, 0:ny, nz, nt)
  real   (wp), intent (in)  :: p     (            nz    )
  integer    , intent (in)  :: mi
  integer    , intent (in)  :: mj
  real   (wp), intent (out) :: u_vor
  real   (wp), intent (out) :: v_vor
  ! Local variables
  real   (wp)               :: u_t0t1(0:nx, 0:ny, nz    )
  real   (wp)               :: v_t0t1(0:nx, 0:ny, nz    )
  real   (wp)               :: u_int (0:nx, 0:ny        )
  real   (wp)               :: v_int (0:nx, 0:ny        )
  integer                   :: ii, jj
  integer                   :: kt1, kt2
  integer                   :: n_steering_s


  kt1 = 1
  kt2 = nt ! should be 2

  u_t0t1 = 0.5 * (u(0:nx, 0:ny, 1:nz, kt1) + u(0:nx, 0:ny, 1:nz, kt2))
  v_t0t1 = 0.5 * (v(0:nx, 0:ny, 1:nz, kt1) + v(0:nx, 0:ny, 1:nz, kt2))

  u_vor = 0.
  v_vor = 0.
  n_steering_s = 0
  do jj = -n_steering_y, n_steering_y
     do ii = -n_steering_x, n_steering_x
        if (      mi + ii >= 0 &
          & .and. mi + ii <= nx &
          & .and. mj + jj >= 0 &
          & .and. mj + jj <= ny) then
          u_int(mi+ii, mj+jj) = integral_p(u_t0t1(mi+ii, mj+jj, 1:nz), p, nz)
          v_int(mi+ii, mj+jj) = integral_p(v_t0t1(mi+ii, mj+jj, 1:nz), p, nz)
          u_vor = u_vor + u_int(mi+ii, mj+jj)
          v_vor = v_vor + v_int(mi+ii, mj+jj)
          n_steering_s = n_steering_s + 1
        endif
     enddo
  enddo

  u_vor = u_vor / n_steering_s
  v_vor = v_vor / n_steering_s

end subroutine steering_wind_f


subroutine steering_wind_r(u, v, p, lon, lat,                                 &
  &                        nx, ny, nz, nt, mi, mj,                            &
  &                        u_vor, v_vor)

  use types, only : wp
  use constants, only: pi, ra, rkilo
  use params, only : r_steering, proj
  use utils, only : integral_p, cosd, sind, great_circle, deg2rad

  implicit none
   
  integer    , intent (in)  :: nx, ny, nz, nt
  real   (wp), intent (in)  :: u     (0:nx, 0:ny, nz, nt)
  real   (wp), intent (in)  :: v     (0:nx, 0:ny, nz, nt)
  real   (wp), intent (in)  :: lon   (0:nx              )
  real   (wp), intent (in)  :: lat   (      0:ny        )
  real   (wp), intent (in)  :: p     (            nz    )
  integer    , intent (in)  :: mi
  integer    , intent (in)  :: mj
  real   (wp), intent (out) :: u_vor
  real   (wp), intent (out) :: v_vor
  ! Local variables
  real   (wp)               :: u_t0t1(0:nx, 0:ny, nz    )
  real   (wp)               :: v_t0t1(0:nx, 0:ny, nz    )
  real   (wp)               :: u_int (0:nx, 0:ny        )
  real   (wp)               :: v_int (0:nx, 0:ny        )

  real   (wp)               :: s_tot
  integer                   :: ii, jj
  real   (wp)               :: d, theta_d
  real   (wp)               :: lonin, latin
  integer                   :: x_steer, y_steer
  integer                   :: kt1, kt2
  integer                   :: add_xy

  kt1 = 1
  kt2 = nt ! should be 2
  add_xy = 0 ! TODO: check why it was +5

  lonin = abs(lon(1) - lon(0))
  latin = abs(lat(1) - lat(0))

  x_steer = nint(r_steering * rkilo / (ra * lonin * deg2rad * cosd(lat(mj))) + add_xy)
  y_steer = nint(r_steering * rkilo / (ra * latin * deg2rad) + add_xy)

  ! print*, '-> x_steer', x_steer
  ! print*, '-> y_steer', y_steer
 
  u_vor = 0.
  v_vor = 0.
  s_tot = 0.
  d = 0.
  theta_d = 0.

  ! print*, '-> u_t0', minval(u(0:nx, 0:ny, 1:nz, kt1)), maxval(u(0:nx, 0:ny, 1:nz, kt1))
  ! print*, '-> u_t1', minval(u(0:nx, 0:ny, 1:nz, kt2)), maxval(u(0:nx, 0:ny, 1:nz, kt2))
  ! print*, '-> min u1-u0', minval(u(0:nx, 0:ny, 1:nz, kt2) - u(0:nx, 0:ny, 1:nz, kt1))
  ! print*, '-> max u1-u0', maxval(u(0:nx, 0:ny, 1:nz, kt2) - u(0:nx, 0:ny, 1:nz, kt2))
  u_t0t1 = 0.5 * (u(0:nx, 0:ny, 1:nz, kt1) + u(0:nx, 0:ny, 1:nz, kt2))
  v_t0t1 = 0.5 * (v(0:nx, 0:ny, 1:nz, kt1) + v(0:nx, 0:ny, 1:nz, kt2))
  ! print*, '-> u_t0t1', minval(u_t0t1), maxval(u_t0t1)
  ! print*, '-> v_t0t1', minval(v_t0t1), maxval(v_t0t1)

  do jj = -y_steer, y_steer
    do ii = -x_steer, x_steer
      if (      mi + ii >= 0 &
        & .and. mi + ii <= nx & 
        & .and. mj + jj >= 0 & 
        & .and. mj + jj <= ny) then
        if (proj == 1) then
          d = great_circle(lon(mi), lon(mi+ii), lat(mj), lat(mj+jj), ra)
        elseif (proj == 2) then
          d = sqrt((ii * lonin)**2 + (jj * latin)**2)
        endif
        if(d <= r_steering * rkilo)then
          u_int(mi+ii, mj+jj) = integral_p(u_t0t1(mi+ii, mj+jj, 1:nz), p, nz)
          v_int(mi+ii, mj+jj) = integral_p(v_t0t1(mi+ii, mj+jj, 1:nz), p, nz)
          ! print*, '--->', lon(mi+ii), lat(mj+jj), u_int(mi+ii, mj+jj), v_int(mi+ii, mj+jj)
          if (proj == 1) then
            u_vor = u_vor + u_int(mi+ii, mj+jj) * cosd(lat(mj+jj))
            v_vor = v_vor + v_int(mi+ii, mj+jj) * cosd(lat(mj+jj))
            s_tot = s_tot + cosd(lat(mj+jj))
          elseif(proj==2)then
            u_vor = u_vor + u_int(mi+ii, mj+jj)
            v_vor = v_vor + v_int(mi+ii, mj+jj)
            s_tot = s_tot + 1
          endif
        endif
      endif
    enddo
  enddo

  u_vor = u_vor / s_tot
  v_vor = v_vor / s_tot

  !print*, u_vor,v_vor

end subroutine steering_wind_r
