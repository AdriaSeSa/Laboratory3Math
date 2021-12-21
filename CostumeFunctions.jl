using LinearAlgebra
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
