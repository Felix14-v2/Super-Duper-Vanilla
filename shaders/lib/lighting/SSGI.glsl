// Written by xirreal#0281 on ShaderLabs
vec3 cosWeightedRandHemisphereDir(vec3 norm, vec2 seed){
    vec2 r = getRand3(seed, 1).xy;
    vec3 uu = normalize(cross(norm, vec3(0, 1, 1)));
    vec3 vv = cross(uu, norm);

    float ra = sqrt(r.y);
    float rx = ra * cos(6.2831 * r.x);
    float ry = ra * sin(6.2831 * r.x);
    float rz = sqrt(1.0 - r.y);
    vec3  rr = vec3(rx * uu + ry * vv + rz * norm);

    return normalize(rr);
}

vec3 getSSGICol(vec3 viewPos, vec3 screenPos, vec3 gBMVNorm, vec2 dither){
    // Sample normal direction...
	vec3 sampleDir = cosWeightedRandHemisphereDir(gBMVNorm, dither);
    // Raytrace scene...
	vec3 GIScreenPos = rayTraceScene(screenPos, viewPos, sampleDir, SSGI_STEPS, 0);
    // Transform coords to previous frame coords
	GIScreenPos.xy = toPrevScreenPos(GIScreenPos.xy);
    
    // Sample color
    vec3 GIcol = texture2D(colortex5, GIScreenPos.xy).rgb * GIScreenPos.z;
    // Output final color and bring it back to HDR
	return 1.0 / (1.0 - GIcol) - 1.0;
}