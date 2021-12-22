# the packages we need
include("CostumeFunctions.jl")

using Gtk, Graphics, Logging, Printf, Quaternions

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

# an array of labels that we use to display normalized inputs,
# and which also gets modified from the callback
normalized_labels = []

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

    q_s = read_original_box("q_s")
    q_x = read_original_box("q_x")
    q_y = read_original_box("q_y")
    q_z = read_original_box("q_z")

    q = Quaternions.Quaternion(q_s, q_x, q_y, q_z, false)

    q = q/abs(q)

    output_normalized("q_s_normalized", q.s)
    output_normalized("q_x_normalized", q.v1)
    output_normalized("q_y_normalized", q.v2)
    output_normalized("q_z_normalized", q.v3)
end

function normalize_alpha()
    output_normalized("alpha_normalized", read_original_box("alpha"))
end

function normalize_phi()
    output_normalized("phi_normalized", read_original_box("phi"))
end

function update_rotation_matrix()

    q_s = read_normalized_label("q_s_normalized")
    q_x = read_normalized_label("q_x_normalized")
    q_y = read_normalized_label("q_y_normalized")
    q_z = read_normalized_label("q_z_normalized")

    q = Quaternions.Quaternion(q_s, q_x, q_y, q_z, false)

    matrix_from_quat = quat_to_mat(q)

    variable_values = ["x", "y", "z"]

    for i = 1:3
        println("test")
        for j = 1:3
            item_n = string(variable_values[i]) * string(j)
            output_normalized("matrix_" * item_n ,matrix_from_quat[i, j])
        end
    end

end


function entry_box_callback(widget)
    # who called us?
    name = get_gtk_property(widget, :name, String)
    text = get_gtk_property(widget, :text, String)

    # trumpet this out to the world
    GAccessor.text(msg_label, name * " changed to " * text)

    #println(name[1])

    # change the correct normalized output
    if name[1] == 'v'
        normalize_v()
    elseif name[1] == 'a'
        normalize_alpha()
    elseif name[1] == 'p'
        normalize_phi()
    elseif name[1] == 'q'
        normalize_quat()
        update_rotation_matrix()
    end

    # actually draw the changes
    draw_the_canvas(the_canvas)
    reveal(the_canvas)
end

function entry_box(label_string)
    # set up the entry
    entry = GtkEntry()
    set_gtk_property!(entry,:width_chars, 5)
    set_gtk_property!(entry,:max_length, 5)
    set_gtk_property!(entry,:name, label_string)

    default_text = string(default_value[label_string])
    GAccessor.text(entry, default_text)
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
    push!(vbox, bold_label("Coordinate rotation"))
    push!(vbox, entry_box("phi"))
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

    push!(vbox, bold_label("Axis"))

    for label in ["v_x", "v_y", "v_z"]
        push!(vbox, entry_box(label))
    end

    push!(vbox, bold_label("Angle"))

    push!(vbox, entry_box("alpha"))
    return vbox
end

function rotation_matrix_label()
    vbox = GtkBox(:v)

    hbox = GtkBox(:h)

    push!(vbox, bold_label("Rotation Matrix"))

    variable_name = ["x", "y", "z"]

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

# Draw the axis vectors of the axonometry
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

function draw_sphere(origin, R1, R2, R3, ctx)
    #Create 3 circles, two around R1 using R2 and R3 as axis
    # And the third using R2 or R3 using R1 as axis

    for i = 0:+2:358
        pointR = to_2d(rotate_phi(R1, i, R2))
        set_source_rgb(ctx, 1, 0, 0)
        circle(ctx, origin[1] + pointR[1] * render_scale * pi,  origin[2] - pointR[2] * render_scale * pi, 1)
        fill(ctx)

        pointG = to_2d(rotate_phi(R1, i, R3))
        set_source_rgb(ctx, 0, 1, 0)
        circle(ctx, origin[1] + pointG[1] * render_scale * pi,  origin[2] - pointG[2] * render_scale * pi, 1)
        fill(ctx)

        pointB = to_2d(rotate_phi(R2, i, R1))
        set_source_rgb(ctx, 0, 0 , 1)
        circle(ctx, origin[1] + pointB[1] * render_scale * pi,  origin[2] - pointB[2] * render_scale * pi, 1)
        fill(ctx)
    end

end

function draw_vector(origin, V, alpha, ctx)

    # Get line
    set_line_width(ctx, 5)
    set_source_rgb(ctx, 0, 0, 0)
    # Create circle to indicate direction
    circle(ctx, origin[1] + V[1] * alpha, origin[2] - V[2] * alpha, 5)
    fill(ctx)
    # Create line
    move_to(ctx, origin[1], origin[2])
    line_to(ctx, origin[1] + V[1] * alpha, origin[2] - V[2] * alpha)
    stroke(ctx)

    # Repeat
    set_line_width(ctx, 2)
    set_source_rgb(ctx, 1, 1, 1)

    circle(ctx, origin[1] + V[1] * alpha, origin[2] - V[2] * alpha, 2)
    fill(ctx)

    move_to(ctx, origin[1], origin[2])
    line_to(ctx, origin[1] + V[1] * alpha, origin[2] - V[2] * alpha)
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
    phi = read_normalized_label("phi_normalized")
    v_x = read_normalized_label("v_x_normalized")
    v_y = read_normalized_label("v_y_normalized")
    v_z = read_normalized_label("v_z_normalized")
    alpha = read_original_box("alpha")

    #Check if alpha is on the 0 to 180 range
    alpha > 180 ? alpha = 180 : alpha < 0 ? alpha = 0 : alpha = alpha

    #Define origin
    origin = [250 250]

    #Get base vectors on the current phi rotation and pass them to 2d
    R1 = [1 0 0]
    R2 = [0 1 0]
    R3 = [0 0 1]

    R1 = rotate_phi_z(R1, phi)
    R2 = rotate_phi_z(R2, phi)
    R3 = rotate_phi_z(R3, phi)

    draw_sphere(origin, R1, R2, R3, ctx)

    R1 = to_2d(R1)
    R2 = to_2d(R2)
    R3 = to_2d(R3)

    draw_axis(origin, R1, R2, R3, ctx)

    # Get current vector, rotate on phi and transform to 2d
    V = [v_x v_y v_z]

    V = rotate_phi_z(V, phi)
    V = to_2d(V)

    # Draw vector on screen
    draw_vector(origin, V, alpha, ctx)
end


# -------- initialize everything ---------


# prepare and  the initial widgets
init_window(win, the_canvas)
showall(win)
