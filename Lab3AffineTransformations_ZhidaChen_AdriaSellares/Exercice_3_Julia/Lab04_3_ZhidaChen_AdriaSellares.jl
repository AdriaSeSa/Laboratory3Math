# the packages we need
include("CostumeFunctions.jl")

using Gtk, Graphics, Logging, Printf

# the main window
win = GtkWindow("SO(3)")

render_scale = 50

function init_canvas(h,w)
    # create the drawing canvas
    c = @GtkCanvas(h,w)
    # create the initial drawing inside a try/catch loop
    @guarded draw(c) do widget
        #  draw the background with the canvas drawing context
        # the code for this comes later
        draw_the_canvas(c)
    end

    show(c)
    return c
end

# Conversion from meter to pixel and pixel to meter
PIXEL_TO_METER = 0.01
METER_TO_PIXEL = 100

# make the canvas
the_canvas = init_canvas(800,800)

# Our origin
origin2D = [50 600]

# --------- part 2 -------------
# define all the widgets

# bool that determines if we are at camera viewpoint or global viewpoint
viewpoint_global = false

# bool that determines if we show lines between projection and camera
show_lines = true

# Array of original circle points
circle_points = 0

# Array of circle points view from the camera
camera_points = 0

# Array of circle points on the focal plane
spatial_points = 0

V1 = [1 0 0]
V2 = [0 1 0]
V3 = [0 0 1]

function find_by_name(list, name)
    for item in list
        if get_gtk_property(item, :name, String) == name
            return item
        end
    end
    @warn name, "not found in list"
    @warn "available names are"
    for item in list
        @warn get_gtk_property(item, :name, String)
    end
end

# Make a vector of dimensions x an homogenic vector of dimensions x+1
function homog(v, f=1.0)
    if (typeof(f) != Float64) f = parse(Float64, f) end
    push!(v, f)
    return v
end

# Make a vector of dimenions x a dehmog vector of dimensions x-1
function dehomog(v)
    vector = zeros(Float64, length(v)-1)
    for i = 1:length(v)-1
        vector[i] = v[i]/v[length(v)]
    end
    return vector
end

function button_callback(widget)
    name = get_gtk_property(widget, :name, String)

    if name[1] == 'P'
        global viewpoint_global = !viewpoint_global
    else
        global show_lines = !show_lines
    end

    # actually draw the changes
    draw_the_canvas(the_canvas)
    reveal(the_canvas)

end

function button_box(label_string)

    button = GtkButton(label_string)
    set_gtk_property!(button, :name, label_string)
    set_gtk_property!(button, "halign", 3)
    set_gtk_property!(button, "valign", 3)

    signal_connect(button_callback, button, "clicked")

    return button

end

function bold_label(label_string)
    label = GtkLabel("")
    GAccessor.markup(label, """<b>""" * label_string * """</b>""")
    return label
end

function init_window(win, canvas)

    # make a vertically stacked box for the data entry widgets
    control_box = GtkBox(:v)
    push!(control_box, button_box("Press to change view"))
    push!(control_box, button_box("View Lines"))

    # make another box for the drawing canvas
    canvas_box = GtkBox(:v)
    push!(canvas_box, canvas)

    # make a containing box that will stack the widgets and the canvas side by side
    global_box = GtkBox(:v)
    push!(global_box, canvas_box)
    push!(global_box, GtkLabel("   ")) # a very basic separator
    push!(global_box, control_box)
    push!(global_box, GtkLabel("   ")) # a very basic separator

    # put it all inside the window
    push!(win, global_box)


end

# Draw an axis on a point on screen
function draw_axis(origin2D, R1, R2, R3, ctx)
    # Set line
    set_line_width(ctx, 5)
    set_source_rgb(ctx, 0, 0, 1)
    # Move to Origin
    move_to(ctx, origin2D[1], origin2D[2])
    line_to(ctx, origin2D[1] + R1[1] * render_scale, origin2D[2] - R1[2] * render_scale)
    stroke(ctx)
    # Circle to determine direction
    circle(ctx, origin2D[1] + R1[1] * render_scale, origin2D[2] - R1[2] * render_scale, 5)
    fill(ctx)

    # Repeat on the other two vectors
    set_line_width(ctx, 5)
    set_source_rgb(ctx, 1, 0, 0)
    move_to(ctx , origin2D[1], origin2D[2])
    line_to(ctx, origin2D[1] + R2[1] * render_scale, origin2D[2] - R2[2] * render_scale)
    stroke(ctx)

    circle(ctx, origin2D[1] + R2[1] * render_scale, origin2D[2] - R2[2] * render_scale, 5)
    fill(ctx)


    set_line_width(ctx, 5)
    set_source_rgb(ctx, 0, 1, 0)
    move_to(ctx, origin2D[1], origin2D[2])
    line_to(ctx, origin2D[1] + R3[1] * render_scale, origin2D[2] - R3[2] * render_scale)
    stroke(ctx)

    circle(ctx, origin2D[1] + R3[1] * render_scale, origin2D[2] - R3[2] * render_scale, 5)
    fill(ctx)

end

function resize_matrix(A, rows, cols)
    resized = similar(A, rows, cols)
    resized[1:size(A, 1), 1:size(A, 2)] = A
    return resized
end

# Read circle.txt file
function read_circle()
    # Get path:
    path = joinpath(@__DIR__, "")

    input_path = string(path,"circle.txt")

    # Points array
    points = Float64[]

    open(input_path,"r") do file
        # line_number
        line = 0
        # read till end of file
        while ! eof(file)
            # read a new / next line for every iteration
            read = readline(file)
            line += 1

            # context = current txt line context
            context = split(read,"\t")

            # Get current point into points array
            for i = 1:3
                push!(points,parse(Float64, context[i]))
            end

        end
    end

    # Get number of points based on dimension (3)
    size_points = Int(length(points) / 3)

    # Create a matrix of dimensions (size_points, 3)
    global circle_points = zeros(Float64, (size_points, 3))

    counter = 1

    # Put all the points into the circle_points matrix
    for i = 1:size_points
        for j = 1:3
            circle_points[i,j] = points[counter]
            counter = counter + 1
        end
    end
end

function calculate_circle_coordinates()

    # Calculate camera viewpoint
    camera_pos = [1; 6; 1]
    ay = 90
    az = -20
    focal_distance = 1.0

    # Get rotation
    Ry = [cosd(ay) 0 sind(ay);
           0      1      0;
         -sind(ay) 0 cosd(ay)]

    Rz = [cosd(az) -sind(az) 0;
          sind(az) cosd(az)  0;
             0      0      1]

    rotation_matrix = Rz * Ry

    #Create affine camera base
    camera_affine_base = [rotation_matrix camera_pos]
    camera_affine_base = [camera_affine_base;[0 0 0 1]]

    camera_affine_base_inverted = inv(camera_affine_base)

    # Create projection matrix
    projection_matrix = [focal_distance 0.0 0.0 0.0; 0.0 focal_distance 0.0 0.0; 0.0 0.0 1.0 0.0]

    # Create matrix of the same dimensions as circle_points to store the points on the plane
    global spatial_points = copy(circle_points)

    # Create a matrix of the size of circle_points but 2 dimensional to store the points seen from camera
    global camera_points = zeros(Float64, (size(spatial_points)[1], 2))


    # Calculate camera points and spatial_points
    for i = 1:size(circle_points)[1]
        # Camera Points-----------
        point = [copy(circle_points[i,1]); copy(circle_points[i,2]); copy(circle_points[i,3])]
        point = dehomog(projection_matrix * camera_affine_base_inverted * homog(point))

        for k = 1:2
            camera_points[i,k] = point[k]
        end

        # Spatial points ------------------------------------
        spatial_point = dehomog(camera_affine_base*homog(homog(point, focal_distance)))
        for j = 1:3
            spatial_points[i,j] = spatial_point[j]
        end
    end

end

# Draw the scene in 3D
function draw_canvas_global(ctx)

    # Draw a global axis---------------
    R1 = [10 0 0]
    R2 = [0 10 0]
    R3 = [0 0 10]

    R1 = to_2d(R1)
    R2 = to_2d(R2)
    R3 = to_2d(R3)

    draw_axis(origin2D, R1, R2, R3, ctx)

    # Draw circle on camera plane-----------------------------
    for i = 1:size(spatial_points)[1]
        point = [spatial_points[i,1]; spatial_points[i,2]; spatial_points[i,3]]
        point = to_2d(point)

        set_source_rgb(ctx, 1, 0, 0)
        circle(ctx, origin2D[1] + (point[1] * METER_TO_PIXEL), origin2D[2] + (point[2] * METER_TO_PIXEL), 1)
        fill(ctx)
    end

    # Draw original circle --------------------------------------
    for i = 1:size(circle_points)[1]

        original_point = [circle_points[i,1]; circle_points[i,2]; circle_points[i,3]]
        original_point = to_2d(original_point)
        set_source_rgb(ctx, 0, 0, 1)
        circle(ctx, origin2D[1] + (original_point[1] * METER_TO_PIXEL), origin2D[2] + (original_point[2] * METER_TO_PIXEL), 1)
        fill(ctx)


        # Draw lines from circle points to camera position
        if (show_lines == true)
            camera_pos = to_2d([1;6;1])
            set_line_width(ctx, 1)
            # Move to Origin
            move_to(ctx, origin2D[1] + camera_pos[1] * METER_TO_PIXEL, origin2D[2] + camera_pos[2] * METER_TO_PIXEL)
            line_to(ctx, origin2D[1] + original_point[1] * METER_TO_PIXEL, origin2D[2] + original_point[2] * METER_TO_PIXEL)
            stroke(ctx)
        end
    end

    # Draw camera axis------------------------------------------------------
    camera_pos = to_2d([1;6;1])

    # Get camera pos in 2D
    camera_pos_pixels = [origin2D[1] + (camera_pos[1] * METER_TO_PIXEL); origin2D[2] + (camera_pos[2] * METER_TO_PIXEL)]

    # Get camera axis vectors
    V1 = [1;0;0]
    V2 = [0;1;0]
    V3 = [0;0;1]

    # Rotate vectors on the Y axis
    V1 = rotate_phi(V1, 90, [0;1;0])
    V2 = rotate_phi(V2, 90, [0;1;0])
    V3 = rotate_phi(V3, 90, [0;1;0])

    # Rotate vectors on the resultant Z axis
    V1 = rotate_phi(V1, -20, V3)
    V2 = rotate_phi(V2, -20, V3)
    V3 = rotate_phi(V3, -20, V3)

    V1 = to_2d(V1)
    V2 = to_2d(V2)
    V3 = to_2d(V3)

    # Draw the axis
    draw_axis(camera_pos_pixels, V1, V2, V3, ctx)

end

# Draw the scene in 2D (camera point of view)
function draw_canvas_camera(ctx)
    # Draw circle seen from camera
    for i = 1:size(camera_points)[1]
        set_source_rgb(ctx, 1, 0, 0)
        circle(ctx, 700 + camera_points[i,1] * render_scale * 20, camera_points[i,2] * render_scale * 20  , 1)
        fill(ctx)
    end
end

function draw_the_canvas(canvas)

    h   = height(canvas)
    w   =  width(canvas)
    ctx =  getgc(canvas)
    # clear the canvas
    rectangle(ctx, 0, 0, w, h)
    set_source_rgb(ctx, 1, 1, 1)
    fill(ctx)

    # Check if we are seeing the 3D or 2D point of view
    if (viewpoint_global == true)
        draw_canvas_global(ctx)
    else
        draw_canvas_camera(ctx)
    end
end
println("----------------------------------START--------------------------------")

# prepare and  the initial widgets
init_window(win, the_canvas)
showall(win)
read_circle()
calculate_circle_coordinates()
