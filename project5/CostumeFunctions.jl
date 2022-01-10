using LinearAlgebra, Quaternions, ReferenceFrameRotations
# Check if a given vector is three-dimensional
function check_vector_3(v)
    if size(v) != (1,3) && size(v) != (3, 1) && size(v) != (3,)
        println(size(v))
        println("\nIncorrect vector3. You must introduce an R3 vector.")
        return false
    end
end
# Format vector3 to be vertically oriented
function format_vector_3(v)
    if size(v) == (1,3)
        v = v'
    end
    return v
end

function to_2d(vector3)
    # Check if the given vector is actually on three dimensions
    if check_vector_3(vector3) == false return end
    # If the vector is given horizontal, we transpose it
    vector3 = format_vector_3(vector3)

    # Defined matrix to convert R3 vector to R2 vector
    # (we find this matrix on the .pdf attached file)
    axonometry_matrix = [-0.5*cosd(42)    cosd(7)     0;
                       -0.5*sind(42)    -sind(7)    1]

    #=axonometry_matrix = [-cosd(30)    cosd(30)     0;
                        -sind(30)    -sind(30)    1]=#

    # Return the result of the multiplication
    return axonometry_matrix * vector3
end

function rotate_phi_z(X, phi)
    # Check if the given vector is actually on three dimensions
    if check_vector_3(X) == false
        return
    end
    # If the vector is given horizontal, we transpose it
    X = format_vector_3(X)

    # Define rotation matrix on Z axis
    R = [ 0 -1 0;
          1 0 0;
          0 0 0 ]

    # Apply the Rodrigues formula
    result = I + sind(phi) * R + (1 - cosd(phi)) * R^2

    # Calculate result using the rotation matrix
    T = result * X
    return T

end

function rotate_phi(X, phi, axis)
    # Check if the given vector is actually on three dimensions
    if check_vector_3(X) == false
        return
    end
    # If the vector is given horizontal, we transpose it
    X = format_vector_3(X)

    axis = normalize(axis)

    # Define rotation matrix on Z axis
    R = [ 0      -axis[3]    axis[2];
         axis[3]    0      -axis[1];
         -axis[2]  axis[1]      0 ]

    # Apply the Rodrigues formula
    result = I + sind(phi) * R + (1 - cosd(phi)) * R^2

    # Calculate result using the rotation matrix
    T = result * X
    return T

end

# To check if the given vector is of dimension 3
function check_vector_3(v)
    if size(v) != (1,3) && size(v) != (3, 1) && size(v) != (3,)
        print("Your vector is size ", size(v))
        println("\nIncorrect vector3. You must introduce an R3 vector.")
        return false
    end
end

# To check if the given object is a Quaternion
function check_quaternion(q)
    if typeof(q) == Quaternions.Quaternion{Float64} || typeof(q) == Quaternions.Quaternion{Int64}
        return true
    end
    println("You must introduce a valid Quaternion! Using Quaternion()")
    return false
end

# To check if the given matrix is of dimensions 3x3
function check_matrix_3(R)
    if size(R) != (3,3)
        print("Your matrix is size ", size(R))
        println("\nIncorrect matrix. You must introduce a 3x3 matrix.")
        return false
    end
end

function check_euler_angleaxis(E)
    if typeof(E) == EulerAngleAxis{Float64} || typeof(E) == EulerAngleAxis{Int64}
        return true
    end
    println("Incorrect EulerAngleAxis. You must introduce an EulerAngleAxis()")
    return false
end
# Axis/Angle to Quaternion
function axis_angle_to_quat(E)

    if check_euler_angleaxis(E) == false
        return
    end

    # We get the axis from our EulerAngleAxis
    V = Vector{Float64}(E.v)
    # We get the angle from our EulerAngleAxis
    phi = E.a

    # Use qrotation function to create a Quaternion with the given axis and angle
    qR = qrotation(V, phi)

    return qR

end

function axis_angle_to_mat(E)

    if check_euler_angleaxis(E) == false
        return
    end
    # We get the axis from our EulerAngleAxis
    V = normalize(E.v)
    # We get the angle from our EulerAngleAxis
    phi = E.a

    # We use Rodrigues Formula to find the Rotation matrix
    # Define rotation matrix on Z axis
    R = [ 0     -V[3]   V[2];
          V[3]   0      -V[1];
         -V[2]   V[1]      0 ]

    # Apply the Rodrigues formula
    result = I + sin(phi) * R + (1 - cos(phi)) * R^2

    return result
end

function mat_to_axis_angle(R)
    if check_matrix_3(R) == false
        return
    end

# Find angle
phi = acos((tr(R) -1) / 2)

# Find axis matrix
V = (R - R') / (2 * sin(phi))

# Get axis values from the axis matrix into a vector
axis = [V[3,2]; V[1,3]; V[2,1]]

return EulerAngleAxis(phi, axis)
end

function quat_to_axis_angle(q)
    if check_quaternion(q) == false
        return
    end

    # Get the angle
    angle = 2 * atan(sqrt(q.v1^2 + q.v2^2 + q.v3^2) / q.s)

    # Normalize the Quaternion
    q = normalize(q)

    # We do the same process as in the
    s = sin(angle/2)

    # If the s is not zero, we divide. If it is zero, we can't divide.
    # Therefore, we set axis as the [1 0 0] vector
    s != 0 ? axis = [q.v1; q.v2; q.v3] / s : axis = [1.0; 0.0; 0.0]

    return EulerAngleAxis(angle, axis)
end

function quat_to_mat(q)
    if check_quaternion(q) == false
        return
    end
    # We apply the matrix to Quaternion transformation
    R = [q.s^2 + q.v1^2 - q.v2^2 - q.v3^2    2*q.v1*q.v2 - 2*q.s*q.v3            2*q.v1*q.v3 + 2*q.s*q.v2;
     2*q.v1*q.v2 + 2*q.s*q.v3                q.s^2 - q.v1^2 + q.v2^2 - q.v3^2    2*q.v2*q.v3 - 2*q.s*q.v1;
     2*q.v1*q.v3 - 2*q.s*q.v2                2*q.v2*q.v3 + 2*q.s*q.v1            q.s^2 - q.v1^2 - q.v2^2 + q.v3^2]

     return R

end

function mat_to_quat(R)
    if check_matrix_3(R) == false
        return
    end

    E = mat_to_axis_angle(R)

    q = axis_angle_to_quat(E)

    return q
end

function rescale_transalte_vector(V, pos, scale)
    # Get Vector without considering origin
    # Change Vector position using pos
    # Position is on world coordinates (always positive)

    #Check vector and position are on the correct format
    V = format_vector_3(V)
    pos = format_vector_3(pos)

    # Rescale vector
    V = V*scale

    # Change vector position
    V = V+pos

    return V

end

#=
Z = rotate_phi([1;1;1], 25, [0;0;1])
Y = rotate_phi(Z, 145, [0;1;0])
X = rotate_phi(Y, 30, [1;0;0])

Mz = [cosd(25) -sind(25) 0;
        sind(25) cosd(25) 0;
        0 0 1]
My =  [cosd(145) 0 sind(145);
        0       1           0;
        -sind(145) 0 cosd(145)]

Mx = [1 0 0;
    0 cosd(30) -sind(30);
    0 sind(30) cosd(30)]

Mr = Mx * My * Mz

Mri = inv(Mr)

MBA = [Mri[1,1] Mri[1,2] Mri[1,3] 3;
        Mri[2,1] Mri[2,2] Mri[2,3] 1;
        Mri[3,1] Mri[3,2] Mri[3,3] -2;
        0 0 0 1]

MAB = [Mr[1,1] Mr[1,2] Mr[1,3] 0;
        Mr[2,1] Mr[2,2] Mr[2,3] 0;
        Mr[3,1] Mr[3,2] Mr[3,3] 0;
        0 0 0 1]

Mi = inv(MBA)

r1 = MAB * [3, 1, -2, 1]
r2 = MBA * r1=#
