shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
// Code de fragment
    ALBEDO = vec4(0.0, 0.0, 0.0, 0.5); // Couleur noire avec une transparence de 0.5
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
