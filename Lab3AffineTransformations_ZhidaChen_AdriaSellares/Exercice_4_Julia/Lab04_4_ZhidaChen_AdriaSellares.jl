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
origin2D = [400 600]

# --------- part 2 -------------
# define all the widgets

# a widget for status messages that we define at the beginning so we can use it from the callback
msg_label = GtkLabel("No message at this time")

# bool that determines if we are at camera viewpoint or global viewpoint
viewpoint_global = false


# Array of circle points view from the camera
camera_points = 0

# Matrix of the points given by the exercice
vector_points = [0.9115 3.7207 1.9659 2.6663;
                1.9397 2.8794 1.0000 3.8191;
                3.3304 4.4372 3.2588 4.5087]

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
    #if (get_gtk_property(widget, :name, String)[1])

    global viewpoint_global = !viewpoint_global

    # actually draw the changes
    draw_the_canvas(the_canvas)
    reveal(the_canvas)

end

function button_box(label_string)

    button = GtkButton(label_string)
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
    push!(control_box, button_box("Press me"))
    push!(control_box, msg_label)

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
function draw_axis(origin, R1, R2, R3, ctx)
    # Set line
    set_line_width(ctx, 5)
    set_source_rgb(ctx, 0, 0, 1)
    # Move to Origin
    move_to(ctx, origin[1], origin[2])
    line_to(ctx, origin[1] + R1[1] * render_scale, origin[2] - R1[2] * render_scale)
    stroke(ctx)
    # Circle to determine direction
    circle(ctx, origin[1] + R1[1] * render_scale, origin[2] - R1[2] * render_scale, 5)
    fill(ctx)

    # Repeat on the other two vectors
    set_line_width(ctx, 5)
    set_source_rgb(ctx, 1, 0, 0)
    move_to(ctx , origin[1], origin[2])
    line_to(ctx, origin[1] + R2[1] * render_scale, origin[2] - R2[2] * render_scale)
    stroke(ctx)

    circle(ctx, origin[1] + R2[1] * render_scale, origin[2] - R2[2] * render_scale, 5)
    fill(ctx)


    set_line_width(ctx, 5)
    set_source_rgb(ctx, 0, 1, 0)
    move_to(ctx, origin[1], origin[2])
    line_to(ctx, origin[1] + R3[1] * render_scale, origin[2] - R3[2] * render_scale)
    stroke(ctx)

    circle(ctx, origin[1] + R3[1] * render_scale, origin[2] - R3[2] * render_scale, 5)
    fill(ctx)

end

function resize_matrix(A, rows, cols)
    resized = similar(A, rows, cols)
    resized[1:size(A, 1), 1:size(A, 2)] = A
    return resized
end

function calculate_point_coordinates()

    # Calculate camera viewpoint
    camera_pos = [4.665; 3.735; -0.5395]
    axis = [0.01;-0.2;1.0]
    angle = -150
    focal_distance = 1.0

    # Get rotation
    rotation_matrix = axis_angle_to_mat(EulerAngleAxis(angle, axis))

    #Create affine camera base
    camera_affine_base = [rotation_matrix camera_pos]
    camera_affine_base = [camera_affine_base;[0 0 0 1]]
    camera_affine_base_inverted = inv(camera_affine_base)

    # Create projection matrix
    projection_matrix = [focal_distance 0.0 0.0 0.0; 0.0 focal_distance 0.0 0.0; 0.0 0.0 1.0 0.0]

    # Create matrix of the same dimensions as circle_points to store the points on the plane
    global camera_points = zeros(Float64, 4,3)

    # Calculate camera points
    for i = 1:4
        point = [vector_points[1,i]; vector_points[2,i]; vector_points[3,i]]
        point = dehomog(projection_matrix * camera_affine_base_inverted * homog(point))
        for k = 1:2
            camera_points[i,k] = point[k]
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

    # Draw vectors seen from the global viewpoints
    for i = 1:2:4
        origin = [vector_points[1,i]; vector_points[2,i]; vector_points[3,i]]
        destination = [vector_points[1,i+1]; vector_points[2,i+1]; vector_points[3,i+1]]

        origin = to_2d(origin)
        destination = to_2d(destination)

        set_line_width(ctx, 5)
        set_source_rgb(ctx, 0, 0, 1)
        # Move to Origin
        move_to(ctx, origin2D[1] + origin[1] * METER_TO_PIXEL, origin2D[2] + origin[2] * METER_TO_PIXEL)
        line_to(ctx, origin2D[1] + destination[1] * METER_TO_PIXEL, origin2D[2] + destination[2] * METER_TO_PIXEL)
        stroke(ctx)
    end

    # Draw camera axis------------------------------------------------------
    camera_pos = to_2d([4.665; 3.735; -0.5395])

    # Get camera pos in 2D
    camera_pos_pixels = [origin2D[1] + (camera_pos[1] * METER_TO_PIXEL); origin2D[2] + (camera_pos[2] * METER_TO_PIXEL)]

    # Get camera axis vectors
    V1 = [1;0;0]
    V2 = [0;1;0]
    V3 = [0;0;1]

    # Rotate vectors on the axis give by the exercice
    V1 = rotate_phi(V1, -150, [0.01;-0.2;1.0])
    V2 = rotate_phi(V2, -150, [0.01;-0.2;1.0])
    V3 = rotate_phi(V3, -150, [0.01;-0.2;1.0])

    V1 = to_2d(V1)
    V2 = to_2d(V2)
    V3 = to_2d(V3)

    # Draw the axis
    draw_axis(camera_pos_pixels, V1, V2, V3, ctx)

end

# Draw the scene in 2D (camera point of view)
function draw_canvas_camera(ctx)
    # Draw the vectors seen from the camera
    for i = 1:2:3
        origin = [camera_points[i,1] camera_points[i,2]]
        destination = [camera_points[i+1,1] camera_points[i+1,2]]

        set_line_width(ctx, 5)
        set_source_rgb(ctx, 0, 0, 1)
        # Move to Origin
        move_to(ctx, origin2D[1] + origin[1] * METER_TO_PIXEL, origin2D[2] + origin[2] * METER_TO_PIXEL)
        line_to(ctx, origin2D[1] + destination[1] * METER_TO_PIXEL, origin2D[2] + destination[2] * METER_TO_PIXEL)
        stroke(ctx)
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
calculate_point_coordinates()
