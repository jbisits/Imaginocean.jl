module Visualanigans

export heatsphere!, heatlatlon!

using Makie
using Oceananigans
using Oceananigans.Grids: xnode, ynode, total_length, topology

"""
    lat_lon_to_cartesian(longitude, latitude)

Convert `(longitude, latitude)` coordinates (in degrees) to
cartesian coordinates `(x, y, z)` on the unit sphere.
"""
lat_lon_to_cartesian(longitude, latitude) = (lat_lon_to_x(longitude, latitude),
                                             lat_lon_to_y(longitude, latitude),
                                             lat_lon_to_z(longitude, latitude))

"""
    lat_lon_to_x(longitude, latitude)

Convert `(longitude, latitude)` coordinates (in degrees) to cartesian `x` on the unit sphere.
"""
lat_lon_to_x(longitude, latitude) = cosd(longitude) * cosd(latitude)

"""
    lat_lon_to_y(longitude, latitude)

Convert `(longitude, latitude)` coordinates (in degrees) to cartesian `y` on the unit sphere.
"""
lat_lon_to_y(longitude, latitude) = sind(longitude) * cosd(latitude)

"""
    lat_lon_to_z(longitude, latitude)

Convert `(longitude, latitude)` coordinates (in degrees) to cartesian `z` on the unit sphere.
"""
lat_lon_to_z(longitude, latitude) = sind(latitude)
    
longitude_in_same_window(λ₁, λ₂) = mod(λ₁ - λ₂ + 180, 360) + λ₂ - 180

flip_location(::Center) = Face()
flip_location(::Face) = Center()

"""
    get_longitude_vertices(i, j, k, grid::Union{LatitudeLongitudeGrid, OrthogonalSphericalShellGrid}, ℓx, ℓy, ℓz)

Return the longitudes that correspond to the four vertices of cell `i, j, k` at
locatiopn `(ℓx, ℓy, ℓz)`. The first vertice is the cell's Southern-Western one
and the rest follow in counter-clockwise order.
"""
function get_longitude_vertices(i, j, k, grid::Union{LatitudeLongitudeGrid, OrthogonalSphericalShellGrid}, ℓx, ℓy, ℓz)

    if ℓx == Center()
        i₀ = i
    elseif ℓx == Face()
        i₀ = i-1
    end

    if ℓy == Center()
        j₀ = j
    elseif ℓy == Face()
        j₀ = j-1
    end

    λ₁ = xnode( i₀,   j₀,  k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)
    λ₂ = xnode(i₀+1,  j₀,  k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)
    λ₃ = xnode(i₀+1, j₀+1, k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)
    λ₄ = xnode( i₀,  j₀+1, k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)

    return [λ₁; λ₂; λ₃; λ₄]
end

"""
    get_latitude_vertices(i, j, k, grid::Union{LatitudeLongitudeGrid, OrthogonalSphericalShellGrid}, ℓx, ℓy, ℓz)

Return the latitudes that correspond to the four vertices of cell `i, j, k` at
locatiopn `(ℓx, ℓy, ℓz)`. The first vertice is the cell's Southern-Western one
and the rest follow in counter-clockwise order.
"""
function get_latitude_vertices(i, j, k, grid::Union{LatitudeLongitudeGrid, OrthogonalSphericalShellGrid}, ℓx, ℓy, ℓz)

    if ℓx == Center()
        i₀ = i
    elseif ℓx == Face()
        i₀ = i-1
    end

    if ℓy == Center()
        j₀ = j
    elseif ℓy == Face()
        j₀ = j-1
    end

    φ₁ = ynode( i₀,   j₀,  k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)
    φ₂ = ynode(i₀+1,  j₀,  k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)
    φ₃ = ynode(i₀+1, j₀+1, k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)
    φ₄ = ynode( i₀,  j₀+1, k, grid, flip_location(ℓx), flip_location(ℓy), ℓz)

    return [φ₁; φ₂; φ₃; φ₄]
end

"""
    get_lat_lon_nodes_and_vertices(grid, ℓx, ℓy, ℓz)

Return the latitude-longitude coordinates of the horizontal nodes of the
`grid` at locations `ℓx`, `ℓy`, and `ℓz` and also the coordinates of the four
vertices that determine the cell surrounding each node.

See [`get_longitude_vertices`](@ref) and [`get_latitude_vertices`](@ref).
"""
function get_lat_lon_nodes_and_vertices(grid, ℓx, ℓy, ℓz)

    TX, TY, TZ = topology(grid)

    nλ, nφ = total_length(ℓx, TX(), grid.Nx, 0), total_length(ℓy, TY(), grid.Ny, 0)

    λ = zeros(eltype(grid), nλ, nφ)
    φ = zeros(eltype(grid), nλ, nφ)

    for j in 1:nφ, i in 1:nλ
        λ[i, j] = xnode(i, j, 1, grid, ℓx, ℓy, ℓz)
        φ[i, j] = ynode(i, j, 1, grid, ℓx, ℓy, ℓz)
    end

    λvertices = zeros(4, size(λ)...)
    φvertices = zeros(4, size(φ)...)

    for j in 1:nφ, i in 1:nλ
        λvertices[:, i, j] = get_longitude_vertices(i, j, 1, grid, ℓx, ℓy, ℓz)
        φvertices[:, i, j] =  get_latitude_vertices(i, j, 1, grid, ℓx, ℓy, ℓz)
    end

    λ = mod.(λ .+ 180, 360) .- 180
    λvertices = longitude_in_same_window.(λvertices, reshape(λ, (1, size(λ)...)))
    
    return (λ, φ), (λvertices, φvertices)
end

"""
    get_cartesian_nodes_and_vertices(grid::Union{LatitudeLongitudeGrid, OrthogonalSphericalShellGrid}, ℓx, ℓy, ℓz)

Return the cartesian coordinates of the horizontal nodes of the `grid`
at locations `ℓx`, `ℓy`, and `ℓz` on the unit sphere and also the corresponding
coordinates of the four vertices that determine the cell surrounding each node.

See [`get_lat_lon_nodes_and_vertices`](@ref).
"""
function get_cartesian_nodes_and_vertices(grid::Union{LatitudeLongitudeGrid, OrthogonalSphericalShellGrid}, ℓx, ℓy, ℓz)

    (λ, φ), (λvertices, φvertices) = get_lat_lon_nodes_and_vertices(grid, ℓx, ℓy, ℓz)

    x = similar(λ)
    y = similar(λ)
    z = similar(λ)

    xvertices = similar(λvertices)
    yvertices = similar(λvertices)
    zvertices = similar(λvertices)

    nλ, nφ = size(λ)

    for j in 1:nφ, i in 1:nλ
        x[i, j] = lat_lon_to_x(λ[i, j], φ[i, j])
        y[i, j] = lat_lon_to_y(λ[i, j], φ[i, j])
        z[i, j] = lat_lon_to_z(λ[i, j], φ[i, j])

        for vertex in 1:4
            xvertices[vertex, i, j] = lat_lon_to_x(λvertices[vertex, i, j], φvertices[vertex, i, j])
            yvertices[vertex, i, j] = lat_lon_to_y(λvertices[vertex, i, j], φvertices[vertex, i, j])
            zvertices[vertex, i, j] = lat_lon_to_z(λvertices[vertex, i, j], φvertices[vertex, i, j])
        end
    end

    return (x, y, z), (xvertices, yvertices, zvertices)
end

function heatsphere!(ax::Axis3, field::Field, k=1; kwargs...)
    LX, LY, LZ = location(field)
    grid = field.grid

    _, (xvertices, yvertices, zvertices) = get_cartesian_nodes_and_vertices(grid, LX(), LY(), LZ())

    quad_points3 = vcat([Point3.(xvertices[:, i, j], yvertices[:, i, j], zvertices[:, i, j]) for i in axes(xvertices, 2), j in axes(xvertices, 3)]...)
    quad_faces = vcat([begin; j = (i-1) * 4 + 1; [j j+1  j+2; j+2 j+3 j]; end for i in 1:length(quad_points3)÷4]...)
    
    colors_per_point = vcat(fill.(vec(interior(field, :, :, k)), 4)...)
    
    mesh!(ax, quad_points3, quad_faces; color = colors_per_point, shading = false, kwargs...)

    return ax
end

function heatlatlon!(ax::Axis, field::Field, k=1; kwargs...)
    LX, LY, LZ = location(field)
    grid = field.grid

    _, (λvertices, φvertices) = get_lat_lon_nodes_and_vertices(grid, LX(), LY(), LZ())

    quad_points = vcat([Point2.(λvertices[:, i, j], φvertices[:, i, j]) for i in 1:size(λvertices, 2), j in 1:size(λvertices, 3)]...)
    quad_faces = vcat([begin; j = (i-1) * 4 + 1; [j j+1  j+2; j+2 j+3 j]; end for i in 1:length(quad_points)÷4]...)

    colors_per_point = vcat(fill.(vec(interior(field, :, :, k)), 4)...)

    mesh!(ax, quad_points, quad_faces; color = colors_per_point, shading = false, kwargs...)

    xlims!(ax, (-180, 180))
    ylims!(ax, (-90, 90))

    return ax
end

end # module Visualanigans
