// Complex lighting calculations all go here
vec3 complexLighting(matPBR material, positionVectors posVector, vec3 dither){
	// Get positions
	vec3 reflectedPlayerPos = reflect(posVector.playerPos, material.normal_m);
	vec3 nLightPos = normalize(posVector.lightPos);
    vec3 nPlayerPos = normalize(-posVector.playerPos);
	vec3 lightVec = normalize(posVector.lightPos - posVector.playerPos);
	vec3 gBMVNorm = mat3(gbufferModelView) * material.normal_m;
	vec3 nDither = dither * 2.0 - 1.0;
	material.light_m = material.light_m;

	/* -Global illumination- */

	// Get direct light diffuse color
	vec3 diffuseCol = getShdMapping(material, posVector.shdPos, nLightPos, dither.r) * lightCol;
	// Get globally illuminated sky
	vec3 GISky = getSkyRender(material.normal_m, 0.0, skyCol, lightCol) * cubed(material.light_m.y);

	#ifdef SSGI
		// Get SSGI
		vec3 GIcol = getSSGICol(posVector.viewPos, posVector.screenPos, gBMVNorm, dither.xy);
	#else
		vec3 GIcol = vec3(0);
	#endif

	/* -Reflections- */

	// Get fresnel
    vec3 F0 = mix(vec3(0.04), material.albedo_t, material.metallic_m);
    vec3 fresnel = getFresnelSchlick(dot(material.normal_m, nPlayerPos), F0);
	// Get specular GGX
	vec3 specCol = getSpecGGX(material, fresnel, nPlayerPos, nLightPos, lightVec) * diffuseCol;

	#ifdef SSR
		vec4 SSRCol = getSSRCol(posVector.viewPos, posVector.screenPos, gBMVNorm, nDither, material.roughness_m);
	#else
		vec4 SSRCol = vec4(0);
	#endif
	
	// Get reflected sky
    vec3 reflectedSkyRender = getSkyRender(reflectedPlayerPos, pow(material.light_m.y, 1.0 / 5.0), skyCol, lightCol) * sqrt(material.light_m.y);

	// Mask reflections
    vec3 reflectCol = mix(reflectedSkyRender, SSRCol.rgb, SSRCol.a);
    reflectCol = reflectCol * fresnel * (1.0 - material.roughness_m); // Will change this later next patch...

	material.albedo_t *= 1.0 - material.metallic_m;

	/* Add lighting */
    return material.albedo_t * (diffuseCol + (GISky + cubed(material.light_m.x) * BLOCK_LIGHT_COL) * material.ambient_m + GIcol + material.emissive_m) + specCol + reflectCol;
}