/* ----- Converters ----- */

vec3 toScreen(vec3 pos){
	vec3 data = vec3(gbufferProjection[0].x, gbufferProjection[1].y, gbufferProjection[2].z) * pos;
	data += gbufferProjection[3].xyz;
	return (data.xyz / -pos.z) * 0.5 + 0.5;
}

vec3 toView(vec3 pos){
	vec3 result = pos * 2.0 - 1.0;
	vec3 viewPos = vec3(vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) * result.xy + gbufferProjectionInverse[3].xy, gbufferProjectionInverse[3].z);
    return viewPos / (gbufferProjectionInverse[2].w * result.z + gbufferProjectionInverse[3].w);
}

vec4 toShadow(vec3 pos){
	vec3 shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * pos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
	float distortFactor = getDistortFactor(shdPos.xy);

	return vec4(shdPos.xyz, distortFactor); // Output final result with distort factor
}

vec3 toScreenSpacePos(vec2 st){
	return vec3(st, texture2D(depthtex0, st).x);
}