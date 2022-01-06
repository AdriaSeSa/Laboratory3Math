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

# make the canvas
the_canvas = init_canvas(800,800)


# --------- part 2 -------------
# define all the widgets

# a widget for status messages that we define at the beginning so we can use it from the callback
msg_label = GtkLabel("No message at this time")

rotation_matrix = [0 0 0; 0 0 0; 0 0 0]

# defaults
default_value = Dict("phi" => 0, "v_x" => 1, "v_y" => 0, "v_z" => 0, "alpha" => 70, "q_s" => 0,  "q_x" => 0,  "q_y" => 0,  "q_z" => 0)

# an array to store the entry boxes
entry_list = []

# an array to store sliders (same functionality as entry_list)
slider_list = []

# an array of labels that we use to display normalized inputs,
# and which also gets modified from the callback
normalized_labels = []

#Coordinates origin
origin3D = [600 600 600]

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

function output_normalized(label, value)
    GAccessor.text(find_by_name(normalized_labels, label), @sprintf("%3.2f", value))
end

function output_normalized_string(label, value)
    GAccessor.text(find_by_name(normalized_labels, label), value)
end

function normalize_v()
    v_x = read_original_box("v_x")
    v_y = read_original_box("v_y")
    v_z = read_original_box("v_z")

    norm = sqrt(v_x*v_x + v_y*v_y + v_z*v_z)

    output_normalized("v_x_normalized", v_x / norm)
    output_normalized("v_y_normalized", v_y / norm)
    output_normalized("v_z_normalized", v_z / norm)
end

function normalize_quat()

    # Read the current quaternion
    q_s = read_original_box("q_s")
    q_x = read_original_box("q_x")
    q_y = read_original_box("q_y")
    q_z = read_original_box("q_z")

    q = Quaternions.Quaternion(q_s, q_x, q_y, q_z, false)

    # Normalize the current quaternion
    q = q/abs(q)

    # Update normalized labels
    output_normalized("q_s_normalized", q.s)
    output_normalized("q_x_normalized", q.v1)
    output_normalized("q_y_normalized", q.v2)
    output_normalized("q_z_normalized", q.v3)
end

function normalize_alpha()
    output_normalized("alpha_normalized", read_slider_box("alpha"))
end

# Updates both the quaternion and rotation matrix based on the current axis and angle
function update_quat_rotation_matrix()

    # Read the current axis and angle
    vx = read_normalized_label("v_x_normalized")
    vy = read_normalized_label("v_y_normalized")
    vz = read_normalized_label("v_z_normalized")
    a = read_normalized_label("alpha_normalized")

    # Update normalized quaternion labels based on the current axis and angle
    q = axis_angle_to_quat(EulerAngleAxis(a, [vx; vy; vz]))
    output_normalized("q_s_normalized", q.s)
    output_normalized("q_x_normalized", q.v1)
    output_normalized("q_y_normalized", q.v2)
    output_normalized("q_z_normalized", q.v3)

    matrix_from_quat = quat_to_mat(q)

    variable_values = ["x", "y", "z"]

    # Update current rotation matrix based on the normalized quaternion
    for i = 1:3
        for j = 1:3
            item_n = string(variable_values[i]) * string(j)
            output_normalized("matrix_" * item_n ,matrix_from_quat[i, j])
        end
    end

end

# Updates both the rotation angle, the axis and the angle based on the current quaternion
function update_rotation_matrix_axis_angle()
    # Read current normalized quaternion
    q_s = read_normalized_label("q_s_normalized")
    q_x = read_normalized_label("q_x_normalized")
    q_y = read_normalized_label("q_y_normalized")
    q_z = read_normalized_label("q_z_normalized")

    q = Quaternions.Quaternion(q_s, q_x, q_y, q_z, false)

    matrix_from_quat = quat_to_mat(q)

    variable_values = ["x", "y", "z"]

    # Update current rotation matrix
    for i = 1:3
        for j = 1:3
            item_n = string(variable_values[i]) * string(j)
            output_normalized("matrix_" * item_n ,matrix_from_quat[i, j])
        end
    end
    # Update current axis angle normalized values
    vector_angle = quat_to_axis_angle(q)
    v = [vector_angle.v[1] vector_angle.v[2] vector_angle.v[3]]
    output_normalized("v_x_normalized", v[1])
    output_normalized("v_y_normalized", v[2])
    output_normalized("v_z_normalized", v[3])
    output_normalized("alpha_normalized", rad2deg(vector_angle.a))

    # Draw changes on canvas
    draw_the_canvas(the_canvas)
    reveal(the_canvas)
end

# Callback function for slider_boxes
function slider_box_callback(widget)
    # who called us?
    name = get_gtk_property(widget, :name, String)

    # If we are updating alpha...
    if name[1] == 'a'
        # ... save current value as noramlized alpha...
        normalize_alpha()
        # ... and update quaternion and rotation matrix to current alpha value
        update_quat_rotation_matrix()
    end
    # actually draw the changes
    draw_the_canvas(the_canvas)
    reveal(the_canvas)
end

function entry_box_callback(widget)
    # who called us?
    name = get_gtk_property(widget, :name, String)
    text = get_gtk_property(widget, :text, String)

    # trumpet this out to the world
    GAccessor.text(msg_label, name * " changed to " * text)

    # change the correct normalized output
    if name[1] == 'v'
        normalize_v()
        # Update quaternion and rotation matrix values based on the axis values
        update_quat_rotation_matrix()
    elseif name[1] == 'q'
        normalize_quat()
        # Update rotation matrix, axis and angle values based on current quaternion
        update_rotation_matrix_axis_angle()
    end

    # actually draw the changes
    draw_the_canvas(the_canvas)
    reveal(the_canvas)
end

function slider_box(label_string, min, max)
    # set up the entry
    entry = GtkScale(false, min:max)
    set_gtk_property!(entry,:name, label_string)

    push!(slider_list, entry)

    # make it communicate changes
    signal_connect(slider_box_callback, entry, "value-changed")

    # make and return the containing box
    hbox = GtkButtonBox(:h)
    push!(hbox, entry)

    return hbox
end

function entry_box(label_string)
    # set up the entry
    entry = GtkEntry()
    set_gtk_property!(entry,:width_chars, 5)
    set_gtk_property!(entry,:max_length, 5)
    set_gtk_property!(entry,:name, label_string)

    default_text = string(default_value[label_string])
    GAccessor.text(entry,default_text)
    push!(entry_list, entry)

    # make it communicate changes
    signal_connect(entry_box_callback, entry, "changed")

    # set up the label and normalized output
    label = GtkLabel(label_string)
    normalized_output = GtkLabel(default_text)
    set_gtk_property!(normalized_output, :name, label_string * "_normalized")

    # make and return the containing box
    hbox = GtkButtonBox(:h)
    push!(hbox, label)
    push!(hbox, entry)
    push!(hbox, normalized_output)

    # export the normalized output for further use
    push!(normalized_labels, normalized_output)

    return hbox
end

function bold_label(label_string)
    label = GtkLabel("")
    GAccessor.markup(label, """<b>""" * label_string * """</b>""")
    return label
end

function phi_box()
    vbox = GtkBox(:v)
    hbox = GtkBox(:h)
    push!(vbox, bold_label("Coordinate rotation"))
    push!(hbox, GtkLabel("\t   phi"))
    push!(hbox, GtkLabel("\t"))
    push!(hbox, slider_box("phi", 0, 360))
    push!(vbox, hbox)
    return vbox
end

function quat_box()
    vbox = GtkBox(:v)

    push!(vbox, bold_label("Rotation Quaternion"))

    for label in ["q_s", "q_x", "q_y", "q_z"]
        push!(vbox, entry_box(label))
    end

    return vbox
end

function vector_angle_box()
    vbox = GtkBox(:v)
    hbox = GtkBox(:h)
    push!(vbox, bold_label("Axis"))

    for label in ["v_x", "v_y", "v_z"]
        push!(vbox, entry_box(label))
    end

    push!(vbox, GtkLabel(""))

    push!(vbox, bold_label("Angle"))

    push!(hbox, GtkLabel("\t alpha"))
    push!(hbox, GtkLabel("\t"))
    push!(hbox, slider_box("alpha", 0, 180))
    # set up the label and normalized output
    label = GtkLabel("alpha")
    normalized_output = GtkLabel("0")
    set_gtk_property!(normalized_output, :name, "alpha_normalized")

    # export the normalized output for further use
    push!(normalized_labels, normalized_output)

    push!(hbox, normalized_output)

    push!(vbox, hbox)

    return vbox
end

function rotation_matrix_label()
    vbox = GtkBox(:v)

    hbox = GtkBox(:h)

    push!(vbox, bold_label("Rotation Matrix"))

    variable_name = ["x", "y", "z"]

    # Set up rotation matrix label
    for i = 1:3
        separation = GtkLabel("\t\t")
        columnBox = GtkBox(:v)
        push!(columnBox, GtkLabel(variable_name[i]))
        push!(hbox, separation)
        push!(hbox, columnBox)
        for j = 1:3
            # Set labels with name "matrix_xj", "matrix_yj", "matrix_zj"
            item = GtkLabel("0.00")
            item_num = string(variable_name[i]) * string(j)
            # Set property to find later
            set_gtk_property!(item, :name, "matrix_" * item_num)
            push!(normalized_labels, item)
            push!(columnBox, item)
        end
    end

    push!(vbox, hbox)

    return vbox

end

# Now put everything into the window,
# including the canvas

function init_window(win, canvas)

    # make a vertically stacked box for the data entry widgets
    control_box = GtkBox(:v)
    push!(control_box, phi_box())
    push!(control_box, GtkLabel(""))
    push!(control_box, vector_angle_box())
    push!(control_box, GtkLabel(""))
    push!(control_box, quat_box())
    push!(control_box, GtkLabel(""))
    push!(control_box, rotation_matrix_label())
    push!(control_box, GtkLabel(""))
    push!(control_box, msg_label)

    # make another box for the drawing canvas
    canvas_box = GtkBox(:v)
    push!(canvas_box, canvas)

    # make a containing box that will stack the widgets and the canvas side by side
    global_box = GtkBox(:h)
    push!(global_box, control_box)
    push!(global_box, GtkLabel("   ")) # a very basic separator
    push!(global_box, canvas_box)

    # put it all inside the window
    push!(win, global_box)


end


# --------- part 3 -------------
# now we make the canvas interactive

function read_box(name, from_which_list, what)
    the_box = find_by_name(from_which_list, name)
    result = parse(Float64, get_gtk_property(the_box, what, String))
    return result
end

function read_original_box(name)
    return read_box(name, entry_list, :text)
end

function read_normalized_label(name)
    return read_box(name, normalized_labels, :label)
end

function read_slider_box(name)
    # Read slider box searching on slider_list
    the_box = find_by_name(slider_list, name)
    result = Gtk.GAccessor.value(the_box)
    return result
end

# Draw the axis at the end of the current vector
function draw_vector_axis(origin2D, position, R1, R2, R3, alpha, ctx, scale)
    #Transfrom alpha to radians
    alpha = deg2rad(alpha)

    # Rescale the three axis
    R1 = rescale_transalte_vector(R1, position*alpha, scale)
    R2 = rescale_transalte_vector(R2, position*alpha, scale)
    R3 = rescale_transalte_vector(R3, position*alpha, scale)

    # Rotate them on current alpha properties
    R1 = rotate_phi(R1, rad2deg(alpha), position)
    R2 = rotate_phi(R2, rad2deg(alpha), position)
    R3 = rotate_phi(R3, rad2deg(alpha), position)

    # Convert them to 2D
    R1 = to_2d(R1)
    R2 = to_2d(R2)
    R3 = to_2d(R3)

    position = to_2d(position)

    #Draw the entire axis
    # Set line
    set_line_width(ctx, 3)
    set_source_rgb(ctx, 0, 0, 1)
    # Move to Origin
    move_to(ctx, origin2D[1] + position[1] *alpha * render_scale, origin2D[2] - position[2]*alpha  * render_scale)
    line_to(ctx, origin2D[1] + R1[1] * render_scale, origin2D[2] - R1[2] * render_scale)
    stroke(ctx)
    # Circle to determine direction
    circle(ctx, origin2D[1] + R1[1] * render_scale, origin2D[2] - R1[2] * render_scale,3)
    fill(ctx)

    # Repeat on the other two vectors
    set_line_width(ctx, 3)
    set_source_rgb(ctx, 1, 0, 0)
    move_to(ctx , origin2D[1] + position[1]*alpha * render_scale, origin2D[2] - position[2] *alpha* render_scale)
    line_to(ctx, origin2D[1] + R2[1] * render_scale, origin2D[2] - R2[2] * render_scale)
    stroke(ctx)

    circle(ctx, origin2D[1] + R2[1] * render_scale, origin2D[2] - R2[2] * render_scale, 3)
    fill(ctx)


    set_line_width(ctx, 3)
    set_source_rgb(ctx, 0, 1, 0)
    move_to(ctx, origin2D[1] + position[1]*alpha  * render_scale, origin2D[2] - position[2]*alpha * render_scale)
    line_to(ctx, origin2D[1] + R3[1] * render_scale, origin2D[2] - R3[2] * render_scale)
    stroke(ctx)

    circle(ctx, origin2D[1] + R3[1] * render_scale, origin2D[2] - R3[2] * render_scale, 3)
    fill(ctx)

end

# Draw the axis vectors of the axonometry
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

function draw_sphere(origin2D, R1, R2, R3, ctx)
    #Create 3 circles, two around R1 using R2 and R3 as axis
    # And the third using R2 or R3 using R1 as axis

    for i = 0:+2:358
        pointR = to_2d(rotate_phi(R1, i, R2))
        set_source_rgb(ctx, 1, 0, 0)
        circle(ctx, origin2D[1] + pointR[1] * render_scale * pi,  origin2D[2] - pointR[2] * render_scale * pi, 1)
        fill(ctx)

        pointG = to_2d(rotate_phi(R1, i, R3))
        set_source_rgb(ctx, 0, 1, 0)
        circle(ctx, origin2D[1] + pointG[1] * render_scale * pi,  origin2D[2] - pointG[2] * render_scale * pi, 1)
        fill(ctx)

        pointB = to_2d(rotate_phi(R2, i, R1))
        set_source_rgb(ctx, 0, 0 , 1)
        circle(ctx, origin2D[1] + pointB[1] * render_scale * pi,  origin2D[2] - pointB[2] * render_scale * pi, 1)
        fill(ctx)
    end

end

function draw_vector(origin2D, V, alpha, ctx)

    #Transfrom alpha to radians
    alpha = deg2rad(alpha)

    # Get line
    set_line_width(ctx, 5)
    set_source_rgb(ctx, 0, 0, 0)
    # Create circle to indicate direction
    circle(ctx, origin2D[1] + V[1] * alpha * render_scale, origin2D[2] - V[2] * alpha * render_scale, 5)
    fill(ctx)
    # Create line
    move_to(ctx, origin2D[1], origin2D[2])
    line_to(ctx, origin2D[1] + V[1] * alpha * render_scale, origin2D[2] - V[2] * alpha * render_scale)
    stroke(ctx)

    # Repeat
    set_line_width(ctx, 2)
    set_source_rgb(ctx, 1, 1, 1)

    circle(ctx, origin2D[1] + V[1] * alpha * render_scale, origin2D[2] - V[2] * alpha * render_scale, 2)
    fill(ctx)

    println("Vector:")
    println(origin2D)
    println(V)
    println(alpha)
    println(render_scale)

    move_to(ctx, origin2D[1], origin2D[2])
    line_to(ctx, origin2D[1] + V[1] * alpha * render_scale, origin2D[2] - V[2] * alpha * render_scale)
    stroke(ctx)

end

# the background drawing
function draw_the_canvas(canvas)
    h   = height(canvas)
    w   =  width(canvas)
    ctx =  getgc(canvas)
    # clear the canvas
    rectangle(ctx, 0, 0, w, h)
    set_source_rgb(ctx, 1, 1, 1)
    fill(ctx)

    # read some normalized boxes and draw a line
    #phi = read_normalized_label("phi_normalized")
    phi = read_slider_box("phi")
    v_x = read_normalized_label("v_x_normalized")
    v_y = read_normalized_label("v_y_normalized")
    v_z = read_normalized_label("v_z_normalized")
    alpha = read_slider_box("alpha")

    #Define origin
    #origin = [250 250]

    origin2D = to_2d(origin3D)

    #Get base vectors on the current phi rotation and pass them to 2d
    R1 = [1 0 0]
    R2 = [0 1 0]
    R3 = [0 0 1]

    R1 = rotate_phi_z(R1, phi)
    R2 = rotate_phi_z(R2, phi)
    R3 = rotate_phi_z(R3, phi)

    draw_sphere(origin2D, R1, R2, R3, ctx)

    R1 = to_2d(R1)
    R2 = to_2d(R2)
    R3 = to_2d(R3)

    draw_axis(origin2D, R1, R2, R3, ctx)

    # Get current vector, rotate on phi and transform to 2d
    V = [v_x v_y v_z]

    V = rotate_phi_z(V, phi)

    # Declare axis on the vector
    R4 = [1 0 0]
    R5 = [0 1 0]
    R6 = [0 0 1]

    # Rotate to current phi value
    R4 = rotate_phi_z(R4, phi)
    R5 = rotate_phi_z(R5, phi)
    R6 = rotate_phi_z(R6, phi)

    # Get axis 3D position
    pos = V

    V = to_2d(V)

    # Draw vector and vector axis on screen
    draw_vector(origin2D, V, alpha, ctx)
    draw_vector_axis(origin2D, pos, R4, R5, R6, alpha, ctx, 0.5)

end
# -------- initialize everything ---------


# prepare and  the initial widgets
init_window(win, the_canvas)
showall(win)
