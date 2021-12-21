using LinearAlgebra, Quaternions, ReferenceFrameRotations

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

# Testing the functions
#You must use an EulerAngelAxis() to use the
#axis_angle_to_mat() and axis_angle_to_quat() functions
#You must use a Quaternion() to use the quat_to_mat()
#and quat_to_axis_angle()

# You must have installed the "Quaternions" and "ReferenceFrameRotations" packages
# import Pkg; Pkg.add("Quaternions")
# import Pkg; Pkg.add("ReferenceFrameRotations")

# Remember to use deg2rad(x) if you were to introduce a degree instead of a radian
E = EulerAngleAxis(deg2rad(90), [1; 2; 3])

println("\n-----------Test1----------------")

q = axis_angle_to_quat(E)
println("\nQuaternion: ", q)
R = quat_to_mat(q)
println("Rotation Matrix: ", R)
E2 = mat_to_axis_angle(R)
print("EulerAngleAxis after functions: ", E2)

print("\nOriginal EulerAngelAxis: ",E)

println("\n\n-----------Test2----------------\n")

R_2 = axis_angle_to_mat(E)
println("Rotation Matrix: ", R_2)
q_2 = mat_to_quat(R_2)
println("Quaternion: ", q_2)
E2_2 = quat_to_axis_angle(q_2)
print("EulerAngleAxis after functions: ", E2_2)

print("\nOriginal EulerAngelAxis: ",E)
